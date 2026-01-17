-- ========================================================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Source: ADO.NET Application Migration from MS SQL Server to PostgreSQL
-- Conversion Method: AWS DMS MCP Tool + Manual Refinement
-- Date: 2026-01-17
-- ========================================================================================================
-- This file contains all SQL statements converted to PostgreSQL syntax.
-- Statements 1, 2, 6, 7: Converted successfully by DMS tool
-- Statements 4, 5: Converted by DMS with manual refinement for ADO.NET compatibility
-- Statement 3: Manual conversion (DMS failed due to DECLARE complexity)
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
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
-- STATEMENT 3: InsertProductAsync - Transaction Block with RETURNING
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Status: MANUAL CONVERSION REQUIRED
-- Note: DMS failed to convert due to DECLARE and SCOPE_IDENTITY() complexity
-- Solution: Split into 3 separate commands, use RETURNING clause, transaction managed at app level
-- ========================================================================================================

-- Command 1: Insert product and return new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Command 2: Log the insertion (use returned ProductId from Command 1)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 3: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block Split for ADO.NET
-- Conversion Method: DMS_TOOL with MANUAL_REFINEMENT
-- Status: SUCCESS with manual refinement for ADO.NET execution
-- Note: Transaction management to be handled at application level via BeginTransaction/Commit
-- ========================================================================================================

-- Command 1: Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Command 2: Log the changes (capture old values from pre-update state)
-- Note: In application, capture old values before update or use a CTE
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 3: Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block Split for ADO.NET
-- Conversion Method: DMS_TOOL with MANUAL_REFINEMENT
-- Status: SUCCESS with manual refinement for ADO.NET execution
-- Note: Transaction management to be handled at application level via BeginTransaction/Commit
-- ========================================================================================================

-- Command 1: Log the deletion (capture values before delete)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, CURRENT_TIMESTAMP
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 2: Delete the product
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- Command 3: Update product statistics
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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Aggregates
-- Conversion Method: DMS_TOOL
-- Status: SUCCESS
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
-- END OF CONVERTED STATEMENTS
-- Total: 7 SQL statements converted
-- DMS Tool Success: 6 statements
-- Manual Conversion: 1 statement (InsertProductAsync)
-- Schema Transformation: Products → productmanagement_dbo.products, 
--                       ProductHistory → productmanagement_dbo.producthistory,
--                       ProductStats → productmanagement_dbo.productstats
-- ========================================================================================================
