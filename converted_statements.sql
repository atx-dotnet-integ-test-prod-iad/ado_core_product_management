-- ===============================================
-- CONVERTED SQL STATEMENTS TO POSTGRESQL
-- Conversion Date: 2026-02-17
-- Updated: 2026-02-17 (Fixed transaction handling)
-- Total Statements: 7
-- DMS Tool Status: All statements failed DMS conversion
-- Conversion Method: Manual conversion after DMS failure
-- Update Notes: Statements 3, 4, 5 updated to use application-level
--               transactions instead of SQL Server BEGIN TRANSACTION blocks
-- ===============================================

-- ===============================================
-- STATEMENT 1 of 7
-- Method: GetAllProductsAsync
-- Source: ProductRepository.cs, Line ~38
-- DMS Conversion Status: FAILED
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Syntax Changes:
--   - No schema name changes (using default 'public' schema)
--   - Compatible window functions (AVG, COUNT OVER)
--   - ROUND function compatible
--   - CASE expressions compatible
-- ===============================================
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

-- ===============================================
-- STATEMENT 2 of 7
-- Method: GetProductByIdAsync
-- Source: ProductRepository.cs, Line ~71
-- DMS Conversion Status: FAILED
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Syntax Changes:
--   - No schema name changes
--   - LAG window function compatible
--   - Parameters remain as @ProductId (Npgsql will handle)
-- ===============================================
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

-- ===============================================
-- STATEMENT 3 of 7
-- Method: InsertProductAsync
-- Source: ProductRepository.cs, Line ~106
-- DMS Conversion Status: FAILED
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (Updated for application-level transactions)
-- PostgreSQL Syntax Changes:
--   - Changed SCOPE_IDENTITY() to RETURNING clause
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Replaced SQL Server multi-statement block with separate SQL commands
--   - Transaction handling moved to application level (NpgsqlTransaction)
-- ===============================================
-- ACTUAL IMPLEMENTATION: Transaction managed by application code
-- This statement is split into 3 separate commands executed within an NpgsqlTransaction:

-- Command 1: Insert and get ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Command 2: Log the insertion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 3: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Transaction commit/rollback handled by application code

-- ===============================================
-- STATEMENT 4 of 7
-- Method: UpdateProductAsync
-- Source: ProductRepository.cs, Line ~137
-- DMS Conversion Status: FAILED
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (Updated for application-level transactions)
-- PostgreSQL Syntax Changes:
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Replaced SQL Server variables with application-level variables
--   - Replaced SQL Server multi-statement block with separate SQL commands
--   - Transaction handling moved to application level (NpgsqlTransaction)
-- ===============================================
-- ACTUAL IMPLEMENTATION: Transaction managed by application code
-- This statement is split into 4 separate commands executed within an NpgsqlTransaction:

-- Command 1: Get old values for history
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Command 3: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 4: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Transaction commit/rollback handled by application code

-- ===============================================
-- STATEMENT 5 of 7
-- Method: DeleteProductAsync
-- Source: ProductRepository.cs, Line ~174
-- DMS Conversion Status: FAILED
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (Updated for application-level transactions)
-- PostgreSQL Syntax Changes:
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Replaced SQL Server variables with application-level variables
--   - Replaced SQL Server multi-statement block with separate SQL commands
--   - Transaction handling moved to application level (NpgsqlTransaction)
-- ===============================================
-- ACTUAL IMPLEMENTATION: Transaction managed by application code
-- This statement is split into 4 separate commands executed within an NpgsqlTransaction:

-- Command 1: Get product info for history
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Command 3: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Command 4: Update product statistics
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

-- Transaction commit/rollback handled by application code

-- ===============================================
-- STATEMENT 6 of 7
-- Method: GetProductsByPriceRangeAsync
-- Source: ProductRepository.cs, Line ~215
-- DMS Conversion Status: FAILED
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Syntax Changes:
--   - No schema name changes
--   - RANK() and PERCENT_RANK() window functions compatible
--   - BETWEEN operator compatible
-- ===============================================
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

-- ===============================================
-- STATEMENT 7 of 7
-- Method: GetLowStockProductsAsync
-- Source: ProductRepository.cs, Line ~247
-- DMS Conversion Status: FAILED
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Syntax Changes:
--   - No schema name changes
--   - AVG, MIN, MAX window functions compatible
--   - ROUND function compatible
-- ===============================================
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

-- ===============================================
-- END OF CONVERTED STATEMENTS
-- ===============================================
-- IMPORTANT NOTES:
-- 1. Transaction blocks (statements 3, 4, 5) using DO $$ blocks need refactoring for ADO.NET
-- 2. These should be split into separate statements executed within a transaction scope
-- 3. Variables should be handled in application code rather than SQL
-- 4. The INSERT with RETURNING (statement 3) can be used directly
-- ===============================================
