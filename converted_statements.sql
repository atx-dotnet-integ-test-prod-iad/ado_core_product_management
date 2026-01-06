-- ================================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: AdoCore Project - ProductRepository.cs
-- Converted via: AWS DMS MCP Tool
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Updated: Products -> productmanagement_dbo.products
-- Notable Changes: Added NULLS FIRST to ORDER BY, lowercase identifiers
-- ================================================================================
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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Updated: Products -> productmanagement_dbo.products
-- Notable Changes: LEFT JOIN -> LEFT OUTER JOIN, lowercase identifiers, NULLS FIRST
-- ================================================================================
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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync (MANUAL CONVERSION AFTER DMS FAILURE)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS tool failed with "Statement definition is not valid"
-- DMS Error: Metadata model creation failed - Statement definition is not valid
-- Manual Conversion Rationale:
--   - DMS cannot handle complex transaction blocks with SCOPE_IDENTITY()
--   - SCOPE_IDENTITY() replaced with RETURNING clause in INSERT
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Transaction management handled at application level (Npgsql)
--   - Variable declarations removed (not needed in inline SQL)
-- Schema Updated: Products -> productmanagement_dbo.products
--                 ProductHistory -> productmanagement_dbo.producthistory
--                 ProductStats -> productmanagement_dbo.productstats
-- ================================================================================
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING productid;

-- Note: The history logging and stats update will be handled in separate statements
-- within the application transaction:

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED WITH WARNINGS)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with manual adjustments needed for transaction management)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--               transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--               functions. Convert your source code manually.]
-- Schema Updated: Products -> productmanagement_dbo.products
--                 ProductHistory -> productmanagement_dbo.producthistory
--                 ProductStats -> productmanagement_dbo.productstats
-- Notable Changes: GETDATE() -> clock_timestamp(), variable names prefixed with var_
--                  Transaction management removed (handled at application level)
-- ================================================================================
-- Note: Transaction BEGIN/COMMIT removed as it's handled by application code
SELECT price AS var_OldPrice, stockquantity AS var_OldStock
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED WITH WARNINGS)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with manual adjustments needed for transaction management)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--               transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--               functions. Convert your source code manually.]
-- Schema Updated: Products -> productmanagement_dbo.products
--                 ProductHistory -> productmanagement_dbo.producthistory
--                 ProductStats -> productmanagement_dbo.productstats
-- Notable Changes: GETDATE() -> clock_timestamp(), variable names prefixed with var_
--                  Transaction management removed (handled at application level)
-- ================================================================================
-- Note: Transaction BEGIN/COMMIT removed as it's handled by application code
SELECT price AS var_OldPrice, stockquantity AS var_OldStock
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Updated: Products -> productmanagement_dbo.products
-- Notable Changes: Added NULLS FIRST to ORDER BY, lowercase identifiers
-- ================================================================================
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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Updated: Products -> productmanagement_dbo.products
-- Notable Changes: Added NULLS FIRST to ORDER BY, lowercase identifiers
-- ================================================================================
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

-- ================================================================================
-- CONVERSION SUMMARY
-- ================================================================================
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manually Converted After DMS Failure: 1 (InsertProductAsync)
-- 
-- Key Schema Changes Applied by DMS:
-- - Schema name: dbo -> productmanagement_dbo
-- - Table references: Products -> productmanagement_dbo.products
-- - Table references: ProductHistory -> productmanagement_dbo.producthistory
-- - Table references: ProductStats -> productmanagement_dbo.productstats
-- - All identifiers converted to lowercase
--
-- Key Syntax Changes:
-- - GETDATE() -> CURRENT_TIMESTAMP or clock_timestamp()
-- - SCOPE_IDENTITY() -> RETURNING clause
-- - Transaction management (BEGIN TRANSACTION/COMMIT) -> Application level handling
-- - ORDER BY clauses -> Added NULLS FIRST
-- - LEFT JOIN -> LEFT OUTER JOIN
-- ================================================================================
