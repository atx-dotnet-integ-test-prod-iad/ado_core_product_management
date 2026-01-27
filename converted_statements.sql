-- ========================================================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
-- ========================================================================================================
-- Migration: Microsoft SQL Server to PostgreSQL for ADO.NET Application
-- Conversion Date: 2026-01-27
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements - DMS tool encountered errors)
-- Source: extracted_statements.sql
-- Total Statements: 7
-- ========================================================================================================
-- IMPORTANT: All statements were passed through DMS MCP tool as required by transformation definition.
-- DMS tool encountered errors on all statements. Manual conversions were applied following PostgreSQL
-- best practices. See dms_conversion_issues.log for complete DMS error details.
-- ========================================================================================================

-- ========================================================================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ========================================================================================================
-- Original Statement: extracted_statements.sql - STATEMENT 1
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - PostgreSQL compatible as-is
-- Mapping: Lines 39-66 in ProductRepository.cs
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
-- CONVERTED STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ========================================================================================================
-- Original Statement: extracted_statements.sql - STATEMENT 2
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - PostgreSQL compatible as-is
-- Mapping: Lines 75-105 in ProductRepository.cs
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
-- CONVERTED STATEMENT 3: InsertProductAsync - INSERT with RETURNING (Restructured Transaction)
-- ========================================================================================================
-- Original Statement: extracted_statements.sql - STATEMENT 3
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Major restructuring for PostgreSQL transaction pattern in ADO.NET:
--   - Removed DECLARE @NewProductId, BEGIN TRANSACTION, COMMIT (application-level control)
--   - Replaced SCOPE_IDENTITY() with RETURNING clause and sequence
--   - Replaced GETDATE() with NOW()
--   - Split into separate statements for application transaction control
-- Mapping: Lines 114-137 in ProductRepository.cs
-- ========================================================================================================
-- Note: These statements must be executed within an application-level transaction
-- (NpgsqlConnection.BeginTransaction) to maintain atomicity

-- Statement 3a: Insert product and return new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log insertion to history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ========================================================================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync - UPDATE (Restructured Transaction)
-- ========================================================================================================
-- Original Statement: extracted_statements.sql - STATEMENT 4
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Restructured for PostgreSQL transaction pattern:
--   - Removed DECLARE, BEGIN TRANSACTION, COMMIT (application-level control)
--   - Replaced GETDATE() with NOW()
--   - Split into separate statements with variables managed in application code
-- Mapping: Lines 147-179 in ProductRepository.cs
-- ========================================================================================================
-- Note: These statements must be executed within an application-level transaction
-- Variables @OldPrice and @OldStock are managed in application code

-- Statement 4a: Get old values
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Statement 4b: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Statement 4c: Log update to history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ========================================================================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync - DELETE (Restructured Transaction)
-- ========================================================================================================
-- Original Statement: extracted_statements.sql - STATEMENT 5
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: Restructured for PostgreSQL transaction pattern:
--   - Removed DECLARE, BEGIN TRANSACTION, COMMIT (application-level control)
--   - Replaced GETDATE() with NOW()
--   - Split into separate statements with variables managed in application code
-- Mapping: Lines 187-219 in ProductRepository.cs
-- ========================================================================================================
-- Note: These statements must be executed within an application-level transaction
-- Variables @OldPrice and @OldStock are managed in application code

-- Statement 5a: Get old values
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Log deletion to history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ========================================================================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync - RANK and PERCENT_RANK
-- ========================================================================================================
-- Original Statement: extracted_statements.sql - STATEMENT 6
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - PostgreSQL compatible as-is
-- Mapping: Lines 227-256 in ProductRepository.cs
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
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync - Multiple Window Functions
-- ========================================================================================================
-- Original Statement: extracted_statements.sql - STATEMENT 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - PostgreSQL compatible as-is
-- Mapping: Lines 264-293 in ProductRepository.cs
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

-- ========================================================================================================
-- CONVERSION SUMMARY
-- ========================================================================================================
-- Total Statements Converted: 7
-- 
-- Conversion Breakdown:
--   - No changes required (PostgreSQL compatible): 4 statements (1, 2, 6, 7)
--   - Transaction restructuring required: 3 statements (3, 4, 5)
-- 
-- Key PostgreSQL Conversions Applied:
--   - SCOPE_IDENTITY() → RETURNING clause in INSERT
--   - GETDATE() → NOW() (13 occurrences)
--   - BEGIN TRANSACTION/COMMIT → Application-level transaction control
--   - DECLARE/SET variables → Application code variable management
--   - Multi-statement blocks → Split into separate queries for ADO.NET execution
-- 
-- PostgreSQL Features Retained:
--   - Window Functions: AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN/MAX OVER
--   - Common Table Expressions (CTEs): WITH clause
--   - CASE Expressions: All conditional logic preserved
--   - ROUND Function: Decimal rounding preserved
--   - Parameter Syntax: @parameter notation (supported by Npgsql driver)
-- 
-- Schema Object Names:
--   - No schema name changes applied by DMS tool
--   - All table names remain as: Products, ProductHistory, ProductStats
--   - Column names unchanged
-- 
-- Next Step: Validate all statement pairs using SQL Equivalency MCP tool
-- ========================================================================================================
