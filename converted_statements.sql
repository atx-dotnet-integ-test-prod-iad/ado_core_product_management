-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Target Schema: productmanagement_dbo (table/column names lowercase per DMS mapping)
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Original: CTE with ProductStats, window functions AVG/COUNT OVER()
-- Changes: All identifiers converted to lowercase per DMS schema mapping
-- ROUND needs explicit CAST for numeric division in PostgreSQL
-- ============================================================================
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

-- ============================================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Original: CTE with LAG window functions for ProductHistory
-- Changes: All identifiers lowercase, @ProductId kept as @ProductId (Npgsql supports @param)
-- ============================================================================
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

-- ============================================================================
-- Statement 3: InsertProductAsync (converted)
-- Original: DECLARE @NewProductId, SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
-- Changes: 
--   - Removed DECLARE @NewProductId (not needed, use RETURNING)
--   - SCOPE_IDENTITY() replaced with INSERT...RETURNING productid into a CTE/subquery approach
--   - GETDATE() -> NOW()
--   - BEGIN TRANSACTION -> BEGIN
--   - Transaction handled at C# level, SQL restructured to use DO block or sequential statements
-- Note: For Npgsql with ExecuteScalar, we restructure to use INSERT...RETURNING
-- Since PostgreSQL cannot use DECLARE in plain SQL sent from app code without DO block,
-- we restructure the transaction into separate commands executed via C# transaction
-- ============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================================
-- Statement 3b: InsertProductAsync - ProductHistory insert (executed separately in C# after getting newProductId)
-- ============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- ============================================================================
-- Statement 3c: InsertProductAsync - ProductStats update (executed separately in C# transaction)
-- ============================================================================
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (converted)
-- Original: BEGIN TRANSACTION, DECLARE @OldPrice/@OldStock, GETDATE()
-- Changes:
--   - DECLARE variables replaced with subquery approach
--   - GETDATE() -> NOW()
--   - Transaction managed at C# level
-- For the C# code, we'll use multiple sequential statements within a C# transaction
-- ============================================================================
-- 4a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- 4b: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- 4c: Log changes (uses @OldPrice, @OldStock captured in C#)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- 4d: Update stats (uses @OldPrice captured in C#)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (converted)
-- Original: BEGIN TRANSACTION, DECLARE @OldPrice/@OldStock, GETDATE(), CASE
-- Changes: Same restructuring as Statement 4
-- ============================================================================
-- 5a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- 5b: Log deletion (uses @OldPrice, @OldStock captured in C#)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- 5c: Delete product
DELETE FROM products 
WHERE productid = @ProductId;

-- 5d: Update stats (uses @OldPrice captured in C#)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Original: CTE with RANK/PERCENT_RANK window functions
-- Changes: All identifiers lowercase
-- ============================================================================
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

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- Original: CTE with AVG/MIN/MAX window functions
-- Changes: All identifiers lowercase, ROUND needs CAST for integer division
-- ============================================================================
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
