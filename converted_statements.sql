-- ==================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Date: 2026-02-01
-- Purpose: PostgreSQL converted versions of all SQL statements
-- Conversion Method: Manual conversion after DMS tool failures
-- Total Statements: 7
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync (MANUALLY CONVERTED AFTER DMS FAILURE)
-- Original: SQL Server CTE with window functions
-- Converted: PostgreSQL compatible syntax
-- Changes: Minimal - PostgreSQL supports CTE, window functions, CASE, and ROUND
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync (MANUALLY CONVERTED AFTER DMS FAILURE)
-- Original: SQL Server CTE with LAG window functions
-- Converted: PostgreSQL compatible syntax with parameter change
-- Changes: @ProductId → $1
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync (MANUALLY CONVERTED AFTER DMS FAILURE)
-- Original: SQL Server transaction with SCOPE_IDENTITY() and GETDATE()
-- Converted: PostgreSQL transaction with RETURNING clause and CURRENT_TIMESTAMP
-- Changes: 
--   - Removed DECLARE and variable handling (will use RETURNING clause)
--   - SCOPE_IDENTITY() → RETURNING ProductId
--   - GETDATE() → CURRENT_TIMESTAMP
--   - @Name → $1, @Description → $2, @Price → $3, @StockQuantity → $4
--   - Combined into CTE for atomic execution
-- Note: This requires restructuring in C# code to handle RETURNING clause
-- ==================================================================================

WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES ($1, $2, $3, $4)
    RETURNING ProductId, Price, StockQuantity
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, Price, NULL, StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING ProductId
),
stats_update AS (
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + (SELECT Price FROM inserted_product)) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING StatId
)
SELECT ProductId FROM inserted_product;

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync (MANUALLY CONVERTED AFTER DMS FAILURE)
-- Original: SQL Server transaction with variables and GETDATE()
-- Converted: PostgreSQL transaction with CTE and CURRENT_TIMESTAMP
-- Changes:
--   - Replaced variable declarations with CTE approach
--   - GETDATE() → CURRENT_TIMESTAMP
--   - @ProductId → $1, @Name → $2, @Description → $3, @Price → $4, @StockQuantity → $5
-- ==================================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = $1
),
product_update AS (
    UPDATE Products
    SET 
        Name = $2,
        Description = $3,
        Price = $4,
        StockQuantity = $5,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = $1
    RETURNING ProductId, Price, StockQuantity
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT $1, 'UPDATE', ov.OldPrice, pu.Price, ov.OldStock, pu.StockQuantity, CURRENT_TIMESTAMP
    FROM product_update pu, old_values ov
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + $4) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync (MANUALLY CONVERTED AFTER DMS FAILURE)
-- Original: SQL Server transaction with variables and GETDATE()
-- Converted: PostgreSQL transaction with CTE and CURRENT_TIMESTAMP
-- Changes:
--   - Replaced variable declarations with CTE approach
--   - GETDATE() → CURRENT_TIMESTAMP
--   - @ProductId → $1
-- ==================================================================================

WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = $1
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT $1, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values
    RETURNING ProductId
),
product_delete AS (
    DELETE FROM Products 
    WHERE ProductId = $1
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

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (MANUALLY CONVERTED AFTER DMS FAILURE)
-- Original: SQL Server CTE with RANK() and PERCENT_RANK() window functions
-- Converted: PostgreSQL compatible syntax with parameter changes
-- Changes: @MinPrice → $1, @MaxPrice → $2
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (MANUALLY CONVERTED AFTER DMS FAILURE)
-- Original: SQL Server CTE with window functions
-- Converted: PostgreSQL compatible syntax with parameter change
-- Changes: @Threshold → $1
-- ==================================================================================

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

-- ==================================================================================
-- END OF CONVERTED STATEMENTS
-- ==================================================================================
