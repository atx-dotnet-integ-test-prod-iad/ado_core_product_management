-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Equivalents
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Used:
--   dbo.Products -> productmanagement_dbo.products (all lowercase columns)
--   dbo.ProductHistory -> productmanagement_dbo.producthistory (all lowercase columns)
--   dbo.ProductStats -> productmanagement_dbo.productstats (all lowercase columns)
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Original: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
-- Changes: Table/column names to lowercase, schema prefix added
-- ============================================================================
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

-- ============================================================================
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Original: CTE with LAG window function, LEFT JOIN, CASE, ROUND
-- Changes: Table/column names to lowercase, schema prefix added
-- ============================================================================
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

-- ============================================================================
-- Statement 3: InsertProductAsync (CONVERTED)
-- Original: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
-- Changes: SCOPE_IDENTITY() -> lastval(), GETDATE() -> NOW(), 
--          BEGIN TRANSACTION -> BEGIN, lowercase names, schema prefix
-- ============================================================================
BEGIN;
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- ============================================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
-- Changes: Used subqueries instead of DECLARE/SET variables,
--          GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, lowercase names
-- ============================================================================
BEGIN;
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', 
        (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId),
        @Price,
        (SELECT stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId),
        @StockQuantity, NOW());
    
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - 
            (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId) 
            + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE
-- Changes: Used subqueries instead of DECLARE/SET variables,
--          GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, lowercase names
-- ============================================================================
BEGIN;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM productmanagement_dbo.products WHERE productid = @ProductId;
    
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - 
                (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId)) 
                / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original: CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE
-- Changes: Table/column names to lowercase, schema prefix added
-- ============================================================================
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

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: Table/column names to lowercase, schema prefix added,
--          CAST added for integer division
-- ============================================================================
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
