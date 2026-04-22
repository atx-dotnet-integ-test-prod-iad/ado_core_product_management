-- ============================================================
-- Converted SQL Statements for PostgreSQL (from MS SQL Server)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool
--   dbo.Products -> productmanagement_dbo.products (columns lowercased)
--   dbo.ProductHistory -> productmanagement_dbo.producthistory (columns lowercased)
--   dbo.ProductStats -> productmanagement_dbo.productstats (columns lowercased)
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync - CTE with window functions
-- Location: ProductRepository.cs, GetAllProductsAsync() method
-- Conversion Notes: 
--   - Table/column names lowercased per schema mapping
--   - ROUND function compatible with PostgreSQL
--   - CTE syntax compatible with PostgreSQL
--   - CASE expressions compatible with PostgreSQL
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync - CTE with LAG window function
-- Location: ProductRepository.cs, GetProductByIdAsync() method
-- Conversion Notes:
--   - Table/column names lowercased per schema mapping
--   - LAG window function compatible with PostgreSQL
--   - ROUND function compatible with PostgreSQL
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync - Transaction with RETURNING/NOW()
-- Location: ProductRepository.cs, InsertProductAsync() method
-- Conversion Notes:
--   - SCOPE_IDENTITY() replaced with INSERT ... RETURNING productid
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION/COMMIT replaced with BEGIN/COMMIT
--   - DECLARE @variable removed (use subquery or RETURNING approach)
--   - Restructured to use CTE with INSERT RETURNING for new product id
-- ============================================================
WITH new_product AS (
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
insert_history AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
),
update_stats AS (
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- ============================================================
-- Statement 4: UpdateProductAsync - Transaction with NOW()
-- Location: ProductRepository.cs, UpdateProductAsync() method
-- Conversion Notes:
--   - DECLARE @variable replaced with CTE subquery
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION/COMMIT replaced with BEGIN/COMMIT
--   - Restructured to use CTEs for old values capture
-- ============================================================
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
        modifieddate = NOW()
    WHERE productid = @ProductId
),
insert_history AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, NOW()
    FROM old_values
)
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync - Transaction with NOW()
-- Location: ProductRepository.cs, DeleteProductAsync() method
-- Conversion Notes:
--   - DECLARE @variable replaced with CTE subquery
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION/COMMIT replaced with BEGIN/COMMIT
--   - Restructured to use CTEs for old values capture
-- ============================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
),
insert_history AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, NOW()
    FROM old_values
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
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- Location: ProductRepository.cs, GetProductsByPriceRangeAsync() method
-- Conversion Notes:
--   - Table/column names lowercased per schema mapping
--   - RANK() and PERCENT_RANK() compatible with PostgreSQL
--   - BETWEEN compatible with PostgreSQL
-- ============================================================
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

-- ============================================================
-- Statement 7: GetLowStockProductsAsync - CTE with window aggregates
-- Location: ProductRepository.cs, GetLowStockProductsAsync() method
-- Conversion Notes:
--   - Table/column names lowercased per schema mapping
--   - Window functions (AVG, MIN, MAX OVER()) compatible with PostgreSQL
--   - ROUND function compatible with PostgreSQL
--   - Integer division needs CAST for PostgreSQL
-- ============================================================
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
