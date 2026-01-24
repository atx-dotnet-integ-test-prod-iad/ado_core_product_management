-- =============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: extracted_statements.sql (MS SQL Server)
-- Converted Using: DMS MCP Tool (dms-mcp____statement_conversion_tool)
-- Target Database: PostgreSQL
-- Target Schema: productmanagement_dbo
-- Total Statements: 7
-- Conversion Date: 2026-01-24
-- =============================================================================

-- =============================================================================
-- STATEMENT BLOCK 1: GetAllProductsAsync
-- =============================================================================
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Metadata Model: sql-conversion-1769281971
-- Source Location: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync
-- Key Conversions: Schema to productmanagement_dbo, lowercase columns, NULLS FIRST in ORDER BY
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
-- STATEMENT BLOCK 2: GetProductByIdAsync
-- =============================================================================
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Metadata Model: sql-conversion-1769281792
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync
-- Key Conversions: Schema to productmanagement_dbo, lowercase columns, LEFT OUTER JOIN
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
-- STATEMENT BLOCK 3: InsertProductAsync
-- =============================================================================
-- Conversion Status: FAILED - MANUAL CONVERSION PROVIDED
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Source Location: DataAccess/ProductRepository.cs, Method: InsertProductAsync
-- DMS Error: Statement definition is not valid (multi-statement batch with DECLARE/BEGIN/SELECT)
-- Key Conversions: SCOPE_IDENTITY() to RETURNING, schema to productmanagement_dbo
-- Note: Transaction management and additional logging must be handled in C# code
-- =============================================================================

-- Simplified INSERT with RETURNING for ADO.NET execution
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Additional statements to be executed within C# transaction:
-- 1. INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
-- 2. UPDATE productmanagement_dbo.productstats
--    SET totalproducts = totalproducts + 1,
--        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--        lastupdated = CURRENT_TIMESTAMP
--    WHERE statid = 1;

-- =============================================================================
-- STATEMENT BLOCK 4: UpdateProductAsync
-- =============================================================================
-- Conversion Status: SUCCESS (with warnings)
-- Conversion Method: DMS_TOOL
-- Metadata Model: sql-conversion-1769282552
-- Source Location: DataAccess/ProductRepository.cs, Method: UpdateProductAsync
-- Warning: Transaction management should be handled in C# code (warning 7807)
-- Key Conversions: GETDATE() to clock_timestamp(), schema to productmanagement_dbo, DECLARE syntax
-- Note: DECLARE/BEGIN/END block unsuitable for ADO.NET - break into separate statements
-- =============================================================================

-- Statement 1: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 2: Update product (execute after retrieving old values in C# code)
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 3: Log changes (execute within same transaction in C# code)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4: Update statistics (execute within same transaction in C# code)
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =============================================================================
-- STATEMENT BLOCK 5: DeleteProductAsync
-- =============================================================================
-- Conversion Status: SUCCESS (with warnings)
-- Conversion Method: DMS_TOOL
-- Metadata Model: sql-conversion-1769282741
-- Source Location: DataAccess/ProductRepository.cs, Method: DeleteProductAsync
-- Warning: Transaction management should be handled in C# code (warning 7807)
-- Key Conversions: GETDATE() to clock_timestamp(), schema to productmanagement_dbo, CASE preserved
-- Note: DECLARE/BEGIN/END block unsuitable for ADO.NET - break into separate statements
-- =============================================================================

-- Statement 1: Get product values before deletion
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 2: Log deletion (execute within transaction in C# code)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 3: Delete product (execute within same transaction in C# code)
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 4: Update statistics (execute within same transaction in C# code)
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =============================================================================
-- STATEMENT BLOCK 6: GetProductsByPriceRangeAsync
-- =============================================================================
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Metadata Model: sql-conversion-1769282159
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Key Conversions: Schema to productmanagement_dbo, lowercase columns, percent_rank() function
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
-- STATEMENT BLOCK 7: GetLowStockProductsAsync
-- =============================================================================
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Metadata Model: sql-conversion-1769282336
-- Source Location: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync
-- Key Conversions: Schema to productmanagement_dbo, lowercase columns, window functions preserved
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
-- END OF CONVERTED SQL STATEMENTS CATALOG
-- =============================================================================
-- Summary:
-- - Total Statements Converted: 7
-- - DMS Tool Successful Conversions: 6
-- - Manual Conversions After DMS Failure: 1
-- - Conversions with Warnings: 2 (transaction management in statements 4 & 5)
-- 
-- Key Schema Transformation:
-- - All table references changed from dbo.TableName to productmanagement_dbo.tablename
-- - This is a DMS-applied schema transformation and MUST be respected in code
-- 
-- Key SQL Server to PostgreSQL Conversions:
-- - SCOPE_IDENTITY() → RETURNING clause
-- - GETDATE() → CURRENT_TIMESTAMP or clock_timestamp()
-- - BEGIN TRANSACTION/COMMIT → Handle in C# code with NpgsqlTransaction
-- - DECLARE variables → Split multi-statement blocks into separate C# executions
-- - Column names → Lowercase
-- - DECIMAL → NUMERIC
-- - INT → INTEGER
-- - Window functions → Syntax preserved (PostgreSQL compatible)
-- - CASE statements → Logic preserved
-- 
-- Implementation Notes:
-- - Transaction blocks (statements 3, 4, 5) must be split into separate SQL statements
-- - Transaction management must be handled in C# code using NpgsqlTransaction
-- - Variable declarations must be replaced with C# variables
-- - Each statement within a transaction should be executed separately within the same transaction
-- =============================================================================
