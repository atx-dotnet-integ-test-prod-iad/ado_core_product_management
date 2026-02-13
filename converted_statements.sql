-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Source: MS SQL Server extracted_statements.sql
-- Conversion Date: 2026-02-13
-- Total Statements: 7
-- Conversion Method: Manual (DMS Tool encountered metadata model errors)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- ============================================================================
-- Original: MS SQL Server CTE with window functions
-- Converted: PostgreSQL compatible syntax
-- Changes: Minimal - PostgreSQL natively supports CTEs and window functions
-- Schema: Products table remains unchanged
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
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- ============================================================================
-- Original: MS SQL Server CTE with LAG window function
-- Converted: PostgreSQL compatible syntax
-- Changes: Minimal - PostgreSQL supports LAG window function
-- Schema: Products table remains unchanged
-- Parameter: @ProductId remains as @ProductId (Npgsql supports named parameters)
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
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- ============================================================================
-- Original: MS SQL Server transaction with SCOPE_IDENTITY() and GETDATE()
-- Converted: PostgreSQL with RETURNING clause and NOW() using C# NpgsqlTransaction
-- Changes: 
--   1. Transaction handling moved to C# code using NpgsqlTransaction
--   2. SCOPE_IDENTITY() -> RETURNING ProductId (returns value to C# code)
--   3. GETDATE() -> NOW()
--   4. Multi-statement SQL split into separate commands for proper transaction control
-- Schema: Products, ProductHistory, ProductStats tables remain unchanged
-- Implementation: Three separate SQL statements executed within C# transaction
-- ============================================================================

-- Statement 3a: Insert product and get ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log the insertion (executed after 3a with ProductId from RETURNING)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- ============================================================================
-- Original: MS SQL Server transaction with variable declarations and GETDATE()
-- Converted: PostgreSQL using C# NpgsqlTransaction with separate statements
-- Changes:
--   1. Transaction handling moved to C# code using NpgsqlTransaction
--   2. Variable declarations moved to C# code (oldPrice, oldStock)
--   3. GETDATE() -> NOW()
--   4. Multi-statement SQL split into separate commands for proper transaction control
-- Schema: Products, ProductHistory, ProductStats tables remain unchanged
-- Implementation: Four separate SQL statements executed within C# transaction
-- ============================================================================

-- Statement 4a: Get old values for history (results stored in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 4b: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Statement 4c: Log the changes (uses C# variables for old values)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @NewPrice, @OldStock, @NewStockQuantity, NOW());

-- Statement 4d: Update product statistics (uses C# variables)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @NewPrice) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- ============================================================================
-- Original: MS SQL Server transaction with variable declarations and GETDATE()
-- Converted: PostgreSQL using C# NpgsqlTransaction with separate statements
-- Changes:
--   1. Transaction handling moved to C# code using NpgsqlTransaction
--   2. Variable declarations moved to C# code (oldPrice, oldStock)
--   3. GETDATE() -> NOW()
--   4. Multi-statement SQL split into separate commands for proper transaction control
-- Schema: Products, ProductHistory, ProductStats tables remain unchanged
-- Implementation: Four separate SQL statements executed within C# transaction
-- ============================================================================

-- Statement 5a: Get product info for history (results stored in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Log the deletion (uses C# variables for old values)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update product statistics (uses C# variable)
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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- ============================================================================
-- Original: MS SQL Server CTE with RANK() and PERCENT_RANK()
-- Converted: PostgreSQL compatible syntax
-- Changes: Minimal - PostgreSQL natively supports these window functions
-- Schema: Products table remains unchanged
-- Parameters: @MinPrice, @MaxPrice remain as named parameters
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
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- ============================================================================
-- Original: MS SQL Server CTE with aggregate window functions
-- Converted: PostgreSQL compatible syntax
-- Changes: Minimal - PostgreSQL supports all these window functions
-- Schema: Products table remains unchanged
-- Parameter: @Threshold remains as named parameter
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
-- END OF CONVERTED STATEMENTS
-- ============================================================================
--
-- CONVERSION SUMMARY:
-- Total Statements Converted: 7
-- Method: Manual conversion after DMS tool failures
-- 
-- KEY CONVERSIONS APPLIED:
-- 1. SCOPE_IDENTITY() → RETURNING clause in PostgreSQL
-- 2. GETDATE() → NOW() or CURRENT_TIMESTAMP
-- 3. Transaction handling moved to C# NpgsqlTransaction (statements 3, 4, 5)
-- 4. SQL-level DECLARE statements moved to C# variables (statements 3, 4, 5)
-- 5. Multi-statement transactions split into separate SQL commands (statements 3, 4, 5)
-- 6. Window functions: Direct compatibility (no changes needed)
-- 7. CTEs: Direct compatibility (no changes needed)
-- 8. Named parameters: @ParamName compatible with Npgsql
-- 9. Schema names: All table names remain unchanged (no schema prefix changes)
--
-- CODE INTEGRATION NOTES:
-- - Statements 1, 2, 6, 7 (SELECT queries): Direct SQL replacement, no transaction needed
-- - Statement 3 (INSERT): Uses NpgsqlTransaction with 3 separate SQL statements
--   * RETURNING clause captures ProductId directly in C# code
--   * Proper error handling with transaction rollback
-- - Statement 4 (UPDATE): Uses NpgsqlTransaction with 4 separate SQL statements
--   * Old values captured in C# variables via SELECT
--   * Proper error handling with transaction rollback
-- - Statement 5 (DELETE): Uses NpgsqlTransaction with 4 separate SQL statements
--   * Old values captured in C# variables via SELECT
--   * Proper error handling with transaction rollback
--
-- TRANSACTION HANDLING:
-- All multi-statement operations (Insert, Update, Delete) now use proper C#
-- NpgsqlTransaction handling instead of SQL-level BEGIN/COMMIT, providing:
-- - Better error handling and rollback control
-- - Compatibility with PostgreSQL transaction semantics
-- - Cleaner separation of concerns (logic in C#, data operations in SQL)
-- ============================================================================
