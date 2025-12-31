-- ========================================================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration for AdoCore
-- ========================================================================================================
-- This catalog contains all extracted SQL statements from the ADO.NET codebase prior to DMS conversion
-- Each statement is tagged with source file location, line numbers, parameters, and complexity analysis
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 42-68 (SQL statement definition)
-- Method: GetAllProductsAsync()
-- Complexity: HIGH
-- SQL Server Features: CTE, Window Functions (AVG OVER, COUNT OVER), CASE Expression, INNER JOIN
-- Parameters: None
-- Transaction: No
-- Description: Retrieves all products with price statistics including average price comparison and categorization
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 75-109 (SQL statement definition)
-- Method: GetProductByIdAsync(int productId)
-- Complexity: HIGH
-- SQL Server Features: CTE, Window Function (LAG OVER), LEFT JOIN, CASE Expression, NULL handling
-- Parameters: @ProductId (INT)
-- Transaction: No
-- Description: Retrieves a product by ID with historical price and stock data, calculating price change percentage
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 115-146 (SQL statement definition)
-- Method: InsertProductAsync(Product product)
-- Complexity: VERY HIGH
-- SQL Server Features: Multi-statement Transaction, Variable Declaration (DECLARE), SCOPE_IDENTITY(), 
--                       GETDATE(), BEGIN TRANSACTION/COMMIT, INSERT with identity retrieval
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Transaction: Yes - BEGIN TRANSACTION/COMMIT with insert, history logging, and statistics update
-- Description: Inserts new product, logs the insertion in history table, updates statistics, returns new ProductId
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 151-187 (SQL statement definition)
-- Method: UpdateProductAsync(Product product)
-- Complexity: VERY HIGH
-- SQL Server Features: Multi-statement Transaction, Variable Declaration (DECLARE), GETDATE(),
--                       BEGIN TRANSACTION/COMMIT, UPDATE with audit logging
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), 
--             @Price (DECIMAL), @StockQuantity (INT)
-- Transaction: Yes - BEGIN TRANSACTION/COMMIT with variable storage, update, history logging, statistics update
-- Description: Updates product with change tracking, logs old/new values in history, updates statistics
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 192-222 (SQL statement definition)
-- Method: DeleteProductAsync(int productId)
-- Complexity: VERY HIGH
-- SQL Server Features: Multi-statement Transaction, Variable Declaration (DECLARE), GETDATE(),
--                       BEGIN TRANSACTION/COMMIT, DELETE with audit logging, CASE expression in UPDATE
-- Parameters: @ProductId (INT)
-- Transaction: Yes - BEGIN TRANSACTION/COMMIT with variable storage, history logging, delete, statistics update
-- Description: Deletes product with audit trail, logs deletion in history, updates statistics with CASE handling
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 228-255 (SQL statement definition)
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Complexity: HIGH
-- SQL Server Features: CTE, Window Functions (RANK OVER, PERCENT_RANK OVER), BETWEEN clause, CASE expression
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Transaction: No
-- Description: Retrieves products within price range with ranking and percentile calculations, categorized by price segment
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 260-291 (SQL statement definition)
-- Method: GetLowStockProductsAsync(int threshold)
-- Complexity: HIGH
-- SQL Server Features: CTE, Multiple Window Functions (AVG OVER, MIN OVER, MAX OVER), CASE expression,
--                       Arithmetic operations with window aggregates
-- Parameters: @Threshold (INT)
-- Transaction: No
-- Description: Retrieves low stock products with stock level analysis including average, min, max comparisons and status categorization
-- ========================================================================================================

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

-- ========================================================================================================
-- EXTRACTION SUMMARY
-- ========================================================================================================
-- Total SQL Operations Extracted: 7
-- 
-- Complexity Breakdown:
--   - HIGH Complexity: 4 statements (GetAllProductsAsync, GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
--   - VERY HIGH Complexity: 3 statements (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
--
-- SQL Server Specific Features Requiring Conversion:
--   1. SCOPE_IDENTITY() - Used in InsertProductAsync (1 occurrence)
--   2. GETDATE() - Used in InsertProductAsync, UpdateProductAsync, DeleteProductAsync (9 occurrences)
--   3. BEGIN TRANSACTION/COMMIT syntax - Used in 3 transaction blocks (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
--   4. Variable declarations (DECLARE @Variable) - Used in 3 transaction blocks (7 variable declarations)
--   5. Window Functions - AVG OVER, COUNT OVER, LAG OVER, RANK OVER, PERCENT_RANK OVER, MIN OVER, MAX OVER (all should be PostgreSQL compatible)
--   6. CTEs (Common Table Expressions) - Used in 5 statements (should be PostgreSQL compatible)
--   7. CASE expressions - Used extensively (should be PostgreSQL compatible)
--   8. ROUND function - Used in 4 statements (should be PostgreSQL compatible)
--
-- Dependencies:
--   - Products table (primary table for all operations)
--   - ProductHistory table (audit trail in Insert, Update, Delete operations)
--   - ProductStats table (statistics tracking in Insert, Update, Delete operations)
--
-- Transaction Blocks:
--   - InsertProductAsync: 3 statements within transaction (INSERT Products, INSERT ProductHistory, UPDATE ProductStats)
--   - UpdateProductAsync: 4 statements within transaction (SELECT for old values, UPDATE Products, INSERT ProductHistory, UPDATE ProductStats)
--   - DeleteProductAsync: 4 statements within transaction (SELECT for old values, INSERT ProductHistory, DELETE Products, UPDATE ProductStats)
--
-- Parameter Usage:
--   - @ProductId: Used in GetProductByIdAsync, UpdateProductAsync, DeleteProductAsync
--   - @Name, @Description, @Price, @StockQuantity: Used in InsertProductAsync, UpdateProductAsync
--   - @MinPrice, @MaxPrice: Used in GetProductsByPriceRangeAsync
--   - @Threshold: Used in GetLowStockProductsAsync
--   - @NewProductId, @OldPrice, @OldStock: Internal variables within transactions
--
-- ========================================================================================================
-- END OF EXTRACTION CATALOG
-- ========================================================================================================
