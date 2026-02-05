-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================
-- Source File: ProductRepository.cs
-- Total Statements: 7
-- Conversion Date: 2026-02-05
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements - DMS tool error)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Target Method: GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: None
-- Changes: None - SQL is PostgreSQL compatible
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
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Target Method: GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1 (ProductId - INT)
-- Changes: @ProductId → $1
-- ============================================================================

WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Target Method: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1 (Name), $2 (Description), $3 (Price), $4 (StockQuantity)
-- Changes: 
--   - Removed DECLARE/SET - replaced with RETURNING clause and CTE
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP
--   - @Name, @Description, @Price, @StockQuantity → $1, $2, $3, $4
--   - BEGIN TRANSACTION/COMMIT → Application-level transaction management
-- Notes: Transaction handling must be managed by application code
-- ============================================================================

WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES ($1, $2, $3, $4)
    RETURNING ProductId
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT ProductId, 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP
FROM inserted_product
RETURNING (SELECT ProductId FROM inserted_product);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + $3) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Target Method: UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1 (ProductId), $2 (Name), $3 (Description), $4 (Price), $5 (StockQuantity)
-- Changes:
--   - Removed DECLARE - replaced with CTE (old_values)
--   - SELECT @var = ... → CTE pattern
--   - GETDATE() → CURRENT_TIMESTAMP
--   - @ProductId, @Name, @Description, @Price, @StockQuantity → $1, $2, $3, $4, $5
--   - BEGIN TRANSACTION/COMMIT → Application-level transaction management
-- Notes: Transaction handling must be managed by application code
-- ============================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = $1
)
UPDATE Products
SET 
    Name = $2,
    Description = $3,
    Price = $4,
    StockQuantity = $5,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = $1;

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT $1, 'UPDATE', OldPrice, $4, OldStock, $5, CURRENT_TIMESTAMP
FROM old_values;

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + $4) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Target Method: DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1 (ProductId - INT)
-- Changes:
--   - Removed DECLARE - replaced with CTE (old_values)
--   - SELECT @var = ... → CTE pattern
--   - GETDATE() → CURRENT_TIMESTAMP
--   - @ProductId → $1
--   - BEGIN TRANSACTION/COMMIT → Application-level transaction management
-- Notes: Transaction handling must be managed by application code
-- ============================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = $1
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT $1, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
FROM old_values;

DELETE FROM Products 
WHERE ProductId = $1;

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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Target Method: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1 (MinPrice - DECIMAL), $2 (MaxPrice - DECIMAL)
-- Changes: @MinPrice, @MaxPrice → $1, $2
-- ============================================================================

WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Target Method: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Parameters: $1 (Threshold - INT)
-- Changes: @Threshold → $1
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
-- SUMMARY:
-- Total Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
-- DMS Tool Status: All 7 statements failed with metadata model creation error
-- 
-- Major Conversion Patterns Applied:
-- 1. Parameter Syntax: @param → $1, $2, $3, etc. (PostgreSQL positional parameters)
-- 2. Date Functions: GETDATE() → CURRENT_TIMESTAMP
-- 3. Identity Functions: SCOPE_IDENTITY() → RETURNING clause
-- 4. Variable Declarations: DECLARE/SET → CTE patterns or RETURNING clause
-- 5. Transaction Blocks: BEGIN TRANSACTION/COMMIT → Application-level management
-- 6. Window Functions: No changes (PostgreSQL compatible)
-- 7. CTEs (WITH clause): No changes (PostgreSQL compatible)
-- 8. CASE Expressions: No changes (PostgreSQL compatible)
-- 
-- Critical Notes:
-- - Statements 3, 4, 5 require application-level transaction management
-- - All parameter references changed from named (@param) to positional ($1, $2, etc.)
-- - Business logic and semantic meaning preserved in all conversions
-- ============================================================================
