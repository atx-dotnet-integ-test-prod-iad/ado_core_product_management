-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- This catalog contains the original MS SQL Server forms of each statement,
-- reconstructed by reversing the known transformations from the current
-- PostgreSQL syntax in the codebase.
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Source: DataAccess/ProductRepository.cs - GetAllProductsAsync() method
-- Parameters: None
-- Description: CTE with window functions to get all products with price stats
-- ============================================================================
-- Original MS SQL Server form:
WITH ProductStats AS (SELECT ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts FROM dbo.Products) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END AS PriceCategory, ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage FROM dbo.Products AS p INNER JOIN ProductStats AS ps ON p.ProductId = ps.ProductId ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name

-- Current PostgreSQL form in code:
-- WITH productstats AS (SELECT productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts FROM productmanagement_dbo.products) SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage FROM productmanagement_dbo.products AS p INNER JOIN productstats AS ps ON p.productid = ps.productid ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END NULLS FIRST, p.name NULLS FIRST

-- ============================================================================
-- Statement 2: GetProductByIdAsync
-- Source: DataAccess/ProductRepository.cs - GetProductByIdAsync() method
-- Parameters: @ProductId (int)
-- Description: CTE with LAG window function to get product with history
-- ============================================================================
-- Original MS SQL Server form:
WITH ProductHistory AS (SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock FROM dbo.Products WHERE ProductId = @ProductId) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock, CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END AS PriceChangePercentage FROM dbo.Products AS p LEFT OUTER JOIN ProductHistory AS ph ON p.ProductId = ph.ProductId WHERE p.ProductId = @ProductId

-- Current PostgreSQL form in code:
-- WITH producthistory AS (SELECT productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock FROM productmanagement_dbo.products WHERE productid = @ProductId) SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock, CASE WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL END AS pricechangepercentage FROM productmanagement_dbo.products AS p LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid WHERE p.productid = @ProductId

-- ============================================================================
-- Statement 3: InsertProductAsync
-- Source: DataAccess/ProductRepository.cs - InsertProductAsync() method
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Multi-statement block with INSERT, SCOPE_IDENTITY, history logging, stats update
-- ============================================================================
-- Original MS SQL Server form:
DECLARE @NewProductId INT; INSERT INTO dbo.Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity); SET @NewProductId = SCOPE_IDENTITY(); INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE()); UPDATE dbo.ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1; SELECT @NewProductId AS ProductId;

-- Current PostgreSQL form in code:
-- WITH ins AS (INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity) VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid), hist AS (INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp() FROM ins), stats AS (UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp() WHERE statid = 1) SELECT productid FROM ins

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- Source: DataAccess/ProductRepository.cs - UpdateProductAsync() method
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Multi-statement block with DECLARE, SELECT INTO, UPDATE, INSERT history, UPDATE stats
-- ============================================================================
-- Original MS SQL Server form:
DECLARE @OldPrice DECIMAL(18, 2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId; UPDATE dbo.Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId; INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE()); UPDATE dbo.ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE() WHERE StatId = 1;

-- Current PostgreSQL form in code:
-- DO $$ DECLARE var_OldPrice NUMERIC(18, 2); var_OldStock INTEGER; BEGIN SELECT price, stockquantity INTO var_OldPrice, var_OldStock FROM productmanagement_dbo.products WHERE productid = @ProductId; UPDATE productmanagement_dbo.products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId; INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp()); UPDATE productmanagement_dbo.productstats SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp() WHERE statid = 1; END $$

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- Source: DataAccess/ProductRepository.cs - DeleteProductAsync() method
-- Parameters: @ProductId (int)
-- Description: Multi-statement block with DECLARE, SELECT INTO, INSERT history, DELETE, UPDATE stats
-- ============================================================================
-- Original MS SQL Server form:
DECLARE @OldPrice DECIMAL(18, 2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId; INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE()); DELETE FROM dbo.Products WHERE ProductId = @ProductId; UPDATE dbo.ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1;

-- Current PostgreSQL form in code:
-- DO $$ DECLARE var_OldPrice NUMERIC(18, 2); var_OldStock INTEGER; BEGIN SELECT price, stockquantity INTO var_OldPrice, var_OldStock FROM productmanagement_dbo.products WHERE productid = @ProductId; INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp()); DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId; UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1) ELSE 0 END, lastupdated = clock_timestamp() WHERE statid = 1; END $$

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Source: DataAccess/ProductRepository.cs - GetProductsByPriceRangeAsync() method
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: CTE with RANK and PERCENT_RANK window functions
-- ============================================================================
-- Original MS SQL Server form:
WITH RankedProducts AS (SELECT p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile FROM dbo.Products AS p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice) SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget' WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS PriceSegment FROM RankedProducts AS rp ORDER BY rp.PriceRank

-- Current PostgreSQL form in code:
-- WITH rankedproducts AS (SELECT p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile FROM productmanagement_dbo.products AS p WHERE p.price BETWEEN @MinPrice AND @MaxPrice) SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget' WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS pricesegment FROM rankedproducts AS rp ORDER BY rp.pricerank NULLS FIRST

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync
-- Source: DataAccess/ProductRepository.cs - GetLowStockProductsAsync() method
-- Parameters: @Threshold (int)
-- Description: CTE with AVG/MIN/MAX window functions for stock analysis
-- ============================================================================
-- Original MS SQL Server form:
WITH StockAnalysis AS (SELECT p.*, AVG(StockQuantity) OVER () AS AvgStock, MIN(StockQuantity) OVER () AS MinStock, MAX(StockQuantity) OVER () AS MaxStock FROM dbo.Products AS p) SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical' WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END AS StockStatus, ROUND((StockQuantity / AvgStock) * 100, 2) AS StockPercentageOfAverage FROM StockAnalysis AS sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity

-- Current PostgreSQL form in code:
-- WITH stockanalysis AS (SELECT p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock FROM productmanagement_dbo.products AS p) SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical' WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage FROM stockanalysis AS sa WHERE stockquantity <= @Threshold ORDER BY stockquantity NULLS FIRST
