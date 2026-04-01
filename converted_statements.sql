-- ============================================================================
-- Converted SQL Statements for PostgreSQL
-- Converted from: Microsoft SQL Server (MSSQL)
-- Target: PostgreSQL
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed for all 7 statements
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync - CTE with ProductStats
-- Source Method: GetAllProductsAsync()
-- Source File: DataAccess/ProductRepository.cs
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
-- Statement 2: GetProductByIdAsync - CTE with ProductHistory
-- Source Method: GetProductByIdAsync(int productId)
-- Source File: DataAccess/ProductRepository.cs
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
-- Statement 3: InsertProductAsync - Transaction block with currval/now()
-- Source Method: InsertProductAsync(Product product)
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Notes: SCOPE_IDENTITY() -> currval('products_productid_seq'),
--   GETDATE() -> now(), BEGIN TRANSACTION -> BEGIN,
--   DECLARE/SET removed (using currval for sequence-based identity)
-- ============================================================================
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@name, @description, @price, @stockquantity);
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (currval('products_productid_seq'), 'INSERT', NULL, @price, NULL, @stockquantity, now());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
        lastupdated = now()
    WHERE statid = 1;
COMMIT;

SELECT currval('products_productid_seq');

-- ============================================================================
-- Statement 4: UpdateProductAsync - Transaction block with now()
-- Source Method: UpdateProductAsync(Product product)
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Notes: GETDATE() -> now(), DECLARE @var removed,
--   Reordered to capture old values before update via INSERT...SELECT and
--   subqueries reading current values before UPDATE modifies them.
-- ============================================================================
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @productid, 'UPDATE', price, @price, stockquantity, @stockquantity, now()
    FROM products WHERE productid = @productid;
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @productid) + @price) / totalproducts,
        lastupdated = now()
    WHERE statid = 1;
    
    UPDATE products
    SET 
        name = @name,
        description = @description,
        price = @price,
        stockquantity = @stockquantity,
        modifieddate = now()
    WHERE productid = @productid;
COMMIT;

-- ============================================================================
-- Statement 5: DeleteProductAsync - Transaction block with now()
-- Source Method: DeleteProductAsync(int productId)
-- Source File: DataAccess/ProductRepository.cs
-- Conversion Notes: GETDATE() -> now(), DECLARE @var removed,
--   Reordered to capture old values before delete via INSERT...SELECT and
--   subqueries reading current values before DELETE removes them.
-- ============================================================================
BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @productid, 'DELETE', price, NULL, stockquantity, NULL, now()
    FROM products WHERE productid = @productid;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @productid)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = now()
    WHERE statid = 1;
    
    DELETE FROM products 
    WHERE productid = @productid;
COMMIT;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Source File: DataAccess/ProductRepository.cs
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
-- Statement 7: GetLowStockProductsAsync - CTE with StockAnalysis
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Source File: DataAccess/ProductRepository.cs
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
