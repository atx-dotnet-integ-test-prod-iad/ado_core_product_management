-- ====================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- SQL Server to PostgreSQL Migration - DMS MCP Tool Conversions
-- ====================================================================
-- Total Statements Converted: 7
-- DMS Tool Successful Conversions: 6
-- Manual Conversions After DMS Failure: 1
-- Conversion Date: 2026-01-04
-- ====================================================================

-- ====================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED BY DMS
-- ====================================================================
-- Original Method: GetAllProductsAsync
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column Names: All lowercase (ProductId -> productid, etc.)
-- ====================================================================
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
GO

-- ====================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED BY DMS
-- ====================================================================
-- Original Method: GetProductByIdAsync
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column Names: All lowercase
-- Window Functions: LAG converted successfully
-- ====================================================================
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
GO

-- ====================================================================
-- STATEMENT 3: InsertProductAsync - MANUAL CONVERSION (DMS FAILED)
-- ====================================================================
-- Original Method: InsertProductAsync
-- Conversion Status: MANUAL (DMS error: Statement definition is not valid)
-- DMS Error: Multi-statement transaction blocks not supported in statement conversion
-- Manual Conversion Notes:
--   - Removed DECLARE/SET variable declarations (will be handled in C# code)
--   - Replaced SCOPE_IDENTITY() with RETURNING clause on INSERT
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Removed explicit BEGIN TRANSACTION/COMMIT (will be handled by NpgsqlTransaction)
--   - Schema changes: Products -> productmanagement_dbo.products, etc.
--   - Column names: All lowercase
-- ====================================================================
-- Note: This is split into 3 separate commands to be executed within a transaction in C# code

-- Command 1: Insert product and return new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Command 2: Log the insertion (will use returned ID from Command 1)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 3: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
GO

-- ====================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED BY DMS (WITH WARNINGS)
-- ====================================================================
-- Original Method: UpdateProductAsync
-- Conversion Status: SUCCESS WITH WARNINGS
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column Names: All lowercase
-- Date Functions: GETDATE() -> clock_timestamp()
-- Variable Declarations: @OldPrice -> var_OldPrice, @OldStock -> var_OldStock
-- Note: Transaction management will be handled by C# NpgsqlTransaction
-- ====================================================================
-- For ADO.NET usage, split into individual commands (remove DECLARE/BEGIN/END wrapper):

-- Command 1: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 2: Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Command 3: Log the changes (using old values captured from Command 1)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 4: Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
GO

-- ====================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED BY DMS (WITH WARNINGS)
-- ====================================================================
-- Original Method: DeleteProductAsync
-- Conversion Status: SUCCESS WITH WARNINGS
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column Names: All lowercase
-- Date Functions: GETDATE() -> clock_timestamp()
-- Variable Declarations: @OldPrice -> var_OldPrice, @OldStock -> var_OldStock
-- Note: Transaction management will be handled by C# NpgsqlTransaction
-- ====================================================================
-- For ADO.NET usage, split into individual commands (remove DECLARE/BEGIN/END wrapper):

-- Command 1: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 2: Log the deletion (using old values captured from Command 1)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Command 3: Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Command 4: Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
GO

-- ====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED BY DMS
-- ====================================================================
-- Original Method: GetProductsByPriceRangeAsync
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column Names: All lowercase
-- Window Functions: RANK, PERCENT_RANK converted successfully
-- ====================================================================
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
GO

-- ====================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED BY DMS
-- ====================================================================
-- Original Method: GetLowStockProductsAsync
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Column Names: All lowercase
-- Window Functions: AVG, MIN, MAX converted successfully
-- ====================================================================
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
GO

-- ====================================================================
-- END OF CONVERTED STATEMENTS
-- ====================================================================
-- Conversion Summary:
-- - Total Statements: 7
-- - DMS Tool Success: 6 (Statements 1, 2, 4, 5, 6, 7)
-- - DMS Tool Failed: 1 (Statement 3 - manual conversion applied)
-- - Schema Name Changed: dbo -> productmanagement_dbo
-- - All Column Names: Converted to lowercase
-- - SQL Server Functions Converted: GETDATE() -> CURRENT_TIMESTAMP/clock_timestamp()
-- - Transaction Management: Removed from SQL (will be handled in C# code)
-- - SCOPE_IDENTITY() -> RETURNING clause pattern
-- - Window Functions: All successfully converted
-- ====================================================================
