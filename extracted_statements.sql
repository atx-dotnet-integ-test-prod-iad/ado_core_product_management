-- ============================================================================
-- Extracted SQL Statements Catalog
-- Source File: DataAccess/ProductRepository.cs
-- Total Statements: 9
-- Purpose: Complete inventory of original MS SQL Server statements for DMS processing
-- DMS Attempt Round 3 Timestamps: 2026-03-21T08:07:17 through 2026-03-21T08:45:22 (all 9 failed)
-- DMS Attempt Round 4 Timestamps: 2026-03-21T09:12:57 through 2026-03-21T09:53:00 (all 9 failed - metadata model conversion/creation errors and timeouts)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with AVG/COUNT window functions
-- Location: ProductRepository.cs, GetAllProductsAsync() method
-- ============================================================================

-- ORIGINAL MS SQL SERVER VERSION:
WITH ProductStats
AS (SELECT
    ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts
    FROM [dbo].[Products])
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END AS PriceCategory, ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage
    FROM [dbo].[Products] AS p
    INNER JOIN ProductStats AS ps
        ON p.ProductId = ps.ProductId
    ORDER BY
    CASE
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END, p.Name;
GO

-- CURRENT POSTGRESQL VERSION (in code):
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG window function and LEFT JOIN
-- Location: ProductRepository.cs, GetProductByIdAsync() method
-- ============================================================================

-- ORIGINAL MS SQL SERVER VERSION:
WITH ProductHistory
AS (SELECT
    ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE
        WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END AS PriceChangePercentage
    FROM [dbo].[Products] AS p
    LEFT JOIN ProductHistory AS ph
        ON p.ProductId = ph.ProductId
    WHERE p.ProductId = @ProductId;
GO

-- CURRENT POSTGRESQL VERSION (in code):
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (insertSql) - INSERT with SCOPE_IDENTITY()
-- Location: ProductRepository.cs, InsertProductAsync() method, insertSql variable
-- ============================================================================

-- ORIGINAL MS SQL SERVER VERSION:
INSERT INTO [dbo].[Products] (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity);
SELECT SCOPE_IDENTITY() AS ProductId;
GO

-- CURRENT POSTGRESQL VERSION (in code):
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================================
-- STATEMENT 4: InsertProductAsync (historySql) - INSERT into ProductHistory
-- Location: ProductRepository.cs, InsertProductAsync() method, historySql variable
-- ============================================================================

-- ORIGINAL MS SQL SERVER VERSION:
INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
GO

-- CURRENT POSTGRESQL VERSION (in code):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- ============================================================================
-- STATEMENT 5: InsertProductAsync (statsSql) - UPDATE ProductStats
-- Location: ProductRepository.cs, InsertProductAsync() method, statsSql variable
-- ============================================================================

-- ORIGINAL MS SQL SERVER VERSION:
UPDATE [dbo].[ProductStats]
SET
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;
GO

-- CURRENT POSTGRESQL VERSION (in code):
UPDATE productmanagement_dbo.productstats
SET
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: UpdateProductAsync - Multi-statement block (DECLARE/SELECT/UPDATE/INSERT/UPDATE)
-- Location: ProductRepository.cs, UpdateProductAsync() method
-- ============================================================================

-- ORIGINAL MS SQL SERVER VERSION:
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;
SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId;
UPDATE [dbo].[Products]
SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
UPDATE [dbo].[ProductStats]
SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE()
    WHERE StatId = 1;
GO

-- CURRENT POSTGRESQL VERSION (in code):
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- ============================================================================
-- STATEMENT 7: DeleteProductAsync - Multi-statement block (DECLARE/SELECT/INSERT/DELETE/UPDATE)
-- Location: ProductRepository.cs, DeleteProductAsync() method
-- ============================================================================

-- ORIGINAL MS SQL SERVER VERSION:
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;
SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId;
INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
DELETE FROM [dbo].[Products]
    WHERE ProductId = @ProductId;
UPDATE [dbo].[ProductStats]
SET TotalProducts = TotalProducts - 1, AveragePrice =
CASE
    WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
    ELSE 0
END, LastUpdated = GETDATE()
    WHERE StatId = 1;
GO

-- CURRENT POSTGRESQL VERSION (in code):
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- ============================================================================
-- STATEMENT 8: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- Location: ProductRepository.cs, GetProductsByPriceRangeAsync() method
-- ============================================================================

-- ORIGINAL MS SQL SERVER VERSION:
WITH RankedProducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM [dbo].[Products] AS p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceSegment
    FROM RankedProducts AS rp
    ORDER BY rp.PriceRank;
GO

-- CURRENT POSTGRESQL VERSION (in code):
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ============================================================================
-- STATEMENT 9: GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions
-- Location: ProductRepository.cs, GetLowStockProductsAsync() method
-- ============================================================================

-- ORIGINAL MS SQL SERVER VERSION:
WITH StockAnalysis
AS (SELECT
    p.*, AVG(StockQuantity) OVER () AS AvgStock, MIN(StockQuantity) OVER () AS MinStock, MAX(StockQuantity) OVER () AS MaxStock
    FROM [dbo].[Products] AS p)
SELECT
    sa.*,
    CASE
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS StockStatus, ROUND((StockQuantity / AvgStock) * 100, 2) AS StockPercentageOfAverage
    FROM StockAnalysis AS sa
    WHERE StockQuantity <= @Threshold
    ORDER BY StockQuantity;
GO

-- CURRENT POSTGRESQL VERSION (in code):
WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

-- ============================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total: 9 SQL statements extracted and cataloged
-- ============================================================================
