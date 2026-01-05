-- =====================================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration via DMS MCP Tool
-- =====================================================================================
-- All statements processed through AWS DMS MCP Tool
-- Migration Project: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
-- Conversion Date: 2026-01-05
-- Schema Transformation: dbo → productmanagement_dbo
-- =====================================================================================

-- =====================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- =====================================================================================
-- SOURCE: sourceCode/DataAccess/ProductRepository.cs
-- METHOD: GetAllProductsAsync()
-- CONVERSION METHOD: DMS_TOOL
-- CONVERSION STATUS: SUCCESS
-- DMS METADATA MODEL: sql-conversion-1767571665
-- SCHEMA CHANGES: 
--   - Products → productmanagement_dbo.products
--   - All column names converted to lowercase
-- NOTES: CTE and window functions converted successfully. NULLS FIRST added to ORDER BY.
-- =====================================================================================

-- ORIGINAL SQL SERVER:
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- CONVERTED POSTGRESQL:
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
-- STATEMENT 2: GetProductByIdAsync
-- =====================================================================================
-- SOURCE: sourceCode/DataAccess/ProductRepository.cs
-- METHOD: GetProductByIdAsync(int productId)
-- CONVERSION METHOD: DMS_TOOL
-- CONVERSION STATUS: SUCCESS
-- DMS METADATA MODEL: sql-conversion-1767571764
-- SCHEMA CHANGES:
--   - Products → productmanagement_dbo.products
--   - All column names converted to lowercase
--   - LEFT JOIN → LEFT OUTER JOIN
-- PARAMETERS: @ProductId (int)
-- NOTES: LAG window function and CTE converted successfully. @ProductId parameter preserved.
-- =====================================================================================

-- ORIGINAL SQL SERVER:
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- CONVERTED POSTGRESQL:
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
-- STATEMENT 3: InsertProductAsync
-- =====================================================================================
-- SOURCE: sourceCode/DataAccess/ProductRepository.cs
-- METHOD: InsertProductAsync(Product product)
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- CONVERSION STATUS: DMS TOOL FAILED - Manual conversion applied
-- DMS ERROR: "Metadata model creation failed: Statement definition is not valid"
-- PARAMETERS: @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- NOTES: DMS tool could not process complex transaction block with DECLARE at start.
--        Manual conversion based on PostgreSQL best practices:
--        - SCOPE_IDENTITY() → RETURNING clause
--        - GETDATE() → CURRENT_TIMESTAMP
--        - Transaction management handled at application level (C# code)
--        - Variable declarations removed (use RETURNING instead)
-- SCHEMA CHANGES:
--   - Products → productmanagement_dbo.products
--   - ProductHistory → productmanagement_dbo.producthistory
--   - ProductStats → productmanagement_dbo.productstats
--   - All column names converted to lowercase
-- TRANSACTION HANDLING: Transaction boundaries (BEGIN/COMMIT) removed from SQL,
--                       handled by C# code using NpgsqlConnection.BeginTransactionAsync()
-- =====================================================================================

-- ORIGINAL SQL SERVER:
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- CONVERTED POSTGRESQL:
-- Note: Transaction management moved to C# code level
-- Insert the new product and get the ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements would be executed in separate commands within the same transaction:
-- Log the insertion (uses the returned productid from previous statement)
-- INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
-- UPDATE productmanagement_dbo.productstats
-- SET 
--     totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = CURRENT_TIMESTAMP
-- WHERE statid = 1;

-- =====================================================================================
-- STATEMENT 4: UpdateProductAsync
-- =====================================================================================
-- SOURCE: sourceCode/DataAccess/ProductRepository.cs
-- METHOD: UpdateProductAsync(Product product)
-- CONVERSION METHOD: DMS_TOOL
-- CONVERSION STATUS: SUCCESS_WITH_WARNING
-- DMS METADATA MODEL: sql-conversion-1767571891
-- DMS WARNING: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction
--              management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your
--              source code manually.]
-- PARAMETERS: @ProductId (int), @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- NOTES: DMS converted the SQL but noted that transaction management (BEGIN TRANSACTION/COMMIT)
--        should be handled in application code. GETDATE() → clock_timestamp()
-- SCHEMA CHANGES:
--   - Products → productmanagement_dbo.products
--   - ProductHistory → productmanagement_dbo.producthistory
--   - ProductStats → productmanagement_dbo.productstats
--   - All column names converted to lowercase
--   - @OldPrice → var_OldPrice, @OldStock → var_OldStock
-- TRANSACTION HANDLING: BEGIN TRANSACTION and COMMIT should be managed at application level
-- =====================================================================================

-- ORIGINAL SQL SERVER:
BEGIN TRANSACTION;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- CONVERTED POSTGRESQL (DMS OUTPUT - needs transaction handling in C# code):
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION;
    */
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
    COMMIT;
END;

-- =====================================================================================
-- STATEMENT 5: DeleteProductAsync
-- =====================================================================================
-- SOURCE: sourceCode/DataAccess/ProductRepository.cs
-- METHOD: DeleteProductAsync(int productId)
-- CONVERSION METHOD: DMS_TOOL
-- CONVERSION STATUS: SUCCESS_WITH_WARNING
-- DMS METADATA MODEL: sql-conversion-1767571990
-- DMS WARNING: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction
--              management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your
--              source code manually.]
-- PARAMETERS: @ProductId (int)
-- NOTES: DMS converted the SQL but noted that transaction management should be handled in
--        application code. GETDATE() → clock_timestamp()
-- SCHEMA CHANGES:
--   - Products → productmanagement_dbo.products
--   - ProductHistory → productmanagement_dbo.producthistory
--   - ProductStats → productmanagement_dbo.productstats
--   - All column names converted to lowercase
--   - @OldPrice → var_OldPrice, @OldStock → var_OldStock
-- TRANSACTION HANDLING: BEGIN TRANSACTION and COMMIT should be managed at application level
-- =====================================================================================

-- ORIGINAL SQL SERVER:
BEGIN TRANSACTION;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- CONVERTED POSTGRESQL (DMS OUTPUT - needs transaction handling in C# code):
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION;
    */
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
    COMMIT;
END;

-- =====================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- =====================================================================================
-- SOURCE: sourceCode/DataAccess/ProductRepository.cs
-- METHOD: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- CONVERSION METHOD: DMS_TOOL
-- CONVERSION STATUS: SUCCESS
-- DMS METADATA MODEL: sql-conversion-1767572088
-- PARAMETERS: @MinPrice (decimal), @MaxPrice (decimal)
-- NOTES: CTE with RANK and PERCENT_RANK window functions converted successfully.
--        NULLS FIRST added to ORDER BY.
-- SCHEMA CHANGES:
--   - Products → productmanagement_dbo.products
--   - All column names converted to lowercase
-- =====================================================================================

-- ORIGINAL SQL SERVER:
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank;

-- CONVERTED POSTGRESQL:
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
-- STATEMENT 7: GetLowStockProductsAsync
-- =====================================================================================
-- SOURCE: sourceCode/DataAccess/ProductRepository.cs
-- METHOD: GetLowStockProductsAsync(int threshold)
-- CONVERSION METHOD: DMS_TOOL
-- CONVERSION STATUS: SUCCESS
-- DMS METADATA MODEL: sql-conversion-1767572188
-- PARAMETERS: @Threshold (int)
-- NOTES: CTE with AVG, MIN, MAX window functions converted successfully.
--        NULLS FIRST added to ORDER BY.
-- SCHEMA CHANGES:
--   - Products → productmanagement_dbo.products
--   - All column names converted to lowercase
-- =====================================================================================

-- ORIGINAL SQL SERVER:
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- CONVERTED POSTGRESQL:
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
-- CONVERSION SUMMARY
-- =====================================================================================
-- Total Statements Processed: 7
-- DMS Tool Successful: 6
-- DMS Tool Failed (Manual Conversion Required): 1 (Statement 3 - InsertProductAsync)
-- 
-- Common Schema Transformations Applied by DMS:
-- 1. Schema prefix added: dbo → productmanagement_dbo
-- 2. Table names: Products → products, ProductHistory → producthistory, ProductStats → productstats
-- 3. All column names converted to lowercase
-- 4. GETDATE() → clock_timestamp() or CURRENT_TIMESTAMP
-- 5. NULLS FIRST added to ORDER BY clauses
-- 6. LEFT JOIN → LEFT OUTER JOIN
-- 7. Variable naming: @Variable → var_Variable (in DECLARE blocks)
-- 
-- Critical Notes for Code Re-integration:
-- 1. Use schema-qualified table names: productmanagement_dbo.products (not just products)
-- 2. Use lowercase column names in all references
-- 3. Transaction management (BEGIN TRANSACTION/COMMIT) must be handled in C# code,
--    not in SQL statements (for Statements 3, 4, 5)
-- 4. @Parameter syntax is preserved and works with Npgsql
-- 5. Statement 3 requires multi-statement execution within a transaction at C# level
-- =====================================================================================
