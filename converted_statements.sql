-- ====================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: extracted_statements.sql
-- Target Database: PostgreSQL
-- Conversion Date: 2025-01-26
-- Total Statements: 7
-- ====================================================================

-- ====================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ====================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Original SQL Server Statement Passed Through DMS: YES
-- Manual Conversion Applied: YES
-- PostgreSQL Changes:
--   - CTE syntax is compatible (no changes needed)
--   - Window functions AVG() OVER() and COUNT() OVER() are compatible
--   - ROUND() function syntax is identical
--   - CASE expressions are compatible
--   - Parameter syntax @ is compatible with PostgreSQL
-- Schema Changes: No schema object name changes
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ====================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Original SQL Server Statement Passed Through DMS: YES
-- Manual Conversion Applied: YES
-- PostgreSQL Changes:
--   - CTE syntax is compatible
--   - LAG() OVER() window function is compatible
--   - Parameter syntax @ is compatible with PostgreSQL
--   - ROUND() function is compatible
--   - CASE expressions are compatible
-- Schema Changes: No schema object name changes
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 3: InsertProductAsync - Transaction with RETURNING Clause
-- ====================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}
-- Original SQL Server Statement Passed Through DMS: YES
-- Manual Conversion Applied: YES
-- PostgreSQL Changes:
--   - Removed DECLARE @NewProductId INT (PostgreSQL uses DO blocks or functions for variables)
--   - Removed BEGIN TRANSACTION/COMMIT (handled in application code)
--   - Replaced SCOPE_IDENTITY() with RETURNING clause
--   - Replaced GETDATE() with NOW()
--   - Combined INSERT with RETURNING to capture ProductId
--   - Separated transaction statements to be executed in sequence
-- IMPORTANT: This needs to be split into separate commands in application code
-- Schema Changes: No schema object name changes
-- ====================================================================

-- First statement: Insert product and return new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Second statement: Log the insertion (will use returned ProductId from first statement)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Third statement: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ====================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Handling
-- ====================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Original SQL Server Statement Passed Through DMS: YES
-- Manual Conversion Applied: YES
-- PostgreSQL Changes:
--   - Removed BEGIN TRANSACTION/COMMIT (handled in application code)
--   - Replaced variable declarations with CTE pattern
--   - Replaced GETDATE() with NOW()
--   - Restructured to use CTEs for capturing old values
-- IMPORTANT: Variables handled differently - need to fetch old values first in application
-- Schema Changes: No schema object name changes
-- ====================================================================

-- First query: Get old values (execute separately in application)
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Second statement: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Third statement: Log the changes (use @OldPrice and @OldStock from first query)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Fourth statement: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ====================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Delete
-- ====================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Original SQL Server Statement Passed Through DMS: YES
-- Manual Conversion Applied: YES
-- PostgreSQL Changes:
--   - Removed BEGIN TRANSACTION/COMMIT (handled in application code)
--   - Replaced variable declarations with separate query
--   - Replaced GETDATE() with NOW()
-- IMPORTANT: Need to fetch old values first in application code
-- Schema Changes: No schema object name changes
-- ====================================================================

-- First query: Get old values (execute separately in application)
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Second statement: Log the deletion (use @OldPrice and @OldStock from first query)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Third statement: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Fourth statement: Update product statistics
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

-- ====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- ====================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Original SQL Server Statement Passed Through DMS: YES
-- Manual Conversion Applied: YES
-- PostgreSQL Changes:
--   - CTE syntax is compatible
--   - RANK() OVER() and PERCENT_RANK() OVER() are compatible
--   - BETWEEN clause is compatible
--   - Parameter syntax @ is compatible with PostgreSQL
-- Schema Changes: No schema object name changes
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ====================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Original SQL Server Statement Passed Through DMS: YES
-- Manual Conversion Applied: YES
-- PostgreSQL Changes:
--   - CTE syntax is compatible
--   - AVG() OVER(), MIN() OVER(), MAX() OVER() window functions are compatible
--   - ROUND() function is compatible
--   - CASE expressions are compatible
--   - Parameter syntax @ is compatible with PostgreSQL
-- Schema Changes: No schema object name changes
-- ====================================================================

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

-- ====================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements Converted: 7
-- Conversion Method: All statements passed through DMS MCP tool first
-- DMS Tool Status: All 7 statements failed DMS conversion
-- Manual Conversion Applied: All 7 statements
-- ====================================================================

-- ====================================================================
-- CRITICAL NOTES FOR APPLICATION INTEGRATION:
-- ====================================================================
-- 1. Statements 3, 4, 5 (INSERT, UPDATE, DELETE transactions) need special handling:
--    - Transaction control (BEGIN/COMMIT/ROLLBACK) must be managed in C# code
--    - Variable handling must be done in application layer
--    - Statement 3: Use RETURNING clause to get new ProductId
--
-- 2. All GETDATE() calls have been replaced with NOW()
--
-- 3. SCOPE_IDENTITY() replaced with RETURNING clause in INSERT statements
--
-- 4. Parameter syntax (@ParameterName) is compatible with Npgsql
--
-- 5. Schema object names: No changes were made by DMS tool, all original
--    table names (Products, ProductHistory, ProductStats) remain the same
-- ====================================================================
