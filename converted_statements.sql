-- ============================================
-- CONVERTED SQL STATEMENTS FROM MS SQL SERVER TO POSTGRESQL
-- Target Database: PostgreSQL 13
-- Conversion Date: 2024-12-29
-- Conversion Method: AWS DMS MCP Tool + Manual Conversion
-- ============================================

-- --------------------------------------------
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Changes: Added NULLS FIRST to ORDER BY, lowercase identifiers
-- --------------------------------------------
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

-- --------------------------------------------
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Changes: LAG function syntax preserved, lowercase identifiers, LEFT JOIN → LEFT OUTER JOIN
-- --------------------------------------------
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

-- --------------------------------------------
-- STATEMENT 3: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: MANUAL CONVERSION
-- DMS Error: "Statement definition is not valid" - Complex transaction with SCOPE_IDENTITY()
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- Key Changes: 
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → NOW()
--   - Variable declarations for PostgreSQL
--   - BEGIN TRANSACTION/COMMIT removed (handled at application level)
--   - Multiple statements restructured for PostgreSQL
-- --------------------------------------------
-- Note: This requires breaking into multiple ADO.NET commands in the application
-- Command 1: Insert product and return ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Command 2: Log the insertion (using returned ID as @NewProductId)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Command 3: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- --------------------------------------------
-- STATEMENT 4: UpdateProductAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS_WITH_WARNINGS
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- Key Changes: 
--   - GETDATE() → clock_timestamp()
--   - Variable names: @OldPrice → var_OldPrice, @OldStock → var_OldStock
--   - DECIMAL(18,2) → NUMERIC(18, 2)
--   - INT → INTEGER
--   - Transaction management removed
-- Note: Transaction handling moved to application level (ExecuteInTransactionAsync)
-- --------------------------------------------
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    -- Store old values for history
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- --------------------------------------------
-- STATEMENT 5: DeleteProductAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS_WITH_WARNINGS
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- Key Changes: Similar to UpdateProductAsync
-- Note: Transaction handling moved to application level
-- --------------------------------------------
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    -- Store product info for history
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;

-- --------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Changes: RANK() and PERCENT_RANK() syntax preserved, NULLS FIRST added
-- --------------------------------------------
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

-- --------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Changes: Window function syntax preserved, lowercase identifiers
-- --------------------------------------------
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

-- ============================================
-- CONVERSION SUMMARY
-- ============================================
-- Total Statements: 7
-- DMS Tool Success: 6
-- Manual Conversion: 1 (Statement 3)
-- DMS Tool Warnings: 2 (Statements 4 & 5 - Transaction management)
-- 
-- Schema Transformation: dbo.Products → productmanagement_dbo.products
-- 
-- Key PostgreSQL Transformations:
-- 1. GETDATE() → NOW() or clock_timestamp()
-- 2. SCOPE_IDENTITY() → RETURNING clause
-- 3. BEGIN TRANSACTION/COMMIT → Application-level transaction management
-- 4. Column/table names → lowercase
-- 5. ORDER BY → Added NULLS FIRST for PostgreSQL null handling
-- 6. LEFT JOIN → LEFT OUTER JOIN
-- 7. DECIMAL → NUMERIC
-- 8. INT → INTEGER
-- 9. Variable names: @ prefix compatible with Npgsql
-- ============================================
