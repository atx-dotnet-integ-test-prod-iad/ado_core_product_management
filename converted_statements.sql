-- ============================================================================
-- Converted SQL Statements for PostgreSQL
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Target Database: PostgreSQL 13
-- Schema Mapping: dbo.Products -> productmanagement_dbo.products
--                 dbo.ProductHistory -> productmanagement_dbo.producthistory
--                 dbo.ProductStats -> productmanagement_dbo.productstats
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7)
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================

-- ==========================================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names lowercase, schema prefix productmanagement_dbo
--          CTE name changed to productstats_cte to avoid conflict with table name
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
-- Statement 2: GetProductByIdAsync (Converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names lowercase, schema prefix productmanagement_dbo
--          CTE name changed to producthistory_cte to avoid conflict with table name
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
-- Statement 3: InsertProductAsync (Converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SCOPE_IDENTITY() -> RETURNING productid INTO v_newproductid
--          GETDATE() -> clock_timestamp()
--          BEGIN TRANSACTION/COMMIT -> wrapped in DO $$ BEGIN...END $$
--          DECLARE @NewProductId -> DECLARE v_newproductid INTEGER
--          Table/column names lowercase, schema prefix productmanagement_dbo
-- ==========================================================================
DO $$
DECLARE
    v_newproductid INTEGER;
BEGIN
    -- Insert the new product
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ==========================================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: GETDATE() -> clock_timestamp()
--          BEGIN TRANSACTION/COMMIT -> wrapped in DO $$ BEGIN...END $$
--          DECLARE @OldPrice -> DECLARE v_oldprice NUMERIC(18,2)
--          DECLARE @OldStock -> DECLARE v_oldstock INTEGER
--          SELECT @var = col -> SELECT col INTO v_var
--          Table/column names lowercase, schema prefix productmanagement_dbo
-- ==========================================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ==========================================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: GETDATE() -> clock_timestamp()
--          BEGIN TRANSACTION/COMMIT -> wrapped in DO $$ BEGIN...END $$
--          DECLARE @OldPrice -> DECLARE v_oldprice NUMERIC(18,2)
--          DECLARE @OldStock -> DECLARE v_oldstock INTEGER
--          SELECT @var = col -> SELECT col INTO v_var
--          Table/column names lowercase, schema prefix productmanagement_dbo
-- ==========================================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, clock_timestamp());
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ==========================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names lowercase, schema prefix productmanagement_dbo
--          CTE name lowercase
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
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names lowercase, schema prefix productmanagement_dbo
--          CTE name lowercase
--          Added CAST(stockquantity AS NUMERIC) for integer division fix
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
