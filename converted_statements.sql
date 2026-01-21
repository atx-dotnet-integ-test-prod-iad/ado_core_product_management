-- ============================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Total Statements: 7
-- Conversion Method: DMS MCP Tool + Manual for Statement 3
-- Schema Transformation: Products → productmanagement_dbo.products
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Key Changes: Lowercase identifiers, schema prefix, NULLS FIRST in ORDER BY
-- ============================================================

WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Key Changes: Lowercase identifiers, schema prefix, LEFT OUTER JOIN, lag() function
-- ============================================================

WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- ============================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: DMS FAILED - Manual conversion applied
-- DMS Error: "Statement definition is not valid" for multi-statement transaction with DECLARE before BEGIN
-- Key Changes: Use RETURNING clause instead of SCOPE_IDENTITY(), NOW() for timestamps, restructured transaction
-- Note: This requires application-level transaction handling or PostgreSQL DO block
-- ============================================================

-- Option 1: Simplified for ADO.NET usage (requires transaction managed by application)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements would be executed separately within the application transaction:
-- INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
-- 
-- UPDATE productmanagement_dbo.productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS with WARNING
-- DMS Warning: PostgreSQL does not support explicit transaction management in functions
-- Key Changes: DECLARE syntax, NUMERIC type, clock_timestamp(), schema prefix
-- Note: BEGIN TRANSACTION commented out by DMS - transaction managed at application level
-- ============================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS with WARNING
-- DMS Warning: PostgreSQL does not support explicit transaction management in functions
-- Key Changes: DECLARE syntax, NUMERIC type, clock_timestamp(), schema prefix
-- Note: BEGIN TRANSACTION commented out by DMS - transaction managed at application level
-- ============================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Key Changes: Lowercase identifiers, schema prefix, percent_rank() function, NULLS FIRST
-- ============================================================

WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Key Changes: Lowercase identifiers, schema prefix, window functions, NULLS FIRST
-- ============================================================

WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

-- ============================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================

-- CRITICAL SCHEMA CHANGES APPLIED BY DMS:
-- 1. Table "Products" → "productmanagement_dbo.products"
-- 2. Table "ProductHistory" → "productmanagement_dbo.producthistory"  
-- 3. Table "ProductStats" → "productmanagement_dbo.productstats"
-- 4. All identifiers converted to lowercase
-- 5. ORDER BY clauses include NULLS FIRST
-- 6. GETDATE() → clock_timestamp() or NOW()
-- 7. DECIMAL(18,2) → NUMERIC(18,2)
-- 8. Transaction management moved to application level for Statements 4-5
-- 9. SCOPE_IDENTITY() → RETURNING clause for Statement 3
