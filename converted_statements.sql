-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- All 7 statements passed through DMS MCP tool - ALL FAILED with metadata model creation errors
-- DMS Attempts: 2 rounds (initial + retry), all failed consistently
-- Manual conversion applied with lowercase schema mapping per DMS schema_mapping_tool output:
--   dbo.Products → productmanagement_dbo.products
--   dbo.ProductHistory → productmanagement_dbo.producthistory
--   dbo.ProductStats → productmanagement_dbo.productstats
--   GETDATE() → clock_timestamp()
--   SCOPE_IDENTITY() → RETURNING clause pattern
--   Column names → lowercase
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- DMS Status: FAILED - Metadata model creation did not complete after 15 attempts
-- DMS Retry Status: FAILED - Metadata model creation did not complete after 15 attempts (2026-03-20T23:46:22)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- Original MS SQL:
-- WITH ProductStats AS (SELECT ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts FROM dbo.Products) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END AS PriceCategory, ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage FROM dbo.Products AS p INNER JOIN ProductStats AS ps ON p.ProductId = ps.ProductId ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name

-- Converted PostgreSQL:
WITH productstats AS (SELECT productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts FROM productmanagement_dbo.products) SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage FROM productmanagement_dbo.products AS p INNER JOIN productstats AS ps ON p.productid = ps.productid ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END NULLS FIRST, p.name NULLS FIRST

-- ============================================================================
-- Statement 2: GetProductByIdAsync
-- DMS Status: FAILED - Metadata model creation did not complete after 15 attempts
-- DMS Retry Status: FAILED - Metadata model creation did not complete after 15 attempts (2026-03-20T23:49:08)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- Original MS SQL:
-- WITH ProductHistory AS (SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock FROM dbo.Products WHERE ProductId = @ProductId) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock, CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END AS PriceChangePercentage FROM dbo.Products AS p LEFT OUTER JOIN ProductHistory AS ph ON p.ProductId = ph.ProductId WHERE p.ProductId = @ProductId

-- Converted PostgreSQL:
WITH producthistory AS (SELECT productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock FROM productmanagement_dbo.products WHERE productid = @ProductId) SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock, CASE WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL END AS pricechangepercentage FROM productmanagement_dbo.products AS p LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid WHERE p.productid = @ProductId

-- ============================================================================
-- Statement 3: InsertProductAsync
-- DMS Status: FAILED - Metadata model creation did not complete after 15 attempts
-- DMS Retry Status: FAILED - Metadata model creation did not complete after 15 attempts (2026-03-20T23:51:54)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- Original MS SQL:
-- DECLARE @NewProductId INT; INSERT INTO dbo.Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity); SET @NewProductId = SCOPE_IDENTITY(); INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE()); UPDATE dbo.ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1; SELECT @NewProductId AS ProductId;

-- Converted PostgreSQL:
WITH ins AS (INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity) VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid), hist AS (INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp() FROM ins), stats AS (UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp() WHERE statid = 1) SELECT productid FROM ins

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- DMS Status: FAILED - Metadata model creation did not complete after 15 attempts
-- DMS Retry Status: FAILED - Metadata model creation did not complete after 15 attempts (2026-03-20T23:54:38)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- Original MS SQL:
-- DECLARE @OldPrice DECIMAL(18, 2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId; UPDATE dbo.Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId; INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE()); UPDATE dbo.ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE() WHERE StatId = 1;

-- Converted PostgreSQL:
DO $$ DECLARE var_OldPrice NUMERIC(18, 2); var_OldStock INTEGER; BEGIN SELECT price, stockquantity INTO var_OldPrice, var_OldStock FROM productmanagement_dbo.products WHERE productid = @ProductId; UPDATE productmanagement_dbo.products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId; INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp()); UPDATE productmanagement_dbo.productstats SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp() WHERE statid = 1; END $$

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- DMS Status: FAILED - Metadata model creation did not complete after 15 attempts
-- DMS Retry Status: FAILED - Metadata model creation did not complete after 15 attempts (2026-03-20T23:57:23)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- Original MS SQL:
-- DECLARE @OldPrice DECIMAL(18, 2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId; INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE()); DELETE FROM dbo.Products WHERE ProductId = @ProductId; UPDATE dbo.ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1;

-- Converted PostgreSQL:
DO $$ DECLARE var_OldPrice NUMERIC(18, 2); var_OldStock INTEGER; BEGIN SELECT price, stockquantity INTO var_OldPrice, var_OldStock FROM productmanagement_dbo.products WHERE productid = @ProductId; INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp()); DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId; UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1) ELSE 0 END, lastupdated = clock_timestamp() WHERE statid = 1; END $$

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- DMS Status: FAILED - Metadata model creation did not complete after 15 attempts
-- DMS Retry Status: FAILED - Metadata model creation did not complete after 15 attempts (2026-03-21T00:00:08)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- Original MS SQL:
-- WITH RankedProducts AS (SELECT p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile FROM dbo.Products AS p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice) SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget' WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS PriceSegment FROM RankedProducts AS rp ORDER BY rp.PriceRank

-- Converted PostgreSQL:
WITH rankedproducts AS (SELECT p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile FROM productmanagement_dbo.products AS p WHERE p.price BETWEEN @MinPrice AND @MaxPrice) SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget' WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS pricesegment FROM rankedproducts AS rp ORDER BY rp.pricerank NULLS FIRST

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync
-- DMS Status: FAILED - Metadata model creation did not complete after 15 attempts
-- DMS Retry Status: FAILED - Metadata model creation did not complete after 15 attempts (2026-03-21T00:02:55)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- Original MS SQL:
-- WITH StockAnalysis AS (SELECT p.*, AVG(StockQuantity) OVER () AS AvgStock, MIN(StockQuantity) OVER () AS MinStock, MAX(StockQuantity) OVER () AS MaxStock FROM dbo.Products AS p) SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical' WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END AS StockStatus, ROUND((StockQuantity / AvgStock) * 100, 2) AS StockPercentageOfAverage FROM StockAnalysis AS sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity

-- Converted PostgreSQL:
WITH stockanalysis AS (SELECT p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock FROM productmanagement_dbo.products AS p) SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical' WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage FROM stockanalysis AS sa WHERE stockquantity <= @Threshold ORDER BY stockquantity NULLS FIRST
