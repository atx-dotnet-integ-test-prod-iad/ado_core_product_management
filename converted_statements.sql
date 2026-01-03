-- ==================================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Tool: AWS DMS MCP Tool + Manual Conversion
-- Target Schema: productmanagement_dbo
-- Total Statements: 7
-- ==================================================================================

-- ==================================================================================
-- STATEMENT ID: 1
-- Source Method: GetAllProductsAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS
-- Description: CTE with window functions (AVG OVER, COUNT OVER, CASE statements)
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
-- STATEMENT ID: 2
-- Source Method: GetProductByIdAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS
-- Parameters: @ProductId
-- Description: CTE with LAG window function for historical price tracking
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
-- STATEMENT ID: 3
-- Source Method: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - "Statement definition is not valid"
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Description: Multi-statement transaction with RETURNING clause
-- Notes: DMS failed to convert. Manual conversion splits into separate statements
--        with transaction management handled in C# ADO.NET code level.
--        Using RETURNING clause instead of SCOPE_IDENTITY()
-- ==================================================================================

-- INSERT statement with RETURNING (replaces SCOPE_IDENTITY):
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING productid;

-- History logging (separate statement, executed with returned productid as @NewProductId):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statistics update (separate statement):
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT ID: 4
-- Source Method: UpdateProductAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS (with warning about transaction management)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Description: Multi-statement transaction with variable storage for history
-- Notes: DMS converted with warning. DECLARE/BEGIN/END will be removed in C# integration.
--        Variables (@OldPrice, @OldStock) will be retrieved in C# code first.
-- ==================================================================================

-- Get old values first (executed as separate SELECT in C#):
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update the product:
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Log the changes (using @OldPrice and @OldStock from C# variables):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics:
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT ID: 5
-- Source Method: DeleteProductAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS (with warning about transaction management)
-- Parameters: @ProductId
-- Description: Multi-statement transaction with deletion and statistics update
-- Notes: DMS converted with warning. DECLARE/BEGIN/END will be removed in C# integration.
--        Variables (@OldPrice, @OldStock) will be retrieved in C# code first.
-- ==================================================================================

-- Get old values first (executed as separate SELECT in C#):
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Log the deletion (using @OldPrice and @OldStock from C# variables):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product:
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update product statistics:
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ==================================================================================
-- STATEMENT ID: 6
-- Source Method: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS
-- Parameters: @MinPrice, @MaxPrice
-- Description: CTE with RANK() and PERCENT_RANK() window functions
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
-- STATEMENT ID: 7
-- Source Method: GetLowStockProductsAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS
-- Parameters: @Threshold
-- Description: CTE with multiple aggregate window functions (AVG, MIN, MAX OVER)
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
-- CONVERSION NOTES
-- ==================================================================================
-- 
-- KEY TRANSFORMATIONS:
-- 1. Schema: All tables now use productmanagement_dbo schema prefix
-- 2. Identifiers: All converted to lowercase (PostgreSQL convention)
-- 3. Date Functions: GETDATE() → CURRENT_TIMESTAMP or clock_timestamp()
-- 4. Identity: SCOPE_IDENTITY() → RETURNING clause
-- 5. Transactions: BEGIN TRANSACTION/COMMIT managed in C# ADO.NET code
-- 6. Variables: T-SQL DECLARE @var moved to C# code for multi-statement blocks
-- 7. NULL Handling: ORDER BY enhanced with NULLS FIRST
-- 8. Window Functions: All window functions (LAG, RANK, PERCENT_RANK, AVG/MIN/MAX OVER) 
--    are compatible and retained
-- 
-- PARAMETER BINDING:
-- - All @Parameter syntax retained (compatible with Npgsql)
-- - No changes needed for parameter binding in C# code
-- 
-- TRANSACTION MANAGEMENT:
-- - Statements 3, 4, 5 require transaction management in C# using NpgsqlTransaction
-- - Begin transaction in C# before executing statement sequence
-- - Commit or rollback based on execution success
-- 
-- ==================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ==================================================================================
