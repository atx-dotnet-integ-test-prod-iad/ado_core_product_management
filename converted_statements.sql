-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: ProductRepository.cs (converted from MS SQL Server)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed - Unknown status: RECEIVED
-- ============================================================

-- ==============================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with AVG/COUNT OVER, CASE, ROUND, ORDER BY CASE
-- Conversion Notes: Query is PostgreSQL-compatible as-is.
--   CTE, window functions, CASE, ROUND all work in PostgreSQL.
-- ==============================================================

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

-- ==============================================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with LAG window function, CASE, ROUND
-- Conversion Notes: Query is PostgreSQL-compatible as-is.
--   LAG window function, CASE, ROUND all work in PostgreSQL.
-- ==============================================================

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

-- ==============================================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Original: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(),
--           INSERT history, UPDATE stats, GETDATE(), SELECT var
-- Conversion Notes:
--   - SCOPE_IDENTITY() replaced with INSERT...RETURNING via CTE
--   - GETDATE() replaced with NOW()
--   - DECLARE @var removed, using CTE chain instead
--   - BEGIN TRANSACTION/COMMIT removed (handled by application)
-- ==============================================================

WITH new_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
hist AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT np.ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product np
    RETURNING ProductId
),
stats AS (
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1
    RETURNING StatId
)
SELECT ProductId FROM new_product;

-- ==============================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Original: BEGIN TRANSACTION, DECLARE @OldPrice/@OldStock,
--           SELECT INTO vars, UPDATE, INSERT history, UPDATE stats, GETDATE()
-- Conversion Notes:
--   - DECLARE removed, using CTE with old_values subquery
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION/COMMIT removed (handled by application)
-- ==============================================================

WITH old_values AS (
    SELECT Price AS OldPrice, StockQuantity AS OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
do_update AS (
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = NOW()
    WHERE ProductId = @ProductId
    RETURNING ProductId
),
do_history AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, NOW()
    FROM old_values ov
    RETURNING HistoryId
)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ==============================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Original: BEGIN TRANSACTION, DECLARE @OldPrice/@OldStock,
--           SELECT INTO vars, INSERT history, DELETE, UPDATE stats with CASE, GETDATE()
-- Conversion Notes:
--   - DECLARE removed, using CTE with old_values subquery
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION/COMMIT removed (handled by application)
-- ==============================================================

WITH old_values AS (
    SELECT Price AS OldPrice, StockQuantity AS OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
do_history AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, NOW()
    FROM old_values ov
    RETURNING HistoryId
),
do_delete AS (
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
    LastUpdated = NOW()
WHERE StatId = 1;

-- ==============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK(), PERCENT_RANK() window functions, CASE
-- Conversion Notes: Query is PostgreSQL-compatible as-is.
--   RANK(), PERCENT_RANK(), CTE, CASE, BETWEEN all work in PostgreSQL.
-- ==============================================================

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

-- ==============================================================
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX OVER, CASE, ROUND
-- Conversion Notes: Added CAST for integer division in ROUND.
--   In PostgreSQL, integer/decimal division needs explicit cast
--   for ROUND to work correctly.
-- ==============================================================

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
    ROUND((CAST(StockQuantity AS decimal) / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ==============================================================
-- END OF CONVERTED STATEMENTS
-- Total: 7 SQL statements converted
-- Conversion method: MANUAL_AFTER_DMS_FAILURE (all 7)
-- DMS tool error: Metadata model creation failed
-- ==============================================================
