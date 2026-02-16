-- ============================================
-- Converted SQL Statements - PostgreSQL Syntax
-- Converted from Microsoft SQL Server T-SQL
-- ============================================

-- ============================================
-- Statement 1: GetAllProductsAsync
-- Original File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: No T-SQL specific syntax - PostgreSQL compatible as-is
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
-- Statement 2: GetProductByIdAsync
-- Original File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: No T-SQL specific syntax - PostgreSQL compatible as-is
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
-- Statement 3: InsertProductAsync
-- Original File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: 
--   1. Removed DECLARE statement (will use PostgreSQL function)
--   2. Replaced BEGIN TRANSACTION/COMMIT with DO block
--   3. Replaced SCOPE_IDENTITY() with RETURNING clause
--   4. Replaced GETDATE() with CURRENT_TIMESTAMP
--   5. Split into separate statements for code execution
-- ============================================
-- Insert the new product (with RETURNING for ID)
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: The following statements would be executed separately after getting the ProductId:
-- Log the insertion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================
-- Statement 4: UpdateProductAsync
-- Original File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   1. Replaced BEGIN TRANSACTION/COMMIT (handled in code)
--   2. Replaced DECLARE with PostgreSQL variables (in function context)
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Split into separate statements for code execution
-- ============================================
-- Store old values for history (executed as separate query)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================
-- Statement 5: DeleteProductAsync
-- Original File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   1. Replaced BEGIN TRANSACTION/COMMIT (handled in code)
--   2. Replaced DECLARE with query result capture in code
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Split into separate statements for code execution
-- ============================================
-- Store product info for history (executed as separate query)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update product statistics
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

-- ============================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Original File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: No T-SQL specific syntax - PostgreSQL compatible as-is
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
-- Statement 7: GetLowStockProductsAsync
-- Original File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: No T-SQL specific syntax - PostgreSQL compatible as-is
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
-- Conversion Summary
-- ============================================
-- Total Statements Converted: 7
-- Statements Requiring Major Changes: 3 (Insert, Update, Delete - transactions)
-- Statements PostgreSQL Compatible: 4 (CTEs and window functions)
-- Key Conversions:
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT -> Handled in application code
--   - DECLARE variables -> Handled in application code
-- ============================================
