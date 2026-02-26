-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Source: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Schema objects converted to lowercase (Products → products, ProductId → productid, etc.)
--   - Window functions (AVG OVER, COUNT OVER) are PostgreSQL compatible
--   - CASE statements are PostgreSQL compatible
--   - ROUND function is PostgreSQL compatible
-- ============================================================================
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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Schema objects converted to lowercase
--   - LAG window function is PostgreSQL compatible
--   - Parameter syntax changed from @ProductId to $1
-- ============================================================================
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = $1
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
WHERE p.productid = $1;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Schema objects converted to lowercase
--   - Removed DECLARE statement (not needed with RETURNING clause)
--   - BEGIN TRANSACTION → BEGIN
--   - COMMIT → COMMIT
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Parameters changed from @Name, @Description, @Price, @StockQuantity to $1, $2, $3, $4
--   - Combined INSERT with RETURNING to get new productid directly
-- ============================================================================
BEGIN;
    -- Insert the new product and return the new ID
    INSERT INTO products (name, description, price, stockquantity)
    VALUES ($1, $2, $3, $4)
    RETURNING productid;
    
    -- Log the insertion (using the returned productid in application code)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES ((SELECT productid FROM products ORDER BY productid DESC LIMIT 1), 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + $3) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Schema objects converted to lowercase
--   - BEGIN TRANSACTION → BEGIN
--   - COMMIT → COMMIT
--   - DECLARE statements removed (use CTEs or subqueries instead)
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Parameters changed from @ProductId, @Name, @Description, @Price, @StockQuantity to $1, $2, $3, $4, $5
-- ============================================================================
BEGIN;
    -- Store old values for history using CTE
    WITH oldvalues AS (
        SELECT price as oldprice, stockquantity as oldstock
        FROM products
        WHERE productid = $1
    )
    -- Update the product
    UPDATE products
    SET 
        name = $2,
        description = $3,
        price = $4,
        stockquantity = $5,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = $1;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT $1, 'UPDATE', oldprice, $4, oldstock, $5, CURRENT_TIMESTAMP
    FROM (
        SELECT price as oldprice, stockquantity as oldstock
        FROM products
        WHERE productid = $1
    ) AS prev;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = $1) + $4) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Schema objects converted to lowercase
--   - BEGIN TRANSACTION → BEGIN
--   - COMMIT → COMMIT
--   - DECLARE statements removed
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Parameter changed from @ProductId to $1
-- ============================================================================
BEGIN;
    -- Store product info for history and log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT $1, 'DELETE', price, NULL, stockquantity, NULL, CURRENT_TIMESTAMP
    FROM products
    WHERE productid = $1;
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = $1;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = $1)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Schema objects converted to lowercase
--   - RANK() and PERCENT_RANK() window functions are PostgreSQL compatible
--   - Parameters changed from @MinPrice, @MaxPrice to $1, $2
-- ============================================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN $1 AND $2
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
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Schema objects converted to lowercase
--   - Aggregate window functions (AVG, MIN, MAX OVER) are PostgreSQL compatible
--   - Parameter changed from @Threshold to $1
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
        WHEN stockquantity <= $1 THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= $1
ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
