-- ================================================================================================
-- CONVERTED SQL STATEMENTS (PostgreSQL)
-- Conversion Date: 2026-01-22
-- Total Statements: 7
-- DMS Tool Conversions: 6
-- Manual Conversions: 1
-- ================================================================================================

-- ================================================================================================
-- STATEMENT 1: GetAllProductsAsync (DMS_TOOL CONVERSION)
-- Original Method: GetAllProductsAsync()
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: CTE name and column names converted to lowercase, NULLS FIRST added to ORDER BY
-- ================================================================================================
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

-- ================================================================================================
-- STATEMENT 2: GetProductByIdAsync (DMS_TOOL CONVERSION)
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: LAG function syntax compatible with PostgreSQL, LEFT JOIN -> LEFT OUTER JOIN
-- ================================================================================================
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

-- ================================================================================================
-- STATEMENT 3: InsertProductAsync (MANUAL_AFTER_DMS_FAILURE CONVERSION)
-- Original Method: InsertProductAsync(Product product)
-- Conversion Status: MANUAL (DMS Tool Failed - Statement definition is not valid)
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: SCOPE_IDENTITY() replaced with RETURNING clause, GETDATE() -> CURRENT_TIMESTAMP, transaction management handled at ADO.NET level
-- Manual Conversion Rationale: DMS tool cannot handle multi-statement batch with SCOPE_IDENTITY() and variable passing
-- ================================================================================================
-- Insert the new product with RETURNING clause for PostgreSQL
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (separate statement, will use returned ID from previous INSERT)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (separate statement)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================================
-- STATEMENT 4: UpdateProductAsync (DMS_TOOL CONVERSION WITH WARNINGS)
-- Original Method: UpdateProductAsync(Product product)
-- Conversion Status: SUCCESS WITH WARNINGS
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management in functions. Transaction management handled at ADO.NET level.]
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: GETDATE() -> clock_timestamp(), transaction BEGIN/COMMIT handled at ADO.NET level, variable declarations converted
-- ================================================================================================
-- Store old values for history
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
    WHERE productid = @ProductId;

-- Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ================================================================================================
-- STATEMENT 5: DeleteProductAsync (DMS_TOOL CONVERSION WITH WARNINGS)
-- Original Method: DeleteProductAsync(int productId)
-- Conversion Status: SUCCESS WITH WARNINGS
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management in functions. Transaction management handled at ADO.NET level.]
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notes: GETDATE() -> clock_timestamp(), transaction BEGIN/COMMIT handled at ADO.NET level
-- ================================================================================================
-- Store product info for history
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Delete the product
DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- ================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (DMS_TOOL CONVERSION)
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: RANK() and PERCENT_RANK() functions compatible with PostgreSQL, NULLS FIRST added to ORDER BY
-- ================================================================================================
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

-- ================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (DMS_TOOL CONVERSION)
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- Notes: Window aggregate functions (AVG, MIN, MAX) compatible with PostgreSQL, NULLS FIRST added to ORDER BY
-- ================================================================================================
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

-- ================================================================================================
-- CONVERSION SUMMARY
-- ================================================================================================
-- Total SQL Statements: 7
-- DMS Tool Successful Conversions: 6
-- DMS Tool Failed Conversions: 1 (Statement 3)
-- Manual Conversions Required: 1
-- 
-- Key PostgreSQL Changes Applied:
-- 1. Schema Qualification: All table references now use productmanagement_dbo schema
-- 2. Case Sensitivity: Column and table names converted to lowercase
-- 3. Window Functions: All window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) preserved with PostgreSQL syntax
-- 4. Date/Time Functions: GETDATE() -> clock_timestamp() or CURRENT_TIMESTAMP
-- 5. Identity/Sequence: SCOPE_IDENTITY() -> RETURNING clause in INSERT
-- 6. Transaction Management: BEGIN TRANSACTION/COMMIT removed (handled at ADO.NET connection level)
-- 7. NULL Handling: NULLS FIRST added to ORDER BY clauses
-- 8. Join Syntax: LEFT JOIN -> LEFT OUTER JOIN (explicit)
-- 
-- Critical Notes for Code Integration:
-- 1. STATEMENT 3 (InsertProductAsync): Must split into multiple ExecuteScalarAsync/ExecuteNonQueryAsync calls
--    - First INSERT with RETURNING to get new product ID
--    - Use returned ID for subsequent INSERT and UPDATE statements
-- 2. STATEMENT 4 & 5 (UpdateProductAsync, DeleteProductAsync): Must handle old values retrieval
--    - First SELECT to get old values into variables
--    - Use these values in subsequent INSERT/UPDATE statements
-- 3. ALL STATEMENTS: Schema name is productmanagement_dbo, table names are lowercase
-- 4. TRANSACTION HANDLING: Use NpgsqlTransaction at ADO.NET level, not in SQL statements
-- ================================================================================================
