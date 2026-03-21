-- ============================================================
-- EXTRACTED MS SQL SERVER STATEMENTS
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 15
-- ============================================================

-- Statement 1: GetAllProductsAsync - CTE with window functions
-- Method: GetAllProductsAsync()
-- Location: ProductRepository.cs
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
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END, p.Name;

-- Statement 2: GetProductByIdAsync - CTE with LAG
-- Method: GetProductByIdAsync(int productId)
-- Location: ProductRepository.cs
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
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

-- Statement 3: InsertProductAsync - INSERT product with SCOPE_IDENTITY
-- Method: InsertProductAsync(Product product) - Transaction Block Statement 1
-- Location: ProductRepository.cs
INSERT INTO dbo.Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity);
SELECT SCOPE_IDENTITY();

-- Statement 4: InsertProductAsync - INSERT history
-- Method: InsertProductAsync(Product product) - Transaction Block Statement 2
-- Location: ProductRepository.cs
INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());

-- Statement 5: InsertProductAsync - UPDATE stats
-- Method: InsertProductAsync(Product product) - Transaction Block Statement 3
-- Location: ProductRepository.cs
UPDATE dbo.ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- Statement 6: UpdateProductAsync - SELECT old values
-- Method: UpdateProductAsync(Product product) - Transaction Block Statement 1
-- Location: ProductRepository.cs
SELECT Price, StockQuantity
FROM dbo.Products
WHERE ProductId = @ProductId;

-- Statement 7: UpdateProductAsync - UPDATE product
-- Method: UpdateProductAsync(Product product) - Transaction Block Statement 2
-- Location: ProductRepository.cs
UPDATE dbo.Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = GETDATE()
WHERE ProductId = @ProductId;

-- Statement 8: UpdateProductAsync - INSERT history
-- Method: UpdateProductAsync(Product product) - Transaction Block Statement 3
-- Location: ProductRepository.cs
INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

-- Statement 9: UpdateProductAsync - UPDATE stats
-- Method: UpdateProductAsync(Product product) - Transaction Block Statement 4
-- Location: ProductRepository.cs
UPDATE dbo.ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- Statement 10: DeleteProductAsync - SELECT old values
-- Method: DeleteProductAsync(int productId) - Transaction Block Statement 1
-- Location: ProductRepository.cs
SELECT Price, StockQuantity
FROM dbo.Products
WHERE ProductId = @ProductId;

-- Statement 11: DeleteProductAsync - INSERT history
-- Method: DeleteProductAsync(int productId) - Transaction Block Statement 2
-- Location: ProductRepository.cs
INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

-- Statement 12: DeleteProductAsync - DELETE product
-- Method: DeleteProductAsync(int productId) - Transaction Block Statement 3
-- Location: ProductRepository.cs
DELETE FROM dbo.Products 
WHERE ProductId = @ProductId;

-- Statement 13: DeleteProductAsync - UPDATE stats
-- Method: DeleteProductAsync(int productId) - Transaction Block Statement 4
-- Location: ProductRepository.cs
UPDATE dbo.ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- Statement 14: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Location: ProductRepository.cs
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) AS PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM dbo.Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank;

-- Statement 15: GetLowStockProductsAsync - CTE with window aggregates
-- Method: GetLowStockProductsAsync(int threshold)
-- Location: ProductRepository.cs
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() AS AvgStock,
        MIN(StockQuantity) OVER() AS MinStock,
        MAX(StockQuantity) OVER() AS MaxStock
    FROM dbo.Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS StockStatus,
    ROUND(CAST(StockQuantity AS NUMERIC(18, 0)) / AvgStock * 100, 2) AS StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;
