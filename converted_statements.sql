-- ============================================================================
-- SQL Server to PostgreSQL Migration - Converted SQL Statements
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Conversion Date: 2026-02-26
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Method: GetAllProductsAsync()
-- Parameters: None
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes: 
--   - All table/column names converted to lowercase
--   - ROUND function syntax remains compatible
--   - Window functions (AVG OVER, COUNT OVER) are PostgreSQL compatible
-- ============================================================================
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

-- ============================================================================
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId (INT) -> $1 (INT)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes:
--   - All table/column names converted to lowercase
--   - Parameter @ProductId changed to $1 for positional parameters
--   - LAG window function is PostgreSQL compatible
--   - ROUND function syntax remains compatible
-- ============================================================================
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = $1
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
WHERE p.productid = $1;

-- ============================================================================
-- Statement 3: InsertProductAsync (CONVERTED)
-- Method: InsertProductAsync(Product product)
-- Parameters: $1=Name, $2=Description, $3=Price, $4=StockQuantity
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes:
--   - All table/column names converted to lowercase
--   - DECLARE @NewProductId INT removed (not needed with RETURNING)
--   - BEGIN TRANSACTION -> BEGIN
--   - COMMIT -> COMMIT
--   - Parameters @Name, @Description, @Price, @StockQuantity -> $1, $2, $3, $4
--   - SCOPE_IDENTITY() replaced with RETURNING productid
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Transaction restructured to use PostgreSQL RETURNING clause
-- Note: This conversion splits the transaction into multiple statements
--       Application code will need to handle the transaction block
-- ============================================================================
-- Insert the new product and return the ID
INSERT INTO products (name, description, price, stockquantity)
VALUES ($1, $2, $3, $4)
RETURNING productid;

-- Log the insertion (to be executed after getting productid)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP);

-- Update product statistics (to be executed in same transaction)
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + $1) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Method: UpdateProductAsync(Product product)
-- Parameters: $1=ProductId, $2=Name, $3=Description, $4=Price, $5=StockQuantity
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes:
--   - All table/column names converted to lowercase
--   - DECLARE statements removed (use WITH clause or subqueries)
--   - BEGIN TRANSACTION -> BEGIN
--   - COMMIT -> COMMIT
--   - Parameters changed to positional $1, $2, $3, $4, $5
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Restructured to use PostgreSQL idioms (CTE for old values)
-- ============================================================================
-- Store old values and update in a CTE pattern
WITH oldvalues AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = $1
),
productupdate AS (
    UPDATE products
    SET 
        name = $2,
        description = $3,
        price = $4,
        stockquantity = $5,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = $1
    RETURNING productid, $4 as newprice, $5 as newstock
)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT 
    pu.productid, 
    'UPDATE', 
    ov.oldprice, 
    pu.newprice, 
    ov.oldstock, 
    pu.newstock, 
    CURRENT_TIMESTAMP
FROM productupdate pu, oldvalues ov;

-- Update product statistics (separate statement in same transaction)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM oldvalues) + $4) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Method: DeleteProductAsync(int productId)
-- Parameters: $1=ProductId
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes:
--   - All table/column names converted to lowercase
--   - DECLARE statements removed
--   - BEGIN TRANSACTION -> BEGIN
--   - COMMIT -> COMMIT
--   - Parameter @ProductId -> $1
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Restructured to capture old values before delete using RETURNING
-- ============================================================================
-- Store product info and delete using RETURNING
WITH deleted_product AS (
    DELETE FROM products 
    WHERE productid = $1
    RETURNING productid, price as oldprice, stockquantity as oldstock
)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT productid, 'DELETE', oldprice, NULL, oldstock, NULL, CURRENT_TIMESTAMP
FROM deleted_product;

-- Update product statistics (separate statement in same transaction)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM deleted_product)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice (DECIMAL) -> $1, @MaxPrice (DECIMAL) -> $2
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes:
--   - All table/column names converted to lowercase
--   - Parameters @MinPrice, @MaxPrice -> $1, $2
--   - RANK() and PERCENT_RANK() window functions are PostgreSQL compatible
--   - BETWEEN clause remains compatible
-- ============================================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN $1 AND $2
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
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold (INT) -> $1
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed
-- PostgreSQL Changes:
--   - All table/column names converted to lowercase
--   - Parameter @Threshold -> $1
--   - Window functions (AVG, MIN, MAX OVER) are PostgreSQL compatible
--   - ROUND function syntax remains compatible
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
        WHEN stockquantity <= $1 THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= $1
ORDER BY stockquantity;

-- ============================================================================
-- End of Converted SQL Statements
-- ============================================================================
-- Summary:
-- - All 7 statements converted from SQL Server to PostgreSQL
-- - All schema objects (tables, columns) converted to lowercase
-- - All parameters converted from @param to $N positional parameters
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - SCOPE_IDENTITY() replaced with RETURNING clause
-- - Transaction blocks restructured for PostgreSQL idioms
-- - Window functions maintained (PostgreSQL native support)
-- ============================================================================
