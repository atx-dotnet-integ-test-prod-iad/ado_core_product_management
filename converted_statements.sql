-- ============================================================================
-- PostgreSQL Converted SQL Statements Catalog
-- ============================================================================
-- This file contains all SQL statements converted from SQL Server T-SQL to
-- PostgreSQL syntax. All statements were processed through DMS MCP tool.
-- Where DMS failed due to infrastructure issues, manual conversion was applied
-- following standard SQL Server to PostgreSQL migration patterns.
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation failed
-- Manual Conversion Reasoning: 
--   - CTEs and window functions (AVG OVER, COUNT OVER) are PostgreSQL compatible
--   - No syntax changes needed for CTE structure
--   - INNER JOIN remains same
--   - No T-SQL specific functions in this query
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
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation failed
-- Manual Conversion Reasoning:
--   - CTEs and LAG window function are PostgreSQL compatible
--   - Parameters use same @ syntax (compatible with Npgsql)
--   - LEFT JOIN remains same
--   - No T-SQL specific functions in this query
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
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation failed
-- Manual Conversion Reasoning:
--   - PostgreSQL does not support DECLARE outside of DO blocks or functions
--   - SCOPE_IDENTITY() replaced with RETURNING clause on INSERT
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT removed (handled by application code)
--   - Transaction management done at ADO.NET level with BeginTransaction()
--   - Split into separate statements to be executed in application transaction
-- NOTE: This should be executed in application-level transaction with ExecuteScalarAsync
--       for the INSERT to get the new ID, then ExecuteNonQueryAsync for subsequent statements
-- ============================================================================

-- First INSERT with RETURNING to get new ID:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Subsequent statements to be executed with the returned ProductId in same transaction:
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation failed
-- Manual Conversion Reasoning:
--   - PostgreSQL supports DO blocks for procedural code, but not inline variables
--   - Split into multiple statements using CTEs for storing old values
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Transaction handled at application level
--   - Use CTE to capture old values before update
-- ============================================================================

-- CTE approach to capture old values and update in one statement:
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
FROM OldValues
WHERE ProductId = @ProductId;

-- Insert to history (executed after update with captured values):
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update stats (executed after history insert):
-- UPDATE ProductStats
-- SET 
--     AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation failed
-- Manual Conversion Reasoning:
--   - Similar to UPDATE, use CTE to capture values before delete
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Transaction handled at application level
--   - Split into multiple statements for proper execution order
-- ============================================================================

-- Capture old values before delete:
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
-- Insert history record:
HistoryInsert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
    FROM OldValues
    RETURNING ProductId
)
-- Delete the product:
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update stats (executed after delete with captured OldPrice):
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts - 1,
--     AveragePrice = CASE 
--         WHEN TotalProducts > 1 
--         THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
--         ELSE 0
--     END,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation failed
-- Manual Conversion Reasoning:
--   - CTEs, RANK(), and PERCENT_RANK() are PostgreSQL compatible
--   - No syntax changes needed
--   - Parameters use @ syntax (Npgsql compatible)
--   - BETWEEN operator remains same
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
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model creation failed
-- Manual Conversion Reasoning:
--   - CTEs and window functions (AVG, MIN, MAX OVER) are PostgreSQL compatible
--   - No syntax changes needed
--   - Parameters use @ syntax (Npgsql compatible)
--   - Arithmetic operators remain same
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
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================================
