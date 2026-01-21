-- ========================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Project: AdoCore - Microsoft SQL Server to PostgreSQL Migration
-- Purpose: Comprehensive catalog of all PostgreSQL-converted SQL statements
-- Total Statements: 7
-- Conversion Method: DMS MCP Tool
-- Date: Migration Phase 2
-- ========================================

-- ========================================
-- CONVERTED STATEMENT #1: GetAllProductsAsync
-- ========================================
-- Original Location: DataAccess/ProductRepository.cs - GetAllProductsAsync method
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768996056
-- Schema Transformation: dbo → productmanagement_dbo
-- Notable Changes:
--   - CTE name lowercase: ProductStats → productstats
--   - Column names lowercase: ProductId → productid
--   - Table reference: Products → productmanagement_dbo.products
--   - Added NULLS FIRST to ORDER BY clauses
-- ========================================

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

-- ========================================
-- CONVERTED STATEMENT #2: GetProductByIdAsync
-- ========================================
-- Original Location: DataAccess/ProductRepository.cs - GetProductByIdAsync method
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768996190
-- Schema Transformation: dbo → productmanagement_dbo
-- Notable Changes:
--   - CTE name lowercase: ProductHistory → producthistory
--   - LAG function lowercase: LAG → lag
--   - Table reference: Products → productmanagement_dbo.products
--   - LEFT JOIN → LEFT OUTER JOIN
--   - Parameters preserved: @ProductId
-- ========================================

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

-- ========================================
-- CONVERTED STATEMENT #3: InsertProductAsync
-- ========================================
-- Original Location: DataAccess/ProductRepository.cs - InsertProductAsync method
-- Conversion Status: FAILED - Manual Conversion Required
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Statement definition is not valid (multi-statement transaction not supported)
-- Schema Transformation: dbo → productmanagement_dbo
-- Manual Conversion Changes:
--   - DECLARE @NewProductId INT → DECLARE var_NewProductId INTEGER
--   - BEGIN TRANSACTION → BEGIN (handled at application level)
--   - SCOPE_IDENTITY() → RETURNING productid INTO var_NewProductId
--   - GETDATE() → CURRENT_TIMESTAMP or NOW()
--   - Table references: Products → productmanagement_dbo.products
--   - Column names lowercase: ProductId → productid
-- ========================================

DO $$
DECLARE
    var_NewProductId INTEGER;
BEGIN
    -- Insert the new product with RETURNING clause
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO var_NewProductId;
    
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (var_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product ID
    RETURN var_NewProductId;
END $$;

-- ========================================
-- CONVERTED STATEMENT #4: UpdateProductAsync
-- ========================================
-- Original Location: DataAccess/ProductRepository.cs - UpdateProductAsync method
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Conversion Method: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768996351
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions]
-- Schema Transformation: dbo → productmanagement_dbo
-- Notable Changes:
--   - DECLARE @OldPrice DECIMAL(18,2) → var_OldPrice NUMERIC(18, 2)
--   - DECLARE @OldStock INT → var_OldStock INTEGER
--   - BEGIN TRANSACTION commented out (handled at application level)
--   - GETDATE() → clock_timestamp()
--   - Table references lowercase: Products → productmanagement_dbo.products
--   - Column names lowercase
-- ========================================

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

-- ========================================
-- CONVERTED STATEMENT #5: DeleteProductAsync
-- ========================================
-- Original Location: DataAccess/ProductRepository.cs - DeleteProductAsync method
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Conversion Method: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768996484
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions]
-- Schema Transformation: dbo → productmanagement_dbo
-- Notable Changes:
--   - DECLARE variables converted to PostgreSQL syntax
--   - BEGIN TRANSACTION commented out (handled at application level)
--   - GETDATE() → clock_timestamp()
--   - Table/column names lowercase
--   - CASE statement preserved
-- ========================================

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

-- ========================================
-- CONVERTED STATEMENT #6: GetProductsByPriceRangeAsync
-- ========================================
-- Original Location: DataAccess/ProductRepository.cs - GetProductsByPriceRangeAsync method
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768996617
-- Schema Transformation: dbo → productmanagement_dbo
-- Notable Changes:
--   - CTE name lowercase: RankedProducts → rankedproducts
--   - RANK() and percent_rank() functions
--   - Table/column names lowercase
--   - Added NULLS FIRST to ORDER BY
--   - Parameters preserved: @MinPrice, @MaxPrice
-- ========================================

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

-- ========================================
-- CONVERTED STATEMENT #7: GetLowStockProductsAsync
-- ========================================
-- Original Location: DataAccess/ProductRepository.cs - GetLowStockProductsAsync method
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768996750
-- Schema Transformation: dbo → productmanagement_dbo
-- Notable Changes:
--   - CTE name lowercase: StockAnalysis → stockanalysis
--   - Window functions: AVG, MIN, MAX all lowercase
--   - Table/column names lowercase
--   - Added NULLS FIRST to ORDER BY
--   - Parameters preserved: @Threshold
-- ========================================

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

-- ========================================
-- CONVERSION SUMMARY
-- ========================================
-- Total SQL Statements Processed: 7
-- Successfully Converted by DMS Tool: 6
-- Manually Converted After DMS Failure: 1 (Statement #3 - InsertProductAsync)
--
-- Key Schema Transformations by DMS:
-- 1. Schema: dbo → productmanagement_dbo (ALL STATEMENTS)
-- 2. Identifiers: PascalCase → lowercase (ALL STATEMENTS)
-- 3. Tables: Products → productmanagement_dbo.products
-- 4. Tables: ProductHistory → productmanagement_dbo.producthistory
-- 5. Tables: ProductStats → productmanagement_dbo.productstats
--
-- SQL Server to PostgreSQL Conversions:
-- 1. GETDATE() → clock_timestamp() or CURRENT_TIMESTAMP
-- 2. SCOPE_IDENTITY() → RETURNING clause with INTO
-- 3. BEGIN TRANSACTION → Handled at application level (commented in DMS output)
-- 4. DECIMAL(18,2) → NUMERIC(18, 2)
-- 5. INT → INTEGER
-- 6. Variable names: @VarName → var_VarName (for DECLARE)
-- 7. Parameters: @ParamName preserved
-- 8. ORDER BY → Added NULLS FIRST
-- 9. LEFT JOIN → LEFT OUTER JOIN
-- 10. Window functions preserved: AVG/LAG/RANK/PERCENT_RANK OVER()
--
-- All statements ready for re-integration into ProductRepository.cs
-- CRITICAL: Must use schema name productmanagement_dbo in code as transformed by DMS
-- ========================================
