-- ============================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Equivalents
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Tool: AWS DMS MCP (6 success, 1 manual)
-- Target Schema: productmanagement_dbo
-- Conversion Date: 2026-03-05
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (DMS_TOOL - SUCCESS)
-- DMS Model: sql-conversion-1772740644
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
-- Statement 2: GetProductByIdAsync (DMS_TOOL - SUCCESS)
-- DMS Model: sql-conversion-1772740738
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
-- Statement 3: InsertProductAsync (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
-- DMS Error: "Metadata model creation failed: Statement definition is not valid."
-- DMS cannot process complex transaction blocks with DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY as a single statement.
-- Manual conversion using CTE chain with RETURNING clause, lowercase schema, productmanagement_dbo prefix
-- ============================================================
WITH new_product AS (
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_insertion AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM new_product
),
update_stats AS (
    UPDATE productmanagement_dbo.productstats
    SET
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- ============================================================
-- Statement 4: UpdateProductAsync (DMS_TOOL - SUCCESS with warning)
-- DMS Model: sql-conversion-1772740855
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit
-- transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.]
-- Restructured as CTE chain for ADO.NET inline execution
-- ============================================================
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
    WHERE productid = @ProductId
    RETURNING productid
),
log_changes AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, clock_timestamp()
    FROM old_values ov
)
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts, lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync (DMS_TOOL - SUCCESS with warning)
-- DMS Model: sql-conversion-1772740944
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit
-- transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.]
-- Restructured as CTE chain for ADO.NET inline execution
-- ============================================================
WITH old_values AS (
    SELECT price AS oldprice, stockquantity AS oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
),
log_deletion AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, clock_timestamp()
    FROM old_values ov
),
do_delete AS (
    DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId
    RETURNING productid
)
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
    ELSE 0
END, lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (DMS_TOOL - SUCCESS)
-- DMS Model: sql-conversion-1772741035
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
-- Statement 7: GetLowStockProductsAsync (DMS_TOOL - SUCCESS)
-- DMS Model: sql-conversion-1772741128
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
