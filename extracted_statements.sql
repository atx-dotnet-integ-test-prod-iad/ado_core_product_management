-- ========================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source Application: AdoCore - Product Management System
-- Extraction Date: 2026-01-02
-- ========================================================================
-- 
-- This catalog contains ALL SQL statements extracted from the codebase
-- for systematic processing through the DMS MCP tool.
-- 
-- CRITICAL: Every statement MUST be converted through DMS tool regardless
-- of perceived complexity or PostgreSQL compatibility.
-- ========================================================================

-- ========================================================================
-- STATEMENT #1: GetAllProductsAsync - Complex CTE with Window Functions
-- ========================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: 42-69
-- Parameters: None
-- SQL Server Specific Features:
--   - CTE (Common Table Expression)
--   - Window functions: AVG() OVER(), COUNT(*) OVER()
--   - ROUND() function
--   - CASE expressions
--   - INNER JOIN
-- Complexity: Medium
-- Transaction: No
-- ========================================================================

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

-- ========================================================================
-- STATEMENT #2: GetProductByIdAsync - CTE with LAG Window Function
-- ========================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: 85-113
-- Parameters: @ProductId (int)
-- SQL Server Specific Features:
--   - CTE (Common Table Expression)
--   - Window function: LAG() OVER (ORDER BY)
--   - LEFT JOIN
--   - Parameter syntax: @ProductId
--   - ROUND() function
--   - NULL handling in CASE
-- Complexity: Medium
-- Transaction: No
-- ========================================================================

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

-- ========================================================================
-- STATEMENT #3: InsertProductAsync - Multi-Statement Transaction Block
-- ========================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: 125-149
-- Parameters: @Name (string), @Description (string/NULL), @Price (decimal), @StockQuantity (int)
-- SQL Server Specific Features:
--   - DECLARE variable syntax (@NewProductId INT)
--   - BEGIN TRANSACTION / COMMIT block
--   - INSERT INTO ... VALUES
--   - SCOPE_IDENTITY() function (CRITICAL - requires PostgreSQL RETURNING clause)
--   - GETDATE() function (requires NOW() or CURRENT_TIMESTAMP)
--   - Multi-statement transaction
--   - UPDATE statement with calculations
--   - Parameter syntax: @Name, @Description, @Price, @StockQuantity, @NewProductId
--   - NULL handling
-- Complexity: Hard
-- Transaction: Yes (3 statements: INSERT, INSERT log, UPDATE stats)
-- ========================================================================

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

-- ========================================================================
-- STATEMENT #4: UpdateProductAsync - Transaction with Variable Declarations
-- ========================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: 163-192
-- Parameters: @ProductId (int), @Name (string), @Description (string/NULL), @Price (decimal), @StockQuantity (int)
-- SQL Server Specific Features:
--   - BEGIN TRANSACTION / COMMIT block
--   - DECLARE variable syntax (DECIMAL, INT)
--   - SELECT into variables (@OldPrice = Price, @OldStock = StockQuantity)
--   - UPDATE with GETDATE()
--   - INSERT into history table
--   - Multi-statement transaction
--   - Parameter syntax: @ProductId, @Name, @Description, @Price, @StockQuantity, @OldPrice, @OldStock
-- Complexity: Hard
-- Transaction: Yes (4 statements: DECLARE, SELECT, UPDATE, INSERT, UPDATE stats)
-- ========================================================================

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

-- ========================================================================
-- STATEMENT #5: DeleteProductAsync - Transaction with Conditional CASE
-- ========================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: 200-229
-- Parameters: @ProductId (int)
-- SQL Server Specific Features:
--   - BEGIN TRANSACTION / COMMIT block
--   - DECLARE variable syntax (DECIMAL, INT)
--   - SELECT into variables
--   - DELETE statement
--   - INSERT with NULL values
--   - UPDATE with CASE expression for conditional average calculation
--   - GETDATE() function
--   - Multi-statement transaction
--   - Parameter syntax: @ProductId, @OldPrice, @OldStock
-- Complexity: Hard
-- Transaction: Yes (4 statements: DECLARE, SELECT, INSERT log, DELETE, UPDATE stats)
-- ========================================================================

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

-- ========================================================================
-- STATEMENT #6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ========================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 241-264
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- SQL Server Specific Features:
--   - CTE (Common Table Expression)
--   - Window functions: RANK() OVER, PERCENT_RANK() OVER
--   - BETWEEN clause
--   - CASE expression for categorization
--   - Percentile calculation
--   - Parameter syntax: @MinPrice, @MaxPrice
-- Complexity: Medium
-- Transaction: No
-- ========================================================================

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

-- ========================================================================
-- STATEMENT #7: GetLowStockProductsAsync - CTE with Multiple Aggregate Window Functions
-- ========================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 276-302
-- Parameters: @Threshold (int)
-- SQL Server Specific Features:
--   - CTE (Common Table Expression)
--   - Window functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - Multiple aggregate window functions in single CTE
--   - CASE expression with calculation (AvgStock * 0.5)
--   - ROUND() function
--   - Parameter syntax: @Threshold
-- Complexity: Medium
-- Transaction: No
-- ========================================================================

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

-- ========================================================================
-- EXTRACTION SUMMARY
-- ========================================================================
-- Total SQL Statements Extracted: 7
-- Total Files Analyzed: 1 (ProductRepository.cs)
-- 
-- Statement Distribution by Type:
--   - SELECT queries: 4 (Statements 1, 2, 6, 7)
--   - INSERT operations: 0 (standalone)
--   - UPDATE operations: 0 (standalone)
--   - DELETE operations: 0 (standalone)
--   - Transaction blocks: 3 (Statements 3, 4, 5)
-- 
-- Complexity Distribution:
--   - Easy: 0
--   - Medium: 4 (Statements 1, 2, 6, 7)
--   - Hard: 3 (Statements 3, 4, 5 - all transaction blocks)
-- 
-- SQL Server Specific Features Requiring Conversion:
--   1. SCOPE_IDENTITY() - 1 occurrence (Statement 3)
--   2. GETDATE() - 8 occurrences (Statements 3, 4, 5)
--   3. BEGIN TRANSACTION/COMMIT - 3 occurrences (Statements 3, 4, 5)
--   4. DECLARE variable syntax - 3 occurrences (Statements 3, 4, 5)
--   5. SET @variable = value - 1 occurrence (Statement 3)
--   6. SELECT @var = column - 2 occurrences (Statements 4, 5)
--   7. Parameter syntax (@param) - all statements with parameters
--   8. Window functions - 6 statements use window functions
--   9. CTEs - 5 statements use CTEs
--  10. ROUND() function - 4 occurrences (Statements 1, 2, 7)
-- 
-- Parameters Used:
--   - @ProductId: Statements 2
--   - @Name, @Description, @Price, @StockQuantity: Statement 3, 4
--   - @MinPrice, @MaxPrice: Statement 6
--   - @Threshold: Statement 7
--   - @NewProductId: Statement 3 (internal variable)
--   - @OldPrice, @OldStock: Statements 4, 5 (internal variables)
-- 
-- NEXT STEP: Process ALL 7 statements through DMS MCP tool
-- ========================================================================
