-- =====================================================
-- Converted SQL Statements for PostgreSQL (Npgsql compatible)
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation did not complete after multiple attempts
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync (Converted to PostgreSQL)
-- Changes: Lowercase schema objects
-- =====================================================
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

-- =====================================================
-- Statement 2: GetProductByIdAsync (Converted to PostgreSQL)
-- Changes: Lowercase schema objects
-- =====================================================
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

-- =====================================================
-- Statement 3: InsertProductAsync (Converted to PostgreSQL)
-- Changes: SCOPE_IDENTITY() -> lastval(), GETDATE() -> NOW(),
--          BEGIN TRANSACTION -> BEGIN, lowercase schema
-- Uses lastval() for sequence value retrieval (equivalent to SCOPE_IDENTITY())
-- =====================================================
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- =====================================================
-- Statement 4: UpdateProductAsync (Converted to PostgreSQL)
-- Changes: GETDATE() -> NOW(), DECLARE -> CTE-based old value capture,
--          BEGIN TRANSACTION -> BEGIN, lowercase schema
-- Uses CTE with UPDATE RETURNING to capture old values
-- =====================================================
BEGIN;
    WITH old_values AS (
        SELECT price as oldprice, stockquantity as oldstock
        FROM products
        WHERE productid = @ProductId
    )
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', p.price, @Price, p.stockquantity, @StockQuantity, NOW()
    FROM (SELECT price, stockquantity FROM products WHERE productid = @ProductId) p;
COMMIT;

-- Wait, this won't work because by the time the INSERT runs, the UPDATE already changed the values.
-- We need a different approach. Let me restructure.

-- =====================================================
-- Statement 4 (REVISED): UpdateProductAsync (Converted to PostgreSQL)
-- Approach: Read old values in a subquery for the INSERT BEFORE the UPDATE
-- Actually, we'll reorder: first insert history with old values from subquery, then update
-- =====================================================

-- (See converted_statements_final section below for the actual implementation)

-- =====================================================
-- FINAL CONVERTED STATEMENTS (used in code)
-- =====================================================

-- STATEMENT 3 FINAL: InsertProductAsync
-- BEGIN;
--     INSERT INTO products (name, description, price, stockquantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity);
--     INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--     VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
--     UPDATE productstats SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = NOW() WHERE statid = 1;
-- COMMIT;
-- SELECT lastval();

-- STATEMENT 4 FINAL: UpdateProductAsync
-- BEGIN;
--     INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--     SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW() FROM products WHERE productid = @ProductId;
--     UPDATE products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId;
--     UPDATE productstats SET averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts, lastupdated = NOW() WHERE statid = 1;
-- COMMIT;
-- NOTE: History INSERT must come BEFORE the UPDATE to capture old values

-- STATEMENT 5 FINAL: DeleteProductAsync
-- BEGIN;
--     INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--     SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW() FROM products WHERE productid = @ProductId;
--     DELETE FROM products WHERE productid = @ProductId;
--     UPDATE productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1) ELSE 0 END, lastupdated = NOW() WHERE statid = 1;
-- COMMIT;

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted to PostgreSQL)
-- Changes: Lowercase schema objects
-- =====================================================
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

-- =====================================================
-- Statement 7: GetLowStockProductsAsync (Converted to PostgreSQL)
-- Changes: Lowercase schema objects, cast to numeric for ROUND
-- =====================================================
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
