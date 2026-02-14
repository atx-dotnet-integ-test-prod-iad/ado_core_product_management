-- ====================================================================
-- CONVERTED SQL STATEMENTS FROM MS SQL SERVER TO POSTGRESQL
-- Source Repository: AdoCore
-- Conversion Date: 2026-02-14
-- Total Statements: 7
-- Conversion Method: Manual after DMS tool metadata model creation failure
-- ====================================================================

-- ====================================================================
-- STATEMENT 1 OF 7 (CONVERTED)
-- ====================================================================
-- Original Source: GetAllProductsAsync() method
-- Conversion Notes: 
--   - CTE syntax is compatible
--   - Window functions (AVG OVER, COUNT OVER) are compatible
--   - CASE expressions are compatible
--   - ROUND() function is compatible
--   - No schema name changes detected
-- Changes Made: None required - PostgreSQL-compatible syntax
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 2 OF 7 (CONVERTED)
-- ====================================================================
-- Original Source: GetProductByIdAsync(int productId) method
-- Conversion Notes:
--   - CTE syntax is compatible
--   - LAG() window function is compatible
--   - Parameter syntax: @ProductId remains as-is (Npgsql handles @ parameters)
--   - CASE expressions are compatible
--   - ROUND() function is compatible
-- Changes Made: None required - PostgreSQL-compatible syntax
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 3 OF 7 (CONVERTED)
-- ====================================================================
-- Original Source: InsertProductAsync(Product product) method
-- Conversion Notes:
--   - DECLARE removed (PostgreSQL uses DO blocks or functions for variables in SQL)
--   - BEGIN TRANSACTION removed (will be handled by C# code with NpgsqlTransaction)
--   - SCOPE_IDENTITY() replaced with RETURNING ProductId
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Multi-statement converted to single INSERT with RETURNING
--   - History and stats updates need to be separate statements in C# code
-- Changes Made:
--   1. Converted to INSERT...RETURNING for getting new ID
--   2. GETDATE() → CURRENT_TIMESTAMP
--   3. Transaction management moved to application layer
-- IMPORTANT: This requires code restructuring to handle as multiple commands
-- ====================================================================

-- Insert statement (returns new ProductId)
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- History logging (separate command)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statistics update (separate command)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ====================================================================
-- STATEMENT 4 OF 7 (CONVERTED)
-- ====================================================================
-- Original Source: UpdateProductAsync(Product product) method
-- Conversion Notes:
--   - BEGIN TRANSACTION removed (handled by NpgsqlTransaction)
--   - DECLARE removed (use separate SELECT to get old values)
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Variable assignment from SELECT converted to separate queries
-- Changes Made:
--   1. GETDATE() → CURRENT_TIMESTAMP
--   2. Transaction management moved to application layer
--   3. Separate queries for old value retrieval
-- IMPORTANT: Requires code restructuring for transaction management
-- ====================================================================

-- Get old values (separate query)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Log changes (separate command)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update statistics (separate command)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ====================================================================
-- STATEMENT 5 OF 7 (CONVERTED)
-- ====================================================================
-- Original Source: DeleteProductAsync(int productId) method
-- Conversion Notes:
--   - BEGIN TRANSACTION removed (handled by NpgsqlTransaction)
--   - DECLARE removed (use separate SELECT)
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - CASE expression is compatible
-- Changes Made:
--   1. GETDATE() → CURRENT_TIMESTAMP
--   2. Transaction management moved to application layer
--   3. Separate queries for old value retrieval
-- IMPORTANT: Requires code restructuring for transaction management
-- ====================================================================

-- Get old values (separate query)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Log deletion (separate command)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update statistics (separate command)
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

-- ====================================================================
-- STATEMENT 6 OF 7 (CONVERTED)
-- ====================================================================
-- Original Source: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice) method
-- Conversion Notes:
--   - CTE syntax is compatible
--   - RANK() and PERCENT_RANK() window functions are compatible
--   - BETWEEN operator is compatible
--   - CASE expressions are compatible
-- Changes Made: None required - PostgreSQL-compatible syntax
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 7 OF 7 (CONVERTED)
-- ====================================================================
-- Original Source: GetLowStockProductsAsync(int threshold) method
-- Conversion Notes:
--   - CTE syntax is compatible
--   - Window functions (AVG OVER, MIN OVER, MAX OVER) are compatible
--   - CASE expressions are compatible
--   - ROUND() function is compatible
-- Changes Made: None required - PostgreSQL-compatible syntax
-- ====================================================================

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

-- ====================================================================
-- END OF CONVERTED STATEMENTS
-- ====================================================================
-- Summary:
-- - Statements 1, 2, 6, 7: Direct PostgreSQL compatibility (no changes needed)
-- - Statements 3, 4, 5: Require code restructuring for transaction management
--   and conversion of T-SQL specific features (SCOPE_IDENTITY, GETDATE, DECLARE)
-- - No schema object name changes detected
-- - Parameter syntax (@param) is compatible with Npgsql
-- ====================================================================
