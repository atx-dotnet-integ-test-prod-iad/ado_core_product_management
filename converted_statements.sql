-- =====================================================================
-- CONVERTED SQL STATEMENTS - SQL Server to PostgreSQL
-- Conversion Date: 2025-02-21
-- DMS Tool Status: FAILED - Manual conversion applied
-- =====================================================================
-- This file contains PostgreSQL converted versions of all SQL statements
-- from extracted_statements.sql. Due to DMS tool failures, manual
-- conversion has been applied following PostgreSQL best practices and
-- lowercase schema object naming conventions.
-- =====================================================================

-- =====================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- =====================================================================
-- Original: SQL Server statement with CTE and window functions
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Notes:
--   - Table names converted to lowercase (Products -> products)
--   - Column names converted to lowercase (ProductId -> productid, Name -> name, etc.)
--   - ROUND() function compatible with PostgreSQL
--   - Window functions (AVG OVER, COUNT OVER) compatible with PostgreSQL
--   - CASE expressions compatible with PostgreSQL
--   - CTE syntax compatible with PostgreSQL
-- =====================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- =====================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- =====================================================================
-- Original: SQL Server statement with CTE, LAG window function, and parameters
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Notes:
--   - Table names converted to lowercase (Products -> products)
--   - Column names converted to lowercase
--   - LAG window function compatible with PostgreSQL
--   - Parameters kept as @ProductId (Npgsql supports named parameters)
--   - ROUND() function compatible with PostgreSQL
--   - NULL handling compatible with PostgreSQL
-- =====================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- =====================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- =====================================================================
-- Original: SQL Server transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Notes:
--   - BEGIN TRANSACTION -> BEGIN (PostgreSQL syntax)
--   - Table/column names converted to lowercase
--   - SCOPE_IDENTITY() -> RETURNING clause for INSERT statement
--   - GETDATE() -> CURRENT_TIMESTAMP (PostgreSQL function)
--   - DECLARE @Variable -> PostgreSQL uses different variable syntax in functions
--   - This will need to be restructured to use RETURNING clause
--   - Parameters kept as named (@Name, @Description, etc.) for Npgsql compatibility
-- =====================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
-- Note: This needs to be restructured for PostgreSQL using WITH CTE and RETURNING
WITH inserted_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1
RETURNING (SELECT productid FROM inserted_product);

-- Alternative simpler approach (recommended for ADO.NET):
-- Execute these as separate statements within a transaction:
-- 1. INSERT INTO products ... RETURNING productid;
-- 2. INSERT INTO producthistory ... (using returned productid)
-- 3. UPDATE productstats ...

-- =====================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- =====================================================================
-- Original: SQL Server transaction block with UPDATE operations
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Notes:
--   - BEGIN TRANSACTION -> BEGIN (PostgreSQL syntax)
--   - Table/column names converted to lowercase
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - DECLARE variables need PostgreSQL DO block or function context
--   - Will restructure to avoid variable declarations
--   - DECIMAL(18,2) -> NUMERIC(18,2) or DECIMAL(18,2) (both supported)
-- =====================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
-- Using CTE to capture old values without variables
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
updated_product AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId
    RETURNING productid
),
log_update AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING productid
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Alternative simpler approach (recommended for ADO.NET):
-- Execute these as separate statements within a transaction:
-- 1. SELECT price, stockquantity FROM products WHERE productid = @ProductId
-- 2. UPDATE products SET ... WHERE productid = @ProductId
-- 3. INSERT INTO producthistory ...
-- 4. UPDATE productstats ...

-- =====================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- =====================================================================
-- Original: SQL Server transaction block with DELETE operations
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Notes:
--   - BEGIN TRANSACTION -> BEGIN (PostgreSQL syntax)
--   - Table/column names converted to lowercase
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - DECLARE variables restructured using CTE
--   - CASE expression compatible with PostgreSQL
-- =====================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
-- Using CTE to capture values before deletion
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
log_delete AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING productid
),
deleted_product AS (
    DELETE FROM products 
    WHERE productid = @ProductId
    RETURNING productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Alternative simpler approach (recommended for ADO.NET):
-- Execute these as separate statements within a transaction:
-- 1. SELECT price, stockquantity FROM products WHERE productid = @ProductId
-- 2. INSERT INTO producthistory ...
-- 3. DELETE FROM products WHERE productid = @ProductId
-- 4. UPDATE productstats ...

-- =====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- =====================================================================
-- Original: SQL Server statement with CTE, RANK and PERCENT_RANK window functions
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Notes:
--   - Table/column names converted to lowercase
--   - RANK() and PERCENT_RANK() window functions compatible with PostgreSQL
--   - BETWEEN operator compatible with PostgreSQL
--   - CASE expression compatible with PostgreSQL
--   - Parameters kept as named (@MinPrice, @MaxPrice)
-- =====================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- =====================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- =====================================================================
-- Original: SQL Server statement with CTE and multiple window functions
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Notes:
--   - Table/column names converted to lowercase
--   - Window functions (AVG, MIN, MAX OVER) compatible with PostgreSQL
--   - ROUND() function compatible with PostgreSQL
--   - CASE expression compatible with PostgreSQL
--   - Parameter kept as named (@Threshold)
-- =====================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- =====================================================================
-- CONVERSION SUMMARY
-- =====================================================================
-- Total Statements Converted: 7
-- Conversion Method: All statements - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Tool Status: FAILED for all statements
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--
-- KEY CONVERSIONS APPLIED:
-- 1. All table names converted to lowercase (Products -> products, ProductHistory -> producthistory, ProductStats -> productstats)
-- 2. All column names converted to lowercase (ProductId -> productid, Name -> name, etc.)
-- 3. SCOPE_IDENTITY() -> RETURNING clause pattern
-- 4. GETDATE() -> CURRENT_TIMESTAMP
-- 5. BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT (or managed by ADO.NET transaction)
-- 6. DECLARE variables -> CTE patterns to avoid variable declarations
-- 7. @Parameter syntax retained (Npgsql supports named parameters)
-- 8. Window functions (LAG, AVG, COUNT, RANK, PERCENT_RANK, MIN, MAX OVER) - compatible as-is
-- 9. ROUND() function - compatible as-is
-- 10. CASE expressions - compatible as-is
--
-- IMPORTANT NOTES FOR CODE INTEGRATION:
-- - Transaction blocks (Statements 3, 4, 5) are complex and may be better handled
--   as separate sequential statements within an ADO.NET transaction rather than
--   as single complex CTEs
-- - Named parameters (@Name, @Price, etc.) are supported by Npgsql
-- - All schema object names must use lowercase in the final code
-- =====================================================================
