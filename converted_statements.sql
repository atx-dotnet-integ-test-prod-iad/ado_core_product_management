-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: MS SQL Server to PostgreSQL Migration
-- Application: AdoCore - Product Management System
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ORIGINAL MS SQL:
-- WITH ProductStats AS (
--     SELECT 
--         ProductId,
--         AVG(Price) OVER() as AvgPrice,
--         COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT 
--     p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name

-- CONVERTED PostgreSQL:
WITH productstats AS (
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
INNER JOIN productstats ps ON p.productid = ps.productid
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

-- ORIGINAL MS SQL:
-- WITH ProductHistory AS (
--     SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
--         LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
--     FROM Products WHERE ProductId = @ProductId
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     ph.PreviousPrice, ph.PreviousStock,
--     CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END as PriceChangePercentage
-- FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId WHERE p.ProductId = @ProductId

-- CONVERTED PostgreSQL:
WITH producthistory AS (
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
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(), DECLARE removed, 
--          uses DO block for multi-statement + RETURNING approach split into 
--          individual statements managed by C# transaction
-- ============================================================================

-- ORIGINAL MS SQL:
-- DECLARE @NewProductId INT;
-- BEGIN TRANSACTION;
--     INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity);
--     SET @NewProductId = SCOPE_IDENTITY();
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     UPDATE ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;
-- SELECT @NewProductId;

-- CONVERTED PostgreSQL:
-- Note: For ADO.NET/Npgsql integration, this is restructured to use individual statements
-- managed by a C# transaction, with RETURNING to get the new ID
-- Statement 3a: Insert and get new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Insert history (uses the returned productid from 3a in C# code)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update stats
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: GETDATE() -> NOW(), DECLARE removed, uses individual statements 
--          managed by C# transaction
-- ============================================================================

-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
--     SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
--     UPDATE Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
--     INSERT INTO ProductHistory ... VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
--     UPDATE ProductStats SET AveragePrice = ... , LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;

-- CONVERTED PostgreSQL:
-- Statement 4a: Get old values
SELECT price as oldprice, stockquantity as oldstock
FROM products
WHERE productid = @ProductId;

-- Statement 4b: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Statement 4c: Insert history (uses old values from 4a in C# code)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update stats (uses old price from 4a in C# code)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: GETDATE() -> NOW(), DECLARE removed, uses individual statements 
--          managed by C# transaction
-- ============================================================================

-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
--     SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
--     INSERT INTO ProductHistory ... VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
--     DELETE FROM Products WHERE ProductId = @ProductId;
--     UPDATE ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE ... END, LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;

-- CONVERTED PostgreSQL:
-- Statement 5a: Get old values
SELECT price as oldprice, stockquantity as oldstock
FROM products
WHERE productid = @ProductId;

-- Statement 5b: Insert history (uses old values from 5a in C# code)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 5d: Update stats (uses old price from 5a in C# code)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ORIGINAL MS SQL:
-- WITH RankedProducts AS (
--     SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
--     FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT rp.*, CASE ... END as PriceSegment FROM RankedProducts rp ORDER BY rp.PriceRank

-- CONVERTED PostgreSQL:
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
-- Changes: Added ::numeric cast for integer division in ROUND
-- ============================================================================

-- ORIGINAL MS SQL:
-- WITH StockAnalysis AS (
--     SELECT p.*, AVG(StockQuantity) OVER() as AvgStock, MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
--     FROM Products p
-- )
-- SELECT sa.*, CASE ... END as StockStatus, ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
-- FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity

-- CONVERTED PostgreSQL:
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
