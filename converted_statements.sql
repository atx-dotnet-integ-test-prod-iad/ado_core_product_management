-- ============================================================================
-- SQL Server to PostgreSQL Migration - Converted SQL Statements
-- ============================================================================
-- This file contains all SQL statements converted from MS SQL Server to PostgreSQL
-- Each statement was attempted through DMS MCP tool, but due to metadata model
-- creation errors, manual conversions were applied following PostgreSQL standards
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Date: 2026-02-06
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Key Changes: None - PostgreSQL supports CTEs and window functions natively
-- Schema Changes: None
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Key Changes: None - PostgreSQL supports LAG window function natively
-- Schema Changes: None
-- Parameter Notes: @ProductId parameter compatible with Npgsql
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement INSERT with RETURNING
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Key Changes:
--   1. SCOPE_IDENTITY() -> RETURNING clause
--   2. GETDATE() -> CURRENT_TIMESTAMP
--   3. Transaction handling moved to C# code (NpgsqlTransaction)
--   4. DECLARE variables removed - logic moved to C# code
--   5. Multi-statement transaction broken into separate commands
-- Schema Changes: None
-- Implementation Notes: 
--   - This will be implemented as multiple C# commands within a transaction
--   - First INSERT returns ProductId via RETURNING clause
--   - Subsequent INSERT/UPDATE use the returned ProductId
-- ============================================================================

-- First INSERT (returns new ProductId)
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Second INSERT (uses ProductId from previous query)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Third UPDATE (uses ProductId from first query)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement UPDATE with Variables
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Key Changes:
--   1. GETDATE() -> CURRENT_TIMESTAMP
--   2. Transaction handling moved to C# code (NpgsqlTransaction)
--   3. DECLARE variables removed - use CTE or separate queries in C#
--   4. Multi-statement transaction broken into separate commands
-- Schema Changes: None
-- Implementation Notes:
--   - First query: SELECT old values (Price, StockQuantity)
--   - Second query: UPDATE Products
--   - Third query: INSERT into ProductHistory
--   - Fourth query: UPDATE ProductStats
-- ============================================================================

-- First query: Get old values
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Second query: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Third query: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Fourth query: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement DELETE with Variables
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Key Changes:
--   1. GETDATE() -> CURRENT_TIMESTAMP
--   2. Transaction handling moved to C# code (NpgsqlTransaction)
--   3. DECLARE variables removed - use separate queries in C#
--   4. Multi-statement transaction broken into separate commands
-- Schema Changes: None
-- Implementation Notes:
--   - First query: SELECT old values (Price, StockQuantity)
--   - Second query: INSERT into ProductHistory
--   - Third query: DELETE from Products
--   - Fourth query: UPDATE ProductStats with CASE
-- ============================================================================

-- First query: Get product info
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Second query: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Third query: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Fourth query: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Key Changes: None - PostgreSQL supports RANK() and PERCENT_RANK() natively
-- Schema Changes: None
-- Parameter Notes: @MinPrice and @MaxPrice parameters compatible with Npgsql
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Key Changes: None - PostgreSQL supports AVG(), MIN(), MAX() window functions natively
-- Schema Changes: None
-- Parameter Notes: @Threshold parameter compatible with Npgsql
-- ============================================================================

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

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Converted: 7
-- DMS Tool Successful Conversions: 0
-- DMS Tool Failed Conversions: 7
-- Manual Conversions Applied: 7
--
-- Key Transformation Patterns Applied:
-- 1. CTEs and Window Functions: Compatible - No changes needed
-- 2. GETDATE(): Converted to CURRENT_TIMESTAMP
-- 3. SCOPE_IDENTITY(): Converted to RETURNING clause
-- 4. BEGIN TRANSACTION/COMMIT: Handled in C# code with NpgsqlTransaction
-- 5. DECLARE variables: Removed - logic moved to C# code
-- 6. Multi-statement batches: Broken into separate C# commands
-- 7. @ Parameters: Compatible with Npgsql - No changes needed
-- 8. CASE statements: Compatible - No changes needed
-- 9. ROUND function: Compatible - No changes needed
--
-- Schema Object Changes: None
-- All table names preserved: Products, ProductHistory, ProductStats
-- ============================================================================
