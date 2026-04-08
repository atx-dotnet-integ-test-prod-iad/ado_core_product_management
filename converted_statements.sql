-- ============================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Syntax
-- Source: DataAccess/ProductRepository.cs
-- Converted: 2026-04-08
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion timed out
-- Schema Mappings from DMS Schema Mapping Tool:
--   dbo.Products -> productmanagement_dbo.products
--   dbo.ProductHistory -> productmanagement_dbo.producthistory
--   dbo.ProductStats -> productmanagement_dbo.productstats
--   All column names -> lowercase
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync
-- Changes: Table/column names to lowercase, schema prefix added
-- CTE alias renamed to productstats_cte to avoid conflict with table productstats
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
-- Statement 2: GetProductByIdAsync
-- Changes: Table/column names to lowercase, schema prefix added
-- CTE alias renamed to producthistory_cte to avoid conflict with table producthistory
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
-- Statement 3: InsertProductAsync
-- Changes: Restructured from single T-SQL batch to multiple PostgreSQL commands
-- SCOPE_IDENTITY() -> RETURNING productid
-- GETDATE() -> CURRENT_TIMESTAMP
-- Transaction managed via C# ADO.NET BeginTransactionAsync()
-- Split into 3 separate SQL commands:
-- ============================================================
-- 3a: Insert product (returns new ID via RETURNING)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- 3b: Insert history record
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- 3c: Update statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync
-- Changes: Restructured from single T-SQL batch with DECLARE/@var to multiple commands
-- GETDATE() -> CURRENT_TIMESTAMP
-- Transaction managed via C# ADO.NET BeginTransactionAsync()
-- Split into 4 separate SQL commands:
-- ============================================================
-- 4a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- 4b: Update product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- 4c: Insert history record
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- 4d: Update statistics
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync
-- Changes: Restructured from single T-SQL batch with DECLARE/@var to multiple commands
-- GETDATE() -> CURRENT_TIMESTAMP
-- Transaction managed via C# ADO.NET BeginTransactionAsync()
-- Split into 4 separate SQL commands:
-- ============================================================
-- 5a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- 5b: Insert history record
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- 5c: Delete product
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- 5d: Update statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Changes: Table/column names to lowercase, schema prefix added
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
-- Statement 7: GetLowStockProductsAsync
-- Changes: Table/column names to lowercase, schema prefix added
-- Added CAST for integer division to get decimal results
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
