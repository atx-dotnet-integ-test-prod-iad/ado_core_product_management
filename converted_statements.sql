-- =====================================================
-- CONVERTED POSTGRESQL STATEMENTS CATALOG
-- Source: AdoCore .NET Application
-- Conversion Date: 2026-03-27
-- Total Statements: 9
-- DMS Conversion Successes: 0
-- Manual Conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA): 9
-- DMS Configuration:
--   Migration Project ARN: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
--   Database Name: ProductManagement
--   Schema Name: dbo
--   Region: us-east-1
--   Server Name: 172.31.94.132
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- DMS Attempt Timestamp: 2026-03-26T23:57:47 / Error: 2026-03-27T00:00:22
-- Key Changes: [dbo].[Products] -> products, PascalCase columns -> lowercase,
--              ROUND(expr, 2) -> ROUND(CAST(expr AS NUMERIC), 2)
-- =====================================================
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
    ROUND(CAST((p.price / ps.avgprice) * 100 AS NUMERIC), 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- =====================================================
-- Statement 2: GetProductByIdAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- DMS Attempt Timestamp: 2026-03-27T00:00:35 / Error: 2026-03-27T00:03:11
-- Key Changes: [dbo].[Products] -> products, PascalCase -> lowercase,
--              ROUND(expr, 2) -> ROUND(CAST(expr AS NUMERIC), 2)
-- =====================================================
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
            ROUND(CAST(((p.price - ph.previousprice) / ph.previousprice) * 100 AS NUMERIC), 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- =====================================================
-- Statement 3: InsertProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- DMS Attempt Timestamp: 2026-03-27T00:03:30 / Error: 2026-03-27T00:06:05
-- Key Changes: BEGIN TRANSACTION -> BEGIN, SCOPE_IDENTITY() -> currval(pg_get_serial_sequence()),
--              GETDATE() -> NOW(), [dbo].[Products] -> products, PascalCase -> lowercase,
--              DECLARE @var removed, replaced with currval()
-- =====================================================
BEGIN;

-- Insert the new product
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity);

-- Log the insertion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (currval(pg_get_serial_sequence('products', 'productid')), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

COMMIT;

SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- =====================================================
-- Statement 4: UpdateProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- DMS Attempt Timestamp: 2026-03-27T00:06:16 / Error: 2026-03-27T00:08:50
-- Key Changes: BEGIN TRANSACTION -> BEGIN, DECLARE/SET -> INSERT-SELECT + subqueries,
--              GETDATE() -> NOW(), [dbo].* -> lowercase tables and columns
-- =====================================================
BEGIN;

-- Log the changes (capture old values before update)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
FROM products
WHERE productid = @ProductId;

-- Update product statistics (use old price before product update)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

COMMIT;

-- =====================================================
-- Statement 5: DeleteProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- DMS Attempt Timestamp: 2026-03-27T00:09:02 / Error: 2026-03-27T00:11:36
-- Key Changes: BEGIN TRANSACTION -> BEGIN, DECLARE/SET -> INSERT-SELECT + subqueries,
--              GETDATE() -> NOW(), [dbo].* -> lowercase tables and columns
-- =====================================================
BEGIN;

-- Log the deletion (capture old values before delete)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
FROM products
WHERE productid = @ProductId;

-- Update product statistics (use old price before delete)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- Delete the product
DELETE FROM products
WHERE productid = @ProductId;

COMMIT;

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- DMS Attempt Timestamp: 2026-03-27T00:11:48 / Error: 2026-03-27T00:14:25
-- Key Changes: [dbo].[Products] -> products, PascalCase -> lowercase
-- =====================================================
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

-- =====================================================
-- Statement 7: GetLowStockProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- DMS Attempt Timestamp: 2026-03-27T00:14:37 / Error: 2026-03-27T00:17:12
-- Key Changes: [dbo].[Products] -> products, PascalCase -> lowercase,
--              ROUND with CAST for NUMERIC compatibility
-- =====================================================
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
    ROUND(CAST(stockquantity AS NUMERIC) / CAST(avgstock AS NUMERIC) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- =====================================================
-- Statement 8: CREATE TABLE Products
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- DMS Attempt Timestamp: 2026-03-27T00:17:22 / Error: 2026-03-27T00:19:57
-- Key Changes: IDENTITY(1,1) -> SERIAL, NVARCHAR -> VARCHAR, DATETIME -> TIMESTAMP,
--              GETDATE() -> NOW(), [dbo].[Products] -> products, PascalCase -> lowercase
-- =====================================================
CREATE TABLE IF NOT EXISTS products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL
);

-- =====================================================
-- Statement 9: sp_GetAllProducts body (PostgreSQL function)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- DMS Attempt Timestamp: 2026-03-27T00:20:05 / Error: 2026-03-27T00:22:41
-- Key Changes: [dbo].[Products] -> products, PascalCase -> lowercase,
--              Stored procedure -> PostgreSQL function
-- =====================================================
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
FROM products p
ORDER BY p.name;
