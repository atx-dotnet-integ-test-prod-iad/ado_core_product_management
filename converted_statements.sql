-- ============================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: Manually converted from MS SQL Server (DMS FAILED)
-- Conversion Date: 2026-02-27
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Original Method: GetAllProductsAsync()
-- Conversion Notes: CTE, window functions, CASE, ROUND - all compatible with PostgreSQL
--   Applied lowercase schema object names per DMS failure fallback rules
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
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion Notes: CTE, LAG window function, CASE, ROUND - all compatible with PostgreSQL
--   Applied lowercase schema object names per DMS failure fallback rules
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
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Original Method: InsertProductAsync(Product product)
-- Conversion Notes: 
--   SCOPE_IDENTITY() -> RETURNING clause pattern
--   GETDATE() -> NOW()
--   DECLARE + SET pattern -> PostgreSQL DO block with RETURNING
--   Transaction managed at application level by Npgsql
--   Applied lowercase schema object names per DMS failure fallback rules
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements are executed separately after getting the new productid
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
-- 
-- UPDATE productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Original Method: UpdateProductAsync(Product product)
-- Conversion Notes:
--   DECLARE + SELECT INTO variables -> use subquery or application-level handling
--   GETDATE() -> NOW()
--   Transaction managed at application level by Npgsql
--   Applied lowercase schema object names per DMS failure fallback rules
-- ============================================================
BEGIN TRANSACTION;
    SELECT price, stockquantity
    INTO TEMP oldvalues
    FROM products
    WHERE productid = @ProductId;
    
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', (SELECT price FROM oldvalues), @Price, (SELECT stockquantity FROM oldvalues), @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM oldvalues) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
    
    DROP TABLE IF EXISTS oldvalues;
COMMIT;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Original Method: DeleteProductAsync(int productId)
-- Conversion Notes:
--   DECLARE + SELECT INTO variables -> use subquery or application-level handling
--   GETDATE() -> NOW()
--   Transaction managed at application level by Npgsql
--   Applied lowercase schema object names per DMS failure fallback rules
-- ============================================================
BEGIN TRANSACTION;
    SELECT price, stockquantity
    INTO TEMP oldvalues
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', (SELECT price FROM oldvalues), NULL, (SELECT stockquantity FROM oldvalues), NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM oldvalues)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
    
    DROP TABLE IF EXISTS oldvalues;
COMMIT;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Notes: CTE, RANK, PERCENT_RANK window functions, BETWEEN, CASE - all compatible with PostgreSQL
--   Applied lowercase schema object names per DMS failure fallback rules
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
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion Notes: CTE, AVG/MIN/MAX OVER window functions, CASE, ROUND - all compatible with PostgreSQL
--   ROUND needs CAST to numeric in PostgreSQL for integer division
--   Applied lowercase schema object names per DMS failure fallback rules
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
    ROUND(CAST(stockquantity AS NUMERIC) / CAST(avgstock AS NUMERIC) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
