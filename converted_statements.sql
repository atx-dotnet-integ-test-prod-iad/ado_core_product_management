-- ============================================================================
-- CONVERTED SQL STATEMENTS - MS SQL SERVER TO POSTGRESQL
-- Conversion Date: 2026-01-17
-- Total Statements: 7
-- Conversion Tool: AWS DMS MCP Tool
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: dbo → productmanagement_dbo
-- Notable Changes: Column names lowercased, NULLS FIRST added to ORDER BY
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: dbo → productmanagement_dbo
-- Notable Changes: LAG function preserved, column names lowercased
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS FAILED - Manual Conversion Applied
-- DMS Error: "Statement definition is not valid"
-- Reasoning: DMS cannot handle complex transaction blocks with SCOPE_IDENTITY and 
--            multiple statements. Manual conversion required for PostgreSQL.
-- Key Transformations:
--   - SCOPE_IDENTITY() → RETURNING clause on INSERT
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Transaction handling remains at application level (ADO.NET)
--   - Variable declarations removed (handled in application code)
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL (Manual):
-- NOTE: This will be executed as separate statements within ADO.NET transaction
-- Statement 1: Insert and get ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 2: Log insertion (productid from RETURNING above)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3: Update statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with warnings)
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction 
--              management in functions. Transaction handling moved to application level.
-- Schema Changes: dbo → productmanagement_dbo
-- Notable Changes: GETDATE() → clock_timestamp(), variable syntax changed
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL (DMS with manual cleanup):
-- NOTE: Transaction handling at ADO.NET level, variables handled in code
-- Statement 1: Get old values (execute scalar/reader in code)
SELECT price AS OldPrice, stockquantity AS OldStock
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 2: Update product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, 
    stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 3: Log changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4: Update statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS (with warnings)
-- DMS Warning: [7807 - CRITICAL] PostgreSQL does not support explicit transaction 
--              management in functions. Transaction handling moved to application level.
-- Schema Changes: dbo → productmanagement_dbo
-- Notable Changes: GETDATE() → clock_timestamp(), CASE expression preserved
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL (DMS with manual cleanup):
-- NOTE: Transaction handling at ADO.NET level, variables handled in code
-- Statement 1: Get old values
SELECT price AS OldPrice, stockquantity AS OldStock
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 2: Log deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 3: Delete product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 4: Update statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: dbo → productmanagement_dbo
-- Notable Changes: RANK() and PERCENT_RANK() preserved, column names lowercased
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: dbo → productmanagement_dbo
-- Notable Changes: AVG/MIN/MAX window functions preserved, column names lowercased
-- ============================================================================

-- ORIGINAL MS SQL:
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

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Processed: 7
-- DMS Tool Successful Conversions: 6
-- Manual Conversions After DMS Failure: 1 (Statement 3)
-- DMS Tool Warnings: 2 (Statements 4, 5 - Transaction management)
--
-- CRITICAL SCHEMA CHANGES:
-- - All table references: dbo schema → productmanagement_dbo schema
-- - All column names: PascalCase → lowercase
-- - All CTE names: PascalCase → lowercase
--
-- FUNCTION TRANSFORMATIONS:
-- - GETDATE() → CURRENT_TIMESTAMP or clock_timestamp()
-- - SCOPE_IDENTITY() → RETURNING clause
-- - Transaction blocks → Application-level transaction management
--
-- PARAMETER SYNTAX:
-- - @ParameterName preserved (Npgsql supports this syntax)
--
-- WINDOW FUNCTIONS:
-- - All window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) preserved
-- - ORDER BY clauses enhanced with NULLS FIRST where appropriate
--
-- NOTES FOR CODE INTEGRATION:
-- 1. Transaction blocks must be handled at ADO.NET level using NpgsqlTransaction
-- 2. Multi-statement transactions (3, 4, 5) require executing each statement separately
--    within a transaction scope
-- 3. RETURNING clause for INSERT requires using ExecuteScalar to capture returned ID
-- 4. Variable declarations and SET operations moved to C# code
-- 5. All schema references updated to productmanagement_dbo
-- ============================================================================
