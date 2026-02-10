-- ============================================================
-- PostgreSQL Converted SQL Statements Catalog
-- ============================================================
-- Source File: ProductRepository.cs
-- Database: ProductManagement
-- Schema: dbo (SQL Server) -> public (PostgreSQL default)
-- Total Statements: 7
-- Conversion Date: 2026-02-10
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
-- DMS Tool Status: All statements failed with "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ============================================================
-- DMS Tool Result: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible with PostgreSQL (no changes needed)
--   - Window functions (AVG, COUNT OVER): Compatible (no changes needed)
--   - CASE statements: Compatible (no changes needed)
--   - ROUND function: Compatible (no changes needed)
--   - Schema: Assuming tables exist in public schema
-- ============================================================
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

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- ============================================================
-- DMS Tool Result: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible (no changes needed)
--   - LAG window function: Compatible (no changes needed)
--   - Parameters: @ProductId -> $1 (will use positional parameters in Npgsql)
--   - CASE statement: Compatible (no changes needed)
-- ============================================================
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

-- ============================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- ============================================================
-- DMS Tool Result: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed DECLARE @NewProductId INT (PostgreSQL doesn't need variable declaration in this context)
--   - Removed BEGIN TRANSACTION/COMMIT (will be handled at application level with NpgsqlTransaction)
--   - Replaced SCOPE_IDENTITY() with RETURNING clause
--   - Replaced GETDATE() with NOW()
--   - Combined INSERT with RETURNING to eliminate variable
--   - Note: This requires restructuring the transaction logic in C# code
-- ============================================================
-- Part 1: Insert product and get new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ($1, $2, $3, $4)
RETURNING ProductId;

-- Part 2: Insert into ProductHistory (to be executed after getting ProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'INSERT', NULL, $2, NULL, $3, NOW());

-- Part 3: Update ProductStats
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- ============================================================
-- DMS Tool Result: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed BEGIN TRANSACTION/COMMIT (handled at application level)
--   - Removed DECLARE statements (use CTEs or separate queries)
--   - Replaced GETDATE() with NOW()
--   - Split into separate statements that will be executed in a transaction
-- ============================================================
-- Part 1: Get old values (to be stored in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

-- Part 2: Update the product
UPDATE Products
SET 
    Name = $1,
    Description = $2,
    Price = $3,
    StockQuantity = $4,
    ModifiedDate = NOW()
WHERE ProductId = $5;

-- Part 3: Insert history record (using old values from Part 1)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'UPDATE', $2, $3, $4, $5, NOW());

-- Part 4: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - $1 + $2) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- ============================================================
-- DMS Tool Result: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - Removed BEGIN TRANSACTION/COMMIT (handled at application level)
--   - Removed DECLARE statements
--   - Replaced GETDATE() with NOW()
--   - Split into separate statements
-- ============================================================
-- Part 1: Get product info for history (to be stored in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

-- Part 2: Insert history record
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'DELETE', $2, NULL, $3, NULL, NOW());

-- Part 3: Delete the product
DELETE FROM Products 
WHERE ProductId = $1;

-- Part 4: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - $1) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ============================================================
-- DMS Tool Result: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible (no changes needed)
--   - RANK() and PERCENT_RANK() window functions: Compatible (no changes needed)
--   - BETWEEN operator: Compatible (no changes needed)
--   - Parameters: @MinPrice -> $1, @MaxPrice -> $2
-- ============================================================
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- ============================================================
-- DMS Tool Result: ERROR - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible (no changes needed)
--   - AVG, MIN, MAX window functions: Compatible (no changes needed)
--   - CASE statement: Compatible (no changes needed)
--   - Parameter: @Threshold -> $1
-- ============================================================
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- ============================================================
-- CONVERSION SUMMARY
-- ============================================================
-- Total Statements: 7
-- DMS Tool Successful Conversions: 0
-- Manual Conversions After DMS Failure: 7
-- 
-- Key PostgreSQL Conversion Patterns Applied:
-- 1. GETDATE() -> NOW()
-- 2. SCOPE_IDENTITY() -> RETURNING clause
-- 3. BEGIN TRANSACTION/COMMIT -> Handled at application level with NpgsqlTransaction
-- 4. DECLARE statements -> Removed (use C# variables or CTEs)
-- 5. SET @variable -> Use RETURNING or separate queries
-- 6. @ParameterName -> $N (positional parameters for Npgsql)
-- 7. Window functions, CTEs, CASE statements -> Compatible as-is
-- 
-- Schema Object Name Changes: None (assuming all tables exist in public schema)
-- ============================================================
