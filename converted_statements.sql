-- ============================================================
-- Converted SQL Statements for PostgreSQL (Npgsql ADO.NET Compatible)
-- Source: DataAccess/ProductRepository.cs (originally MS SQL Server)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion did not complete after multiple attempts (timeout)
-- Conversion Date: 2026-04-02
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync
-- Conversion Notes: 
--   - Schema objects converted to lowercase (products, productid, etc.)
--   - ROUND, CASE, window functions (AVG OVER, COUNT OVER) compatible with PostgreSQL
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
-- Statement 2: GetProductByIdAsync
-- Conversion Notes:
--   - Schema objects converted to lowercase
--   - LAG window function is compatible with PostgreSQL
-- ============================================================
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @productid
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
WHERE p.productid = @productid;

-- ============================================================
-- Statement 3: InsertProductAsync
-- Conversion Notes:
--   - SCOPE_IDENTITY() replaced with INSERT...RETURNING and subqueries
--   - GETDATE() -> NOW()
--   - Transaction block restructured as sequential statements compatible with Npgsql
--   - Uses currval() after INSERT...RETURNING for subsequent references
--   - Multiple statements in single command text for Npgsql batch execution
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@name, @description, @price, @stockquantity);

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (lastval(), 'INSERT', NULL, @price, NULL, @stockquantity, NOW());

UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

SELECT lastval();

-- ============================================================
-- Statement 4: UpdateProductAsync
-- Conversion Notes:
--   - DECLARE/SET pattern removed; uses subqueries for old values
--   - GETDATE() -> NOW()
--   - Restructured as sequential statements compatible with Npgsql
-- ============================================================
UPDATE products
SET 
    name = @name,
    description = @description,
    price = @price,
    stockquantity = @stockquantity,
    modifieddate = NOW()
WHERE productid = @productid;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT @productid, 'UPDATE', 
    (SELECT price FROM products WHERE productid = @productid), 
    @price,
    (SELECT stockquantity FROM products WHERE productid = @productid), 
    @stockquantity, NOW();

UPDATE productstats
SET 
    averageprice = (SELECT AVG(price) FROM products),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync
-- Conversion Notes:
--   - DECLARE/SET pattern removed; uses subqueries for old values
--   - GETDATE() -> NOW()
--   - Restructured as sequential statements compatible with Npgsql
-- ============================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
FROM products WHERE productid = @productid;

DELETE FROM products 
WHERE productid = @productid;

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

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Conversion Notes:
--   - Schema objects converted to lowercase
--   - RANK(), PERCENT_RANK() are compatible with PostgreSQL
-- ============================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @minprice AND @maxprice
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
-- Statement 7: GetLowStockProductsAsync
-- Conversion Notes:
--   - Schema objects converted to lowercase
--   - Added CAST for integer division to produce decimal result
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
        WHEN stockquantity <= @threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @threshold
ORDER BY stockquantity;
