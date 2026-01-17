-- ===============================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL Target
-- Source: SQL Server statements from extracted_statements.sql
-- Conversion Tool: AWS DMS MCP Statement Conversion Tool
-- Conversion Date: 2026-01-17
-- Total Statements: 7
-- ===============================================================================
-- 
-- CRITICAL SCHEMA CHANGES FROM DMS CONVERSION:
-- - Table name: Products → productmanagement_dbo.products
-- - Table name: ProductHistory → productmanagement_dbo.producthistory  
-- - Table name: ProductStats → productmanagement_dbo.productstats
-- - All column names converted to lowercase
-- - CTE names converted to lowercase
-- 
-- CRITICAL FUNCTION CONVERSIONS:
-- - GETDATE() → clock_timestamp()
-- - SCOPE_IDENTITY() → Requires RETURNING clause (manual conversion needed)
-- - Window functions: Compatible, preserved
-- - Transaction management: Requires code-level handling in ADO.NET
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ===============================================================================
-- Original Method: GetAllProductsAsync()
-- Conversion Status: SUCCESS via DMS Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Column Case: All lowercase (productid, name, description, price, etc.)
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ===============================================================================
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion Status: SUCCESS via DMS Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Parameter: @ProductId (unchanged)
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with RETURNING
-- ===============================================================================
-- Original Method: InsertProductAsync(Product product)
-- Conversion Status: MANUAL CONVERSION AFTER DMS FAILURE
-- DMS Error: "Statement definition is not valid" - Multi-statement transactions not supported
-- Manual Conversion Applied: Split into separate statements, use RETURNING clause
-- Schema Changes: Products → productmanagement_dbo.products
--                ProductHistory → productmanagement_dbo.producthistory
--                ProductStats → productmanagement_dbo.productstats
-- Critical Changes:
--   - SCOPE_IDENTITY() → RETURNING productid clause on INSERT
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Transaction management moved to ADO.NET code (BeginTransaction/Commit)
--   - Multiple statements to be executed within same transaction via code
-- ===============================================================================

-- Statement 3a: Insert product and return new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion (execute after getting productid from RETURNING)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ===============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction
-- ===============================================================================
-- Original Method: UpdateProductAsync(Product product)
-- Conversion Status: SUCCESS via DMS Tool (with warnings about transaction management)
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Schema Changes: Products → productmanagement_dbo.products
--                ProductHistory → productmanagement_dbo.producthistory
--                ProductStats → productmanagement_dbo.productstats
-- Manual Adjustment: Remove DECLARE/BEGIN/END wrapper, execute as separate statements
--                   within ADO.NET transaction, use CURRENT_TIMESTAMP instead of clock_timestamp()
-- ===============================================================================

-- Statement 4a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 4b: Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, 
    description = @Description, 
    price = @Price, 
    stockquantity = @StockQuantity, 
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 4c: Log the changes (use retrieved old values)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ===============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction
-- ===============================================================================
-- Original Method: DeleteProductAsync(int productId)
-- Conversion Status: SUCCESS via DMS Tool (with warnings about transaction management)
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Schema Changes: Products → productmanagement_dbo.products
--                ProductHistory → productmanagement_dbo.producthistory
--                ProductStats → productmanagement_dbo.productstats
-- Manual Adjustment: Remove DECLARE/BEGIN/END wrapper, execute as separate statements
--                   within ADO.NET transaction, use CURRENT_TIMESTAMP instead of clock_timestamp()
-- ===============================================================================

-- Statement 5a: Get old values for history
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5b: Log the deletion (use retrieved old values)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ===============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- ===============================================================================
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: SUCCESS via DMS Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Parameters: @MinPrice, @MaxPrice (unchanged)
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ===============================================================================
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion Status: SUCCESS via DMS Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Parameter: @Threshold (unchanged)
-- ===============================================================================

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

-- ===============================================================================
-- CONVERSION SUMMARY
-- ===============================================================================
-- Total Statements Processed: 7
-- DMS Tool Successful Conversions: 6 (Statements 1, 2, 4, 5, 6, 7)
-- DMS Tool Failures Requiring Manual Conversion: 1 (Statement 3)
-- 
-- Key Schema Transformations by DMS:
--   1. Table Names: Products → productmanagement_dbo.products
--   2. Table Names: ProductHistory → productmanagement_dbo.producthistory
--   3. Table Names: ProductStats → productmanagement_dbo.productstats
--   4. Column Names: All converted to lowercase
--   5. CTE Names: All converted to lowercase
-- 
-- Key Function Transformations:
--   1. GETDATE() → clock_timestamp() (adjusted to CURRENT_TIMESTAMP for consistency)
--   2. SCOPE_IDENTITY() → RETURNING clause (Statement 3 manual conversion)
--   3. Window Functions: Preserved (LAG, RANK, PERCENT_RANK, AVG OVER, etc.)
--   4. CTEs: Preserved with lowercase naming
-- 
-- Transaction Management:
--   - SQL Server BEGIN TRANSACTION/COMMIT removed from SQL statements
--   - Transaction management moved to ADO.NET code level
--   - Multi-statement transactions split into individual statements
--   - All statements executed within NpgsqlTransaction in C# code
-- 
-- Parameter Syntax:
--   - @ParamName syntax preserved (Npgsql supports this)
--   - No parameter syntax conversion needed
-- ===============================================================================
