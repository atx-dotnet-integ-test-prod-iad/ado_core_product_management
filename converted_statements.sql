-- ===================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Source: extracted_statements.sql
-- Conversion Method: DMS MCP Tool + Manual (where DMS failed)
-- Target Schema: productmanagement_dbo (DMS renamed from dbo)
-- Total Statements: 7
-- ===================================================================

-- ===================================================================
-- STATEMENT 1: GetAllProductsAsync - DMS TOOL SUCCESS
-- Schema Change: Products -> productmanagement_dbo.products
-- ===================================================================
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

-- ===================================================================
-- STATEMENT 2: GetProductByIdAsync - DMS TOOL SUCCESS
-- Schema Change: Products -> productmanagement_dbo.products
-- Note: LAG function converted successfully
-- ===================================================================
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

-- ===================================================================
-- STATEMENT 3: InsertProductAsync - MANUAL AFTER DMS FAILURE
-- DMS Error: Statement definition is not valid (transaction syntax)
-- Manual Conversion: Removed DECLARE/BEGIN TRANSACTION, use RETURNING for SCOPE_IDENTITY
-- Schema Changes: Products -> productmanagement_dbo.products
--                 ProductHistory -> productmanagement_dbo.producthistory
--                 ProductStats -> productmanagement_dbo.productstats
-- Note: Transactions handled at ADO.NET level, not in SQL
-- ===================================================================
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log insertion (separate command after capturing returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Update statistics (separate command)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ===================================================================
-- STATEMENT 4: UpdateProductAsync - DMS TOOL WITH WARNINGS
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management
-- Schema Changes: All tables prefixed with productmanagement_dbo
-- Note: GETDATE() -> clock_timestamp(), transaction handled at ADO.NET level
-- ===================================================================
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
END;

-- ===================================================================
-- STATEMENT 5: DeleteProductAsync - DMS TOOL WITH WARNINGS
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management
-- Schema Changes: All tables prefixed with productmanagement_dbo
-- ===================================================================
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
END;

-- ===================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - DMS TOOL SUCCESS
-- Schema Change: Products -> productmanagement_dbo.products
-- Note: RANK() and PERCENT_RANK() converted successfully
-- ===================================================================
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

-- ===================================================================
-- STATEMENT 7: GetLowStockProductsAsync - DMS TOOL SUCCESS
-- Schema Change: Products -> productmanagement_dbo.products
-- Note: Multiple window functions (AVG, MIN, MAX) converted successfully
-- ===================================================================
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

-- ===================================================================
-- END OF CONVERTED STATEMENTS
-- ===================================================================
