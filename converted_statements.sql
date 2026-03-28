-- ============================================================================
-- Converted SQL Statements (MS SQL Server → PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion did not complete after max attempts (timeout)
-- Schema Mapping Reference: DMS schema_mapping_tool (successful) provided target schema
--   Products → products (schema: productmanagement_dbo, columns: productid, name, description, price, stockquantity, createddate, modifieddate)
--   ProductHistory → producthistory (schema: productmanagement_dbo, columns: historyid, productid, action, oldprice, newprice, oldstock, newstock, actiondate, modifiedby)
--   ProductStats → productstats (schema: productmanagement_dbo, columns: statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (Converted to PostgreSQL)
-- Original: CTE with ProductStats, AVG/COUNT OVER, CASE, ROUND, INNER JOIN
-- Changes: Table/column names to lowercase per DMS schema mapping
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
-- Statement 2: GetProductByIdAsync (Converted to PostgreSQL)
-- Original: CTE with ProductHistory, LAG OVER, CASE, ROUND, LEFT JOIN
-- Changes: Table/column names to lowercase per DMS schema mapping
-- Parameters: @ProductId (Npgsql supports @param syntax)
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
-- Statement 3: InsertProductAsync (Converted to PostgreSQL)
-- Original: Multi-statement transaction with DECLARE, SCOPE_IDENTITY(), GETDATE()
-- Changes: SCOPE_IDENTITY() → currval(pg_get_serial_sequence('products','productid')),
--          GETDATE() → NOW(), BEGIN TRANSACTION → BEGIN,
--          table/column names to lowercase
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Note: Uses currval() after INSERT to get the auto-generated ID.
--       The INSERT triggers the sequence, then currval() retrieves it.
-- ============================================================================
BEGIN;
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    -- Log the insertion (using currval for the auto-generated id)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (currval(pg_get_serial_sequence('products','productid')), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('products','productid'));

-- ============================================================================
-- Statement 4: UpdateProductAsync (Converted to PostgreSQL)
-- Original: Multi-statement transaction with DECLARE, SELECT INTO variables,
--           UPDATE Products, INSERT ProductHistory, UPDATE ProductStats, GETDATE()
-- Changes: Restructured to log history BEFORE update (to capture old values
--          via subquery), GETDATE() → NOW(), table/column names to lowercase
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================================
BEGIN;
    -- Log the changes BEFORE update (capture old values via subquery)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (SELECT COALESCE(AVG(price), 0) FROM products),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- Statement 5: DeleteProductAsync (Converted to PostgreSQL)
-- Original: Multi-statement transaction with DECLARE, SELECT INTO variables,
--           INSERT ProductHistory, DELETE, UPDATE ProductStats with CASE, GETDATE()
-- Changes: Restructured with subqueries, GETDATE() → NOW(),
--          table/column names to lowercase
-- Parameters: @ProductId
-- ============================================================================
BEGIN;
    -- Log the deletion (capture current values before delete)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products WHERE productid = @ProductId;
    
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

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted to PostgreSQL)
-- Original: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
-- Changes: Table/column names to lowercase
-- Parameters: @MinPrice, @MaxPrice
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
-- Statement 7: GetLowStockProductsAsync (Converted to PostgreSQL)
-- Original: CTE with AVG/MIN/MAX OVER, CASE, ROUND
-- Changes: Table/column names to lowercase, CAST for integer division
-- Parameters: @Threshold
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
