-- ============================================================================
-- Converted SQL Statements for PostgreSQL (from MS SQL Server)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation/conversion did not complete after 15 attempts
-- All 7 statements attempted through DMS, all failed with timeout
-- Total Statements: 7
-- ============================================================================

-- ==========================================================================
-- Statement 1: GetAllProductsAsync (converted to PostgreSQL)
-- Conversion: Lowercase schema objects; CTE/window functions compatible
-- ==========================================================================
WITH productstats AS (
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
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ==========================================================================
-- Statement 2: GetProductByIdAsync (converted to PostgreSQL)
-- Conversion: Lowercase schema objects; LAG window function compatible
-- ==========================================================================
WITH producthistory AS (
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
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ==========================================================================
-- Statement 3: InsertProductAsync (converted to PostgreSQL)
-- Conversion: SCOPE_IDENTITY() -> RETURNING/lastval(), GETDATE() -> NOW(),
--   DECLARE/SET removed, transaction block restructured for PostgreSQL DO block
-- Note: For ADO.NET usage, this is restructured as individual statements
--   with RETURNING clause instead of SCOPE_IDENTITY()
-- ==========================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (followed by separate statements in application code for history and stats)
-- INSERT INTO producthistory ...
-- UPDATE productstats ...

-- ==========================================================================
-- Statement 4: UpdateProductAsync (converted to PostgreSQL)
-- Conversion: GETDATE() -> NOW(), DECLARE removed, lowercase schema objects
-- Note: Variables replaced with subqueries for PostgreSQL compatibility
-- ==========================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
)
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- ==========================================================================
-- Statement 5: DeleteProductAsync (converted to PostgreSQL)
-- Conversion: GETDATE() -> NOW(), DECLARE removed, lowercase schema objects
-- ==========================================================================
DELETE FROM products 
WHERE productid = @ProductId;

-- ==========================================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted to PostgreSQL)
-- Conversion: Lowercase schema objects; RANK/PERCENT_RANK compatible
-- ==========================================================================
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

-- ==========================================================================
-- Statement 7: GetLowStockProductsAsync (converted to PostgreSQL)
-- Conversion: Lowercase schema objects; AVG/MIN/MAX OVER() compatible
-- ==========================================================================
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
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
