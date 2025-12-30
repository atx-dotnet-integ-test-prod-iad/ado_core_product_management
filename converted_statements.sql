-- =====================================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Converted using AWS DMS MCP Tool
-- =====================================================================================

-- =====================================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED via DMS
-- =====================================================================================
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: Successfully converted CTE with window functions, added NULLS FIRST to ORDER BY
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED via DMS
-- =====================================================================================
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: Successfully converted CTE with LAG window function, changed LEFT JOIN to LEFT OUTER JOIN
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 3: InsertProductAsync - MANUAL CONVERSION (DMS FAILED)
-- =====================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: "Statement definition is not valid"
-- Schema Changes: Products → productmanagement_dbo.products, 
--                 ProductHistory → productmanagement_dbo.producthistory,
--                 ProductStats → productmanagement_dbo.productstats
-- Notes: DMS cannot convert multi-statement transaction blocks. Manual conversion:
--        - Removed BEGIN TRANSACTION/COMMIT (managed at ADO.NET level)
--        - Replaced SCOPE_IDENTITY() with RETURNING clause
--        - Replaced GETDATE() with CURRENT_TIMESTAMP
--        - This will be executed as separate commands within a transaction in C# code
-- =====================================================================================

-- Insert the product and return the new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements would be executed separately in the transaction:
-- INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
-- 
-- UPDATE productmanagement_dbo.productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = CURRENT_TIMESTAMP
-- WHERE statid = 1;

-- =====================================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED via DMS (with warnings)
-- =====================================================================================
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products,
--                 ProductHistory → productmanagement_dbo.producthistory,
--                 ProductStats → productmanagement_dbo.productstats
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Notes: Converted with warning about transaction management. For ADO.NET use, we'll remove 
--        the DECLARE/BEGIN/END wrapper and execute as separate statements in a transaction
-- =====================================================================================

-- Store old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, 
    description = @Description, 
    price = @Price, 
    stockquantity = @StockQuantity, 
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED via DMS (with warnings)
-- =====================================================================================
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products,
--                 ProductHistory → productmanagement_dbo.producthistory,
--                 ProductStats → productmanagement_dbo.productstats
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Notes: Converted with warning about transaction management. For ADO.NET use, we'll remove 
--        the DECLARE/BEGIN/END wrapper and execute as separate statements in a transaction
-- =====================================================================================

-- Store product info
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Update statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED via DMS
-- =====================================================================================
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: Successfully converted CTE with RANK and PERCENT_RANK window functions
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED via DMS
-- =====================================================================================
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Notes: Successfully converted CTE with multiple window functions (AVG, MIN, MAX OVER)
-- =====================================================================================

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

-- =====================================================================================
-- END OF CONVERSION
-- Total Statements: 7
-- DMS Tool Success: 6
-- Manual Conversion: 1 (Statement 3 - InsertProductAsync)
-- =====================================================================================
