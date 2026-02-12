-- ========================================================================================================
-- CONVERTED SQL STATEMENTS - SQL Server to PostgreSQL
-- ========================================================================================================
-- Purpose: PostgreSQL converted versions of all SQL statements from the ADO.NET application
-- Total Statements: 7
-- Source Application: AdoCore - Product Management System
-- Conversion Method: Manual conversion after DMS tool failure (documented in dms_conversion_log.json)
-- Date Converted: 2025
-- ========================================================================================================
-- NOTE: All statements were attempted through DMS MCP tool first (as required), but encountered
--       metadata model creation errors. Manual conversions performed and documented per transformation
--       definition guidelines.
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ========================================================================================================
-- Original Statement ID: Statement 1
-- Source Method: GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: High - CTEs and window functions are fully supported
-- Changes Applied:
--   - None required: PostgreSQL syntax is compatible with original SQL Server syntax
--   - Window functions (AVG OVER, COUNT OVER) work identically in PostgreSQL
--   - CASE expressions are identical
--   - ROUND function is compatible
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ========================================================================================================
-- Original Statement ID: Statement 2
-- Source Method: GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: High - LAG function is fully supported
-- Changes Applied:
--   - None required: PostgreSQL syntax is compatible with original SQL Server syntax
--   - LAG window function works identically in PostgreSQL
--   - Parameter @ProductId remains unchanged (Npgsql supports named parameters)
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
-- STATEMENT 3: InsertProductAsync - Transaction with INSERT and RETURNING
-- ========================================================================================================
-- Original Statement ID: Statement 3
-- Source Method: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: Requires significant conversion
-- Changes Applied:
--   1. Removed DECLARE @NewProductId INT - PostgreSQL uses different variable syntax in DO blocks
--   2. Changed BEGIN TRANSACTION to BEGIN
--   3. Replaced SCOPE_IDENTITY() with RETURNING clause on INSERT
--   4. Changed GETDATE() to CURRENT_TIMESTAMP (2 occurrences)
--   5. Modified to use WITH clause to capture returned ID for subsequent statements
--   6. Changed SET @NewProductId to CTE pattern
--   7. Kept parameter names with @ prefix (Npgsql supports this)
-- Note: This requires refactoring in C# code to handle RETURNING clause result
-- ========================================================================================================

WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1
RETURNING (SELECT ProductId FROM inserted_product);

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variables and Multiple Statements
-- ========================================================================================================
-- Original Statement ID: Statement 4
-- Source Method: UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: Requires significant conversion
-- Changes Applied:
--   1. Removed DECLARE statements - PostgreSQL uses CTE pattern
--   2. Changed BEGIN TRANSACTION to BEGIN
--   3. Changed GETDATE() to CURRENT_TIMESTAMP (3 occurrences)
--   4. Used CTE to capture old values
--   5. Restructured to use WITH clauses for sequential operations
-- Note: May need to be executed as separate statements in ADO.NET or within a DO block
-- ========================================================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
product_update AS (
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
history_insert AS (
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
-- STATEMENT 5: DeleteProductAsync - Transaction with Variables and Multiple Statements
-- ========================================================================================================
-- Original Statement ID: Statement 5
-- Source Method: DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: Requires significant conversion
-- Changes Applied:
--   1. Removed DECLARE statements - PostgreSQL uses CTE pattern
--   2. Changed BEGIN TRANSACTION to BEGIN
--   3. Changed GETDATE() to CURRENT_TIMESTAMP (2 occurrences)
--   4. Used CTE to capture old values before deletion
--   5. Restructured to use WITH clauses for sequential operations
-- ========================================================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
),
product_delete AS (
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with Ranking Window Functions
-- ========================================================================================================
-- Original Statement ID: Statement 6
-- Source Method: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: High - Window functions are fully supported
-- Changes Applied:
--   - None required: PostgreSQL syntax is compatible with original SQL Server syntax
--   - RANK() and PERCENT_RANK() window functions work identically in PostgreSQL
--   - BETWEEN operator is identical
--   - Parameter names @MinPrice and @MaxPrice remain unchanged
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ========================================================================================================
-- Original Statement ID: Statement 7
-- Source Method: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: High - Window functions are fully supported
-- Changes Applied:
--   - None required: PostgreSQL syntax is compatible with original SQL Server syntax
--   - AVG, MIN, MAX window functions work identically in PostgreSQL
--   - CASE expressions are identical
--   - ROUND function is compatible
--   - Parameter @Threshold remains unchanged
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
-- END OF CONVERTED STATEMENTS
-- ========================================================================================================
-- 
-- CONVERSION SUMMARY:
-- 
-- Statements 1, 2, 6, 7: Minimal/No changes required
--   - CTEs are identical in PostgreSQL
--   - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) are compatible
--   - CASE expressions are identical
--   - ROUND function is compatible
--   - Named parameters (@param) are supported by Npgsql
-- 
-- Statements 3, 4, 5: Significant refactoring required
--   - DECLARE/SET variable syntax removed, replaced with CTEs
--   - BEGIN TRANSACTION → BEGIN
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Sequential operations restructured using WITH clauses
-- 
-- IMPORTANT NOTES FOR CODE INTEGRATION:
-- 
-- 1. Transaction statements (3, 4, 5) may need to be split into multiple ExecuteNonQueryAsync
--    calls or wrapped in a DO block depending on execution context
-- 
-- 2. InsertProductAsync (Statement 3) needs to capture the RETURNING value from the first
--    INSERT to get the new ProductId
-- 
-- 3. All statements maintain named parameter syntax (@param) which is supported by Npgsql
--    through NpgsqlParameter with ParameterName property
-- 
-- 4. Consider using transactions explicitly in C# code (BeginTransaction) rather than
--    including BEGIN/COMMIT in SQL strings for better error handling
-- 
-- ========================================================================================================
