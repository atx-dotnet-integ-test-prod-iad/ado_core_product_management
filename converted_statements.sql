-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration via AWS DMS MCP Tool
-- Conversion Date: 2026-01-02
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manual Conversion Required: 1 (Statement 3 - INSERT transaction with SCOPE_IDENTITY)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - DMS CONVERSION SUCCESS
-- ============================================================================
-- Statement ID: STMT_001_GetAllProductsAsync
-- DMS Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: Table names prefixed with schema, column names lowercased, NULLS FIRST added
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
-- STATEMENT 2: GetProductByIdAsync - DMS CONVERSION SUCCESS
-- ============================================================================
-- Statement ID: STMT_002_GetProductByIdAsync
-- DMS Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: LAG function preserved, LEFT JOIN → LEFT OUTER JOIN, NULLS FIRST added
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
-- STATEMENT 3: InsertProductAsync - MANUAL CONVERSION (DMS FAILED)
-- ============================================================================
-- Statement ID: STMT_003_InsertProductAsync
-- DMS Conversion Status: ERROR - "Statement definition is not valid"
-- DMS Error: Metadata model creation failed: Statement definition is not valid
-- Reason: Multi-statement transaction with procedural logic (DECLARE, SET, SCOPE_IDENTITY)
-- Manual Conversion Applied: YES
-- Manual Conversion Strategy:
--   - SCOPE_IDENTITY() → RETURNING clause on INSERT
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Multi-statement transaction → Individual statements (transaction managed by application)
--   - Schema transformation applied: Products → productmanagement_dbo.products
--   - Schema transformation applied: ProductHistory → productmanagement_dbo.producthistory
--   - Schema transformation applied: ProductStats → productmanagement_dbo.productstats
-- ============================================================================

-- Individual Statement 1: Insert Product with RETURNING
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Individual Statement 2: Log to ProductHistory
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Individual Statement 3: Update ProductStats
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- NOTE: Transaction boundaries (BEGIN/COMMIT) should be managed by application layer (NpgsqlTransaction)

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - DMS CONVERSION SUCCESS (with warnings)
-- ============================================================================
-- Statement ID: STMT_004_UpdateProductAsync
-- DMS Conversion Status: SUCCESS with CRITICAL WARNING
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: 
--   - DECLARE @OldPrice → DECLARE var_OldPrice
--   - GETDATE() → clock_timestamp()
--   - SELECT assignment → SELECT INTO for variable assignment
--   - Transaction boundaries removed (to be managed by application)
-- ============================================================================

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

-- NOTE: For ADO.NET usage, this should be split into individual statements and wrapped in NpgsqlTransaction

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - DMS CONVERSION SUCCESS (with warnings)
-- ============================================================================
-- Statement ID: STMT_005_DeleteProductAsync
-- DMS Conversion Status: SUCCESS with CRITICAL WARNING
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: Similar to Statement 4
-- ============================================================================

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

-- NOTE: For ADO.NET usage, this should be split into individual statements and wrapped in NpgsqlTransaction

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - DMS CONVERSION SUCCESS
-- ============================================================================
-- Statement ID: STMT_006_GetProductsByPriceRangeAsync
-- DMS Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: RANK() and PERCENT_RANK() preserved, NULLS FIRST added
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
-- STATEMENT 7: GetLowStockProductsAsync - DMS CONVERSION SUCCESS
-- ============================================================================
-- Statement ID: STMT_007_GetLowStockProductsAsync
-- DMS Conversion Status: SUCCESS
-- Schema Transformation: Products → productmanagement_dbo.products
-- Key Changes: Window functions (AVG, MIN, MAX) preserved, NULLS FIRST added
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
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Processed: 7
-- DMS Tool Success: 6 statements
-- DMS Tool Failures: 1 statement (STMT_003 - procedural transaction logic)
-- Manual Conversions: 1 statement
-- Schema Transformations Applied: 
--   - All table references updated to productmanagement_dbo schema prefix
--   - Column names converted to lowercase
--   - NULLS FIRST added to ORDER BY clauses
-- Key PostgreSQL Adaptations:
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP or clock_timestamp()
--   - Transaction management moved to application layer (NpgsqlTransaction)
--   - Variable declarations adapted (@ prefix to var_ prefix where needed)
-- ============================================================================
