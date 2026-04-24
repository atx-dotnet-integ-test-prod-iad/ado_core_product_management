-- ============================================================
-- CONVERTED SQL STATEMENTS (MS SQL Server -> PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, GetAllProductsAsync method
-- Conversion: ROUND needs explicit cast for numeric division in PostgreSQL
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
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, GetProductByIdAsync method
-- Parameters: @ProductId
-- Conversion: LAG window functions are compatible, ROUND needs numeric types
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
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, InsertProductAsync method
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Conversion: SCOPE_IDENTITY() -> RETURNING + currval, GETDATE() -> NOW(), DECLARE -> DO block not needed, use INSERT RETURNING
-- Note: PostgreSQL does not support SCOPE_IDENTITY() or DECLARE in the same way.
--       This is restructured to use INSERT...RETURNING and separate statements.
-- ============================================================
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid;

    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (currval('products_productid_seq'), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, UpdateProductAsync method
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Conversion: DECLARE variables -> SELECT INTO, GETDATE() -> NOW()
-- ============================================================
BEGIN;
    SELECT price AS oldprice, stockquantity AS oldstock
    INTO TEMPORARY temp_old_values
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
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, NOW()
    FROM temp_old_values;

    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT oldprice FROM temp_old_values) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;

    DROP TABLE IF EXISTS temp_old_values;
COMMIT;

-- ============================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, DeleteProductAsync method
-- Parameters: @ProductId
-- Conversion: DECLARE variables -> SELECT INTO, GETDATE() -> NOW()
-- ============================================================
BEGIN;
    SELECT price AS oldprice, stockquantity AS oldstock
    INTO TEMPORARY temp_old_values
    FROM products
    WHERE productid = @ProductId;

    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, NOW()
    FROM temp_old_values;

    DELETE FROM products 
    WHERE productid = @ProductId;

    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT oldprice FROM temp_old_values)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;

    DROP TABLE IF EXISTS temp_old_values;
COMMIT;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, GetProductsByPriceRangeAsync method
-- Parameters: @MinPrice, @MaxPrice
-- Conversion: RANK() and PERCENT_RANK() are compatible with PostgreSQL
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
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original Location: DataAccess/ProductRepository.cs, GetLowStockProductsAsync method
-- Parameters: @Threshold
-- Conversion: AVG/MIN/MAX OVER() are compatible, ROUND needs numeric types
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
