-- =============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source Application: AdoCore (.NET 9.0 Console Application)
-- Conversion Date: 2024-12-27
-- DMS MCP Tool Used: dms-mcp____statement_conversion_tool
-- Total Statements Converted: 7 (6 attempted through DMS, 1 failed)
-- =============================================================================

-- =============================================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync
-- =============================================================================
-- Source Method: GetAllProductsAsync()
-- Conversion Status: SUCCESS via DMS Tool
-- DMS Schema Mapping: Products → productmanagement_dbo.products
-- Key Changes: Column names to lowercase, schema prefix added, NULLS FIRST added to ORDER BY
-- =============================================================================

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

-- =============================================================================
-- CONVERTED STATEMENT 2: GetProductByIdAsync
-- =============================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion Status: SUCCESS via DMS Tool
-- DMS Schema Mapping: Products → productmanagement_dbo.products
-- Key Changes: Column names to lowercase, schema prefix added, LEFT JOIN → LEFT OUTER JOIN
-- =============================================================================

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

-- =============================================================================
-- CONVERTED STATEMENT 3: InsertProductAsync
-- =============================================================================
-- Source Method: InsertProductAsync(Product product)
-- Conversion Status: FAILED via DMS Tool - Manual conversion applied
-- DMS Error: "Statement definition is not valid"
-- Reason: DMS cannot handle multi-statement transaction blocks with SCOPE_IDENTITY
-- Manual Conversion Applied: Transaction handling managed at ADO.NET level, 
--                           SCOPE_IDENTITY() replaced with RETURNING clause
-- =============================================================================

-- Note: For ADO.NET execution, this will be split into separate commands:
-- 1. INSERT with RETURNING to get new ID
-- 2. INSERT into ProductHistory
-- 3. UPDATE ProductStats
-- Transaction managed by NpgsqlTransaction in C# code

-- INSERT statement with RETURNING:
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (executed after getting the returned ID):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (executed as part of same transaction):
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =============================================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync
-- =============================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Conversion Status: SUCCESS with WARNING via DMS Tool
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in functions]
-- DMS Schema Mapping: Products → productmanagement_dbo.products
--                    ProductHistory → productmanagement_dbo.producthistory
--                    ProductStats → productmanagement_dbo.productstats
-- Key Changes: GETDATE() → clock_timestamp(), column names to lowercase, 
--             DECLARE/BEGIN/END wrapper removed (not needed for ADO.NET execution)
-- Manual Adjustment: Removed DECLARE/BEGIN/END wrapper for ADO.NET context
-- =============================================================================

-- Store old values for history
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =============================================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync
-- =============================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Conversion Status: SUCCESS with WARNING via DMS Tool
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in functions]
-- DMS Schema Mapping: Products → productmanagement_dbo.products
--                    ProductHistory → productmanagement_dbo.producthistory
--                    ProductStats → productmanagement_dbo.productstats
-- Key Changes: GETDATE() → clock_timestamp(), column names to lowercase
-- Manual Adjustment: Removed DECLARE/BEGIN/END wrapper for ADO.NET context
-- =============================================================================

-- Store product info for history
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =============================================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync
-- =============================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: SUCCESS via DMS Tool
-- DMS Schema Mapping: Products → productmanagement_dbo.products
-- Key Changes: Column names to lowercase, schema prefix added, NULLS FIRST added to ORDER BY
-- =============================================================================

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

-- =============================================================================
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync
-- =============================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion Status: SUCCESS via DMS Tool
-- DMS Schema Mapping: Products → productmanagement_dbo.products
-- Key Changes: Column names to lowercase, schema prefix added, NULLS FIRST added to ORDER BY
-- =============================================================================

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

-- =============================================================================
-- CONVERSION SUMMARY
-- =============================================================================
-- Total SQL Statements Processed: 7
-- Successfully Converted by DMS: 6
-- Failed DMS Conversion (Manual Applied): 1
-- Statements with DMS Warnings: 2 (Statements 4, 5 - transaction management)
--
-- Key Schema Changes by DMS:
-- - Table: Products → productmanagement_dbo.products
-- - Table: ProductHistory → productmanagement_dbo.producthistory
-- - Table: ProductStats → productmanagement_dbo.productstats
-- - All column names converted to lowercase
-- - Schema prefix 'productmanagement_dbo' added to all table references
--
-- Key PostgreSQL Conversions:
-- - GETDATE() → CURRENT_TIMESTAMP or clock_timestamp()
-- - SCOPE_IDENTITY() → RETURNING clause
-- - ORDER BY with NULLS FIRST added where appropriate
-- - LEFT JOIN → LEFT OUTER JOIN
-- - Transaction management moved to ADO.NET level (NpgsqlTransaction)
--
-- NOTE: Transaction blocks (Statements 3, 4, 5) will be managed at the 
--       ADO.NET level using NpgsqlTransaction, not within SQL statements.
-- =============================================================================
