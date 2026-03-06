-- ============================================================================
-- Extracted SQL Statements - Original MS SQL Server Versions
-- Source: ProductRepository.cs
-- Purpose: Catalog of all SQL statements for DMS conversion
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Method: GetAllProductsAsync()
-- Type: CTE with window functions (AVG, COUNT OVER)
-- Location: ProductRepository.cs, GetAllProductsAsync method
-- ============================================================================
-- Original MS SQL Server version:
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
    CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name;
GO

-- ============================================================================
-- Statement 2: GetProductByIdAsync
-- Method: GetProductByIdAsync(int productId)
-- Type: CTE with LAG window function
-- Location: ProductRepository.cs, GetProductByIdAsync method
-- ============================================================================
-- Original MS SQL Server version:
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice,
           LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
    FROM dbo.Products
    WHERE ProductId = @ProductId
)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
    CASE
        WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END AS PriceChangePercentage
FROM dbo.Products AS p
LEFT OUTER JOIN ProductHistory AS ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;
GO

-- ============================================================================
-- Statement 3: InsertProductAsync
-- Method: InsertProductAsync(Product product)
-- Type: BEGIN/END block with SCOPE_IDENTITY(), multi-table INSERT/UPDATE
-- Location: ProductRepository.cs, InsertProductAsync method
-- ============================================================================
-- Original MS SQL Server version:
DECLARE @NewProductId INT;
BEGIN
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
END;
GO

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- Method: UpdateProductAsync(Product product)
-- Type: BEGIN/END block with SELECT INTO, UPDATE, INSERT
-- Location: ProductRepository.cs, UpdateProductAsync method
-- ============================================================================
-- Original MS SQL Server version:
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;
BEGIN
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM dbo.Products
    WHERE ProductId = @ProductId;

    UPDATE dbo.Products
    SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;

    INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

    UPDATE dbo.ProductStats
    SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE()
    WHERE StatId = 1;
END;
GO

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- Method: DeleteProductAsync(int productId)
-- Type: BEGIN/END block with SELECT INTO, INSERT, DELETE, UPDATE with CASE
-- Location: ProductRepository.cs, DeleteProductAsync method
-- ============================================================================
-- Original MS SQL Server version:
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;
BEGIN
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM dbo.Products
    WHERE ProductId = @ProductId;

    INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

    DELETE FROM dbo.Products
    WHERE ProductId = @ProductId;

    UPDATE dbo.ProductStats
    SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE
            WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
END;
GO

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Type: CTE with RANK, PERCENT_RANK
-- Location: ProductRepository.cs, GetProductsByPriceRangeAsync method
-- ============================================================================
-- Original MS SQL Server version:
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank,
           PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM dbo.Products AS p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceSegment
FROM RankedProducts AS rp
ORDER BY rp.PriceRank;
GO

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync(int threshold)
-- Type: CTE with AVG, MIN, MAX window functions
-- Location: ProductRepository.cs, GetLowStockProductsAsync method
-- ============================================================================
-- Original MS SQL Server version:
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER () AS AvgStock,
           MIN(StockQuantity) OVER () AS MinStock,
           MAX(StockQuantity) OVER () AS MaxStock
    FROM dbo.Products AS p
)
SELECT sa.*,
    CASE
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS StockStatus,
    ROUND((CAST(StockQuantity AS DECIMAL(18, 0)) / AvgStock) * 100, 2) AS StockPercentageOfAverage
FROM StockAnalysis AS sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;
GO
