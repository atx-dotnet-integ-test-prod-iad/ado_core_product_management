-- ============================================================================
-- Converted SQL Statements Catalog
-- Source File: DataAccess/ProductRepository.cs
-- Total Statements: 9
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model conversion/creation did not complete after 15 attempts
-- DMS Attempt Round 1 Timestamps: 2026-03-21T05:56:14 through 2026-03-21T06:36:58
-- DMS Attempt Round 2 Timestamps: 2026-03-21T07:01:46 through 2026-03-21T07:41:47
-- DMS Attempt Round 3 Timestamps: 2026-03-21T08:07:17 through 2026-03-21T08:45:22
-- DMS Attempt Round 4 Timestamps: 2026-03-21T09:12:57 through 2026-03-21T09:53:00 (all 9 failed)
-- Schema Mappings (Confirmed via DMS Schema Mapping Tool - SUCCESS):
--   [dbo].[Products] -> productmanagement_dbo.products
--   [dbo].[ProductHistory] -> productmanagement_dbo.producthistory
--   [dbo].[ProductStats] -> productmanagement_dbo.productstats
-- Function Mappings:
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING productid
--   DECLARE @var -> DO $$ DECLARE var_xxx
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with AVG/COUNT window functions
-- DMS Conversion Round 1: FAILED (timestamp: 2026-03-21T05:56:14 - 2026-03-21T05:59:00)
-- DMS Conversion Round 2: FAILED (timestamp: 2026-03-21T07:01:46 - 2026-03-21T07:04:32)
-- DMS Conversion Round 3: FAILED (timestamp: 2026-03-21T08:07:17 - 2026-03-21T08:12:13)
-- DMS Conversion Round 4: FAILED (timestamp: 2026-03-21T09:12:57 - 2026-03-21T09:15:43)
-- DMS Error: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
-- Manual Conversion: Applied lowercase schema mapping with DMS-confirmed schema names
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG window function and LEFT JOIN
-- DMS Conversion Round 1: FAILED (timestamp: 2026-03-21T05:59:01 - 2026-03-21T06:03:35)
-- DMS Conversion Round 2: FAILED (timestamp: 2026-03-21T07:04:43 - 2026-03-21T07:09:28)
-- DMS Conversion Round 3: FAILED (timestamp: 2026-03-21T08:12:37 - 2026-03-21T08:15:12)
-- DMS Conversion Round 4: FAILED (timestamp: 2026-03-21T09:15:54 - 2026-03-21T09:20:50)
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Manual Conversion: Applied lowercase schema mapping with DMS-confirmed schema names
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
-- STATEMENT 3: InsertProductAsync (insertSql) - INSERT with RETURNING
-- DMS Conversion Round 1: FAILED (timestamp: 2026-03-21T06:03:36 - 2026-03-21T06:08:21)
-- DMS Conversion Round 2: FAILED (timestamp: 2026-03-21T07:09:37 - 2026-03-21T07:14:22)
-- DMS Conversion Round 3: FAILED (timestamp: 2026-03-21T08:15:21 - 2026-03-21T08:17:56)
-- DMS Conversion Round 4: FAILED (timestamp: 2026-03-21T09:20:59 - 2026-03-21T09:25:55)
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Manual Conversion: SCOPE_IDENTITY() -> RETURNING productid
-- ============================================================================
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================================
-- STATEMENT 4: InsertProductAsync (historySql) - INSERT into ProductHistory
-- DMS Conversion Round 1: FAILED (timestamp: 2026-03-21T06:08:38 - 2026-03-21T06:13:02)
-- DMS Conversion Round 2: FAILED (timestamp: 2026-03-21T07:14:33 - 2026-03-21T07:19:18)
-- DMS Conversion Round 3: FAILED (timestamp: 2026-03-21T08:18:05 - 2026-03-21T08:20:40)
-- DMS Conversion Round 4: FAILED (timestamp: 2026-03-21T09:26:00 - timeout after 300s)
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- Manual Conversion: GETDATE() -> clock_timestamp()
-- ============================================================================
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- ============================================================================
-- STATEMENT 5: InsertProductAsync (statsSql) - UPDATE ProductStats
-- DMS Conversion Round 1: FAILED (timestamp: 2026-03-21T06:13:03 - 2026-03-21T06:17:59)
-- DMS Conversion Round 2: FAILED (timestamp: 2026-03-21T07:19:28 - 2026-03-21T07:24:24)
-- DMS Conversion Round 3: FAILED (timestamp: 2026-03-21T08:20:49 - 2026-03-21T08:25:13)
-- DMS Conversion Round 4: FAILED (timestamp: 2026-03-21T09:31:00 - timeout after 300s)
-- DMS Error: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
-- Manual Conversion: GETDATE() -> clock_timestamp()
-- ============================================================================
UPDATE productmanagement_dbo.productstats
SET
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: UpdateProductAsync - Multi-statement DO block
-- DMS Conversion Round 1: FAILED (timestamp: 2026-03-21T06:17:59 - 2026-03-21T06:22:44)
-- DMS Conversion Round 2: FAILED (timestamp: 2026-03-21T07:24:35 - 2026-03-21T07:29:09)
-- DMS Conversion Round 3: FAILED (timestamp: 2026-03-21T08:25:24 - 2026-03-21T08:30:09)
-- DMS Conversion Round 4: FAILED (timestamp: 2026-03-21T09:36:00 - timeout after 300s)
-- DMS Error: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
-- Manual Conversion: DECLARE @var -> DO $ DECLARE var_xxx, GETDATE() -> clock_timestamp()
-- ============================================================================
DO $
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
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
END $;

-- ============================================================================
-- STATEMENT 7: DeleteProductAsync - Multi-statement DO block
-- DMS Conversion Round 1: FAILED (timestamp: 2026-03-21T06:23:04 - 2026-03-21T06:27:27)
-- DMS Conversion Round 2: FAILED (timestamp: 2026-03-21T07:29:21 - 2026-03-21T07:34:05)
-- DMS Conversion Round 3: FAILED (timestamp: 2026-03-21T08:30:19 - 2026-03-21T08:35:15)
-- DMS Conversion Round 4: FAILED (timestamp: 2026-03-21T09:41:32 - 2026-03-21T09:44:07)
-- DMS Error: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
-- Manual Conversion: DECLARE @var -> DO $ DECLARE var_xxx, GETDATE() -> clock_timestamp()
-- ============================================================================
DO $
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
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
END $$;

-- ============================================================================
-- STATEMENT 8: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- DMS Conversion Round 1: FAILED (timestamp: 2026-03-21T06:27:28 - 2026-03-21T06:32:12)
-- DMS Conversion Round 2: FAILED (timestamp: 2026-03-21T07:34:16 - 2026-03-21T07:39:01)
-- DMS Conversion Round 3: FAILED (timestamp: 2026-03-21T08:35:26 - 2026-03-21T08:40:11)
-- DMS Conversion Round 4: FAILED (timestamp: 2026-03-21T09:44:18 - 2026-03-21T09:48:09)
-- DMS Error: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
-- Manual Conversion: Applied lowercase schema mapping with DMS-confirmed schema names
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
-- STATEMENT 9: GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions
-- DMS Conversion Round 1: FAILED (timestamp: 2026-03-21T06:32:13 - 2026-03-21T06:36:58)
-- DMS Conversion Round 2: FAILED (timestamp: 2026-03-21T07:39:12 - 2026-03-21T07:41:47)
-- DMS Conversion Round 3: FAILED (timestamp: 2026-03-21T08:40:26 - 2026-03-21T08:45:22)
-- DMS Conversion Round 4: FAILED (timestamp: 2026-03-21T09:48:18 - timeout after 300s)
-- DMS Error: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
-- Manual Conversion: Applied lowercase schema mapping with DMS-confirmed schema names
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
-- END OF CONVERTED STATEMENTS CATALOG
-- Total: 9 SQL statements converted (all via manual conversion after DMS failure)
-- DMS Tool Status: All 9 attempts failed across 4 rounds (36 total attempts)
-- Manual Conversion Applied: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
