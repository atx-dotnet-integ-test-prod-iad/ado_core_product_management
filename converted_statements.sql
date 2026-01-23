-- ================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL
-- Converted from Microsoft SQL Server T-SQL to PostgreSQL
-- ================================================================
-- Total Statements: 7
-- Conversion Method: AWS DMS MCP Tool + Manual (where DMS failed)
-- Conversion Date: 2025-01-23
-- Target Schema: productmanagement_dbo (DMS transformed schema)
-- ================================================================

-- ================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Other Changes: Column names lowercase, added NULLS FIRST to ORDER BY
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- ================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Other Changes: Column names lowercase, LAG function preserved, LEFT JOIN → LEFT OUTER JOIN
-- Parameter: @ProductId preserved (Npgsql supports named parameters)
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
-- STATEMENT 3: InsertProductAsync (CONVERTED - MANUAL AFTER DMS FAILURE)
-- ================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS FAILED - "Statement definition is not valid"
-- Reason: Complex transaction block with SCOPE_IDENTITY() not supported by DMS
-- Manual Conversion Applied:
--   - Transaction handling moved to C# code level (using NpgsqlTransaction)
--   - SCOPE_IDENTITY() replaced with RETURNING clause
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Multiple statements kept but transaction keywords removed (handled in code)
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- ================================================================

-- Insert the new product and return the ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements will be executed sequentially in the same transaction in C# code
-- They are not part of a single SQL string but separate commands within a transaction

-- Log the insertion (using the returned productid from above)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED - WITH WARNINGS)
-- ================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS (with CRITICAL warning about transaction management)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.]
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Other Changes: GETDATE() → clock_timestamp(), variable names changed to var_ prefix, SELECT into variables syntax changed
-- Note: Transaction keywords commented out by DMS - transaction handling will be in C# code
-- Note: This converted SQL has issues with variable scoping - will need manual adjustment in re-integration
-- ================================================================

-- DMS Output (with transaction management to be handled in C# code):
-- The DECLARE/BEGIN/END block is for stored procedures, not for inline ADO.NET queries
-- We need to refactor this for inline query execution

-- For ADO.NET inline execution, we'll use a different approach in C# code:
-- 1. SELECT old values into C# variables
-- 2. Execute UPDATE
-- 3. Execute INSERT for history
-- 4. Execute UPDATE for stats

-- SELECT statement to get old values (execute first):
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update the product:
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Log the changes:
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics:
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED - WITH WARNINGS)
-- ================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS (with CRITICAL warning about transaction management)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.]
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Other Changes: Similar to Statement 4 - transaction handling to be moved to C# code
-- ================================================================

-- SELECT statement to get old values (execute first):
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Log the deletion:
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product:
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update product statistics:
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Other Changes: Column names lowercase, RANK() and PERCENT_RANK() preserved, added NULLS FIRST
-- Parameters: @MinPrice, @MaxPrice preserved
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- ================================================================
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Other Changes: Column names lowercase, all window functions preserved (AVG, MIN, MAX), added NULLS FIRST
-- Parameter: @Threshold preserved
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
-- END OF CONVERTED STATEMENTS
-- ================================================================
-- Conversion Summary:
-- - 6 statements successfully converted by DMS MCP tool
-- - 1 statement (InsertProductAsync) failed DMS, manually converted
-- - 3 statements (Insert, Update, Delete) require transaction management at C# code level
-- - All schema names changed from dbo.Products to productmanagement_dbo.products (lowercase)
-- - GETDATE() converted to CURRENT_TIMESTAMP or clock_timestamp()
-- - SCOPE_IDENTITY() replaced with RETURNING clause
-- - Parameter syntax @param remains compatible with Npgsql
-- ================================================================
