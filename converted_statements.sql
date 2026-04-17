-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs (converted from MS SQL Server)
-- Target Database: PostgreSQL (productmanagement_dbo schema)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: Unknown metadata model creation status: RECEIVED
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Conversion Date: 2026-04-17
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Original Source: DataAccess/ProductRepository.cs, GetAllProductsAsync()
-- Conversion: Table/column names lowercased per DMS schema mapping
-- Schema: productmanagement_dbo.products
-- ============================================================
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Original Source: DataAccess/ProductRepository.cs, GetProductByIdAsync()
-- Conversion: Table/column names lowercased per DMS schema mapping
-- Schema: productmanagement_dbo.products
-- ============================================================
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Original Source: DataAccess/ProductRepository.cs, InsertProductAsync()
-- Conversion: SCOPE_IDENTITY() -> RETURNING + CTE approach
--             GETDATE() -> clock_timestamp()
--             BEGIN TRANSACTION -> BEGIN
--             Table/column names lowercased per DMS schema mapping
-- Schema: productmanagement_dbo.products, productmanagement_dbo.producthistory, productmanagement_dbo.productstats
-- ============================================================
WITH new_product AS (
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_insert AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM new_product
),
update_stats AS (
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Original Source: DataAccess/ProductRepository.cs, UpdateProductAsync()
-- Conversion: DECLARE/SET variable pattern -> CTE subquery approach
--             GETDATE() -> clock_timestamp()
--             BEGIN TRANSACTION -> BEGIN
--             Table/column names lowercased per DMS schema mapping
-- Schema: productmanagement_dbo.products, productmanagement_dbo.producthistory, productmanagement_dbo.productstats
-- ============================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId
),
log_change AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, clock_timestamp()
    FROM old_values
)
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Original Source: DataAccess/ProductRepository.cs, DeleteProductAsync()
-- Conversion: DECLARE/SET variable pattern -> CTE subquery approach
--             GETDATE() -> clock_timestamp()
--             BEGIN TRANSACTION -> BEGIN
--             Table/column names lowercased per DMS schema mapping
-- Schema: productmanagement_dbo.products, productmanagement_dbo.producthistory, productmanagement_dbo.productstats
-- ============================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
),
log_deletion AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, clock_timestamp()
    FROM old_values
),
do_delete AS (
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId
)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original Source: DataAccess/ProductRepository.cs, GetProductsByPriceRangeAsync()
-- Conversion: Table/column names lowercased per DMS schema mapping
-- Schema: productmanagement_dbo.products
-- ============================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
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

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Original Source: DataAccess/ProductRepository.cs, GetLowStockProductsAsync()
-- Conversion: Table/column names lowercased per DMS schema mapping
-- ROUND integer division fix: CAST to NUMERIC for proper decimal division
-- Schema: productmanagement_dbo.products
-- ============================================================
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
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
