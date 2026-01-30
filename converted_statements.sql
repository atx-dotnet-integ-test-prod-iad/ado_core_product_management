-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
-- Target: PostgreSQL Database
-- Converted from: SQL Server statements in extracted_statements.sql
-- Conversion Method: Manual conversion after DMS tool failures
-- Total Operations: 7 distinct SQL operations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Source Method: GetAllProductsAsync
-- Conversion: Manual (DMS error: Metadata model conversion timeout)
-- Parameters: None
-- Key Changes: 
--   - CTEs and window functions compatible with PostgreSQL
--   - ROUND() function compatible
--   - No schema prefix needed (will use default 'public' schema)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Source Method: GetProductByIdAsync
-- Conversion: Manual (DMS error: Metadata model conversion timeout)
-- Parameters: $1 (ProductId - INT)
-- Key Changes:
--   - @ProductId → $1 (PostgreSQL parameter syntax)
--   - LAG() function compatible with PostgreSQL
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Source Method: InsertProductAsync
-- Conversion: Manual (DMS error: Transaction syntax not supported)
-- Parameters: $1 (Name), $2 (Description), $3 (Price), $4 (StockQuantity)
-- Key Changes:
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT → PostgreSQL transaction block (handled at ADO.NET level)
--   - Multi-statement transaction split into separate commands
--   - DECLARE variables removed (use RETURNING clause instead)
-- Note: Transaction handling moved to application level with NpgsqlTransaction
-- ----------------------------------------------------------------------------
-- Statement 3a: Insert product with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
RETURNING ProductId;

-- Statement 3b: Insert history log
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP);

-- Statement 3c: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ----------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Source Method: UpdateProductAsync
-- Conversion: Manual (DMS error: Transaction syntax not supported)
-- Parameters: $1 (ProductId), $2 (Name), $3 (Description), $4 (Price), $5 (StockQuantity)
-- Key Changes:
--   - GETDATE() → CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT → handled at ADO.NET level
--   - DECLARE variables → Subquery for fetching old values
-- Note: Transaction handling moved to application level
-- ----------------------------------------------------------------------------
-- Statement 4a: Fetch old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

-- Statement 4b: Update product
UPDATE Products
SET 
    Name = $2,
    Description = $3,
    Price = $4,
    StockQuantity = $5,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = $1;

-- Statement 4c: Insert history log
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'UPDATE', $2, $3, $4, $5, CURRENT_TIMESTAMP);

-- Statement 4d: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - $1 + $2) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ----------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Source Method: DeleteProductAsync
-- Conversion: Manual (DMS error: Transaction syntax not supported)
-- Parameters: $1 (ProductId)
-- Key Changes:
--   - GETDATE() → CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT → handled at ADO.NET level
--   - DECLARE variables → Subquery for fetching old values
-- Note: Transaction handling moved to application level
-- ----------------------------------------------------------------------------
-- Statement 5a: Fetch old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

-- Statement 5b: Insert deletion log
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete product
DELETE FROM Products 
WHERE ProductId = $1;

-- Statement 5d: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - $1) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ----------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Source Method: GetProductsByPriceRangeAsync
-- Conversion: Manual (DMS error: Metadata model conversion timeout)
-- Parameters: $1 (MinPrice), $2 (MaxPrice)
-- Key Changes:
--   - @MinPrice/@MaxPrice → $1/$2
--   - RANK() and PERCENT_RANK() compatible with PostgreSQL
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Source Method: GetLowStockProductsAsync
-- Conversion: Manual (DMS error: Metadata model conversion timeout)
-- Parameters: $1 (Threshold)
-- Key Changes:
--   - @Threshold → $1
--   - Window functions (AVG, MIN, MAX) compatible with PostgreSQL
-- ----------------------------------------------------------------------------
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
-- END OF CONVERTED SQL STATEMENTS CATALOG
-- ============================================================================
