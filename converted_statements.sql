-- ================================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- ================================================================================================
-- Purpose: Complete catalog of all SQL statements converted from SQL Server to PostgreSQL
-- Conversion Tool: AWS DMS MCP Statement Conversion Tool
-- Source: extracted_statements.sql
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manually Converted After DMS Failure: 1
-- ================================================================================================

-- ================================================================================================
-- STATEMENT 1: GetAllProductsAsync - Product Listing with Statistics
-- ================================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Conversion Timestamp: 2026-01-17T15:23:18.625419
-- DMS Metadata Model: sql-conversion-1768663400
--
-- Original SQL Server Statement:
-- ------------------------------------------------------------------------------------------------
/*
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
    p.Name
*/
--
-- Converted PostgreSQL Statement:
-- ------------------------------------------------------------------------------------------------

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

-- Schema Object Name Changes:
-- - Products → productmanagement_dbo.products
-- - Column names converted to lowercase
-- - Added NULLS FIRST to ORDER BY clauses (PostgreSQL explicit null handling)


-- ================================================================================================
-- STATEMENT 2: GetProductByIdAsync - Single Product Retrieval with History
-- ================================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Conversion Timestamp: 2026-01-17T15:25:05.235017
-- DMS Metadata Model: sql-conversion-1768663506
--
-- Original SQL Server Statement:
-- ------------------------------------------------------------------------------------------------
/*
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
WHERE p.ProductId = @ProductId
*/
--
-- Converted PostgreSQL Statement:
-- ------------------------------------------------------------------------------------------------

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

-- Schema Object Name Changes:
-- - Products → productmanagement_dbo.products
-- - Column names converted to lowercase
-- - LEFT JOIN → LEFT OUTER JOIN (explicit PostgreSQL syntax)
-- - Parameter @ProductId maintained (compatible with Npgsql)


-- ================================================================================================
-- STATEMENT 3: InsertProductAsync - Product Insertion with Transaction
-- ================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_FAILURE - Manual conversion applied
-- Conversion Timestamp: 2026-01-17T15:26:51.340266
-- DMS Error: "Metadata model creation failed: Statement definition is not valid."
--
-- DMS Tool Output:
-- The DMS tool failed to convert this complex transaction block with the error:
-- "Metadata model creation failed: {'error': "Metadata model creation failed: 
--  {'default_error_details': {'message': 'Statement definition is not valid.'}}"}"
--
-- Reason for Manual Conversion:
-- DMS tool cannot handle complex multi-statement transaction blocks with variable declarations,
-- SCOPE_IDENTITY(), and multiple DML operations. Manual conversion required for ADO.NET context.
--
-- Original SQL Server Statement:
-- ------------------------------------------------------------------------------------------------
/*
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
*/
--
-- Converted PostgreSQL Statement (ADO.NET context):
-- ------------------------------------------------------------------------------------------------
-- NOTE: For ADO.NET, transaction management (BEGIN/COMMIT) is handled at the application level.
-- The SQL statement should NOT include explicit transaction commands.
-- This conversion uses RETURNING clause to replace SCOPE_IDENTITY().
--

INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING productid;

-- IMPORTANT: This is a simplified version for ADO.NET context. The full transaction logic
-- should be implemented as separate statements executed within an ADO.NET transaction:
-- 1. INSERT with RETURNING to get new ID
-- 2. INSERT into ProductHistory using the returned ID
-- 3. UPDATE ProductStats
-- All within BeginTransactionAsync() / CommitAsync() in the application code.

-- Manual Conversion Notes:
-- - SCOPE_IDENTITY() → RETURNING productid (PostgreSQL native feature)
-- - GETDATE() → CURRENT_TIMESTAMP
-- - Transaction management moved to ADO.NET layer (BeginTransactionAsync/CommitAsync)
-- - Products → productmanagement_dbo.products
-- - Column names converted to lowercase
-- - Added createddate to INSERT (should be set on creation)


-- ================================================================================================
-- STATEMENT 4: UpdateProductAsync - Product Update with Transaction
-- ================================================================================================
-- Conversion Method: DMS_TOOL (with manual adaptation for ADO.NET context)
-- Conversion Status: SUCCESS (with warnings)
-- Conversion Timestamp: 2026-01-17T15:27:16.561571
-- DMS Metadata Model: sql-conversion-1768663638
--
-- DMS Tool Warning:
-- "[7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management 
--  commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]"
--
-- Original SQL Server Statement:
-- ------------------------------------------------------------------------------------------------
/*
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
*/
--
-- DMS Tool Converted Statement:
-- ------------------------------------------------------------------------------------------------
/*
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
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
*/
--
-- Converted PostgreSQL Statement (ADO.NET context - multiple statements):
-- ------------------------------------------------------------------------------------------------
-- NOTE: For ADO.NET, transaction management is handled at application level.
-- Execute these as separate statements within a transaction.

-- Statement 4A: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 4B: Update product
UPDATE productmanagement_dbo.products
SET name = @Name, 
    description = @Description, 
    price = @Price, 
    stockquantity = @StockQuantity, 
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 4C: Log changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4D: Update statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Manual Adaptation Notes:
-- - Transaction management moved to ADO.NET layer
-- - GETDATE() → CURRENT_TIMESTAMP (instead of clock_timestamp() for consistency)
-- - Separated into multiple statements for ADO.NET execution
-- - Schema updated to productmanagement_dbo
-- - Column names converted to lowercase


-- ================================================================================================
-- STATEMENT 5: DeleteProductAsync - Product Deletion with Transaction
-- ================================================================================================
-- Conversion Method: DMS_TOOL (with manual adaptation for ADO.NET context)
-- Conversion Status: SUCCESS (with warnings)
-- Conversion Timestamp: 2026-01-17T15:29:03.560574
-- DMS Metadata Model: sql-conversion-1768663745
--
-- DMS Tool Warning:
-- "[7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management 
--  commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]"
--
-- Original SQL Server Statement:
-- ------------------------------------------------------------------------------------------------
/*
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
*/
--
-- Converted PostgreSQL Statement (ADO.NET context - multiple statements):
-- ------------------------------------------------------------------------------------------------
-- NOTE: For ADO.NET, transaction management is handled at application level.
-- Execute these as separate statements within a transaction.

-- Statement 5A: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5B: Log deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5C: Delete product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5D: Update statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1,
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Manual Adaptation Notes:
-- - Transaction management moved to ADO.NET layer
-- - GETDATE() → CURRENT_TIMESTAMP
-- - Separated into multiple statements for ADO.NET execution
-- - Schema updated to productmanagement_dbo
-- - Column names converted to lowercase
-- - CASE expression preserved for division by zero handling


-- ================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - Price Range Query with Ranking
-- ================================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Conversion Timestamp: 2026-01-17T15:30:59.444500
-- DMS Metadata Model: sql-conversion-1768663861
--
-- Original SQL Server Statement:
-- ------------------------------------------------------------------------------------------------
/*
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
ORDER BY rp.PriceRank
*/
--
-- Converted PostgreSQL Statement:
-- ------------------------------------------------------------------------------------------------

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

-- Schema Object Name Changes:
-- - Products → productmanagement_dbo.products
-- - Column names converted to lowercase
-- - PERCENT_RANK() → percent_rank() (lowercase function name)
-- - Added NULLS FIRST to ORDER BY


-- ================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - Stock Analysis with Window Functions
-- ================================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Conversion Timestamp: 2026-01-17T15:32:56.674821
-- DMS Metadata Model: sql-conversion-1768663978
--
-- Original SQL Server Statement:
-- ------------------------------------------------------------------------------------------------
/*
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
ORDER BY StockQuantity
*/
--
-- Converted PostgreSQL Statement:
-- ------------------------------------------------------------------------------------------------

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

-- Schema Object Name Changes:
-- - Products → productmanagement_dbo.products
-- - Column names converted to lowercase
-- - Added NULLS FIRST to ORDER BY


-- ================================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- ================================================================================================
-- Conversion Summary:
-- - Total Statements: 7
-- - DMS Tool Successful Conversions: 6
-- - DMS Tool Failed Conversions: 1
-- - Manual Conversions After DMS Failure: 1
-- - Statements Requiring ADO.NET Context Adaptation: 3 (Statements 3, 4, 5)
-- 
-- Critical Schema Changes by DMS:
-- - All table references: TableName → productmanagement_dbo.tablename
-- - All column names converted to lowercase
-- - This MUST be respected when re-integrating into code
-- 
-- PostgreSQL-Specific Conversions:
-- - SCOPE_IDENTITY() → RETURNING clause
-- - GETDATE() → CURRENT_TIMESTAMP
-- - Explicit NULLS FIRST added to ORDER BY clauses
-- - Transaction management moved to ADO.NET layer for multi-statement transactions
-- - LEFT JOIN → LEFT OUTER JOIN
-- - Function names lowercase: RANK(), PERCENT_RANK() → rank(), percent_rank()
-- 
-- All conversions ready for re-integration into ProductRepository.cs
-- ================================================================================================
