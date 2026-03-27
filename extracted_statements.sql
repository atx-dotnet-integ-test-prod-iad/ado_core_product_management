-- ============================================================
-- Extracted SQL Statements Catalog
-- Source: DataAccess/ProductRepository.cs
-- Extraction Date: 2026-03-27
-- Total Statements: 15
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync - CTE with Window Functions
-- Method: GetAllProductsAsync
-- Variable: sql
-- Line: ~46-68
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync - CTE with LAG Window Function
-- Method: GetProductByIdAsync
-- Variable: sql
-- Line: ~79-99
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync - INSERT with RETURNING
-- Method: InsertProductAsync
-- Variable: insertProductSql
-- Line: ~115-118
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================
-- Statement 4: InsertProductAsync - INSERT History for INSERT action
-- Method: InsertProductAsync
-- Variable: insertHistorySql
-- Line: ~130-131
-- ============================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- ============================================================
-- Statement 5: InsertProductAsync - UPDATE Stats for insert
-- Method: InsertProductAsync
-- Variable: updateStatsSql
-- Line: ~143-147
-- ============================================================
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 6: UpdateProductAsync - SELECT Old Values (update path)
-- Method: UpdateProductAsync
-- Variable: selectOldValuesSql
-- Line: ~165-167
-- ============================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- ============================================================
-- Statement 7: UpdateProductAsync - UPDATE Product
-- Method: UpdateProductAsync
-- Variable: updateProductSql
-- Line: ~179-185
-- ============================================================
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- ============================================================
-- Statement 8: UpdateProductAsync - INSERT History for UPDATE action
-- Method: UpdateProductAsync
-- Variable: insertHistorySql
-- Line: ~197-198
-- ============================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- ============================================================
-- Statement 9: UpdateProductAsync - UPDATE Stats for update
-- Method: UpdateProductAsync
-- Variable: updateStatsSql
-- Line: ~211-214
-- ============================================================
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 10: DeleteProductAsync - SELECT Old Values (delete path)
-- Method: DeleteProductAsync
-- Variable: selectOldValuesSql
-- Line: ~234-236
-- ============================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- ============================================================
-- Statement 11: DeleteProductAsync - INSERT History for DELETE action
-- Method: DeleteProductAsync
-- Variable: insertHistorySql
-- Line: ~248-249
-- ============================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- ============================================================
-- Statement 12: DeleteProductAsync - DELETE Product
-- Method: DeleteProductAsync
-- Variable: deleteProductSql
-- Line: ~260-261
-- ============================================================
DELETE FROM products 
WHERE productid = @ProductId;

-- ============================================================
-- Statement 13: DeleteProductAsync - UPDATE Stats for delete
-- Method: DeleteProductAsync
-- Variable: updateStatsSql
-- Line: ~270-278
-- ============================================================
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

-- ============================================================
-- Statement 14: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- Method: GetProductsByPriceRangeAsync
-- Variable: sql
-- Line: ~296-312
-- ============================================================
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

-- ============================================================
-- Statement 15: GetLowStockProductsAsync - CTE with Window Aggregates
-- Method: GetLowStockProductsAsync
-- Variable: sql
-- Line: ~331-348
-- ============================================================
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
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
