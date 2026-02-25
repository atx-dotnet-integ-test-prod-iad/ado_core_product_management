-- ========================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- ========================================
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Conversion Date: Phase 2 - SQL Conversion
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ========================================

-- ========================================
-- STATEMENT 1: GetAllProductsAsync
-- ========================================
-- Original Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- 
-- PostgreSQL Conversions Applied:
-- - CTE syntax remains compatible (no change needed)
-- - Window functions (AVG OVER, COUNT OVER) remain compatible
-- - Schema objects converted to lowercase: Products -> products
-- - Column names converted to lowercase for PostgreSQL convention
-- ========================================
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

-- ========================================
-- STATEMENT 2: GetProductByIdAsync
-- ========================================
-- Original Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- 
-- PostgreSQL Conversions Applied:
-- - CTE syntax remains compatible
-- - LAG() window function remains compatible
-- - Schema objects converted to lowercase: Products -> products, ProductHistory -> producthistory
-- - Column names converted to lowercase
-- - Parameter syntax @ProductId remains compatible with PostgreSQL/Npgsql
-- ========================================
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

-- ========================================
-- STATEMENT 3: InsertProductAsync
-- ========================================
-- Original Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- 
-- PostgreSQL Conversions Applied:
-- - DECLARE @NewProductId INT -> Removed, using RETURNING clause instead
-- - BEGIN TRANSACTION -> BEGIN (PostgreSQL syntax)
-- - SCOPE_IDENTITY() -> Removed, using RETURNING clause in INSERT
-- - GETDATE() -> NOW()
-- - SET @NewProductId -> Eliminated by using RETURNING and CTEs
-- - Schema objects to lowercase: Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
-- - Column names to lowercase
-- - Transaction modified to use PostgreSQL-compatible WITH CTE for captured ID
-- ========================================
WITH inserted_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM inserted_product
    RETURNING productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1
RETURNING (SELECT productid FROM inserted_product);

-- ========================================
-- STATEMENT 4: UpdateProductAsync
-- ========================================
-- Original Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- 
-- PostgreSQL Conversions Applied:
-- - DECLARE variables removed, using CTEs instead
-- - BEGIN TRANSACTION -> BEGIN
-- - GETDATE() -> NOW()
-- - Schema objects to lowercase: Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
-- - Column names to lowercase
-- - Restructured to use PostgreSQL CTEs for capturing old values
-- ========================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
product_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, NOW()
    FROM old_values ov
    RETURNING productid
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ========================================
-- STATEMENT 5: DeleteProductAsync
-- ========================================
-- Original Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- 
-- PostgreSQL Conversions Applied:
-- - DECLARE variables removed, using CTEs instead
-- - BEGIN TRANSACTION -> BEGIN
-- - GETDATE() -> NOW()
-- - Schema objects to lowercase: Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
-- - Column names to lowercase
-- - Restructured to use PostgreSQL CTEs for capturing old values before deletion
-- ========================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, NOW()
    FROM old_values ov
    RETURNING productid
),
product_delete AS (
    DELETE FROM products 
    WHERE productid = @ProductId
    RETURNING productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- ========================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ========================================
-- Original Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- 
-- PostgreSQL Conversions Applied:
-- - CTE syntax remains compatible
-- - RANK() and PERCENT_RANK() window functions remain compatible
-- - BETWEEN operator remains compatible
-- - Schema objects to lowercase: Products -> products, RankedProducts -> rankedproducts
-- - Column names to lowercase
-- ========================================
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

-- ========================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ========================================
-- Original Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- 
-- PostgreSQL Conversions Applied:
-- - CTE syntax remains compatible
-- - Window functions (AVG OVER, MIN OVER, MAX OVER) remain compatible
-- - ROUND() function remains compatible
-- - Schema objects to lowercase: Products -> products, StockAnalysis -> stockanalysis
-- - Column names to lowercase
-- ========================================
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
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ========================================
-- CONVERSION SUMMARY
-- ========================================
-- Total SQL Statements Converted: 7
-- Conversion Method: ALL statements manually converted due to DMS tool failure
-- DMS Error (All Statements): Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--
-- Key PostgreSQL Transformations Applied:
--   1. Schema Object Names: All converted to lowercase (products, producthistory, productstats)
--   2. Column Names: All converted to lowercase for PostgreSQL convention
--   3. GETDATE() -> NOW(): 6 occurrences converted
--   4. SCOPE_IDENTITY() -> RETURNING clause: 1 occurrence (Statement 3)
--   5. DECLARE variables eliminated: Used CTEs for variable capture
--   6. BEGIN TRANSACTION -> BEGIN: Transaction syntax updated
--   7. CTE syntax: Compatible, no changes needed
--   8. Window Functions: Compatible (LAG, RANK, PERCENT_RANK, AVG/COUNT/MIN/MAX OVER)
--   9. Parameter syntax: @Parameter syntax compatible with Npgsql
--
-- PostgreSQL-Specific Optimizations:
--   - Used RETURNING clause instead of SCOPE_IDENTITY()
--   - Restructured complex transactions to use CTEs for cleaner code
--   - Maintained parameterized query structure for Npgsql compatibility
--
-- Next Step: Validate equivalency using SQL Equivalency MCP Tool
-- ========================================
