-- ============================================================================
-- CONVERTED SQL STATEMENTS (PostgreSQL)
-- Migration: Microsoft SQL Server to PostgreSQL
-- Conversion Method: DMS MCP Tool + Manual Conversion
-- Total Statements: 7
-- Date: 2026-01-04
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Change: Products → productmanagement_dbo.products
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
-- Schema Change: Products → productmanagement_dbo.products
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
-- Status: SUCCESS (Manual Conversion)
-- DMS Error: Statement definition is not valid - multi-statement transaction not supported
-- Schema Change: Products → productmanagement_dbo.products
-- Note: Transaction management handled at application level (ExecuteInTransactionAsync)
--       SCOPE_IDENTITY() converted to RETURNING clause
--       GETDATE() converted to CURRENT_TIMESTAMP
-- ============================================================================
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING productid;

-- Note: The following statements would be executed separately in the same transaction:

-- INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- UPDATE productmanagement_dbo.productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = CURRENT_TIMESTAMP
-- WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS_WITH_WARNINGS
-- Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Schema Change: Products → productmanagement_dbo.products
-- Note: Transaction management handled at application level
--       GETDATE() converted to clock_timestamp()
-- ============================================================================
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
        WHERE statid = 1;
END $$;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS_WITH_WARNINGS
-- Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Schema Change: Products → productmanagement_dbo.products
-- Note: Transaction management handled at application level
--       GETDATE() converted to clock_timestamp()
-- ============================================================================
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, CURRENT_TIMESTAMP);
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = CURRENT_TIMESTAMP
        WHERE statid = 1;
END $$;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Change: Products → productmanagement_dbo.products
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
-- Schema Change: Products → productmanagement_dbo.products
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
-- Total: 7 SQL statements converted
-- Successful DMS conversions: 6
-- Manual conversions after DMS failure: 1
-- ============================================================================
