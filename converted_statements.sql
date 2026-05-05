-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- All statements converted to PostgreSQL with lowercase schema objects
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync
-- Location: ProductRepository.cs - GetAllProductsAsync method
-- Conversion: CTE with window functions - compatible with PostgreSQL
--   Changes: table/column names to lowercase, ROUND cast to numeric
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
-- Location: ProductRepository.cs - GetProductByIdAsync method
-- Conversion: CTE with LAG window function - compatible with PostgreSQL
--   Changes: table/column names to lowercase, ROUND cast
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
-- Statement 3: InsertProductAsync
-- Location: ProductRepository.cs - InsertProductAsync method
-- Conversion: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(),
--   BEGIN TRANSACTION -> BEGIN, variable elimination with RETURNING
-- ============================================================
BEGIN;
    -- Insert the new product and get the new ID
    WITH new_product AS (
        INSERT INTO products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING productid
    ),
    -- Log the insertion
    log_insert AS (
        INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
        SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
        FROM new_product
    )
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- ============================================================
-- Statement 4: UpdateProductAsync
-- Location: ProductRepository.cs - UpdateProductAsync method
-- Conversion: DECLARE/SET -> subquery, GETDATE() -> NOW(),
--   BEGIN TRANSACTION -> BEGIN
-- ============================================================
BEGIN;
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    -- Log the changes (using subquery for old values)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (SELECT AVG(price) FROM products),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- Statement 5: DeleteProductAsync
-- Location: ProductRepository.cs - DeleteProductAsync method
-- Conversion: DECLARE/SET -> subquery, GETDATE() -> NOW(),
--   BEGIN TRANSACTION -> BEGIN, CASE preserved
-- ============================================================
BEGIN;
    -- Log the deletion (capture values before delete)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (SELECT COALESCE(AVG(price), 0) FROM products)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Location: ProductRepository.cs - GetProductsByPriceRangeAsync method
-- Conversion: RANK/PERCENT_RANK window functions - compatible with PostgreSQL
--   Changes: table/column names to lowercase
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
-- Location: ProductRepository.cs - GetLowStockProductsAsync method
-- Conversion: Window functions - compatible with PostgreSQL
--   Changes: table/column names to lowercase, ROUND with cast
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
