-- ============================================
-- POSTGRESQL CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- All statements attempted through DMS MCP tool first
-- DMS Error: Metadata model creation failed
-- ============================================

-- ============================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Source Location: ProductRepository.cs, Method: GetAllProductsAsync
-- Statement Type: SELECT with CTE and Window Functions
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: No major syntax changes needed - PostgreSQL supports CTEs and window functions similarly
-- ============================================

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

-- ============================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Source Location: ProductRepository.cs, Method: GetProductByIdAsync
-- Statement Type: SELECT with CTE, LAG Window Function
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: Parameter syntax changed from @ProductId to $1 (will use named parameters in C# code)
-- ============================================

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

-- ============================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Source Location: ProductRepository.cs, Method: InsertProductAsync
-- Statement Type: TRANSACTION with INSERT statements
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes:
--   1. Removed DECLARE @NewProductId INT (not needed in PostgreSQL with RETURNING)
--   2. Removed BEGIN TRANSACTION/COMMIT (transactions handled at connection level in ADO.NET)
--   3. Changed SCOPE_IDENTITY() to RETURNING ProductId clause
--   4. Changed GETDATE() to NOW() or CURRENT_TIMESTAMP
--   5. Changed SET @NewProductId = SCOPE_IDENTITY() to use RETURNING clause
--   6. Combined INSERT with RETURNING to get new ID
-- Note: Transaction management will be handled by C# code using NpgsqlTransaction
-- ============================================

-- This statement will be split into multiple statements in C# code with proper transaction handling
-- Statement 3a: Insert product and get new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log the insertion (to be executed after getting ProductId from 3a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Source Location: ProductRepository.cs, Method: UpdateProductAsync
-- Statement Type: TRANSACTION with UPDATE and INSERT statements
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes:
--   1. Removed BEGIN TRANSACTION/COMMIT (handled at connection level)
--   2. Removed DECLARE statements (will use DO block or handle in code)
--   3. Changed GETDATE() to NOW()
-- Note: Variables will be handled in C# code by fetching old values first
-- ============================================

-- Statement 4a: Get old values (to be executed first in C# code)
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

-- Statement 4c: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Source Location: ProductRepository.cs, Method: DeleteProductAsync
-- Statement Type: TRANSACTION with DELETE and UPDATE statements
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes:
--   1. Removed BEGIN TRANSACTION/COMMIT (handled at connection level)
--   2. Removed DECLARE statements (will handle in code)
--   3. Changed GETDATE() to NOW()
-- Note: Variables will be handled in C# code by fetching values first
-- ============================================

-- Statement 5a: Get product info for history (to be executed first in C# code)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update product statistics
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

-- ============================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Source Location: ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Statement Type: SELECT with CTE and Window Functions (RANK, PERCENT_RANK)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: No major syntax changes needed - PostgreSQL supports RANK and PERCENT_RANK
-- ============================================

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

-- ============================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Source Location: ProductRepository.cs, Method: GetLowStockProductsAsync
-- Statement Type: SELECT with CTE and Window Functions (AVG, MIN, MAX OVER)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Key Changes: No major syntax changes needed - PostgreSQL supports window aggregates
-- ============================================

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

-- ============================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total SQL Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered metadata model creation errors)
-- ============================================
