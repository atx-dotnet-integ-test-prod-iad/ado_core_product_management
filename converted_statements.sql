-- ========================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Tool: AWS DMS MCP Tool
-- Total Statements: 7
-- ========================================

-- ========================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ========================================
-- Statement ID: STMT_001
-- Original Statement ID: STMT_001
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notable Changes: Column names converted to lowercase, added NULLS FIRST to ORDER BY
-- ========================================

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

-- ========================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- ========================================
-- Statement ID: STMT_002
-- Original Statement ID: STMT_002
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notable Changes: Column names to lowercase, LEFT JOIN to LEFT OUTER JOIN, lag() function syntax preserved
-- ========================================

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

-- ========================================
-- STATEMENT 3: InsertProductAsync (MANUAL CONVERSION AFTER DMS FAILURE)
-- ========================================
-- Statement ID: STMT_003
-- Original Statement ID: STMT_003
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- Conversion Method: MANUAL (DMS tool returned error: Statement definition is not valid)
-- DMS Error: Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Manual Changes Applied:
--   1. Removed DECLARE @NewProductId and SELECT @NewProductId - replaced with RETURNING clause
--   2. Replaced SCOPE_IDENTITY() with RETURNING productid
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Transaction management handled at application level (removed BEGIN TRANSACTION/COMMIT)
--   5. Split into separate statements for C# ExecuteScalarAsync pattern with RETURNING
-- NOTE: This conversion requires the INSERT to use RETURNING clause and handle as multiple statements in transaction
-- ========================================

-- Insert the new product and return the ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (requires @NewProductId from previous RETURNING)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ========================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED WITH WARNINGS)
-- ========================================
-- Statement ID: STMT_004
-- Original Statement ID: STMT_004
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Conversion Method: DMS_TOOL
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notable Changes: DECLARE to var_ prefix, GETDATE() to clock_timestamp(), transaction management needs manual handling at app level
-- NOTE: Transaction BEGIN/COMMIT must be handled at application level, not in SQL
-- ========================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ========================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED WITH WARNINGS)
-- ========================================
-- Statement ID: STMT_005
-- Original Statement ID: STMT_005
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Conversion Method: DMS_TOOL
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notable Changes: DECLARE to var_ prefix, GETDATE() to clock_timestamp(), CASE expression preserved
-- NOTE: Transaction BEGIN/COMMIT must be handled at application level
-- ========================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END;

-- ========================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ========================================
-- Statement ID: STMT_006
-- Original Statement ID: STMT_006
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notable Changes: Column names to lowercase, RANK() and percent_rank() preserved, NULLS FIRST added
-- ========================================

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

-- ========================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- ========================================
-- Statement ID: STMT_007
-- Original Statement ID: STMT_007
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notable Changes: Column names to lowercase, window functions (AVG, MIN, MAX) preserved, NULLS FIRST added
-- ========================================

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

-- ========================================
-- CONVERSION SUMMARY
-- ========================================
-- Total Statements Processed: 7
-- Successfully Converted by DMS: 6
-- Manual Conversion After DMS Failure: 1 (STMT_003 - InsertProductAsync)
-- Conversions with Warnings: 2 (STMT_004, STMT_005 - transaction management)
--
-- CRITICAL SCHEMA CHANGES (Must be applied in code):
-- - All table references: Products -> productmanagement_dbo.products
-- - All table references: ProductHistory -> productmanagement_dbo.producthistory
-- - All table references: ProductStats -> productmanagement_dbo.productstats
-- - All column names converted to lowercase
--
-- FUNCTION REPLACEMENTS:
-- - GETDATE() -> CURRENT_TIMESTAMP or clock_timestamp()
-- - SCOPE_IDENTITY() -> RETURNING clause
--
-- TRANSACTION HANDLING:
-- - BEGIN TRANSACTION/COMMIT must be handled at C# application level using NpgsqlTransaction
-- - DECLARE blocks for statements 4 and 5 need special handling (DO blocks or stored procedures)
--
-- APPLICATION-LEVEL CHANGES REQUIRED:
-- - InsertProductAsync: Use RETURNING clause, handle multiple statements in transaction
-- - UpdateProductAsync: Execute DECLARE/BEGIN/END as DO block or handle variables in C#
-- - DeleteProductAsync: Execute DECLARE/BEGIN/END as DO block or handle variables in C#
-- ========================================
