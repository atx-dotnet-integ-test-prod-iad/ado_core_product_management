-- ============================================================================
-- Extracted SQL Statements from ProductRepository.cs
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 15
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync - Complex CTE query with window functions
-- Method: GetAllProductsAsync()
-- Location: Lines ~46-68
-- ============================================================================
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
-- Statement 2: GetProductByIdAsync - CTE query with LAG window functions
-- Method: GetProductByIdAsync(int productId)
-- Location: Lines ~79-100
-- ============================================================================
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
-- Statement 3: InsertProductAsync - INSERT into products with RETURNING
-- Method: InsertProductAsync(Product product)
-- Location: Lines ~114-117
-- ============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================================
-- Statement 4: InsertProductAsync - INSERT into producthistory
-- Method: InsertProductAsync(Product product)
-- Location: Lines ~128-129
-- ============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- ============================================================================
-- Statement 5: InsertProductAsync - UPDATE productstats
-- Method: InsertProductAsync(Product product)
-- Location: Lines ~139-143
-- ============================================================================
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 6: UpdateProductAsync - SELECT old price and stockquantity
-- Method: UpdateProductAsync(Product product)
-- Location: Lines ~162-164
-- ============================================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- ============================================================================
-- Statement 7: UpdateProductAsync - UPDATE products
-- Method: UpdateProductAsync(Product product)
-- Location: Lines ~176-182
-- ============================================================================
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- ============================================================================
-- Statement 8: UpdateProductAsync - INSERT producthistory
-- Method: UpdateProductAsync(Product product)
-- Location: Lines ~193-194
-- ============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @NewPrice, @OldStock, @NewStock, NOW());

-- ============================================================================
-- Statement 9: UpdateProductAsync - UPDATE productstats
-- Method: UpdateProductAsync(Product product)
-- Location: Lines ~206-209
-- ============================================================================
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @NewPrice) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 10: DeleteProductAsync - SELECT old price and stockquantity
-- Method: DeleteProductAsync(int productId)
-- Location: Lines ~228-230
-- ============================================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- ============================================================================
-- Statement 11: DeleteProductAsync - INSERT producthistory
-- Method: DeleteProductAsync(int productId)
-- Location: Lines ~242-243
-- ============================================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- ============================================================================
-- Statement 12: DeleteProductAsync - DELETE from products
-- Method: DeleteProductAsync(int productId)
-- Location: Lines ~253-254
-- ============================================================================
DELETE FROM products 
WHERE productid = @ProductId;

-- ============================================================================
-- Statement 13: DeleteProductAsync - UPDATE productstats with CASE
-- Method: DeleteProductAsync(int productId)
-- Location: Lines ~264-271
-- ============================================================================
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
-- Statement 14: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Location: Lines ~289-305
-- ============================================================================
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
-- Statement 15: GetLowStockProductsAsync - CTE with AVG, MIN, MAX window functions
-- Method: GetLowStockProductsAsync(int threshold)
-- Location: Lines ~322-338
-- ============================================================================
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
