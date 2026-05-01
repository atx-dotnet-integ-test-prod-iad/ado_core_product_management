-- =============================================
-- Converted SQL Statements for PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Unknown metadata model creation status: RECEIVED
-- Schema Mapping (from DMS schema_mapping_tool):
--   dbo.Products -> productmanagement_dbo.products (lowercase columns)
--   dbo.ProductHistory -> productmanagement_dbo.producthistory (lowercase columns)
--   dbo.ProductStats -> productmanagement_dbo.productstats (lowercase columns)
-- Note: For C# code integration, schema prefix productmanagement_dbo is used
-- =============================================

-- =============================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Conversion: CTE alias renamed to lowercase, table/column names lowercase
-- GETDATE() not present, ROUND compatible, CASE compatible
-- =============================================
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

-- =============================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Conversion: LAG window function compatible, lowercase names
-- =============================================
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

-- =============================================
-- Statement 3: InsertProductAsync (Converted)
-- Conversion: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(),
--   DECLARE/SET removed, BEGIN TRANSACTION -> BEGIN, uses RETURNING clause
-- =============================================
BEGIN;
    -- Insert the new product and get the new ID
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- =============================================
-- Statement 4: UpdateProductAsync (Converted)
-- Conversion: DECLARE removed (handled in app code), GETDATE() -> NOW()
-- =============================================
BEGIN;
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- =============================================
-- Statement 5: DeleteProductAsync (Converted)
-- Conversion: DECLARE removed (handled in app code), GETDATE() -> NOW()
-- =============================================
BEGIN;
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- =============================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Conversion: RANK/PERCENT_RANK compatible, lowercase names
-- =============================================
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

-- =============================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Conversion: AVG/MIN/MAX window functions compatible, ROUND needs NUMERIC cast
-- =============================================
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
    ROUND((stockquantity::NUMERIC / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
