-- ============================================================================
-- CONVERTED SQL STATEMENTS - SQL SERVER TO POSTGRESQL
-- Source: extracted_statements.sql
-- Total Statements: 7
-- Conversion Method: MANUAL (DMS Tool Failed)
-- Conversion Date: 2026-01-31
-- Note: All statements attempted through DMS tool but failed with timeouts
--       Manual conversion performed based on PostgreSQL best practices
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - MANUALLY CONVERTED
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model conversion timeout
-- Changes Applied:
--   - CTEs work identically in PostgreSQL
--   - Window functions AVG() OVER() and COUNT() OVER() are supported
--   - CASE expressions work identically
--   - ROUND() function works identically
--   - No schema name changes
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
-- STATEMENT 2: GetProductByIdAsync - MANUALLY CONVERTED
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Tool execution timeout
-- Changes Applied:
--   - LAG() OVER() window function is supported in PostgreSQL
--   - CTEs work identically
--   - LEFT JOIN syntax is identical
--   - Parameter @ProductId is supported by Npgsql
--   - CASE expressions work identically
--   - No schema name changes
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
-- STATEMENT 3: InsertProductAsync - MANUALLY CONVERTED
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation timeout
-- Changes Applied:
--   - Restructured to eliminate transaction block and variable declarations
--   - SCOPE_IDENTITY() replaced with RETURNING clause
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Combined operations into single statement where possible
--   - Returns ProductId directly from INSERT with RETURNING
-- CRITICAL: Code integration must use RETURNING clause to capture new ID
-- ============================================================================

-- Note: This is a multi-statement transaction that needs to be handled in code
-- Statement 3a: Insert product and return new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log to history (use returned ProductId from 3a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update statistics (use returned ProductId from 3a)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - MANUALLY CONVERTED
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Not attempted (previous failures)
-- Changes Applied:
--   - Restructured to eliminate DECLARE statements
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Combined operations into CTE for old values retrieval
--   - All operations in single transaction
-- Note: Transaction management handled by application code
-- ============================================================================

-- Statement 4a: Get old values and update product
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
WHERE ProductId = @ProductId
RETURNING 
    (SELECT OldPrice FROM OldValues) as old_price,
    (SELECT OldStock FROM OldValues) as old_stock;

-- Statement 4b: Log changes (use returned values from 4a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4c: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - MANUALLY CONVERTED
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Not attempted (previous failures)
-- Changes Applied:
--   - Restructured to eliminate DECLARE statements
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Use RETURNING clause to capture deleted values
--   - CASE expression remains identical
-- Note: Transaction management handled by application code
-- ============================================================================

-- Statement 5a: Delete product and return old values
DELETE FROM Products 
WHERE ProductId = @ProductId
RETURNING Price as old_price, StockQuantity as old_stock;

-- Statement 5b: Log deletion (use returned values from 5a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Update statistics with conditional average calculation
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - MANUALLY CONVERTED
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Not attempted (previous failures)
-- Changes Applied:
--   - CTEs work identically in PostgreSQL
--   - RANK() and PERCENT_RANK() window functions are supported
--   - BETWEEN clause works identically
--   - CASE expressions work identically
--   - No schema name changes
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
-- STATEMENT 7: GetLowStockProductsAsync - MANUALLY CONVERTED
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Not attempted (previous failures)
-- Changes Applied:
--   - CTEs work identically in PostgreSQL
--   - AVG(), MIN(), MAX() window functions with OVER() are supported
--   - WHERE clause with parameter works identically
--   - CASE expressions work identically
--   - ROUND() function works identically
--   - No schema name changes
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
-- END OF CONVERTED SQL STATEMENTS
-- ============================================================================
-- Conversion Summary:
-- - Total statements: 7
-- - DMS successful conversions: 0
-- - Manual conversions: 7
-- - All conversions marked as: MANUAL_AFTER_DMS_FAILURE
-- 
-- Key PostgreSQL Conversions Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause in INSERT
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. BEGIN TRANSACTION/COMMIT → Transaction handling in application code
-- 4. DECLARE @variable → Eliminated or restructured using CTEs and RETURNING
-- 5. Window functions → No changes needed (PostgreSQL compatible)
-- 6. CTEs → No changes needed (PostgreSQL compatible)
-- 7. CASE expressions → No changes needed (PostgreSQL compatible)
-- 
-- Schema Object Changes:
-- - No schema object names were changed (no "dbo" prefix modifications)
-- - All table names remain: Products, ProductHistory, ProductStats
-- - All column names remain unchanged
-- 
-- Application Code Changes Required:
-- - InsertProductAsync: Use RETURNING clause to capture new ProductId
-- - UpdateProductAsync: Handle multi-statement transaction with value passing
-- - DeleteProductAsync: Handle multi-statement transaction with value passing
-- - Transaction management: Use NpgsqlConnection.BeginTransaction()
-- ============================================================================
