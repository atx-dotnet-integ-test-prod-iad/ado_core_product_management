-- =====================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: ProductRepository.cs (7 statements)
-- Format: Original MS SQL Server statements (pre-migration)
-- =====================================================

-- =====================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Description: CTE with window functions (AVG, COUNT OVER), CASE expressions, INNER JOIN, ORDER BY
-- =====================================================
-- ORIGINAL MS SQL SERVER:
WITH ProductStats AS (
    SELECT
        ProductId,
        AVG(Price) OVER () AS AvgPrice,
        COUNT(*) OVER () AS TotalProducts
    FROM [dbo].[Products]
)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END AS PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage
FROM [dbo].[Products] AS p
INNER JOIN ProductStats AS ps ON p.ProductId = ps.ProductId
ORDER BY
    CASE
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END, p.Name;

-- =====================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Description: CTE with LAG window function, LEFT OUTER JOIN, parameterized (@ProductId)
-- =====================================================
-- ORIGINAL MS SQL SERVER:
WITH ProductHistory AS (
    SELECT
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId
)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
    CASE
        WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice), 2)
        ELSE NULL
    END AS PriceChangePercentage
FROM [dbo].[Products] AS p
LEFT OUTER JOIN ProductHistory AS ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- =====================================================
-- STATEMENT 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Description: Transaction block with INSERT, history logging, stats update, SCOPE_IDENTITY
-- =====================================================
-- ORIGINAL MS SQL SERVER:
BEGIN
    DECLARE @NewProductId INT;

    INSERT INTO [dbo].[Products] (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);

    SET @NewProductId = SCOPE_IDENTITY();

    INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());

    UPDATE [dbo].[ProductStats]
    SET TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;

    SELECT @NewProductId;
END;

-- =====================================================
-- STATEMENT 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Description: Transaction block with DECLARE, SELECT INTO, UPDATE, INSERT history, UPDATE stats
-- =====================================================
-- ORIGINAL MS SQL SERVER:
BEGIN
    DECLARE @OldPrice DECIMAL(18, 2);
    DECLARE @OldStock INT;

    /* Store old values for history */
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId;

    /* Update the product */
    UPDATE [dbo].[Products]
    SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;

    /* Log the changes */
    INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

    /* Update product statistics */
    UPDATE [dbo].[ProductStats]
    SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE()
    WHERE StatId = 1;
END;

-- =====================================================
-- STATEMENT 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Description: Transaction block with DECLARE, SELECT INTO, INSERT history, DELETE, UPDATE stats
-- =====================================================
-- ORIGINAL MS SQL SERVER:
BEGIN
    DECLARE @OldPrice DECIMAL(18, 2);
    DECLARE @OldStock INT;

    /* Store product info for history */
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId;

    /* Log the deletion */
    INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

    /* Delete the product */
    DELETE FROM [dbo].[Products]
    WHERE ProductId = @ProductId;

    /* Update product statistics */
    UPDATE [dbo].[ProductStats]
    SET TotalProducts = TotalProducts - 1, AveragePrice =
    CASE
        WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END, LastUpdated = GETDATE()
    WHERE StatId = 1;
END;

-- =====================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Description: CTE with RANK and PERCENT_RANK window functions, BETWEEN, CASE, parameterized
-- =====================================================
-- ORIGINAL MS SQL SERVER:
WITH RankedProducts AS (
    SELECT
        p.*,
        RANK() OVER (ORDER BY p.Price) AS PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM [dbo].[Products] AS p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT
    rp.*,
    CASE
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceSegment
FROM RankedProducts AS rp
ORDER BY rp.PriceRank;

-- =====================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Description: CTE with AVG/MIN/MAX window functions, CASE, parameterized
-- =====================================================
-- ORIGINAL MS SQL SERVER:
WITH StockAnalysis AS (
    SELECT
        p.*,
        AVG(StockQuantity) OVER () AS AvgStock,
        MIN(StockQuantity) OVER () AS MinStock,
        MAX(StockQuantity) OVER () AS MaxStock
    FROM [dbo].[Products] AS p
)
SELECT
    sa.*,
    CASE
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) AS StockPercentageOfAverage
FROM StockAnalysis AS sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;
