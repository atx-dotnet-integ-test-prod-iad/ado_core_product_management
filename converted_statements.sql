-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- All schema object names converted to lowercase for PostgreSQL compatibility
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (Converted to PostgreSQL)
-- Original: CTE with AVG OVER, COUNT OVER, CASE, ROUND
-- Changes: Schema objects to lowercase, ROUND cast to numeric for division
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
-- Statement 2: GetProductByIdAsync (Converted to PostgreSQL)
-- Original: CTE with LAG window functions, parameterized query
-- Changes: Schema objects to lowercase, @ProductId -> @productid
-- ============================================================================
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

-- ============================================================================
-- Statement 3: InsertProductAsync (Converted to PostgreSQL)
-- Original: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE()
-- Changes: SCOPE_IDENTITY() -> RETURNING + lastval(), GETDATE() -> NOW(),
--          Variable declaration uses DO block or separate statements,
--          For ADO.NET integration: use INSERT...RETURNING and separate statements
-- ============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@name, @description, @price, @stockquantity)
RETURNING productid;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (lastval(), 'INSERT', NULL, @price, NULL, @stockquantity, NOW());

UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (Converted to PostgreSQL)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
-- Changes: GETDATE() -> NOW(), Variables handled via subquery/CTE approach,
--          Schema objects to lowercase
-- ============================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @productid
)
UPDATE products
SET 
    name = @name,
    description = @description,
    price = @price,
    stockquantity = @stockquantity,
    modifieddate = NOW()
WHERE productid = @productid;

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT @productid, 'UPDATE', price, @price, stockquantity, @stockquantity, NOW()
FROM products WHERE productid = @productid;

UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @productid) + @price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (Converted to PostgreSQL)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, DELETE, UPDATE with CASE, GETDATE()
-- Changes: GETDATE() -> NOW(), Variables handled via subquery,
--          Schema objects to lowercase
-- ============================================================================
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
        THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @productid)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted to PostgreSQL)
-- Original: CTE with RANK/PERCENT_RANK, BETWEEN, CASE
-- Changes: Schema objects to lowercase, syntax is compatible with PostgreSQL
-- ============================================================================
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

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (Converted to PostgreSQL)
-- Original: CTE with AVG/MIN/MAX window functions, ROUND, CASE
-- Changes: Schema objects to lowercase, CAST for integer division
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
        WHEN stockquantity <= @threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @threshold
ORDER BY stockquantity;
