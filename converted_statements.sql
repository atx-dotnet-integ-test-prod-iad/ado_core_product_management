-- ================================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Date: 2026-02-24
-- Total Statements: 7
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ================================================================================

-- ORIGINAL MS SQL STATEMENT:
-- WITH ProductStats AS (
--     SELECT 
--         ProductId,
--         AVG(Price) OVER() as AvgPrice,
--         COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 'Above Average'
--         WHEN p.Price < ps.AvgPrice THEN 'Below Average'
--         ELSE 'Average'
--     END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p
-- INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY 
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 1
--         ELSE 2
--     END,
--     p.Name;

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ================================================================================

-- ORIGINAL MS SQL STATEMENT:
-- WITH ProductHistory AS (
--     SELECT 
--         ProductId,
--         LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
--         LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
--     FROM Products
--     WHERE ProductId = @ProductId
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     ph.PreviousPrice,
--     ph.PreviousStock,
--     CASE 
--         WHEN ph.PreviousPrice IS NOT NULL THEN 
--             ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
--         ELSE NULL
--     END as PriceChangePercentage
-- FROM Products p
-- LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
-- WHERE p.ProductId = @ProductId;

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Notes: SCOPE_IDENTITY() replaced with RETURNING clause, GETDATE() replaced with CURRENT_TIMESTAMP
-- ================================================================================

-- ORIGINAL MS SQL STATEMENT:
-- DECLARE @NewProductId INT;
-- 
-- BEGIN TRANSACTION;
--     -- Insert the new product
--     INSERT INTO Products (Name, Description, Price, StockQuantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity);
--     
--     SET @NewProductId = SCOPE_IDENTITY();
--     
--     -- Log the insertion
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     
--     -- Update product statistics
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts + 1,
--         AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;
-- 
-- SELECT @NewProductId;

-- CONVERTED POSTGRESQL STATEMENT:
DO $$
DECLARE
    v_newproductid INT;
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product id
    PERFORM v_newproductid;
END $$;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Notes: GETDATE() replaced with CURRENT_TIMESTAMP, Transaction handled by ADO.NET
-- ================================================================================

-- ORIGINAL MS SQL STATEMENT:
-- BEGIN TRANSACTION;
--     -- Store old values for history
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     -- Update the product
--     UPDATE Products
--     SET 
--         Name = @Name,
--         Description = @Description,
--         Price = @Price,
--         StockQuantity = @StockQuantity,
--         ModifiedDate = GETDATE()
--     WHERE ProductId = @ProductId;
--     
--     -- Log the changes
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
--     
--     -- Update product statistics
--     UPDATE ProductStats
--     SET 
--         AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;

-- CONVERTED POSTGRESQL STATEMENT:
DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Notes: GETDATE() replaced with CURRENT_TIMESTAMP, Transaction handled by ADO.NET
-- ================================================================================

-- ORIGINAL MS SQL STATEMENT:
-- BEGIN TRANSACTION;
--     -- Store product info for history
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     -- Log the deletion
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
--     
--     -- Delete the product
--     DELETE FROM Products 
--     WHERE ProductId = @ProductId;
--     
--     -- Update product statistics
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts - 1,
--         AveragePrice = CASE 
--             WHEN TotalProducts > 1 
--             THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
--             ELSE 0
--         END,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;

-- CONVERTED POSTGRESQL STATEMENT:
DO $$
DECLARE
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ================================================================================

-- ORIGINAL MS SQL STATEMENT:
-- WITH RankedProducts AS (
--     SELECT 
--         p.*,
--         RANK() OVER (ORDER BY p.Price) as PriceRank,
--         PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
--     FROM Products p
--     WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT 
--     rp.*,
--     CASE 
--         WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
--         WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
--         ELSE 'Premium'
--     END as PriceSegment
-- FROM RankedProducts rp
-- ORDER BY rp.PriceRank;

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ================================================================================

-- ORIGINAL MS SQL STATEMENT:
-- WITH StockAnalysis AS (
--     SELECT 
--         p.*,
--         AVG(StockQuantity) OVER() as AvgStock,
--         MIN(StockQuantity) OVER() as MinStock,
--         MAX(StockQuantity) OVER() as MaxStock
--     FROM Products p
-- )
-- SELECT 
--     sa.*,
--     CASE 
--         WHEN StockQuantity <= @Threshold THEN 'Critical'
--         WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
--         ELSE 'Adequate'
--     END as StockStatus,
--     ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
-- FROM StockAnalysis sa
-- WHERE StockQuantity <= @Threshold
-- ORDER BY StockQuantity;

-- CONVERTED POSTGRESQL STATEMENT:
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
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ================================================================================

-- SUMMARY:
-- Total Statements: 7
-- DMS Tool Conversions: 0
-- Manual Conversions (DMS Failures): 7
-- 
-- All statements failed DMS conversion with error: 
-- "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- 
-- Manual conversions applied:
-- 1. All schema object names converted to lowercase (Products -> products, ProductId -> productid, etc.)
-- 2. GETDATE() replaced with CURRENT_TIMESTAMP
-- 3. SCOPE_IDENTITY() replaced with RETURNING clause
-- 4. T-SQL transactions converted to PostgreSQL DO $$ blocks with proper variable declarations
-- 5. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) are PostgreSQL compatible
-- 6. CASE expressions are PostgreSQL compatible
-- 7. ROUND function is PostgreSQL compatible
-- ================================================================================
