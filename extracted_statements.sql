-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Purpose: Comprehensive catalog of all original MS SQL Server statements
--          extracted for DMS conversion to PostgreSQL
-- Date: 2026-03-07
-- Total Statements: 7
-- Other .cs files verified: Business/ProductService.cs, CLI/CommandLineInterface.cs,
--   CLI/InteractiveMenu.cs, Models/Product.cs, Program.cs - No SQL statements found
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Method: GetAllProductsAsync()
-- Location: DataAccess/ProductRepository.cs, lines ~43-62
-- Parameters: None
-- Description: CTE with window functions (AVG OVER, COUNT OVER) selecting
--              from dbo.Products with price category analysis
-- ============================================================================
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts
    FROM dbo.Products
)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END AS PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage
FROM dbo.Products AS p
INNER JOIN ProductStats AS ps ON p.ProductId = ps.ProductId
ORDER BY
    CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END,
    p.Name;

-- ============================================================================
-- Statement 2: GetProductByIdAsync
-- Method: GetProductByIdAsync(int productId)
-- Location: DataAccess/ProductRepository.cs, lines ~73-93
-- Parameters: @ProductId (int)
-- Description: CTE with LAG window function for price/stock history
-- ============================================================================
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice,
           LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
    FROM dbo.Products
    WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
    CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END AS PriceChangePercentage
FROM dbo.Products AS p
LEFT JOIN ProductHistory AS ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ============================================================================
-- Statement 3: InsertProductAsync
-- Method: InsertProductAsync(Product product)
-- Location: DataAccess/ProductRepository.cs, lines ~108-133
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Multi-statement transaction block with SCOPE_IDENTITY(), GETDATE()
--              Inserts product, logs to history, updates stats
-- ============================================================================
BEGIN TRANSACTION;
DECLARE @NewProductId INT;
INSERT INTO dbo.Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity);
SET @NewProductId = SCOPE_IDENTITY();
INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
UPDATE dbo.ProductStats
SET TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;
COMMIT TRANSACTION;
SELECT @NewProductId;

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- Method: UpdateProductAsync(Product product)
-- Location: DataAccess/ProductRepository.cs, lines ~143-170
-- Parameters: @ProductId (int), @Name (string), @Description (string),
--             @Price (decimal), @StockQuantity (int)
-- Description: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT history
-- ============================================================================
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;
SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId;
UPDATE dbo.Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
UPDATE dbo.ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE() WHERE StatId = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- Method: DeleteProductAsync(int productId)
-- Location: DataAccess/ProductRepository.cs, lines ~181-210
-- Parameters: @ProductId (int)
-- Description: Transaction block with DECLARE, SELECT INTO vars, INSERT history,
--              DELETE product, UPDATE stats
-- ============================================================================
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;
SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId;
INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
DELETE FROM dbo.Products WHERE ProductId = @ProductId;
UPDATE dbo.ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Location: DataAccess/ProductRepository.cs, lines ~221-238
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: CTE with RANK and PERCENT_RANK window functions
-- ============================================================================
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank,
           PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM dbo.Products AS p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
         WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
         ELSE 'Premium' END AS PriceSegment
FROM RankedProducts AS rp
ORDER BY rp.PriceRank;

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync(int threshold)
-- Location: DataAccess/ProductRepository.cs, lines ~249-268
-- Parameters: @Threshold (int)
-- Description: CTE with AVG/MIN/MAX window functions for stock analysis
-- ============================================================================
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER () AS AvgStock, MIN(StockQuantity) OVER () AS MinStock,
           MAX(StockQuantity) OVER () AS MaxStock
    FROM dbo.Products AS p
)
SELECT sa.*,
    CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
         WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
         ELSE 'Adequate' END AS StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) AS StockPercentageOfAverage
FROM StockAnalysis AS sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ============================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total statements: 7
-- All statements extracted from: DataAccess/ProductRepository.cs
-- No other .cs files contain SQL statements (verified by scanning all .cs files)
-- ============================================================================
