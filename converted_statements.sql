-- ==================================================================================
-- CONVERTED SQL STATEMENTS CATALOG for PostgreSQL Migration
-- ==================================================================================
-- This catalog contains all SQL statements converted from MS SQL Server to PostgreSQL
-- Source: extracted_statements.sql
-- Conversion Method: DMS MCP Tool + Manual conversion where needed
-- Total Statements: 7
-- Conversion Date: 2025-12-27
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1 (STMT_001): GetAllProductsAsync - SELECT with CTE and window functions
-- ==================================================================================
-- Conversion Status: SUCCESS (DMS Tool)
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 2 (STMT_002): GetProductByIdAsync - SELECT with CTE and LAG function
-- ==================================================================================
-- Conversion Status: SUCCESS (DMS Tool)
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3 (STMT_003): InsertProductAsync - Multi-statement transaction
-- ==================================================================================
-- Conversion Status: MANUAL (DMS Tool failed)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Statement definition is not valid
-- Manual Conversion Rationale: Transaction blocks with SCOPE_IDENTITY() not supported
--                              by DMS single-statement conversion. Converted to use
--                              RETURNING clause with transaction management in C# code.
-- Schema Changes: Products → productmanagement_dbo.products
--                ProductHistory → productmanagement_dbo.producthistory
--                ProductStats → productmanagement_dbo.productstats
-- ==================================================================================
-- Note: For ADO.NET application, the transaction block is split into separate commands
--       executed within a C# transaction. The INSERT uses RETURNING for the new ID.
-- ==================================================================================

-- Main INSERT statement with RETURNING clause (replaces SCOPE_IDENTITY())
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- History logging (executed as separate command within transaction)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statistics update (executed as separate command within transaction)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT 4 (STMT_004): UpdateProductAsync - Multi-statement transaction
-- ==================================================================================
-- Conversion Status: SUCCESS (DMS Tool with warnings)
-- Conversion Method: DMS_TOOL
-- DMS Warning: [7807] Transaction management commands need manual handling
-- Schema Changes: Products → productmanagement_dbo.products
--                ProductHistory → productmanagement_dbo.producthistory
--                ProductStats → productmanagement_dbo.productstats
-- Note: Transaction control handled by C# ADO.NET code, not in SQL
-- ==================================================================================

-- Simplified version for ADO.NET (transaction managed by C# code):
-- Get old values
SELECT price AS oldprice, stockquantity AS oldstock
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Log history
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT 5 (STMT_005): DeleteProductAsync - Multi-statement transaction
-- ==================================================================================
-- Conversion Status: SUCCESS (DMS Tool with warnings)
-- Conversion Method: DMS_TOOL
-- DMS Warning: [7807] Transaction management commands need manual handling
-- Schema Changes: Products → productmanagement_dbo.products
--                ProductHistory → productmanagement_dbo.producthistory
--                ProductStats → productmanagement_dbo.productstats
-- Note: Transaction control handled by C# ADO.NET code, not in SQL
-- ==================================================================================

-- Simplified version for ADO.NET (transaction managed by C# code):
-- Get old values
SELECT price AS oldprice, stockquantity AS oldstock
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Log deletion before removing
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT 6 (STMT_006): GetProductsByPriceRangeAsync - SELECT with CTE and ranking
-- ==================================================================================
-- Conversion Status: SUCCESS (DMS Tool)
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7 (STMT_007): GetLowStockProductsAsync - SELECT with CTE and window functions
-- ==================================================================================
-- Conversion Status: SUCCESS (DMS Tool)
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- ==================================================================================

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

-- ==================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ==================================================================================
-- Conversion Summary:
-- - Total Statements: 7
-- - DMS Tool Success: 6
-- - Manual Conversion: 1 (STMT_003 - InsertProductAsync)
-- - Statements with Warnings: 2 (STMT_004, STMT_005 - transaction management)
--
-- All SQL Server specific syntax has been converted:
-- - SCOPE_IDENTITY() → RETURNING clause
-- - GETDATE() → CURRENT_TIMESTAMP / clock_timestamp()
-- - BEGIN TRANSACTION/COMMIT → Managed by ADO.NET application code
-- - Schema qualified: productmanagement_dbo prefix added to all tables
-- - Window functions preserved and working in PostgreSQL
-- - CTE syntax compatible with PostgreSQL
-- ==================================================================================
