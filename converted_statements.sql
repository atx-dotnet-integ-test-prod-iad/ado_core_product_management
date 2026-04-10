-- Converted SQL Statements for PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Schema mapping: dbo -> productmanagement_dbo (from DMS schema_mapping_tool)
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Total: 7 SQL Statements

-- ========================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- ========================================
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

-- ========================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- ========================================
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @productid;

-- ========================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- ========================================
BEGIN;
    -- Insert the new product and get the new id
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@name, @description, @price, @stockquantity)
    RETURNING productid;

-- Note: The RETURNING clause replaces SCOPE_IDENTITY()
-- The subsequent INSERT INTO producthistory and UPDATE productstats 
-- must be handled in application code after retrieving the new productid

-- ========================================
-- Statement 3b: InsertProductAsync - Log insertion (PostgreSQL)
-- ========================================
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@newproductid, 'INSERT', NULL, @price, NULL, @stockquantity, clock_timestamp());

-- ========================================
-- Statement 3c: InsertProductAsync - Update stats (PostgreSQL)
-- ========================================
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

-- ========================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- ========================================
BEGIN;
    -- Store old values for history (using subselect in PostgreSQL)
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        name = @name,
        description = @description,
        price = @price,
        stockquantity = @stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = @productid;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@productid, 'UPDATE', @oldprice, @price, @oldstock, @stockquantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - @oldprice + @price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

-- ========================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- ========================================
BEGIN;
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@productid, 'DELETE', @oldprice, NULL, @oldstock, NULL, clock_timestamp());
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @productid;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - @oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

-- ========================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- ========================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
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

-- ========================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- ========================================
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
        WHEN stockquantity <= @threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND(CAST(stockquantity AS NUMERIC) / avgstock * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @threshold
ORDER BY stockquantity;
