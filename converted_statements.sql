-- ============================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL VERSION
-- Source: SQL Server T-SQL to PostgreSQL Migration
-- Date: 2026-01-28
-- Conversion Method: Manual (after DMS tool timeout errors)
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion: Manual (DMS timeout)
-- Changes: None required - PostgreSQL supports CTEs, window functions, CASE, ROUND
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
-- STATEMENT 2: GetProductByIdAsync
-- Conversion: Manual (DMS timeout)
-- Changes: None required - PostgreSQL supports LAG, CTEs, CASE, ROUND
-- ============================================================
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

-- ============================================================
-- STATEMENT 3: InsertProductAsync
-- Conversion: Manual (DMS timeout)
-- Changes: 
--   1. Removed DECLARE @NewProductId - use PostgreSQL DO block or RETURNING clause
--   2. Replaced BEGIN TRANSACTION/COMMIT with PostgreSQL syntax (handled by ADO.NET)
--   3. Replaced SCOPE_IDENTITY() with RETURNING clause
--   4. Replaced GETDATE() with CURRENT_TIMESTAMP
-- ============================================================
-- Note: Transaction boundaries handled by NpgsqlTransaction in ADO.NET
-- Using CTE approach for multiple statements with RETURNING

WITH new_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
product_history AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM new_product
    RETURNING ProductId
),
stats_update AS (
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING StatId
)
SELECT ProductId FROM new_product;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion: Manual (DMS timeout)
-- Changes:
--   1. Removed DECLARE statements - use CTEs
--   2. Replaced BEGIN TRANSACTION/COMMIT (handled by ADO.NET)
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Use CTEs to chain operations
-- ============================================================
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
    RETURNING HistoryId
)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion: Manual (DMS timeout)
-- Changes:
--   1. Removed DECLARE statements - use CTEs
--   2. Replaced BEGIN TRANSACTION/COMMIT (handled by ADO.NET)
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Use CTEs to chain operations
-- ============================================================
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values
    RETURNING HistoryId
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

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion: Manual (DMS timeout)
-- Changes: None required - PostgreSQL supports RANK, PERCENT_RANK, CTEs
-- ============================================================
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

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion: Manual (DMS timeout)
-- Changes: None required - PostgreSQL supports window functions (AVG, MIN, MAX), CTEs
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
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ============================================================
-- CONVERSION SUMMARY
-- ============================================================
-- Total SQL Statements Converted: 7
-- DMS Tool Successful Conversions: 0 (all timed out)
-- Manual Conversions: 7
-- 
-- Key PostgreSQL Changes Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. DECLARE variables → CTEs with RETURNING
-- 4. BEGIN TRANSACTION/COMMIT → Handled by NpgsqlTransaction in ADO.NET
-- 5. Parameter syntax (@param) remains same (Npgsql supports it)
-- 
-- No schema object name changes were made by conversion
-- ============================================================
