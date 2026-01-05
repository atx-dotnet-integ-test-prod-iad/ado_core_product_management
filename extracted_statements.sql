-- =====================================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- =====================================================================================
-- Source: ProductRepository.cs
-- Total Statement Groups: 7
-- Extraction Date: 2025-01-04
-- Purpose: Comprehensive catalog of all SQL statements for DMS MCP tool processing
-- =====================================================================================

-- =====================================================================================
-- STATEMENT GROUP 1: GetAllProductsAsync
-- =====================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Range: ~38-70
-- Statement Type: SELECT with CTE and Window Functions
-- Complexity: Complex - CTE, AVG OVER, COUNT OVER, CASE expressions
-- Parameters: None
-- Transaction Context: No transaction
-- SQL Server Features Used:
--   - Common Table Expression (CTE)
--   - Window functions: AVG() OVER(), COUNT(*) OVER()
--   - CASE expressions
--   - INNER JOIN
--   - ROUND function
-- =====================================================================================
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

-- =====================================================================================
-- STATEMENT GROUP 2: GetProductByIdAsync
-- =====================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Range: ~74-106
-- Statement Type: SELECT with CTE and Window Functions
-- Complexity: Medium - CTE, LAG window function
-- Parameters: @ProductId (int)
-- Transaction Context: No transaction
-- SQL Server Features Used:
--   - Common Table Expression (CTE)
--   - Window function: LAG() OVER (ORDER BY)
--   - LEFT JOIN
--   - CASE expression with NULL handling
--   - ROUND function
-- =====================================================================================
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

-- =====================================================================================
-- STATEMENT GROUP 3: InsertProductAsync
-- =====================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Range: ~110-139
-- Statement Type: Multi-statement Transaction Block (INSERT, UPDATE)
-- Complexity: Hard - Transaction, Variable declarations, SCOPE_IDENTITY
-- Parameters: @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Transaction Context: BEGIN TRANSACTION ... COMMIT
-- SQL Server Features Used:
--   - Transaction block (BEGIN TRANSACTION, COMMIT)
--   - Variable declarations (DECLARE @NewProductId INT)
--   - SCOPE_IDENTITY() function
--   - GETDATE() function
--   - Multiple INSERT and UPDATE statements
--   - Transaction-scoped variable usage
-- =====================================================================================
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

-- =====================================================================================
-- STATEMENT GROUP 4: UpdateProductAsync
-- =====================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Range: ~143-180
-- Statement Type: Multi-statement Transaction Block (SELECT, UPDATE, INSERT)
-- Complexity: Hard - Transaction, Variable declarations, Multiple statements
-- Parameters: @ProductId (int), @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Transaction Context: BEGIN TRANSACTION ... COMMIT
-- SQL Server Features Used:
--   - Transaction block (BEGIN TRANSACTION, COMMIT)
--   - Variable declarations (DECLARE @OldPrice, @OldStock)
--   - SELECT INTO variables
--   - GETDATE() function
--   - Multiple UPDATE and INSERT statements
-- =====================================================================================
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

-- =====================================================================================
-- STATEMENT GROUP 5: DeleteProductAsync
-- =====================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Range: ~184-219
-- Statement Type: Multi-statement Transaction Block (SELECT, INSERT, DELETE, UPDATE)
-- Complexity: Hard - Transaction, Variable declarations, Conditional logic
-- Parameters: @ProductId (int)
-- Transaction Context: BEGIN TRANSACTION ... COMMIT
-- SQL Server Features Used:
--   - Transaction block (BEGIN TRANSACTION, COMMIT)
--   - Variable declarations (DECLARE @OldPrice, @OldStock)
--   - SELECT INTO variables
--   - GETDATE() function
--   - DELETE statement
--   - UPDATE with CASE expression
--   - Multiple statements in transaction
-- =====================================================================================
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

-- =====================================================================================
-- STATEMENT GROUP 6: GetProductsByPriceRangeAsync
-- =====================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: ~223-253
-- Statement Type: SELECT with CTE and Window Functions
-- Complexity: Medium - CTE, RANK, PERCENT_RANK window functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Transaction Context: No transaction
-- SQL Server Features Used:
--   - Common Table Expression (CTE)
--   - Window functions: RANK() OVER, PERCENT_RANK() OVER
--   - WHERE with BETWEEN
--   - CASE expression
--   - ORDER BY with window function result
-- =====================================================================================
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

-- =====================================================================================
-- STATEMENT GROUP 7: GetLowStockProductsAsync
-- =====================================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: ~257-287
-- Statement Type: SELECT with CTE and Multiple Window Functions
-- Complexity: Medium - CTE, AVG/MIN/MAX OVER, CASE expression
-- Parameters: @Threshold (int)
-- Transaction Context: No transaction
-- SQL Server Features Used:
--   - Common Table Expression (CTE)
--   - Window functions: AVG() OVER, MIN() OVER, MAX() OVER
--   - CASE expression with multiple conditions
--   - WHERE clause filtering
--   - ROUND function
--   - ORDER BY
-- =====================================================================================
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

-- =====================================================================================
-- EXTRACTION SUMMARY
-- =====================================================================================
-- Total Statement Groups: 7
-- Simple SELECT statements: 0
-- Complex SELECT with CTEs: 4 (Groups 1, 2, 6, 7)
-- Transaction blocks: 3 (Groups 3, 4, 5)
-- Statements with window functions: 5 (Groups 1, 2, 6, 7)
-- Statements with parameters: 6 (Groups 2, 3, 4, 5, 6, 7)
-- 
-- SQL Server-specific features to be converted:
-- - SCOPE_IDENTITY() → PostgreSQL equivalent (RETURNING clause or LASTVAL())
-- - GETDATE() → CURRENT_TIMESTAMP or NOW()
-- - BEGIN TRANSACTION/COMMIT → PostgreSQL transaction syntax
-- - @parameter syntax → May need conversion to $1, $2 positional parameters
-- - Variable declarations → PostgreSQL DO block or function
-- - DECIMAL(18,2) → NUMERIC(18,2)
-- 
-- All statements extracted and ready for DMS MCP tool processing.
-- =====================================================================================
