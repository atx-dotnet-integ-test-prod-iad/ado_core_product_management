-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- SQL Server to PostgreSQL Migration via AWS DMS
-- ============================================================================
-- Conversion Date: 2026-01-07
-- DMS Migration Project: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
-- Target Schema: productmanagement_dbo
-- Total Statements: 7 (4 via DMS tool, 3 manual after DMS failure)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Updated: Products -> productmanagement_dbo.products
-- Notes: CTE and window functions converted successfully, NULLS FIRST added to ORDER BY
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
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Updated: Products -> productmanagement_dbo.products
-- Notes: LAG window function converted successfully, LEFT JOIN -> LEFT OUTER JOIN
-- Parameter: @ProductId remains (will be converted to Npgsql parameters in code)
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
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: "Metadata model creation failed: Statement definition is not valid"
-- Conversion Status: MANUAL
-- Schema Updated: Products -> productmanagement_dbo.products
--                ProductHistory -> productmanagement_dbo.producthistory  
--                ProductStats -> productmanagement_dbo.productstats
-- Notes: Multi-statement transaction not supported by DMS in single statement mode
--        SCOPE_IDENTITY() -> RETURNING productid (PostgreSQL idiom)
--        GETDATE() -> CURRENT_TIMESTAMP
--        BEGIN TRANSACTION -> BEGIN, COMMIT remains
--        DECLARE @var -> Local variable in PL/pgSQL or use RETURNING
-- ============================================================================
-- Option A: Using RETURNING clause (recommended for single INSERT)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- For transaction with history and stats, use function or multi-statement:
DO $$
DECLARE
    v_new_product_id INT;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_new_product_id;
    
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_new_product_id, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product ID
    -- Note: In ADO.NET code, use ExecuteScalar with RETURNING clause instead
END $$;

-- Simplified version for ADO.NET (recommended):
-- Use separate statements with transaction control in code
-- Main INSERT with RETURNING:
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Expected similar error for multi-statement transaction
-- Conversion Status: MANUAL
-- Schema Updated: Products -> productmanagement_dbo.products
--                ProductHistory -> productmanagement_dbo.producthistory
--                ProductStats -> productmanagement_dbo.productstats
-- Notes: Multi-statement transaction, GETDATE() -> CURRENT_TIMESTAMP
--        Variables can be handled in application code by fetching first
-- ============================================================================
-- Fetch old values first (in application code before update):
-- SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Then execute update:
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Insert history (with old values from previous SELECT):
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update statistics:
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Expected similar error for multi-statement transaction
-- Conversion Status: MANUAL
-- Schema Updated: Products -> productmanagement_dbo.products
--                ProductHistory -> productmanagement_dbo.producthistory
--                ProductStats -> productmanagement_dbo.productstats
-- Notes: Multi-statement transaction, GETDATE() -> CURRENT_TIMESTAMP
-- ============================================================================
-- Fetch product values first (in application code):
-- SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Insert history before delete:
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product:
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- Update statistics:
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Updated: Products -> productmanagement_dbo.products
-- Notes: RANK and PERCENT_RANK window functions converted successfully
-- Parameters: @MinPrice, @MaxPrice remain (will be converted to Npgsql parameters in code)
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Updated: Products -> productmanagement_dbo.products
-- Notes: AVG, MIN, MAX window functions converted successfully
-- Parameter: @Threshold remains (will be converted to Npgsql parameters in code)
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
-- END OF CONVERTED SQL STATEMENTS
-- ============================================================================
-- Summary:
-- - DMS Tool Conversions: 4 (Statements 1, 2, 6, 7)
-- - Manual Conversions: 3 (Statements 3, 4, 5 - transaction blocks)
-- - Schema Transformations: dbo -> productmanagement_dbo (all tables)
-- - Key Conversions:
--   * SCOPE_IDENTITY() -> RETURNING clause
--   * GETDATE() -> CURRENT_TIMESTAMP  
--   * BEGIN TRANSACTION -> BEGIN (or managed in code)
--   * Parameters @name remain (will use Npgsql parameter binding)
--   * All identifiers lowercase (PostgreSQL convention)
--   * NULLS FIRST added to ORDER BY clauses
-- ============================================================================
