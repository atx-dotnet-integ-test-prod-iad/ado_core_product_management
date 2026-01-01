-- ==================================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: AWS DMS MCP Tool
-- ==================================================================================
-- This catalog contains all SQL statements converted from T-SQL to PostgreSQL
-- using the AWS Database Migration Service (DMS) MCP tool.
-- Schema transformed: dbo → productmanagement_dbo
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ==================================================================================
-- Source Method: GetAllProductsAsync()
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Change: Products → productmanagement_dbo.products
-- Key Transformations: CTE name lowercase, column names lowercase, NULLS FIRST added
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- ==================================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Change: Products → productmanagement_dbo.products
-- Key Transformations: LAG function compatible, LEFT JOIN → LEFT OUTER JOIN
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync (MANUAL CONVERSION - DMS FAILED)
-- ==================================================================================
-- Source Method: InsertProductAsync(Product product)
-- Conversion Status: DMS_ERROR - "Statement definition is not valid"
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Multi-statement transactions with DECLARE/SET/SCOPE_IDENTITY not supported
-- Key Transformations: Removed DECLARE/SET, use RETURNING clause for identity
-- Manual Conversion Note: Transactions will be handled at application level in C#
-- ==================================================================================

-- This statement will be handled as multiple statements in C# code with:
-- 1. INSERT with RETURNING clause to get new product ID
-- 2. INSERT into ProductHistory
-- 3. UPDATE ProductStats
-- Transaction management will be at the ADO.NET level using NpgsqlTransaction

INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED WITH WARNINGS)
-- ==================================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Conversion Method: DMS_TOOL
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Key Transformations: GETDATE() → clock_timestamp(), DECLARE with var_ prefix
-- Note: Transaction management removed by DMS, will be handled at application level
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED WITH WARNINGS)
-- ==================================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Conversion Method: DMS_TOOL
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Key Transformations: GETDATE() → clock_timestamp(), transaction removed
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ==================================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Key Transformations: RANK and PERCENT_RANK functions compatible
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- ==================================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Key Transformations: Multiple window functions (AVG, MIN, MAX OVER) compatible
-- ==================================================================================

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

-- ==================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements: 7
-- Successful DMS Conversions: 6
-- Manual Conversions After DMS Failure: 1
-- Statements with DMS Warnings: 2
-- Schema Transformation: dbo → productmanagement_dbo
-- ==================================================================================
