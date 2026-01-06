-- =====================================================================================
-- SQL SERVER TO POSTGRESQL MIGRATION - CONVERTED SQL STATEMENTS
-- =====================================================================================
-- Conversion Tool: AWS DMS MCP Statement Conversion Tool
-- Migration Project: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
-- Database: ProductManagement
-- Schema: dbo -> productmanagement_dbo
-- Total Statements Converted: 7
-- Conversion Date: 2026-01-06
-- =====================================================================================

-- =====================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED SUCCESSFULLY)
-- =====================================================================================
-- Method: GetAllProductsAsync()
-- Conversion Status: SUCCESS
-- Schema Change: Products -> productmanagement_dbo.products
-- Notable Changes: Added NULLS FIRST to ORDER BY, lowercase identifiers
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED SUCCESSFULLY)
-- =====================================================================================
-- Method: GetProductByIdAsync(int productId)
-- Conversion Status: SUCCESS
-- Schema Change: Products -> productmanagement_dbo.products
-- Notable Changes: LEFT JOIN -> LEFT OUTER JOIN, lowercase identifiers, LAG function preserved
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
-- STATEMENT 3: InsertProductAsync (CONVERSION FAILED - MANUAL CONVERSION REQUIRED)
-- =====================================================================================
-- Method: InsertProductAsync(Product product)
-- Conversion Status: FAILED
-- DMS Error: Metadata model creation failed: Statement definition is not valid
-- Reason: DMS tool cannot convert multi-statement transactions with SCOPE_IDENTITY()
-- Manual Conversion: Use PostgreSQL RETURNING clause for INSERT with multiple statements
-- =====================================================================================

-- MANUAL CONVERSION REQUIRED FOR ADO.NET CONTEXT
-- This requires breaking the transaction into separate commands in the C# code
-- with proper transaction management through NpgsqlConnection.BeginTransaction()

-- Insert statement with RETURNING:
-- INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity)
-- RETURNING productid;

-- Then in separate commands within the same transaction:
-- INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- UPDATE productmanagement_dbo.productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- =====================================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED WITH WARNINGS)
-- =====================================================================================
-- Method: UpdateProductAsync(Product product)
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notable Changes: GETDATE() -> clock_timestamp(), DECLARE syntax changed, transaction warning
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Note: Transaction management must be handled in C# code, not in SQL
-- =====================================================================================

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
    COMMIT;
END;

-- =====================================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED WITH WARNINGS)
-- =====================================================================================
-- Method: DeleteProductAsync(int productId)
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- Schema Changes: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- Notable Changes: GETDATE() -> clock_timestamp(), DECLARE syntax changed, transaction warning
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Note: Transaction management must be handled in C# code, not in SQL
-- =====================================================================================

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
    COMMIT;
END;

-- =====================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED SUCCESSFULLY)
-- =====================================================================================
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: SUCCESS
-- Schema Change: Products -> productmanagement_dbo.products
-- Notable Changes: Added NULLS FIRST to ORDER BY, lowercase identifiers, RANK and PERCENT_RANK preserved
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED SUCCESSFULLY)
-- =====================================================================================
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Status: SUCCESS
-- Schema Change: Products -> productmanagement_dbo.products
-- Notable Changes: Added NULLS FIRST to ORDER BY, lowercase identifiers, window functions preserved
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
-- END OF CONVERTED SQL STATEMENTS
-- =====================================================================================
-- Summary:
-- - Total Statements Processed: 7
-- - Successfully Converted: 5 (Statements 1, 2, 6, 7)
-- - Converted with Warnings: 2 (Statements 4, 5 - transaction management warnings)
-- - Failed Conversion Requiring Manual Intervention: 1 (Statement 3 - SCOPE_IDENTITY)
-- - Schema Name Changed: dbo -> productmanagement_dbo
-- - Table Name Changes: All table references now include schema prefix
-- - GETDATE() -> clock_timestamp() or NOW()
-- - All identifiers converted to lowercase
-- - NULLS FIRST added to ORDER BY clauses
-- =====================================================================================
