-- ========================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL
-- Source: Microsoft SQL Server (ADO.NET Application)
-- Target: PostgreSQL
-- Conversion Date: 2026-02-08
-- Conversion Method: Manual (DMS Tool Failure - Metadata model creation error)
-- ========================================

-- ========================================
-- STATEMENT 1: GetAllProductsAsync
-- Original Method: GetAllProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: CTE and window functions are supported
-- Changes Made:
--   - No schema name changes (Products remains Products)
--   - Window functions (AVG OVER, COUNT OVER) are PostgreSQL compatible
--   - ROUND() syntax is PostgreSQL compatible
--   - CASE expressions are PostgreSQL compatible
-- ========================================
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

-- ========================================
-- STATEMENT 2: GetProductByIdAsync
-- Original Method: GetProductByIdAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: LAG window function is supported
-- Changes Made:
--   - No schema name changes (Products remains Products)
--   - LAG() OVER is PostgreSQL compatible
--   - Parameter @ProductId is PostgreSQL compatible (Npgsql supports @ syntax)
-- ========================================
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

-- ========================================
-- STATEMENT 3: InsertProductAsync
-- Original Method: InsertProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: Transaction and RETURNING supported
-- Changes Made:
--   - Removed DECLARE statement (not needed with RETURNING clause)
--   - Replaced SCOPE_IDENTITY() with RETURNING clause
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION simplified (PostgreSQL handles implicitly in code)
--   - Removed SET variable assignment
--   - Modified to use RETURNING ProductId for the first INSERT
-- Note: This will need code-level transaction handling in C#
-- ========================================
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- The following statements should be executed in the same transaction:

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ========================================
-- STATEMENT 4: UpdateProductAsync
-- Original Method: UpdateProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: WITH for data modification queries
-- Changes Made:
--   - Replaced DECLARE/SET with CTE pattern
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Transaction handling moved to code level
--   - Using WITH clause to capture old values
-- ========================================
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
WHERE ProductId = @ProductId;

-- The following should be executed in the same transaction after capturing OldPrice and OldStock:

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ========================================
-- STATEMENT 5: DeleteProductAsync
-- Original Method: DeleteProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: CTE for capturing values before delete
-- Changes Made:
--   - Replaced DECLARE/SET with CTE or code-level variable capture
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Transaction handling moved to code level
-- ========================================
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT OldPrice, OldStock FROM OldValues;

-- After capturing old values, execute these in transaction:

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

DELETE FROM Products 
WHERE ProductId = @ProductId;

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

-- ========================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Original Method: GetProductsByPriceRangeAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: RANK and PERCENT_RANK are supported
-- Changes Made:
--   - No changes needed - fully PostgreSQL compatible
--   - RANK() OVER and PERCENT_RANK() OVER are standard SQL
-- ========================================
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

-- ========================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Original Method: GetLowStockProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Compatibility: Aggregate window functions are supported
-- Changes Made:
--   - No changes needed - fully PostgreSQL compatible
--   - AVG, MIN, MAX with OVER clause are standard SQL
-- ========================================
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

-- ========================================
-- CONVERSION SUMMARY
-- ========================================
-- Total SQL Statements Converted: 7
-- DMS Tool Status: FAILED (Metadata model creation error)
-- Manual Conversions: 7
-- Key PostgreSQL Transformations:
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - DECLARE/SET variables -> CTE or code-level handling
--   - Transaction blocks -> Code-level transaction handling
-- PostgreSQL Native Features Used:
--   - RETURNING clause for INSERT operations
--   - WITH clauses for data capture
--   - Window functions (fully compatible)
-- ========================================
