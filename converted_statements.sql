/*
========================================================================================================
CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
========================================================================================================
Project: AdoCore - ADO.NET Product Management System
Source File: extracted_statements.sql
Target Database: PostgreSQL
Conversion Date: 2026-02-15
Purpose: Catalog of all SQL statements converted from SQL Server to PostgreSQL

This file contains all converted PostgreSQL statements that will be re-integrated into the codebase.
Each statement is documented with:
- Statement ID (matching extracted_statements.sql)
- Conversion method (DMS_TOOL or MANUAL_AFTER_DMS_FAILURE)
- DMS tool output (if attempted)
- Schema object name changes (if any)
- PostgreSQL-specific syntax notes

Total Statements: 7
========================================================================================================
*/

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions (CONVERTED)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Changes: None (Products table name unchanged)
-- PostgreSQL Conversion Notes:
--   - CTE syntax is compatible between SQL Server and PostgreSQL
--   - Window functions (AVG OVER, COUNT OVER) are compatible
--   - ROUND function syntax is compatible
--   - CASE expressions are compatible
--   - String literals use single quotes (already correct)
-- ========================================================================================================

WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function (CONVERTED)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Changes: None (Products table name unchanged)
-- PostgreSQL Conversion Notes:
--   - CTE syntax is compatible
--   - LAG window function is compatible
--   - Parameter syntax @ProductId remains same in PostgreSQL with Npgsql
--   - LEFT JOIN syntax is compatible
--   - CASE and ROUND functions are compatible
-- ========================================================================================================

WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with RETURNING (CONVERTED)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Changes: None (Products, ProductHistory, ProductStats tables unchanged)
-- PostgreSQL Conversion Notes:
--   - DECLARE syntax not needed (use DO block or eliminate variable)
--   - BEGIN TRANSACTION -> BEGIN
--   - SCOPE_IDENTITY() -> RETURNING clause on INSERT
--   - GETDATE() -> CURRENT_TIMESTAMP or NOW()
--   - COMMIT syntax is compatible
--   - For ADO.NET ExecuteScalar, restructure to use WITH clause and RETURNING
-- Critical Changes:
--   - Replaced SCOPE_IDENTITY() with RETURNING ProductId
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Removed variable declaration, using WITH clause for chaining
-- ========================================================================================================

WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
logged_history AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING ProductId
),
updated_stats AS (
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING StatId
)
SELECT ProductId FROM inserted_product;

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with History Logging (CONVERTED)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Changes: None (Products, ProductHistory, ProductStats tables unchanged)
-- PostgreSQL Conversion Notes:
--   - BEGIN TRANSACTION -> BEGIN
--   - DECLARE syntax -> Use WITH clause or subqueries
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - SELECT INTO variables -> Use WITH clause for chaining
--   - Multiple statements can be chained with WITH clauses
-- ========================================================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
updated_product AS (
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId
    RETURNING ProductId
),
logged_history AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with Statistics Update (CONVERTED)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Changes: None (Products, ProductHistory, ProductStats tables unchanged)
-- PostgreSQL Conversion Notes:
--   - BEGIN TRANSACTION -> BEGIN
--   - DECLARE syntax -> Use WITH clause
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - DELETE ... FROM -> DELETE FROM (syntax variation)
--   - CASE expressions are compatible
-- ========================================================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
logged_history AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
),
deleted_product AS (
    DELETE FROM Products 
    WHERE ProductId = @ProductId
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK (CONVERTED)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Changes: None (Products table name unchanged)
-- PostgreSQL Conversion Notes:
--   - CTE syntax is compatible
--   - RANK() window function is compatible
--   - PERCENT_RANK() window function is compatible
--   - BETWEEN operator is compatible
--   - CASE expressions are compatible
--   - p.* wildcard syntax is compatible
-- ========================================================================================================

WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank;

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Window Functions (CONVERTED)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Changes: None (Products table name unchanged)
-- PostgreSQL Conversion Notes:
--   - CTE syntax is compatible
--   - Window functions (AVG, MIN, MAX OVER) are compatible
--   - ROUND function is compatible
--   - CASE expressions are compatible
--   - Arithmetic operations are compatible
-- ========================================================================================================

WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

/*
========================================================================================================
END OF CONVERTED STATEMENTS CATALOG
========================================================================================================

CONVERSION SUMMARY:
==================
Total Statements Processed: 7
DMS Tool Successful Conversions: 0
Manual Conversions After DMS Failure: 7

DMS TOOL FAILURE DOCUMENTATION:
================================
All 7 statements failed with the same DMS error:
"Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"

This appears to be a DMS infrastructure/configuration issue rather than SQL syntax issues.
All statements were manually converted following PostgreSQL best practices.

KEY CONVERSION PATTERNS APPLIED:
=================================
1. CTE Syntax: Compatible, no changes needed (Statements 1, 2, 6, 7)
2. Window Functions: All window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) are compatible
3. SCOPE_IDENTITY(): Replaced with RETURNING clause (Statement 3)
4. GETDATE(): Replaced with CURRENT_TIMESTAMP (Statements 3, 4, 5)
5. BEGIN TRANSACTION/COMMIT: Replaced with WITH clause chaining for multi-statement operations
6. DECLARE variables: Eliminated using WITH clauses and subqueries
7. Parameter syntax @ParameterName: Compatible with Npgsql, no changes needed

SCHEMA OBJECT NAME CHANGES:
============================
None - All table names (Products, ProductHistory, ProductStats) remain unchanged

NEXT STEPS:
===========
1. Validate all 7 statement pairs using SQL Equivalency tool
2. Re-integrate converted statements into ProductRepository.cs
3. Update package dependencies to Npgsql
4. Update ADO.NET classes to Npgsql equivalents
5. Update connection strings for PostgreSQL
========================================================================================================
*/
