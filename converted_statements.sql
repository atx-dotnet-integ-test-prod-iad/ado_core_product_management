-- ============================================================================
-- Converted SQL Statements Catalog
-- Source: ADO.NET ProductManagement Application
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
--   Products -> products (columns lowercase)
--   ProductHistory -> producthistory (columns lowercase)
--   ProductStats -> productstats (columns lowercase)
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> INSERT...RETURNING
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- [MSSQL_ORIGINAL]
-- WITH ProductStats AS (
--     SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name

-- [POSTGRESQL_CONVERTED]
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- [MSSQL_ORIGINAL]
-- WITH ProductHistory AS (
--     SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
--     FROM Products WHERE ProductId = @ProductId
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
--     CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END as PriceChangePercentage
-- FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId WHERE p.ProductId = @ProductId

-- [POSTGRESQL_CONVERTED]
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Note: SCOPE_IDENTITY() replaced with INSERT...RETURNING pattern
--       GETDATE() replaced with clock_timestamp()
--       Transaction managed by C# code (Npgsql), not in SQL
--       Split into 3 separate statements executed within C# transaction
-- ============================================================================
-- [MSSQL_ORIGINAL]
-- DECLARE @NewProductId INT;
-- BEGIN TRANSACTION;
--     INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity);
--     SET @NewProductId = SCOPE_IDENTITY();
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     UPDATE ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;
-- SELECT @NewProductId;

-- [POSTGRESQL_CONVERTED] - Statement 3a: Insert product and return new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- [POSTGRESQL_CONVERTED] - Statement 3b: Log insertion to history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- [POSTGRESQL_CONVERTED] - Statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Note: DECLARE variables replaced with subqueries and C# transaction handling
--       GETDATE() replaced with clock_timestamp()
--       Split into 4 separate statements executed within C# transaction
-- ============================================================================
-- [MSSQL_ORIGINAL]
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
--     SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
--     UPDATE Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
--     UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;

-- [POSTGRESQL_CONVERTED] - Statement 4a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- [POSTGRESQL_CONVERTED] - Statement 4b: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- [POSTGRESQL_CONVERTED] - Statement 4c: Log changes to history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- [POSTGRESQL_CONVERTED] - Statement 4d: Update statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Note: DECLARE variables replaced with subqueries and C# transaction handling
--       GETDATE() replaced with clock_timestamp()
--       Split into 4 separate statements executed within C# transaction
-- ============================================================================
-- [MSSQL_ORIGINAL]
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
--     SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
--     DELETE FROM Products WHERE ProductId = @ProductId;
--     UPDATE ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;

-- [POSTGRESQL_CONVERTED] - Statement 5a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- [POSTGRESQL_CONVERTED] - Statement 5b: Log deletion to history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- [POSTGRESQL_CONVERTED] - Statement 5c: Delete product
DELETE FROM products 
WHERE productid = @ProductId;

-- [POSTGRESQL_CONVERTED] - Statement 5d: Update statistics
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- [MSSQL_ORIGINAL]
-- WITH RankedProducts AS (
--     SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
--     FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget' WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as PriceSegment
-- FROM RankedProducts rp ORDER BY rp.PriceRank

-- [POSTGRESQL_CONVERTED]
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Note: Added explicit cast for integer division to NUMERIC
-- ============================================================================
-- [MSSQL_ORIGINAL]
-- WITH StockAnalysis AS (
--     SELECT p.*, AVG(StockQuantity) OVER() as AvgStock, MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
--     FROM Products p
-- )
-- SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical' WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END as StockStatus,
--     ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
-- FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity

-- [POSTGRESQL_CONVERTED]
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity::NUMERIC / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- Total: 7 SQL statement blocks converted
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7)
-- DMS Failure Reason: Metadata model creation failed: RECEIVED
-- ============================================================================
