-- ================================================================================
-- CONVERTED SQL STATEMENTS (MS SQL Server to PostgreSQL)
-- ================================================================================
-- Conversion Date: 2025-02-22
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Total Statements: 7
-- Note: ALL statements were processed through DMS MCP tool first but failed
--       with metadata model creation errors. Manual conversion applied with
--       lowercase schema mapping rules for PostgreSQL compatibility.
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GET_ALL_PRODUCTS (PostgreSQL)
-- ================================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Table names to lowercase: Products -> products
--   - Column names to lowercase: ProductId -> productid, Name -> name, etc.
--   - No syntax changes needed (CTE, window functions, CASE compatible)
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 2: GET_BY_ID (PostgreSQL)
-- ================================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Table names to lowercase: Products -> products
--   - Column names to lowercase: ProductId -> productid, Price -> price, etc.
--   - LAG function compatible with PostgreSQL
--   - Parameter placeholder @ProductId compatible with Npgsql
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 3: INSERT_PRODUCT (PostgreSQL)
-- ================================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Removed DECLARE (PostgreSQL uses DO block or handles inline)
--   - Removed BEGIN TRANSACTION/COMMIT (handled in code layer)
--   - SCOPE_IDENTITY() -> RETURNING productid
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - Table/column names to lowercase
--   - Combined INSERT statements with RETURNING clause
-- ================================================================================

WITH inserted_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid, price, stockquantity
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, price, NULL, stockquantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING productid
),
stats_update AS (
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + (SELECT price FROM inserted_product)) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1
    RETURNING statid
)
SELECT productid FROM inserted_product;

-- ================================================================================
-- STATEMENT 4: UPDATE_PRODUCT (PostgreSQL)
-- ================================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Removed BEGIN TRANSACTION/COMMIT (handled in code layer)
--   - Store old values using WITH clause instead of DECLARE
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - Table/column names to lowercase
-- ================================================================================

WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
product_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, CURRENT_TIMESTAMP
    FROM old_values
    RETURNING productid
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 5: DELETE_PRODUCT (PostgreSQL)
-- ================================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Removed BEGIN TRANSACTION/COMMIT (handled in code layer)
--   - Store old values using WITH clause instead of DECLARE
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - Table/column names to lowercase
-- ================================================================================

WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, CURRENT_TIMESTAMP
    FROM old_values
    RETURNING productid
),
product_delete AS (
    DELETE FROM products 
    WHERE productid = @ProductId
    RETURNING productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 6: GET_PRODUCTS_BY_PRICE_RANGE (PostgreSQL)
-- ================================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Table/column names to lowercase
--   - RANK() and PERCENT_RANK() compatible with PostgreSQL
--   - BETWEEN operator compatible
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 7: GET_LOW_STOCK_PRODUCTS (PostgreSQL)
-- ================================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Changes Applied:
--   - Table/column names to lowercase
--   - Window functions AVG/MIN/MAX compatible with PostgreSQL
--   - CASE statement compatible
-- ================================================================================

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

-- ================================================================================
-- CONVERSION SUMMARY
-- ================================================================================
-- Total Statements Converted: 7
-- DMS Successful: 0
-- DMS Failed (Manual Conversion): 7
-- Key PostgreSQL Transformations Applied:
--   1. All table names converted to lowercase
--   2. All column names converted to lowercase
--   3. SCOPE_IDENTITY() replaced with RETURNING clause
--   4. GETDATE() replaced with CURRENT_TIMESTAMP
--   5. BEGIN TRANSACTION/COMMIT removed (handled at code layer)
--   6. DECLARE statements replaced with CTE (WITH clauses)
--   7. Window functions (LAG, RANK, PERCENT_RANK, AVG, COUNT, MIN, MAX) - compatible
--   8. CASE statements - compatible
--   9. Parameter placeholders (@ParameterName) - compatible with Npgsql
-- ================================================================================
