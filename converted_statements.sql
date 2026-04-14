-- ============================================================
-- Converted SQL Statements for PostgreSQL
-- Source: ProductRepository.cs (originally MS SQL Server)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Conversion Date: 2026-04-14
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Conversion: Lowercase table/column names per DMS schema mapping
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Conversion: Lowercase table/column names, LAG preserved (PostgreSQL compatible)
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
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Conversion: SCOPE_IDENTITY() -> lastval(), GETDATE() -> clock_timestamp(),
--             Lowercase table/column names, PostgreSQL DO block for variables
-- ============================================================
DO $$
DECLARE newproductid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    newproductid := lastval();
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

SELECT lastval();

-- ============================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Conversion: GETDATE() -> clock_timestamp(), Lowercase table/column names,
--             PostgreSQL DO block for variables
-- ============================================================
DO $$
DECLARE oldprice NUMERIC(18,2);
DECLARE oldstock INTEGER;
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
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, clock_timestamp());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - oldprice + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Conversion: GETDATE() -> clock_timestamp(), Lowercase table/column names,
--             PostgreSQL DO block for variables
-- ============================================================
DO $$
DECLARE oldprice NUMERIC(18,2);
DECLARE oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO oldprice, oldstock
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, clock_timestamp());
    
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
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Conversion: Lowercase table/column names, RANK/PERCENT_RANK preserved (PostgreSQL compatible)
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
-- Conversion: Lowercase table/column names, ROUND with cast for integer division
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
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
