-- =====================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET CODE
-- Source: Microsoft SQL Server to PostgreSQL Migration
-- Extraction Date: 2025
-- =====================================================================
-- This file catalogs all SQL statements extracted from the ADO.NET
-- application for DMS conversion and equivalency validation.
-- =====================================================================

-- =====================================================================
-- STATEMENT 1: GetAllProductsAsync
-- =====================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 39-68
-- Method: GetAllProductsAsync()
-- Statement Type: SELECT with CTE and Window Functions
-- SQL Server Features: 
--   - Common Table Expression (WITH)
--   - Window Functions (AVG OVER, COUNT OVER)
--   - INNER JOIN
--   - ROUND() function
--   - CASE expressions
--   - Calculated columns
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 2: GetProductByIdAsync
-- =====================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 76-105
-- Method: GetProductByIdAsync(int productId)
-- Statement Type: SELECT with CTE, Window Functions, and Parameters
-- Parameters: @ProductId (int)
-- SQL Server Features:
--   - Common Table Expression (WITH)
--   - Window Functions (LAG OVER)
--   - LEFT JOIN
--   - ROUND() function
--   - CASE expressions
--   - Parameterized query (@ProductId)
--   - NULL handling
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 3: InsertProductAsync
-- =====================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 113-137
-- Method: InsertProductAsync(Product product)
-- Statement Type: TRANSACTION BLOCK (INSERT operations)
-- Parameters: @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- SQL Server Features:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE variable
--   - INSERT statement
--   - SCOPE_IDENTITY() function (SQL Server specific)
--   - GETDATE() function (SQL Server specific)
--   - Multiple INSERT statements in transaction
--   - UPDATE statement
--   - Variable assignment (SET)
--   - Final SELECT to return new ID
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 4: UpdateProductAsync
-- =====================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 150-183
-- Method: UpdateProductAsync(Product product)
-- Statement Type: TRANSACTION BLOCK (UPDATE operations)
-- Parameters: @ProductId (int), @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- SQL Server Features:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE variables
--   - SELECT to capture old values
--   - UPDATE statement
--   - INSERT statement for history
--   - GETDATE() function (SQL Server specific)
--   - DECIMAL(18,2) data type
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 5: DeleteProductAsync
-- =====================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 191-223
-- Method: DeleteProductAsync(int productId)
-- Statement Type: TRANSACTION BLOCK (DELETE operations)
-- Parameters: @ProductId (int)
-- SQL Server Features:
--   - BEGIN TRANSACTION / COMMIT
--   - DECLARE variables
--   - SELECT to capture values before deletion
--   - DELETE statement
--   - INSERT statement for history logging
--   - UPDATE statement for statistics
--   - GETDATE() function (SQL Server specific)
--   - CASE expression for conditional calculation
--   - DECIMAL(18,2) data type
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- =====================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 229-256
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- SQL Server Features:
--   - Common Table Expression (WITH)
--   - Window Functions (RANK OVER, PERCENT_RANK OVER)
--   - BETWEEN operator
--   - CASE expression
--   - Derived calculated columns
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- =====================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Line Number: 262-290
-- Method: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @Threshold (int)
-- SQL Server Features:
--   - Common Table Expression (WITH)
--   - Window Functions (AVG OVER, MIN OVER, MAX OVER)
--   - CASE expression
--   - ROUND() function
--   - WHERE clause filtering
--   - Calculated columns in result set
-- =====================================================================
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

-- =====================================================================
-- EXTRACTION SUMMARY
-- =====================================================================
-- Total SQL Statements Extracted: 7
-- SELECT Statements: 4 (Statements 1, 2, 6, 7)
-- TRANSACTION BLOCKS: 3 (Statements 3, 4, 5)
-- Statements with CTEs: 5 (Statements 1, 2, 6, 7 contain WITH clauses)
-- Statements with Window Functions: 5 (Statements 1, 2, 6, 7)
-- Statements with Parameters: 5 (Statements 2, 3, 4, 5, 6, 7)
-- Statements using GETDATE(): 3 (Statements 3, 4, 5)
-- Statements using SCOPE_IDENTITY(): 1 (Statement 3)
-- Statements using ROUND(): 3 (Statements 1, 2, 7)
--
-- CRITICAL SQL SERVER SPECIFIC FEATURES REQUIRING CONVERSION:
-- 1. SCOPE_IDENTITY() - Needs conversion to PostgreSQL RETURNING clause or LASTVAL()
-- 2. GETDATE() - Needs conversion to CURRENT_TIMESTAMP or NOW()
-- 3. @Parameter syntax - May need conversion to $1, $2, etc. (PostgreSQL positional parameters)
-- 4. DECIMAL(18,2) - Verify PostgreSQL NUMERIC/DECIMAL compatibility
-- 5. Window Functions - Verify PostgreSQL compatibility (generally supported)
-- 6. CTEs - Verify PostgreSQL compatibility (generally supported)
-- 7. Transaction syntax - Verify PostgreSQL BEGIN/COMMIT compatibility
-- =====================================================================
