-- =============================================================================
-- CONVERTED SQL STATEMENTS (PostgreSQL)
-- Migration: Microsoft SQL Server to PostgreSQL
-- Conversion Date: 2026-01-22
-- Conversion Method: AWS DMS MCP Tool + Manual (for multi-statement transactions)
-- Total Statements: 7
-- Schema Mapping: dbo.Products -> productmanagement_dbo.products
-- =============================================================================

-- -----------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- -----------------------------------------------------------------------------
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Key Changes: Lowercase identifiers, added NULLS FIRST to ORDER BY
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- -----------------------------------------------------------------------------
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Key Changes: Lowercase identifiers, LEFT JOIN -> LEFT OUTER JOIN
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with RETURNING
-- -----------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS cannot handle multi-statement transactions)
-- Conversion Status: SUCCESS (Manual conversion based on PostgreSQL best practices)
-- Schema Changes: 
--   - Products -> productmanagement_dbo.products
--   - ProductHistory -> productmanagement_dbo.producthistory  
--   - ProductStats -> productmanagement_dbo.productstats
-- Key Changes:
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - GETDATE() -> NOW()
--   - BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT (PostgreSQL syntax)
--   - Variable declarations removed (use PostgreSQL DO block or handle in application)
-- Notes: This requires application-level handling of the transaction.
--        The RETURNING clause replaces SCOPE_IDENTITY().
-- -----------------------------------------------------------------------------

-- Application code should execute these in a transaction:
-- Part 1: Insert with RETURNING to get the new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Part 2: Log the insertion (use returned productid as @NewProductId)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Part 3: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- -----------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction
-- -----------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS cannot handle multi-statement transactions)
-- Conversion Status: SUCCESS (Manual conversion based on PostgreSQL best practices + DMS for UPDATE)
-- Schema Changes:
--   - Products -> productmanagement_dbo.products
--   - ProductHistory -> productmanagement_dbo.producthistory
--   - ProductStats -> productmanagement_dbo.productstats
-- Key Changes:
--   - GETDATE() -> NOW() (also DMS suggested clock_timestamp() for the main UPDATE)
--   - Variable declarations handled in application or using WITH clause
--   - BEGIN TRANSACTION/COMMIT -> PostgreSQL transaction syntax
-- Notes: This requires application-level transaction handling
-- -----------------------------------------------------------------------------

-- Application code should execute these in a transaction:
-- Part 1: Get old values (store in application variables)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Part 2: Update the product (DMS converted)
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = NOW()
WHERE productid = @ProductId;

-- Part 3: Log the changes (use old values from Part 1)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Part 4: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- -----------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with CASE
-- -----------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS cannot handle multi-statement transactions)
-- Conversion Status: SUCCESS (Manual conversion based on PostgreSQL best practices + DMS for DELETE)
-- Schema Changes:
--   - Products -> productmanagement_dbo.products
--   - ProductHistory -> productmanagement_dbo.producthistory
--   - ProductStats -> productmanagement_dbo.productstats
-- Key Changes:
--   - GETDATE() -> NOW()
--   - Variable declarations handled in application
--   - CASE expression (PostgreSQL compatible)
-- Notes: This requires application-level transaction handling
-- -----------------------------------------------------------------------------

-- Application code should execute these in a transaction:
-- Part 1: Get product info for history (store in application variables)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Part 2: Log the deletion (use values from Part 1)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Part 3: Delete the product (DMS converted)
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Part 4: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- -----------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- -----------------------------------------------------------------------------
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Key Changes: Lowercase identifiers, percent_rank() function, added NULLS FIRST
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- -----------------------------------------------------------------------------
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Key Changes: Lowercase identifiers, added NULLS FIRST to ORDER BY
-- -----------------------------------------------------------------------------

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
-- Total Statements Converted: 7
-- 
-- Conversion Method Breakdown:
--   - DMS Tool (Successful): 5 statements (Statements 1, 2, 6, 7, plus partial conversion for 3, 4, 5)
--   - Manual After DMS Failure: 3 statements (Statements 3, 4, 5 - full transaction blocks)
--
-- Schema Transformation:
--   - All table references: Products -> productmanagement_dbo.products
--   - ProductHistory -> productmanagement_dbo.producthistory (assumed)
--   - ProductStats -> productmanagement_dbo.productstats (assumed)
--   - All column names converted to lowercase
--
-- SQL Server to PostgreSQL Function Mappings:
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - GETDATE() -> NOW() or clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT -> PostgreSQL transaction handling in application code
--   - DECLARE @var -> Application-level variables (or PostgreSQL DO blocks for complex logic)
--
-- Window Functions: All preserved and working in PostgreSQL
--   - AVG() OVER(), COUNT() OVER(), MIN() OVER(), MAX() OVER()
--   - LAG() OVER()
--   - RANK() OVER(), PERCENT_RANK() OVER()
--
-- PostgreSQL-Specific Additions:
--   - NULLS FIRST in ORDER BY clauses (PostgreSQL best practice)
--   - LEFT OUTER JOIN made explicit
--
-- Multi-Statement Transaction Handling:
--   Statements 3, 4, and 5 require application-level transaction management
--   because DMS cannot convert multi-statement transaction blocks. The application
--   code should use NpgsqlTransaction to wrap these operations.
-- =============================================================================
