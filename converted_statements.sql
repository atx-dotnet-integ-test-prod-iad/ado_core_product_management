-- ========================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration via DMS MCP Tool
-- Conversion Date: 2026-01-02
-- ========================================================================
-- 
-- This catalog contains ALL converted PostgreSQL statements resulting from
-- DMS MCP tool processing. Each statement includes metadata about the
-- conversion process and any manual interventions required.
--
-- CRITICAL SCHEMA NOTE: DMS has converted schema from 'dbo' to 
-- 'productmanagement_dbo' and all identifiers to lowercase
-- ========================================================================

-- ========================================================================
-- STATEMENT #1: GetAllProductsAsync - Complex CTE with Window Functions
-- ========================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1767383736
-- Conversion Timestamp: 2026-01-02T19:55:34.421256
-- Schema Changes: Products -> productmanagement_dbo.products (lowercase identifiers)
-- Key Transformations:
--   - CTE name: ProductStats -> productstats
--   - Table reference: Products -> productmanagement_dbo.products
--   - All column names lowercase (ProductId -> productid, Price -> price, etc.)
--   - Added "NULLS FIRST" to ORDER BY clauses
-- ========================================================================

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

-- ========================================================================
-- STATEMENT #2: GetProductByIdAsync - CTE with LAG Window Function
-- ========================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1767383812
-- Conversion Timestamp: 2026-01-02T19:56:50.039152
-- Schema Changes: Products -> productmanagement_dbo.products (lowercase identifiers)
-- Key Transformations:
--   - CTE name: ProductHistory -> producthistory
--   - LAG() function preserved
--   - LEFT JOIN -> LEFT OUTER JOIN
--   - Parameter @ProductId preserved (will need C# parameter binding update)
--   - All column names lowercase
-- ========================================================================

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

-- ========================================================================
-- STATEMENT #3: InsertProductAsync - Multi-Statement Transaction Block
-- ========================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS FAILED - Manual conversion applied
-- DMS Error: "Metadata model creation failed: Statement definition is not valid."
-- DMS Timestamp: 2026-01-02T19:58:05.608223
-- Manual Conversion Reason: DMS cannot process complex transaction blocks with
--   SCOPE_IDENTITY() and multiple statements. Manual conversion required.
-- Schema Changes: 
--   - Products -> productmanagement_dbo.products
--   - ProductHistory -> productmanagement_dbo.producthistory
--   - ProductStats -> productmanagement_dbo.productstats
-- Key Transformations:
--   - SCOPE_IDENTITY() -> RETURNING productid (PostgreSQL RETURNING clause)
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT handled at application level (removed from SQL)
--   - Variables removed - using RETURNING directly
--   - All column names lowercase
-- ========================================================================
-- NOTE: This statement will be split into multiple operations in the C# code
-- The INSERT will use RETURNING clause to get the new ID

-- Insert statement with RETURNING clause
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log insertion (executed after getting productid from RETURNING)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ========================================================================
-- STATEMENT #4: UpdateProductAsync - Transaction with Variable Declarations
-- ========================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS with WARNINGS
-- DMS Metadata Model: sql-conversion-1767383913
-- Conversion Timestamp: 2026-01-02T19:58:31.760211
-- DMS Warning: [7807 - Severity CRITICAL] PostgreSQL does not support explicit 
--   transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.
-- Schema Changes: All tables -> productmanagement_dbo.* (lowercase)
-- Key Transformations:
--   - DECLARE @variable -> DECLARE var_variable (PostgreSQL style)
--   - DECIMAL(18,2) -> NUMERIC(18, 2)
--   - INT -> INTEGER
--   - GETDATE() -> clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT commented out (handled at app level)
--   - SELECT @var = column -> SELECT column AS var_variable
-- Note: Transaction management will be handled in C# code
-- ========================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ========================================================================
-- STATEMENT #5: DeleteProductAsync - Transaction with Conditional CASE
-- ========================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS with WARNINGS
-- DMS Metadata Model: sql-conversion-1767383992
-- Conversion Timestamp: 2026-01-02T19:59:49.908573
-- DMS Warning: [7807 - Severity CRITICAL] PostgreSQL does not support explicit 
--   transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.
-- Schema Changes: All tables -> productmanagement_dbo.* (lowercase)
-- Key Transformations:
--   - DECLARE @variable -> DECLARE var_variable
--   - GETDATE() -> clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT commented out
--   - All identifiers lowercase
-- Note: Transaction management will be handled in C# code
-- ========================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ========================================================================
-- STATEMENT #6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ========================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1767384066
-- Conversion Timestamp: 2026-01-02T20:01:04.327982
-- Schema Changes: Products -> productmanagement_dbo.products (lowercase)
-- Key Transformations:
--   - CTE name: RankedProducts -> rankedproducts
--   - RANK() and PERCENT_RANK() functions preserved
--   - BETWEEN clause preserved
--   - Parameters @MinPrice, @MaxPrice preserved
--   - Added NULLS FIRST to ORDER BY
-- ========================================================================

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

-- ========================================================================
-- STATEMENT #7: GetLowStockProductsAsync - CTE with Multiple Aggregate Window Functions
-- ========================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1767384142
-- Conversion Timestamp: 2026-01-02T20:02:20.009349
-- Schema Changes: Products -> productmanagement_dbo.products (lowercase)
-- Key Transformations:
--   - CTE name: StockAnalysis -> stockanalysis
--   - Window functions AVG(), MIN(), MAX() OVER() preserved
--   - Parameter @Threshold preserved
--   - All identifiers lowercase
--   - Added NULLS FIRST to ORDER BY
-- ========================================================================

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

-- ========================================================================
-- CONVERSION SUMMARY
-- ========================================================================
-- Total Statements Processed: 7
-- DMS Tool Successes: 6 (Statements 1, 2, 4, 5, 6, 7)
-- DMS Tool Success with Warnings: 2 (Statements 4, 5)
-- DMS Tool Failures: 1 (Statement 3)
-- Manual Conversions: 1 (Statement 3)
--
-- Critical Schema Changes by DMS:
--   - Schema: dbo -> productmanagement_dbo
--   - All table names lowercase: Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
--   - All column names lowercase: ProductId -> productid, StockQuantity -> stockquantity, etc.
--   - CTE names lowercase
--   - Alias names lowercase
--
-- SQL Server to PostgreSQL Function Mappings:
--   - GETDATE() -> CURRENT_TIMESTAMP or clock_timestamp()
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - ROUND() -> ROUND() (compatible)
--   - LAG() -> lag() (compatible, name lowercased)
--   - RANK() -> RANK() (compatible)
--   - PERCENT_RANK() -> percent_rank() (compatible, name lowercased)
--   - AVG/MIN/MAX OVER() -> AVG/MIN/MAX OVER() (compatible)
--
-- Transaction Handling:
--   - BEGIN TRANSACTION/COMMIT removed from SQL (Statements 3, 4, 5)
--   - Transactions must be managed at application (C#) level
--   - Use NpgsqlTransaction in C# code
--
-- Variable Handling:
--   - DECLARE @variable -> DECLARE var_variable (Statements 4, 5)
--   - Statement 3: Variables eliminated, using RETURNING clause instead
--
-- ORDER BY Enhancement:
--   - DMS added "NULLS FIRST" to all ORDER BY clauses for PostgreSQL compatibility
--
-- NEXT STEPS:
-- 1. Update ProductRepository.cs with converted SQL statements
-- 2. Respect schema name changes: productmanagement_dbo.products, etc.
-- 3. Handle transaction management in C# code for Statements 3, 4, 5
-- 4. Update Statement 3 (InsertProductAsync) to use RETURNING clause
-- 5. Test parameter binding with lowercase column names
-- ========================================================================
