-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source Application: AdoCore (.NET ADO.NET Application)
-- Conversion: MS SQL Server → PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7 statements)
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema object names lowercased (Products→products, ProductId→productid, etc.)
--          ROUND function is compatible with PostgreSQL (no change needed)
--          Window functions (AVG OVER, COUNT OVER) are compatible
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
--     p.Name

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
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema object names lowercased, LAG window function compatible
-- ============================================================================

-- ORIGINAL MS SQL:
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
-- WHERE p.ProductId = @ProductId

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
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema object names lowercased, SCOPE_IDENTITY()→RETURNING, 
--          GETDATE()→NOW(), DECLARE/SET pattern→DO block or restructured,
--          Transaction block restructured for PostgreSQL compatibility
-- NOTE: Since this runs through ADO.NET as a single command text, we use
--       PostgreSQL-compatible DO block with RETURNING for the INSERT.
-- ============================================================================

-- ORIGINAL MS SQL:
-- DECLARE @NewProductId INT;
-- 
-- BEGIN TRANSACTION;
--     INSERT INTO Products (Name, Description, Price, StockQuantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity);
--     
--     SET @NewProductId = SCOPE_IDENTITY();
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     
--     UPDATE ProductStats
--     SET 
--         TotalProducts = TotalProducts + 1,
--         AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;
-- 
-- SELECT @NewProductId;

-- CONVERTED PostgreSQL:
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
),
update_stats AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema object names lowercased, GETDATE()→NOW(),
--          DECLARE/SELECT INTO→CTE with subqueries, transaction restructured
-- ============================================================================

-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     UPDATE Products
--     SET 
--         Name = @Name,
--         Description = @Description,
--         Price = @Price,
--         StockQuantity = @StockQuantity,
--         ModifiedDate = GETDATE()
--     WHERE ProductId = @ProductId;
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
--     
--     UPDATE ProductStats
--     SET 
--         AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT;

-- CONVERTED PostgreSQL:
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, NOW()
    FROM old_values
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema object names lowercased, GETDATE()→NOW(),
--          DECLARE/SELECT INTO→CTE, CASE expression preserved, transaction restructured
-- ============================================================================

-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2);
--     DECLARE @OldStock INT;
--     
--     SELECT @OldPrice = Price, @OldStock = StockQuantity
--     FROM Products
--     WHERE ProductId = @ProductId;
--     
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
--     
--     DELETE FROM Products 
--     WHERE ProductId = @ProductId;
--     
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

-- CONVERTED PostgreSQL:
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, NOW()
    FROM old_values
),
do_delete AS (
    DELETE FROM products 
    WHERE productid = @ProductId
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema object names lowercased, RANK/PERCENT_RANK compatible
-- ============================================================================

-- ORIGINAL MS SQL:
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
-- ORDER BY rp.PriceRank

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
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Schema object names lowercased, ROUND with CAST for integer division,
--          Window functions (AVG/MIN/MAX OVER) compatible
-- ============================================================================

-- ORIGINAL MS SQL:
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
-- ORDER BY StockQuantity

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

-- ============================================================================
-- DMS FAILURE SUMMARY
-- ============================================================================
-- All 7 statements failed DMS conversion with the same error:
-- "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- 
-- All statements were manually converted with lowercase schema object names
-- as per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA protocol.
--
-- Key conversion patterns applied:
-- 1. All schema object names (tables, columns, aliases) → lowercase
-- 2. SCOPE_IDENTITY() → RETURNING clause with CTE
-- 3. GETDATE() → NOW()
-- 4. DECLARE @var / SET @var / SELECT @var = → CTE with subqueries
-- 5. BEGIN TRANSACTION/COMMIT → Writable CTEs (single-statement approach)
-- 6. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) → compatible
-- 7. CASE expressions → compatible
-- 8. ROUND function → compatible (added ::numeric cast for integer division)
-- 9. Parameters (@Name, @Price, etc.) → preserved for Npgsql compatibility
-- ============================================================================
