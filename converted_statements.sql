-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Purpose: Complete catalog of all SQL statements converted to PostgreSQL syntax
-- Source: Microsoft SQL Server ADO.NET Application
-- Target: PostgreSQL
-- Conversion Method: AWS DMS MCP Tool + Manual Conversion
-- Conversion Date: 2024-12-27
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1 of 7 - CONVERTED
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1766878336
-- Schema Transformations: Products → productmanagement_dbo.products
-- Syntax Changes: Column names lowercased, NULLS FIRST added to ORDER BY
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
-- STATEMENT 2 of 7 - CONVERTED
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1766878376
-- Schema Transformations: Products → productmanagement_dbo.products
-- Syntax Changes: LAG function preserved, LEFT JOIN → LEFT OUTER JOIN, column names lowercased
-- Parameters: @ProductId (int)
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
-- STATEMENT 3 of 7 - MANUALLY CONVERTED AFTER DMS FAILURE
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS FAILED - Manual conversion applied
-- DMS Error: Metadata model creation failed: Statement definition is not valid
-- Schema Transformations: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Syntax Changes: SCOPE_IDENTITY() → RETURNING clause, GETDATE() → CURRENT_TIMESTAMP, transaction handled at application level
-- Parameters: @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- Special Notes: Transaction management must be handled in C# code using NpgsqlTransaction
--                This will be split into multiple commands in the C# implementation
-- ============================================================================

-- First INSERT with RETURNING to get new ID (ExecuteScalar)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Following statements to be executed within the same transaction (ExecuteNonQuery)
-- Statement 3a: Log the insertion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3b: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4 of 7 - CONVERTED WITH WARNING
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS WITH WARNING
-- DMS Metadata Model: sql-conversion-1766878442
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Schema Transformations: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Syntax Changes: GETDATE() → clock_timestamp(), variables prefixed with var_, transaction handled at application level
-- Parameters: @ProductId (int), @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- Special Notes: DECLARE/BEGIN/END wrapper should be removed, statements executed within NpgsqlTransaction
--                Variables @OldPrice and @OldStock need to be handled in C# code
-- ============================================================================

-- Statement 4a: Get old values (ExecuteScalar or ExecuteReader)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 4b: Update the product (ExecuteNonQuery)
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 4c: Log the changes (ExecuteNonQuery)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update product statistics (ExecuteNonQuery)
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5 of 7 - CONVERTED WITH WARNING
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS WITH WARNING
-- DMS Metadata Model: sql-conversion-1766878483
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Schema Transformations: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Syntax Changes: GETDATE() → clock_timestamp(), CASE expression preserved, transaction handled at application level
-- Parameters: @ProductId (int)
-- Special Notes: DECLARE/BEGIN/END wrapper should be removed, statements executed within NpgsqlTransaction
--                Variables @OldPrice and @OldStock need to be handled in C# code
-- ============================================================================

-- Statement 5a: Get old values (ExecuteScalar or ExecuteReader)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5b: Log the deletion (ExecuteNonQuery)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete the product (ExecuteNonQuery)
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5d: Update product statistics (ExecuteNonQuery)
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6 of 7 - CONVERTED
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1766878523
-- Schema Transformations: Products → productmanagement_dbo.products
-- Syntax Changes: RANK() and PERCENT_RANK() preserved, column names lowercased, NULLS FIRST added to ORDER BY
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
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
-- STATEMENT 7 of 7 - CONVERTED
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- DMS Metadata Model: sql-conversion-1766878564
-- Schema Transformations: Products → productmanagement_dbo.products
-- Syntax Changes: Multiple window functions preserved, column names lowercased, NULLS FIRST added to ORDER BY
-- Parameters: @Threshold (int)
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
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================================
-- Conversion Summary:
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manually Converted After DMS Failure: 1 (Statement 3)
-- Statements with Warnings: 2 (Statements 4, 5 - transaction management)
-- 
-- Common Schema Transformations Applied:
-- - dbo.Products → productmanagement_dbo.products
-- - dbo.ProductHistory → productmanagement_dbo.producthistory  
-- - dbo.ProductStats → productmanagement_dbo.productstats
--
-- Transaction Handling Notes:
-- - Statements 3, 4, 5 require transaction management in C# application code
-- - Use NpgsqlTransaction with BeginTransactionAsync(), CommitAsync(), RollbackAsync()
-- - Multi-statement transactions split into separate commands
-- - Variables (e.g., @OldPrice, @OldStock, @NewProductId) handled in C# code
-- ============================================================================
