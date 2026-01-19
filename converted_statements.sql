-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Migration: Microsoft SQL Server to PostgreSQL using AWS DMS
-- Conversion Date: 2026-01-19
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manual Conversion After DMS Failure: 1
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: MANUAL CONVERSION REQUIRED
-- DMS Error: Statement definition is not valid
-- Notes: DMS could not parse multi-statement transaction with SCOPE_IDENTITY()
--        Manual conversion using PostgreSQL RETURNING clause for identity
-- Schema Transformation: Products → productmanagement_dbo.products
--                        ProductHistory → productmanagement_dbo.producthistory
--                        ProductStats → productmanagement_dbo.productstats
-- ============================================================================

INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The INSERT into ProductHistory and UPDATE of ProductStats will be
-- handled in application code using the returned productid from RETURNING clause.
-- This is the recommended PostgreSQL pattern for handling SCOPE_IDENTITY() scenarios.
-- Full transaction in Npgsql code will be:
-- BEGIN;
--   INSERT INTO products RETURNING productid;
--   INSERT INTO producthistory VALUES (returned_id, ...);
--   UPDATE productstats WHERE statid = 1;
-- COMMIT;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS_WITH_WARNING
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management 
--              commands such as BEGIN TRAN, SAVE TRAN in functions
-- Notes: Transaction management will be handled at application level with Npgsql
-- Schema Transformation: Products → productmanagement_dbo.products
--                        ProductHistory → productmanagement_dbo.producthistory
--                        ProductStats → productmanagement_dbo.productstats
-- ============================================================================

-- Variables declaration (for PL/pgSQL block if needed)
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity
        INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS_WITH_WARNING
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management 
--              commands such as BEGIN TRAN, SAVE TRAN in functions
-- Notes: Transaction management will be handled at application level with Npgsql
-- Schema Transformation: Products → productmanagement_dbo.products
--                        ProductHistory → productmanagement_dbo.producthistory
--                        ProductStats → productmanagement_dbo.productstats
-- ============================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity
        INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());
    
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- ============================================================================

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

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- Summary:
-- - All column names converted to lowercase (PostgreSQL convention)
-- - All table names prefixed with schema: productmanagement_dbo
-- - GETDATE() converted to clock_timestamp()
-- - LAG, RANK, PERCENT_RANK window functions preserved
-- - CASE expressions preserved
-- - ROUND function preserved
-- - ORDER BY clauses have NULLS FIRST added (PostgreSQL explicit handling)
-- - Transaction management moved to application layer (Npgsql)
-- - SCOPE_IDENTITY() replaced with RETURNING clause pattern
-- - DECLARE variable syntax converted to PostgreSQL format
-- ============================================================================
