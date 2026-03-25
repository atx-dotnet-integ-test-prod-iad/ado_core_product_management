-- ============================================================
-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL syntax (lowercase schema objects)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed / Command execution timed out
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (converted)
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
-- Statement 2: GetProductByIdAsync (converted)
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
-- Statement 3: InsertProductAsync (converted)
-- Restructured as separate statements for C# transaction management:
--   3a: INSERT with RETURNING
--   3b: INSERT into producthistory
--   3c: UPDATE productstats
-- ============================================================
-- 3a: Insert product and get new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- 3b: Log the insertion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync (converted)
-- Restructured as separate statements for C# transaction management:
--   4a: SELECT old values
--   4b: UPDATE product
--   4c: INSERT into producthistory
--   4d: UPDATE productstats
-- ============================================================
-- 4a: Store old values for history
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- 4b: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- 4c: Log the changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- 4d: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync (converted)
-- Restructured as separate statements for C# transaction management:
--   5a: SELECT old values
--   5b: INSERT into producthistory
--   5c: DELETE product
--   5d: UPDATE productstats
-- ============================================================
-- 5a: Store product info for history
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- 5b: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- 5c: Delete the product
DELETE FROM products WHERE productid = @ProductId;

-- 5d: Update product statistics
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
-- Statement 6: GetProductsByPriceRangeAsync (converted)
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
-- Statement 7: GetLowStockProductsAsync (converted)
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
