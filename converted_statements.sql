-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed for all 7 statements
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
--   Products -> products (schema: productmanagement_dbo)
--   ProductHistory -> producthistory (schema: productmanagement_dbo)
--   ProductStats -> productstats (schema: productmanagement_dbo)
-- Key Conversions:
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING clause
--   DECLARE @var -> DO $$ block or subquery restructuring
--   All table/column names -> lowercase per DMS schema mapping
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Changes: Table/column names to lowercase per DMS schema mapping
-- ============================================================================
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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Changes: Table/column names to lowercase per DMS schema mapping
-- ============================================================================
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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp(),
--          DECLARE/SET removed, restructured with RETURNING and subqueries,
--          Table/column names to lowercase per DMS schema mapping
-- ============================================================================
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM new_product
),
update_stats AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Changes: DECLARE removed, GETDATE() -> clock_timestamp(), restructured with
--          subqueries and CTEs, Table/column names to lowercase per DMS schema mapping
-- ============================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, clock_timestamp()
    FROM old_values
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Changes: DECLARE removed, GETDATE() -> clock_timestamp(), restructured with
--          CTEs, Table/column names to lowercase per DMS schema mapping
-- ============================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, clock_timestamp()
    FROM old_values
),
do_delete AS (
    DELETE FROM products 
    WHERE productid = @ProductId
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Changes: Table/column names to lowercase per DMS schema mapping
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Changes: Table/column names to lowercase per DMS schema mapping,
--          ROUND with integer division fix (cast to numeric)
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
