-- ============================================================
-- CONVERTED POSTGRESQL STATEMENTS
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Schema Mapping Source: DMS schema_mapping_tool
--   dbo.Products -> productmanagement_dbo.products
--   dbo.ProductHistory -> productmanagement_dbo.producthistory
--   dbo.ProductStats -> productmanagement_dbo.productstats
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING productid
-- Total Statements: 15
-- ============================================================

-- Statement 1: GetAllProductsAsync - CTE with window functions
-- Method: GetAllProductsAsync()
WITH productstats AS (
    SELECT productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
FROM productmanagement_dbo.products AS p
INNER JOIN productstats AS ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- Statement 2: GetProductByIdAsync - CTE with LAG
-- Method: GetProductByIdAsync(int productId)
WITH producthistory AS (
    SELECT productid, LAG(price) OVER (ORDER BY modifieddate) AS previousprice, LAG(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    ph.previousprice, ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
FROM productmanagement_dbo.products AS p
LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- Statement 3: InsertProductAsync - INSERT product with RETURNING
-- Method: InsertProductAsync(Product product) - Transaction Block Statement 1
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 4: InsertProductAsync - INSERT history
-- Method: InsertProductAsync(Product product) - Transaction Block Statement 2
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Statement 5: InsertProductAsync - UPDATE stats
-- Method: InsertProductAsync(Product product) - Transaction Block Statement 3
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- Statement 6: UpdateProductAsync - SELECT old values
-- Method: UpdateProductAsync(Product product) - Transaction Block Statement 1
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 7: UpdateProductAsync - UPDATE product
-- Method: UpdateProductAsync(Product product) - Transaction Block Statement 2
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Statement 8: UpdateProductAsync - INSERT history
-- Method: UpdateProductAsync(Product product) - Transaction Block Statement 3
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Statement 9: UpdateProductAsync - UPDATE stats
-- Method: UpdateProductAsync(Product product) - Transaction Block Statement 4
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- Statement 10: DeleteProductAsync - SELECT old values
-- Method: DeleteProductAsync(int productId) - Transaction Block Statement 1
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 11: DeleteProductAsync - INSERT history
-- Method: DeleteProductAsync(int productId) - Transaction Block Statement 2
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Statement 12: DeleteProductAsync - DELETE product
-- Method: DeleteProductAsync(int productId) - Transaction Block Statement 3
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- Statement 13: DeleteProductAsync - UPDATE stats
-- Method: DeleteProductAsync(int productId) - Transaction Block Statement 4
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- Statement 14: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) AS pricerank,
        percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank NULLS FIRST;

-- Statement 15: GetLowStockProductsAsync - CTE with window aggregates
-- Method: GetLowStockProductsAsync(int threshold)
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() AS avgstock,
        MIN(stockquantity) OVER() AS minstock,
        MAX(stockquantity) OVER() AS maxstock
    FROM productmanagement_dbo.products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus,
    ROUND(CAST(stockquantity AS NUMERIC(18, 0)) / avgstock * 100, 2) AS stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity NULLS FIRST;
