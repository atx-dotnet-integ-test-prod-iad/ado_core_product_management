-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Migration: MS SQL Server to PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion/creation timed out for all statements
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
--   dbo.Products -> productmanagement_dbo.products
--   dbo.ProductHistory -> productmanagement_dbo.producthistory
--   dbo.ProductStats -> productmanagement_dbo.productstats
-- ============================================================================

-- ==========================================================================
-- Statement 1: GetAllProductsAsync (Converted to PostgreSQL)
-- Original: CTE with window functions, CASE, ROUND, INNER JOIN
-- Changes: Lowercase table/column names, schema prefix added
-- ==========================================================================
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ==========================================================================
-- Statement 2: GetProductByIdAsync (Converted to PostgreSQL)
-- Original: CTE with LAG window function, CASE NULL handling, LEFT JOIN
-- Changes: Lowercase table/column names, schema prefix added
-- Parameters: @ProductId
-- ==========================================================================
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ==========================================================================
-- Statement 3: InsertProductAsync (Converted to PostgreSQL)
-- Original: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
-- Changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp(),
--          Removed DECLARE/SET, used DO block / CTE approach,
--          Restructured to use RETURNING for new ID
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ==========================================================================
WITH new_product AS (
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_insert AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM new_product
),
update_stats AS (
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- ==========================================================================
-- Statement 4: UpdateProductAsync (Converted to PostgreSQL)
-- Original: Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT, GETDATE()
-- Changes: DECLARE/@variables removed, restructured with CTEs,
--          GETDATE() -> clock_timestamp(), lowercase names
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ==========================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId
),
log_update AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, clock_timestamp()
    FROM old_values ov
)
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ==========================================================================
-- Statement 5: DeleteProductAsync (Converted to PostgreSQL)
-- Original: Transaction block with DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
-- Changes: DECLARE/@variables removed, restructured with CTEs,
--          GETDATE() -> clock_timestamp(), lowercase names
-- Parameters: @ProductId
-- ==========================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
),
log_delete AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, clock_timestamp()
    FROM old_values ov
),
do_delete AS (
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId
)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ==========================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted to PostgreSQL)
-- Original: CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
-- Changes: Lowercase table/column names, schema prefix added
-- Parameters: @MinPrice, @MaxPrice
-- ==========================================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
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

-- ==========================================================================
-- Statement 7: GetLowStockProductsAsync (Converted to PostgreSQL)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: Lowercase table/column names, schema prefix added,
--          Cast integer division to numeric for ROUND
-- Parameters: @Threshold
-- ==========================================================================
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
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
