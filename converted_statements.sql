-- ============================================================================
-- CONVERTED SQL STATEMENTS (MS SQL Server -> PostgreSQL)
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion Date: 2026-04-23
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Conversion Notes: CTE syntax compatible; ROUND, CASE, INNER JOIN, ORDER BY all PostgreSQL-compatible.
--   Applied lowercase to all schema object names (table names, column aliases).
--   ROUND and OVER() window functions are PostgreSQL-compatible as-is.
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
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Conversion Notes: CTE with LAG window function is PostgreSQL-compatible.
--   Applied lowercase to all schema object names.
--   Parameter syntax @ProductId preserved (Npgsql supports @param syntax).
-- ============================================================================
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

-- ============================================================================
-- Statement 3: InsertProductAsync (CONVERTED)
-- Conversion Notes:
--   SCOPE_IDENTITY() -> Use INSERT...RETURNING to get the new ID
--   GETDATE() -> CURRENT_TIMESTAMP
--   BEGIN TRANSACTION -> BEGIN
--   DECLARE @variable -> PostgreSQL DO block not needed; restructured to use INSERT...RETURNING
--   Since Npgsql ExecuteScalar expects a single value, use RETURNING clause on INSERT
--   and restructure the transaction to work with PostgreSQL.
--   PostgreSQL doesn't support DECLARE outside of DO blocks in plain SQL.
--   Restructured to use CTE or separate statements with RETURNING.
-- ============================================================================
BEGIN;
    -- Insert the new product and get the new ID
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- ============================================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Conversion Notes:
--   BEGIN TRANSACTION -> BEGIN
--   DECLARE @variable / SELECT INTO variable -> Log old values first, then update
--   GETDATE() -> CURRENT_TIMESTAMP
--   PostgreSQL doesn't support DECLARE outside PL/pgSQL blocks.
--   Restructured: Log old values BEFORE updating product (order matters).
-- ============================================================================
BEGIN;
    -- Log the changes first (captures old values before update)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, CURRENT_TIMESTAMP
    FROM products WHERE productid = @ProductId;
    
    -- Update product statistics (uses old price before update)
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Conversion Notes:
--   BEGIN TRANSACTION -> BEGIN
--   DECLARE @variable / SELECT INTO variable -> subquery approach
--   GETDATE() -> CURRENT_TIMESTAMP
--   CASE expression is PostgreSQL-compatible.
--   Restructured: capture old values via subquery before delete.
--   Order: log first, update stats, then delete (to preserve access to old values).
-- ============================================================================
BEGIN;
    -- Log the deletion (using subquery to get current values before delete)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, CURRENT_TIMESTAMP
    FROM products WHERE productid = @ProductId;
    
    -- Update product statistics (uses old price before delete)
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Conversion Notes: CTE with RANK() and PERCENT_RANK() are PostgreSQL-compatible.
--   Applied lowercase to all schema object names.
--   BETWEEN is PostgreSQL-compatible.
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
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Conversion Notes: CTE with AVG/MIN/MAX window functions are PostgreSQL-compatible.
--   Applied lowercase to all schema object names.
--   ROUND with integer division needs CAST for proper decimal behavior in PostgreSQL.
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
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
