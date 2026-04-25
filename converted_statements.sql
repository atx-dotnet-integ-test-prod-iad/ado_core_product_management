-- ============================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Target: PostgreSQL (via manual conversion with DMS schema mapping)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool
--   Products -> products (schema: productmanagement_dbo)
--   ProductHistory -> producthistory (schema: productmanagement_dbo)
--   ProductStats -> productstats (schema: productmanagement_dbo)
-- Total Statements: 7
-- ============================================

-- ============================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Changes: Table/column names to lowercase per DMS schema mapping
-- ROUND needs explicit cast for numeric division in PostgreSQL
-- ============================================
WITH productstats_cte AS (
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
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Changes: Table/column names to lowercase, parameter @ProductId preserved for Npgsql
-- ============================================
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

-- ============================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Changes: SCOPE_IDENTITY() -> RETURNING via CTE pattern, GETDATE() -> NOW(), 
--          DECLARE/SET pattern restructured for ADO.NET batch compatibility, lowercase schema
--          BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- ============================================
BEGIN;
    -- Insert the new product and capture the new ID
    WITH new_product AS (
        INSERT INTO products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING productid
    )
    -- Log the insertion using the new product ID
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- ============================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Changes: DECLARE pattern -> subquery approach for ADO.NET compatibility, 
--          GETDATE() -> NOW(), lowercase schema
--          BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- ============================================
BEGIN;
    -- Log the changes (capture old values via subquery)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Update product statistics (capture old price via subquery)
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
COMMIT;

-- ============================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Changes: DECLARE pattern -> subquery approach for ADO.NET compatibility, 
--          GETDATE() -> NOW(), lowercase schema
--          BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- ============================================
BEGIN;
    -- Log the deletion (capture old values via subquery)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Update product statistics (capture old price via subquery before delete)
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
COMMIT;

-- ============================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Changes: Table/column names to lowercase per DMS schema mapping
-- ============================================
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

-- ============================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Changes: Table/column names to lowercase, ROUND with cast for integer division
-- ============================================
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
    ROUND((stockquantity::NUMERIC / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
