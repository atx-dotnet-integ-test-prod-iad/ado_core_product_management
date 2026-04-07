-- ============================================================================
-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL 13 (ProductManagement database)
-- Schema: productmanagement_dbo (from DMS schema mapping)
-- Conversion Date: 2026-04-07
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Note: DMS statement conversion tool failed (metadata model creation/conversion timeout)
--       Schema mappings were successfully retrieved from DMS and used for conversion
-- ============================================================================

-- =============================================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Original CTE alias "ProductStats" renamed to "productstats_cte" to avoid 
-- conflict with the actual "productstats" table
-- ROUND function works the same in PostgreSQL
-- =============================================================================
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- =============================================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Original CTE alias "ProductHistory" renamed to "producthistory_cte" to avoid
-- conflict with the actual "producthistory" table
-- LAG window function works the same in PostgreSQL
-- =============================================================================
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- =============================================================================
-- Statement 3: InsertProductAsync (converted)
-- SCOPE_IDENTITY() -> RETURNING productid
-- GETDATE() -> clock_timestamp()
-- Transaction block restructured for PostgreSQL
-- DECLARE/SET -> use subquery with RETURNING clause
-- The C# code uses ExecuteScalarAsync, so we need to return the new ID
-- PostgreSQL approach: Use RETURNING on first INSERT, then use CTE or 
-- separate statements. Since Npgsql supports multiple statements, we restructure.
-- =============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements for InsertProductAsync are handled separately in C# code
-- after capturing the returned productid:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
--
-- UPDATE productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = clock_timestamp()
-- WHERE statid = 1;

-- =============================================================================
-- Statement 4: UpdateProductAsync (converted)
-- DECLARE @var -> SELECT INTO within DO block or separate queries
-- GETDATE() -> clock_timestamp()
-- Transaction managed by C# code (BeginTransactionAsync/CommitAsync)
-- Restructured as multiple statements for C# execution
-- =============================================================================
-- Step 1: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Step 2: Update product
UPDATE products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId;
-- Step 3: Log changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
-- Step 4: Update stats
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp() WHERE statid = 1;

-- =============================================================================
-- Statement 5: DeleteProductAsync (converted)
-- Same pattern as UpdateProductAsync - restructured as multiple statements
-- GETDATE() -> clock_timestamp()
-- CASE expression works the same in PostgreSQL
-- =============================================================================
-- Step 1: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Step 2: Log deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
-- Step 3: Delete product
DELETE FROM products WHERE productid = @ProductId;
-- Step 4: Update stats
UPDATE productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END, lastupdated = clock_timestamp() WHERE statid = 1;

-- =============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- RANK() and PERCENT_RANK() work the same in PostgreSQL
-- BETWEEN works the same in PostgreSQL
-- =============================================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- =============================================================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- AVG/MIN/MAX OVER() work the same in PostgreSQL
-- Added CAST for integer division to produce correct ROUND results
-- ROUND works the same in PostgreSQL for NUMERIC types
-- =============================================================================
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
