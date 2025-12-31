-- ========================================================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration for AdoCore
-- ========================================================================================================
-- This catalog contains all SQL statements converted to PostgreSQL through the DMS MCP tool
-- Each statement includes metadata about the conversion process and resulting PostgreSQL syntax
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - SUCCESSFULLY CONVERTED
-- ========================================================================================================
-- Conversion Method: DMS MCP Tool
-- Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: Lowercase column/table names, NULLS FIRST added to ORDER BY
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync - SUCCESSFULLY CONVERTED
-- ========================================================================================================
-- Conversion Method: DMS MCP Tool
-- Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: Lowercase column/table names, LEFT JOIN → LEFT OUTER JOIN, lag() function lowercase
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync - MANUAL CONVERSION AFTER DMS FAILURE
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS FAILED - "Statement definition is not valid"
-- DMS Error: Metadata model creation failed: {'error': "Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}"}
-- Schema Transformation: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Key Changes:
--   1. SCOPE_IDENTITY() converted to RETURNING clause in INSERT statement
--   2. GETDATE() converted to CURRENT_TIMESTAMP
--   3. BEGIN TRANSACTION/COMMIT converted to PostgreSQL transaction syntax
--   4. Variable declarations removed (using RETURNING directly)
--   5. Multi-statement transaction converted to DO block
-- ========================================================================================================

DO $$
DECLARE
    v_newproductid INT;
BEGIN
    -- Insert the new product and get the ID
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product ID
    -- Note: In ADO.NET implementation, this will need to be retrieved differently
    -- Consider using RETURNING clause in the INSERT or a separate SELECT
END $$;

-- Alternative implementation for ADO.NET (recommended):
-- Use INSERT with RETURNING clause directly in C# code:
-- INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity)
-- RETURNING productid;

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - SUCCESSFULLY CONVERTED WITH WARNINGS
-- ========================================================================================================
-- Conversion Method: DMS MCP Tool
-- Conversion Status: SUCCESS (with transaction warning)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Transformation: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Key Changes:
--   1. DECLARE @Variable → DECLARE var_Variable
--   2. GETDATE() → clock_timestamp()
--   3. Variable type DECIMAL(18,2) → NUMERIC(18, 2), INT → INTEGER
--   4. Transaction management converted
-- ========================================================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION;
    */
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

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync - SUCCESSFULLY CONVERTED WITH WARNINGS
-- ========================================================================================================
-- Conversion Method: DMS MCP Tool
-- Conversion Status: SUCCESS (with transaction warning)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Transformation: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Key Changes:
--   1. DECLARE @Variable → DECLARE var_Variable
--   2. GETDATE() → clock_timestamp()
--   3. Variable type DECIMAL(18,2) → NUMERIC(18, 2), INT → INTEGER
--   4. CASE expression maintained (compatible)
-- ========================================================================================================

DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION;
    */
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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - SUCCESSFULLY CONVERTED
-- ========================================================================================================
-- Conversion Method: DMS MCP Tool
-- Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: Lowercase column/table names, NULLS FIRST added to ORDER BY, percent_rank() function lowercase
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - SUCCESSFULLY CONVERTED
-- ========================================================================================================
-- Conversion Method: DMS MCP Tool
-- Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: Lowercase column/table names, NULLS FIRST added to ORDER BY, window functions (AVG, MIN, MAX OVER) lowercase
-- ========================================================================================================

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

-- ========================================================================================================
-- CONVERSION SUMMARY
-- ========================================================================================================
-- Total Statements Processed: 7
-- Successfully Converted by DMS: 6
-- Manual Conversions Required: 1 (Statement 3 - InsertProductAsync)
-- Statements with Warnings: 2 (Statements 4, 5 - Transaction management warnings)
--
-- Key Schema Transformations by DMS:
--   - Products → productmanagement_dbo.products
--   - ProductHistory → productmanagement_dbo.producthistory
--   - ProductStats → productmanagement_dbo.productstats
--   - All column names converted to lowercase
--   - All table names converted to lowercase
--
-- PostgreSQL Specific Changes:
--   - GETDATE() → clock_timestamp() or CURRENT_TIMESTAMP
--   - SCOPE_IDENTITY() → RETURNING clause
--   - DECLARE @Variable → DECLARE var_Variable (when needed)
--   - DECIMAL(18,2) → NUMERIC(18, 2)
--   - INT → INTEGER
--   - Added NULLS FIRST to ORDER BY clauses
--   - LEFT JOIN → LEFT OUTER JOIN
--   - Transaction blocks need manual handling in ADO.NET code
--
-- ========================================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ========================================================================================================
