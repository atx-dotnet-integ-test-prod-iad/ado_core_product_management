-- Converted SQL Statements (MS SQL Server -> PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- All statements failed DMS conversion due to metadata model creation errors.
-- Manual conversion applied with lowercase schema object naming for PostgreSQL.

-- ============================================================
-- Statement 1: GetAllProductsAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Changes: Schema objects lowercased
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
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Changes: Schema objects lowercased, CTE renamed to avoid conflict with table name
-- ============================================================
WITH producthistory_cte AS (
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
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================
-- Statement 3: InsertProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Changes: SCOPE_IDENTITY() replaced with RETURNING clause via writable CTE,
--          GETDATE() replaced with NOW(), schema objects lowercased,
--          Transaction logic restructured as atomic writable CTE
-- ============================================================
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
    RETURNING productid
),
update_stats AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
    RETURNING statid
)
SELECT productid FROM new_product;

-- ============================================================
-- Statement 4: UpdateProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Changes: DECLARE/SET variables replaced with CTE subquery,
--          GETDATE() replaced with NOW(), schema objects lowercased,
--          Transaction logic restructured as atomic writable CTE
-- ============================================================
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock
    FROM products
    WHERE productid = @ProductId
),
update_product AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId
    RETURNING productid
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, NOW()
    FROM old_values ov
    RETURNING productid
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Changes: DECLARE/SET variables replaced with CTE subquery,
--          GETDATE() replaced with NOW(), schema objects lowercased,
--          Transaction logic restructured as atomic writable CTE
-- ============================================================
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock
    FROM products
    WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, NOW()
    FROM old_values ov
    RETURNING productid
),
delete_product AS (
    DELETE FROM products 
    WHERE productid = @ProductId
    RETURNING productid
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

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Changes: Schema objects lowercased
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
-- Statement 7: GetLowStockProductsAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Changes: Schema objects lowercased, added table alias qualifiers,
--          added ::numeric cast for integer division
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
        WHEN sa.stockquantity <= @Threshold THEN 'Critical'
        WHEN sa.stockquantity <= sa.avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((sa.stockquantity::numeric / sa.avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE sa.stockquantity <= @Threshold
ORDER BY sa.stockquantity;
