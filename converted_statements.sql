-- =====================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion did not complete after multiple attempts (timeout)
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync (Converted to PostgreSQL)
-- Conversion Notes:
--   - Table/column names converted to lowercase
--   - ROUND function: PostgreSQL requires numeric types; cast to numeric for division
--   - CTE and window functions (AVG OVER, COUNT OVER) are compatible with PostgreSQL
-- =====================================================
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

-- =====================================================
-- Statement 2: GetProductByIdAsync (Converted to PostgreSQL)
-- Conversion Notes:
--   - Table/column names converted to lowercase
--   - LAG() OVER window function is compatible with PostgreSQL
--   - ROUND function works the same in PostgreSQL
--   - Parameter @ProductId kept as @ProductId (Npgsql supports this syntax)
-- =====================================================
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

-- =====================================================
-- Statement 3: InsertProductAsync (Converted to PostgreSQL)
-- Conversion Notes:
--   - SCOPE_IDENTITY() replaced with INSERT...RETURNING pattern
--   - GETDATE() -> NOW()
--   - Transaction block restructured: uses multi-statement batch with 
--     INSERT...RETURNING to capture new ID, then uses lastval() for subsequent inserts
--   - Cannot use DO $$ block because parameters are bound via Npgsql
--   - Restructured to avoid DECLARE variables (not available in plain SQL batch)
-- =====================================================
BEGIN;
    -- Insert the new product and return new ID
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    -- Log the insertion (use lastval() to get the auto-generated ID)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- =====================================================
-- Statement 4: UpdateProductAsync (Converted to PostgreSQL)
-- Conversion Notes:
--   - DECLARE @OldPrice/OldStock removed - log old values BEFORE update using subquery
--   - GETDATE() -> NOW()
--   - BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
--   - Reordered: insert history BEFORE update to capture old values
-- =====================================================
BEGIN;
    -- Log the changes (capture old values before update)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products
    WHERE productid = @ProductId;
    
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
        averageprice = (SELECT AVG(price) FROM products),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- =====================================================
-- Statement 5: DeleteProductAsync (Converted to PostgreSQL)
-- Conversion Notes:
--   - DECLARE @OldPrice/OldStock removed - use subqueries and CTEs
--   - GETDATE() -> NOW()
--   - Reordered: log deletion BEFORE deleting (to capture old values)
--   - CASE expression works the same in PostgreSQL
-- =====================================================
BEGIN;
    -- Log the deletion (before deleting, to capture old values)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products
    WHERE productid = @ProductId;
    
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

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted to PostgreSQL)
-- Conversion Notes:
--   - RANK() OVER and PERCENT_RANK() OVER are compatible with PostgreSQL
--   - BETWEEN works the same
--   - Table/column names converted to lowercase
-- =====================================================
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

-- =====================================================
-- Statement 7: GetLowStockProductsAsync (Converted to PostgreSQL)
-- Conversion Notes:
--   - AVG/MIN/MAX OVER() window functions are compatible with PostgreSQL
--   - ROUND works the same but needs cast for integer division (::numeric)
--   - Table/column names converted to lowercase
-- =====================================================
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
