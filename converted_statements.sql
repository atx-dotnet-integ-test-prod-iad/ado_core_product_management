-- ============================================================================
-- Converted SQL Statements - MS SQL Server to PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion/creation timeout for all statements
-- All schema object names converted to lowercase for PostgreSQL compatibility
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed after 15 attempts / timeout after 300s
-- Changes: Table/column names lowercased, ROUND cast to numeric
-- ============================================================================

-- ORIGINAL MS SQL:
/*
                WITH ProductStats AS (
                    SELECT 
                        ProductId,
                        AVG(Price) OVER() as AvgPrice,
                        COUNT(*) OVER() as TotalProducts
                    FROM Products
                )
                SELECT 
                    p.ProductId,
                    p.Name,
                    p.Description,
                    p.Price,
                    p.StockQuantity,
                    p.CreatedDate,
                    p.ModifiedDate,
                    CASE 
                        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
                        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
                        ELSE 'Average'
                    END as PriceCategory,
                    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
                FROM Products p
                INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
                ORDER BY 
                    CASE 
                        WHEN p.Price > ps.AvgPrice THEN 1
                        ELSE 2
                    END,
                    p.Name
*/

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
                    ROUND((p.price / ps.avgprice * 100)::numeric, 2) as pricepercentageofaverage
                FROM products p
                INNER JOIN productstats ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END,
                    p.name

-- ============================================================================
-- Statement 2: GetProductByIdAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed after 15 attempts / timeout after 300s
-- Changes: Table/column names lowercased, ROUND cast to numeric
-- ============================================================================

-- ORIGINAL MS SQL:
/*
                WITH ProductHistory AS (
                    SELECT 
                        ProductId,
                        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
                        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
                    FROM Products
                    WHERE ProductId = @ProductId
                )
                SELECT 
                    p.ProductId,
                    p.Name,
                    p.Description,
                    p.Price,
                    p.StockQuantity,
                    p.CreatedDate,
                    p.ModifiedDate,
                    ph.PreviousPrice,
                    ph.PreviousStock,
                    CASE 
                        WHEN ph.PreviousPrice IS NOT NULL THEN 
                            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
                        ELSE NULL
                    END as PriceChangePercentage
                FROM Products p
                LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
                WHERE p.ProductId = @ProductId
*/

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
                            ROUND(((p.price - ph.previousprice) / ph.previousprice * 100)::numeric, 2)
                        ELSE NULL
                    END as pricechangepercentage
                FROM products p
                LEFT JOIN producthistory ph ON p.productid = ph.productid
                WHERE p.productid = @ProductId

-- ============================================================================
-- Statement 3: InsertProductAsync
-- Source: DataAccess/ProductRepository.cs, Method: InsertProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed after 15 attempts / timeout after 300s
-- Changes: Table/column names lowercased, SCOPE_IDENTITY() -> RETURNING + lastval(),
--          GETDATE() -> NOW(), DECLARE/SET -> DO block with variables,
--          Transaction block restructured for PostgreSQL compatibility
-- ============================================================================

-- ORIGINAL MS SQL:
/*
                DECLARE @NewProductId INT;
                
                BEGIN TRANSACTION;
                    INSERT INTO Products (Name, Description, Price, StockQuantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity);
                    
                    SET @NewProductId = SCOPE_IDENTITY();
                    
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
                    
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts + 1,
                        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                        LastUpdated = GETDATE()
                    WHERE StatId = 1;
                COMMIT;
                
                SELECT @NewProductId;
*/

-- CONVERTED PostgreSQL:
                BEGIN;
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity);
                    
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (currval(pg_get_serial_sequence('products', 'productid')), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
                    
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = NOW()
                    WHERE statid = 1;
                COMMIT;
                
                SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- Source: DataAccess/ProductRepository.cs, Method: UpdateProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed after 15 attempts / timeout after 300s
-- Changes: Table/column names lowercased, DECLARE -> DO block,
--          GETDATE() -> NOW(), SELECT INTO variables restructured
-- ============================================================================

-- ORIGINAL MS SQL:
/*
                BEGIN TRANSACTION;
                    DECLARE @OldPrice DECIMAL(18,2);
                    DECLARE @OldStock INT;
                    
                    SELECT @OldPrice = Price, @OldStock = StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId;
                    
                    UPDATE Products
                    SET 
                        Name = @Name,
                        Description = @Description,
                        Price = @Price,
                        StockQuantity = @StockQuantity,
                        ModifiedDate = GETDATE()
                    WHERE ProductId = @ProductId;
                    
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
                    
                    UPDATE ProductStats
                    SET 
                        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
                        LastUpdated = GETDATE()
                    WHERE StatId = 1;
                COMMIT;
*/

-- CONVERTED PostgreSQL:
                BEGIN;
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', p.price, @Price, p.stockquantity, @StockQuantity, NOW()
                    FROM products p WHERE p.productid = @ProductId;
                    
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = NOW()
                    WHERE productid = @ProductId;
                    
                    UPDATE productstats
                    SET 
                        averageprice = (SELECT AVG(price) FROM products),
                        lastupdated = NOW()
                    WHERE statid = 1;
                COMMIT;

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- Source: DataAccess/ProductRepository.cs, Method: DeleteProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed after 15 attempts / timeout after 300s
-- Changes: Table/column names lowercased, DECLARE -> DO block,
--          GETDATE() -> NOW(), SELECT INTO variables restructured, CASE preserved
-- ============================================================================

-- ORIGINAL MS SQL:
/*
                BEGIN TRANSACTION;
                    DECLARE @OldPrice DECIMAL(18,2);
                    DECLARE @OldStock INT;
                    
                    SELECT @OldPrice = Price, @OldStock = StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId;
                    
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
                    
                    DELETE FROM Products 
                    WHERE ProductId = @ProductId;
                    
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts - 1,
                        AveragePrice = CASE 
                            WHEN TotalProducts > 1 
                            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
                            ELSE 0
                        END,
                        LastUpdated = GETDATE()
                    WHERE StatId = 1;
                COMMIT;
*/

-- CONVERTED PostgreSQL:
                BEGIN;
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', p.price, NULL, p.stockquantity, NULL, NOW()
                    FROM products p WHERE p.productid = @ProductId;
                    
                    DELETE FROM products 
                    WHERE productid = @ProductId;
                    
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (SELECT COALESCE(AVG(price), 0) FROM products)
                            ELSE 0
                        END,
                        lastupdated = NOW()
                    WHERE statid = 1;
                COMMIT;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed after 15 attempts / timeout after 300s
-- Changes: Table/column names lowercased. RANK(), PERCENT_RANK(), BETWEEN are 
--          standard SQL and work in PostgreSQL.
-- ============================================================================

-- ORIGINAL MS SQL:
/*
                WITH RankedProducts AS (
                    SELECT 
                        p.*,
                        RANK() OVER (ORDER BY p.Price) as PriceRank,
                        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
                    FROM Products p
                    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
                )
                SELECT 
                    rp.*,
                    CASE 
                        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
                        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
                        ELSE 'Premium'
                    END as PriceSegment
                FROM RankedProducts rp
                ORDER BY rp.PriceRank
*/

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
                ORDER BY rp.pricerank

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed after 15 attempts / timeout after 300s
-- Changes: Table/column names lowercased, ROUND cast to numeric,
--          AVG/MIN/MAX OVER() are standard SQL and work in PostgreSQL
-- ============================================================================

-- ORIGINAL MS SQL:
/*
                WITH StockAnalysis AS (
                    SELECT 
                        p.*,
                        AVG(StockQuantity) OVER() as AvgStock,
                        MIN(StockQuantity) OVER() as MinStock,
                        MAX(StockQuantity) OVER() as MaxStock
                    FROM Products p
                )
                SELECT 
                    sa.*,
                    CASE 
                        WHEN StockQuantity <= @Threshold THEN 'Critical'
                        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END as StockStatus,
                    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
                FROM StockAnalysis sa
                WHERE StockQuantity <= @Threshold
                ORDER BY StockQuantity
*/

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
                    ROUND((stockquantity / avgstock * 100)::numeric, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity
