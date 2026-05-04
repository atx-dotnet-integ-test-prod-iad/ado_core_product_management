-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- All schema object names converted to lowercase for PostgreSQL compatibility
-- ============================================================================

-- ===========================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs (lines ~47-70)
-- ===========================================
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

-- ===========================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs (lines ~82-108)
-- ===========================================
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

-- ===========================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs (lines ~118-140)
-- Conversion notes: 
--   SCOPE_IDENTITY() -> RETURNING productid (via INSERT...RETURNING)
--   GETDATE() -> NOW()
--   Transaction block restructured for PostgreSQL DO block with variable support
-- ===========================================
DO $$
DECLARE
    newproductid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO newproductid;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- ===========================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs (lines ~155-185)
-- Conversion notes:
--   DECLARE @var -> DO block with DECLARE
--   GETDATE() -> NOW()
--   SELECT INTO variables -> SELECT INTO
-- ===========================================
DO $$
DECLARE
    oldprice DECIMAL(18,2);
    oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO oldprice, oldstock
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
    VALUES (@ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - oldprice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ===========================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs (lines ~196-228)
-- Conversion notes:
--   DECLARE @var -> DO block with DECLARE
--   GETDATE() -> NOW()
-- ===========================================
DO $$
DECLARE
    oldprice DECIMAL(18,2);
    oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO oldprice, oldstock
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ===========================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs (lines ~238-255)
-- ===========================================
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

-- ===========================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original Source: DataAccess/ProductRepository.cs (lines ~270-292)
-- Conversion notes:
--   ROUND with integer division -> ROUND with CAST to ensure decimal division
-- ===========================================
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
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
