-- ================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Migration
-- Source: AdoCore Application
-- Conversion Date: 2026-01-24
-- Total Statements: 7
-- Conversion Tool: AWS DMS MCP Statement Conversion Tool
-- ================================================================

-- ================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Original Location: ProductRepository.cs Lines 42-67
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Note: Column names converted to lowercase, added NULLS FIRST in ORDER BY
-- ================================================================

WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- ================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Original Location: ProductRepository.cs Lines 83-111
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Note: Column names converted to lowercase, LAG function preserved, LEFT JOIN → LEFT OUTER JOIN
-- ================================================================

WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- ================================================================
-- STATEMENT 3: InsertProductAsync
-- Original Location: ProductRepository.cs Lines 125-149
-- Conversion Status: FAILED - Manual Conversion Required
-- DMS Error: Statement definition is not valid (multi-statement transaction block)
-- Manual Conversion Applied: Split into separate statements, handle transaction in application code
-- Note: SCOPE_IDENTITY() must be replaced with RETURNING clause in application code
--       GETDATE() must be replaced with NOW() or CURRENT_TIMESTAMP
-- ================================================================

-- Manual PostgreSQL Conversion for InsertProductAsync:
-- This must be handled as separate statements in application code with transaction management

-- Statement 1: Insert product and get new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 2: Log the insertion (using returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3: Update statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ================================================================
-- STATEMENT 4: UpdateProductAsync
-- Original Location: ProductRepository.cs Lines 163-194
-- Conversion Status: SUCCESS (with warnings)
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Note: DECLARE converted, GETDATE() → clock_timestamp(), transaction management must be handled in application code
-- ================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ================================================================
-- STATEMENT 5: DeleteProductAsync
-- Original Location: ProductRepository.cs Lines 208-236
-- Conversion Status: SUCCESS (with warnings)
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Note: DECLARE converted, GETDATE() → clock_timestamp(), transaction management must be handled in application code
-- ================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Original Location: ProductRepository.cs Lines 250-272
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Note: Column names converted to lowercase, RANK() and PERCENT_RANK() preserved, added NULLS FIRST in ORDER BY
-- ================================================================

WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Original Location: ProductRepository.cs Lines 286-311
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Note: Column names converted to lowercase, window functions (AVG, MIN, MAX) preserved, added NULLS FIRST in ORDER BY
-- ================================================================

WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

-- ================================================================
-- END OF CONVERTED SQL STATEMENTS
-- Summary:
--   Total Statements: 7
--   Successfully Converted by DMS: 6
--   Manual Conversion Required: 1 (InsertProductAsync - multi-statement transaction)
--   Statements with Warnings: 2 (UpdateProductAsync, DeleteProductAsync - transaction management)
--
-- Critical Schema Changes by DMS:
--   - All table names prefixed with schema: productmanagement_dbo
--   - All column names converted to lowercase
--   - GETDATE() → clock_timestamp() or NOW()
--   - SCOPE_IDENTITY() → RETURNING clause (manual conversion)
--   - Transaction blocks require application-level management
--   - ORDER BY clauses now include NULLS FIRST for PostgreSQL compatibility
-- ================================================================
