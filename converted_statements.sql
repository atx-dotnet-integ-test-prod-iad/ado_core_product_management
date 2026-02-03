-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Conversion Date: 2026-02-03
-- Source Application: AdoCore - Product Management System
-- Target Database: PostgreSQL
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool experienced infrastructure errors)
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT ID: STMT-001
-- Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None
-- PostgreSQL Compatibility: CTEs and window functions are fully supported
-- ============================================================================

-- Original SQL Server Statement:
-- WITH ProductStats AS (
--     SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--        CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
--        ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name

-- Converted PostgreSQL Statement:
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
    p.Name

-- Conversion Notes:
-- - No changes required - SQL is PostgreSQL compatible
-- - CTE syntax is identical
-- - Window functions (AVG OVER, COUNT OVER) are supported
-- - ROUND() function has same syntax
-- - CASE expressions are identical

-- ============================================================================
-- STATEMENT ID: STMT-002
-- Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None
-- Parameters: @ProductId
-- ============================================================================

-- Converted PostgreSQL Statement:
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
WHERE p.ProductId = @ProductId

-- Conversion Notes:
-- - No changes required - SQL is PostgreSQL compatible
-- - LAG() window function is fully supported
-- - @ProductId parameter syntax works with Npgsql
-- - CASE with NULL handling is identical

-- ============================================================================
-- STATEMENT ID: STMT-003
-- Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None
-- Major Changes: SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), transaction syntax
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ============================================================================

-- Original SQL Server Transaction (multi-statement):
-- DECLARE @NewProductId INT;
-- BEGIN TRANSACTION;
--     INSERT INTO Products (Name, Description, Price, StockQuantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity);
--     SET @NewProductId = SCOPE_IDENTITY();
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     UPDATE ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;
-- SELECT @NewProductId;

-- Converted PostgreSQL Statements (to be executed in sequence within transaction):

-- Statement 3a: Insert Product and return ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log to ProductHistory (execute with returned ProductId as @NewProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update ProductStats
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- Conversion Notes:
-- - BEGIN TRANSACTION/COMMIT removed from SQL (managed by ADO.NET)
-- - DECLARE @NewProductId removed - use RETURNING clause instead
-- - SCOPE_IDENTITY() replaced with RETURNING ProductId
-- - GETDATE() replaced with NOW()
-- - Multi-statement transaction split into 3 separate statements
-- - Application code must capture RETURNING value and use it in subsequent statements
-- - All statements executed within ADO.NET transaction for atomicity

-- ============================================================================
-- STATEMENT ID: STMT-004
-- Method: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None
-- Major Changes: DECLARE → CTE, GETDATE() → NOW(), transaction syntax
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================================

-- Converted PostgreSQL Statements (to be executed in sequence within transaction):

-- Statement 4a: Update Product and capture old values via CTE
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
    ModifiedDate = NOW()
WHERE ProductId = @ProductId
RETURNING (SELECT OldPrice FROM OldValues) as OldPrice, (SELECT OldStock FROM OldValues) as OldStock;

-- Alternative approach (simpler, two separate statements):
-- Statement 4a-alt: Capture old values first
SELECT Price as OldPrice, StockQuantity as OldStock
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

-- Statement 4c: Log to ProductHistory (use captured @OldPrice and @OldStock)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update ProductStats
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- Conversion Notes:
-- - DECLARE variables removed - use SELECT to capture values first
-- - GETDATE() replaced with NOW()
-- - BEGIN TRANSACTION/COMMIT managed by ADO.NET
-- - Application code must execute statements in sequence within transaction
-- - Recommended approach: Execute 4a-alt first to get old values, then 4b, 4c, 4d

-- ============================================================================
-- STATEMENT ID: STMT-005
-- Method: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None
-- Major Changes: DECLARE → SELECT first, GETDATE() → NOW(), transaction syntax
-- Parameters: @ProductId
-- ============================================================================

-- Converted PostgreSQL Statements (to be executed in sequence within transaction):

-- Statement 5a: Capture product info before deletion
SELECT Price as OldPrice, StockQuantity as OldStock
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Log to ProductHistory (use captured @OldPrice and @OldStock)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update ProductStats
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

-- Conversion Notes:
-- - DECLARE variables removed - use SELECT to capture values first
-- - GETDATE() replaced with NOW()
-- - CASE expression within UPDATE is compatible
-- - BEGIN TRANSACTION/COMMIT managed by ADO.NET
-- - Application code must execute statements in sequence within transaction

-- ============================================================================
-- STATEMENT ID: STMT-006
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None
-- Parameters: @MinPrice, @MaxPrice
-- ============================================================================

-- Converted PostgreSQL Statement:
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
ORDER BY rp.PriceRank

-- Conversion Notes:
-- - No changes required - SQL is PostgreSQL compatible
-- - RANK() and PERCENT_RANK() window functions are fully supported
-- - BETWEEN clause is identical
-- - CASE expression is identical

-- ============================================================================
-- STATEMENT ID: STMT-007
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None
-- Parameters: @Threshold
-- ============================================================================

-- Converted PostgreSQL Statement:
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
ORDER BY StockQuantity

-- Conversion Notes:
-- - No changes required - SQL is PostgreSQL compatible
-- - AVG/MIN/MAX OVER window functions are fully supported
-- - ROUND() function has same syntax
-- - CASE expression is identical

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Converted: 7
-- 
-- Conversion Method Breakdown:
-- - MANUAL_AFTER_DMS_FAILURE: 7 (all statements)
-- 
-- Schema Object Name Changes:
-- - None (all table names remain unchanged)
-- 
-- SQL Server to PostgreSQL Syntax Changes:
-- - GETDATE() → NOW() (3 occurrences in transactions)
-- - SCOPE_IDENTITY() → RETURNING clause (1 occurrence)
-- - BEGIN TRANSACTION/COMMIT → Managed by ADO.NET (3 transactions)
-- - DECLARE @variable → SELECT to capture values or RETURNING (3 transactions)
-- 
-- Statements Requiring No Changes (PostgreSQL Compatible):
-- - STMT-001: GetAllProductsAsync() - CTE with window functions
-- - STMT-002: GetProductByIdAsync() - CTE with LAG function
-- - STMT-006: GetProductsByPriceRangeAsync() - CTE with RANK/PERCENT_RANK
-- - STMT-007: GetLowStockProductsAsync() - CTE with aggregate window functions
-- 
-- Statements Requiring Significant Restructuring:
-- - STMT-003: InsertProductAsync() - Split into 3 statements, use RETURNING
-- - STMT-004: UpdateProductAsync() - Split into 4 statements, capture values first
-- - STMT-005: DeleteProductAsync() - Split into 4 statements, capture values first
-- 
-- Application Code Impact:
-- For transaction statements (STMT-003, STMT-004, STMT-005):
-- - Must split multi-statement transactions into separate ADO.NET commands
-- - Must use ADO.NET BeginTransaction() for transaction management
-- - Must capture intermediate values (e.g., from RETURNING, from SELECT)
-- - Must pass captured values to subsequent statements as parameters
-- - Transaction atomicity preserved through ADO.NET transaction scope
-- 
-- Next Step: Validate all statement pairs using SQL Equivalency tool
-- ============================================================================
