-- ============================================================================
-- CONVERTED SQL STATEMENTS (MS SQL Server → PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mappings from DMS schema_mapping_tool:
--   Products → productmanagement_dbo.products (lowercase columns)
--   ProductHistory → productmanagement_dbo.producthistory (lowercase columns)
--   ProductStats → productmanagement_dbo.productstats (lowercase columns)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Original: CTE with AVG/COUNT OVER, CASE, ROUND, INNER JOIN
-- Changes: Table/column names lowercased per DMS schema mapping
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
-- Original: CTE with LAG, LEFT JOIN, CASE with ROUND
-- Changes: Table/column names lowercased per DMS schema mapping
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
-- Original: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE()
-- Changes: SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), lowercased schema,
--          Restructured to use RETURNING clause instead of SCOPE_IDENTITY()
-- ============================================================================

INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================================
-- STATEMENT 3b: InsertProductAsync - ProductHistory INSERT (CONVERTED)
-- This is executed separately after getting the new product ID
-- ============================================================================

INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- ============================================================================
-- STATEMENT 3c: InsertProductAsync - ProductStats UPDATE (CONVERTED)
-- ============================================================================

UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Original: BEGIN TRANSACTION with DECLARE, SELECT into vars, UPDATE, INSERT, UPDATE
-- Changes: GETDATE() → NOW(), lowercased schema, restructured for PostgreSQL
-- ============================================================================

BEGIN;
    SELECT price, stockquantity
    INTO TEMP oldvals
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
    VALUES (@ProductId, 'UPDATE', (SELECT price FROM oldvals), @Price, (SELECT stockquantity FROM oldvals), @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM oldvals) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
    
    DROP TABLE IF EXISTS oldvals;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Original: BEGIN TRANSACTION with DECLARE, SELECT into vars, INSERT, DELETE, UPDATE with CASE
-- Changes: GETDATE() → NOW(), lowercased schema, restructured for PostgreSQL
-- ============================================================================

BEGIN;
    SELECT price, stockquantity
    INTO TEMP oldvals
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', (SELECT price FROM oldvals), NULL, (SELECT stockquantity FROM oldvals), NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM oldvals)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
    
    DROP TABLE IF EXISTS oldvals;
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original: CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE
-- Changes: Table/column names lowercased per DMS schema mapping
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
-- Original: CTE with AVG/MIN/MAX OVER, CASE, ROUND
-- Changes: Table/column names lowercased per DMS schema mapping,
--          Cast to numeric for ROUND compatibility
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
    ROUND((CAST(stockquantity AS numeric) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
