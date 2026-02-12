-- ========================================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- ========================================================================================================
-- Purpose: Comprehensive catalog of all SQL statements extracted from the codebase for PostgreSQL migration
-- Total Statements: 7
-- Source Application: AdoCore - Product Management System
-- Date Extracted: 2025
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Range: 39-68
-- Statement Type: SELECT
-- Complexity: COMPLEX
-- Description: Retrieves all products with price analysis using CTE, window functions (AVG, COUNT), 
--              CASE expressions, and ROUND function. Includes dynamic price categorization.
-- SQL Server Features Used:
--   - Common Table Expression (CTE)
--   - Window Functions (AVG OVER, COUNT OVER)
--   - CASE expressions
--   - ROUND function
--   - INNER JOIN
--   - Complex ORDER BY with CASE
-- Parameters: None
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Line Range: 82-114
-- Statement Type: SELECT
-- Complexity: COMPLEX
-- Description: Retrieves a single product with historical price analysis using LAG window function
--              to compare current values with previous values.
-- SQL Server Features Used:
--   - Common Table Expression (CTE)
--   - LAG window function
--   - ROUND function
--   - CASE expressions with NULL handling
--   - LEFT JOIN
--   - Parameterized query (@ProductId)
-- Parameters: @ProductId (INT)
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
-- STATEMENT 3: InsertProductAsync - Transaction with SCOPE_IDENTITY and Multiple Statements
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Line Range: 128-153
-- Statement Type: TRANSACTION (INSERT, UPDATE)
-- Complexity: COMPLEX
-- Description: Inserts a new product within a transaction, captures the new ID using SCOPE_IDENTITY(),
--              logs the insertion to ProductHistory, and updates ProductStats table.
-- SQL Server Features Used:
--   - Transaction (BEGIN TRANSACTION, COMMIT)
--   - DECLARE variable (@NewProductId)
--   - INSERT with IDENTITY column
--   - SCOPE_IDENTITY() function
--   - GETDATE() function (3 occurrences)
--   - SET variable assignment
--   - Multi-statement transaction
--   - Arithmetic operations in UPDATE
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
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
-- STATEMENT 4: UpdateProductAsync - Transaction with Variables and Multiple Statements
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Line Range: 165-197
-- Statement Type: TRANSACTION (UPDATE, INSERT)
-- Complexity: COMPLEX
-- Description: Updates a product within a transaction, stores old values in variables,
--              logs changes to ProductHistory, and updates ProductStats.
-- SQL Server Features Used:
--   - Transaction (BEGIN TRANSACTION, COMMIT)
--   - DECLARE variables (@OldPrice, @OldStock with DECIMAL and INT types)
--   - SELECT INTO variables
--   - UPDATE with GETDATE() (3 occurrences)
--   - Multi-statement transaction
--   - Arithmetic operations in UPDATE
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
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
-- STATEMENT 5: DeleteProductAsync - Transaction with Variables and Multiple Statements
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Line Range: 207-241
-- Statement Type: TRANSACTION (DELETE, INSERT, UPDATE)
-- Complexity: COMPLEX
-- Description: Deletes a product within a transaction, stores product info in variables,
--              logs deletion to ProductHistory, and updates ProductStats with conditional logic.
-- SQL Server Features Used:
--   - Transaction (BEGIN TRANSACTION, COMMIT)
--   - DECLARE variables (@OldPrice, @OldStock with DECIMAL and INT types)
--   - SELECT INTO variables
--   - DELETE statement
--   - UPDATE with CASE expression (3 occurrences of GETDATE())
--   - Multi-statement transaction
--   - Arithmetic operations with CASE in UPDATE
-- Parameters: @ProductId (INT)
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with Ranking Window Functions
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Line Range: 253-276
-- Statement Type: SELECT
-- Complexity: COMPLEX
-- Description: Retrieves products within a price range with ranking analysis using
--              RANK and PERCENT_RANK window functions, and categorizes by percentile.
-- SQL Server Features Used:
--   - Common Table Expression (CTE)
--   - RANK() window function
--   - PERCENT_RANK() window function
--   - BETWEEN operator
--   - CASE expression with percentile ranges
--   - ORDER BY with ranking
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions and Complex CASE
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Line Range: 288-313
-- Statement Type: SELECT
-- Complexity: COMPLEX
-- Description: Retrieves low stock products with stock analysis using multiple window functions
--              (AVG, MIN, MAX), CASE expressions, and ROUND function.
-- SQL Server Features Used:
--   - Common Table Expression (CTE)
--   - Multiple window functions (AVG OVER, MIN OVER, MAX OVER)
--   - CASE expression with multiple conditions
--   - ROUND function
--   - WHERE clause filtering
--   - Arithmetic operations in CASE conditions
-- Parameters: @Threshold (INT)
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
-- END OF EXTRACTED STATEMENTS
-- ========================================================================================================
-- 
-- SUMMARY OF SQL SERVER SPECIFIC FEATURES REQUIRING CONVERSION:
-- 
-- 1. Transaction Syntax:
--    - BEGIN TRANSACTION → PostgreSQL: BEGIN
--    - COMMIT → PostgreSQL: COMMIT (same)
-- 
-- 2. Identity and Sequence Functions:
--    - SCOPE_IDENTITY() → PostgreSQL: RETURNING clause or currval()
-- 
-- 3. Date/Time Functions:
--    - GETDATE() → PostgreSQL: NOW() or CURRENT_TIMESTAMP
-- 
-- 4. Variable Declarations:
--    - DECLARE @Variable TYPE → PostgreSQL: May need DO block or function context
--    - SET @Variable = value → PostgreSQL: variable := value
-- 
-- 5. Window Functions:
--    - LAG, RANK, PERCENT_RANK, AVG OVER, COUNT OVER, MIN OVER, MAX OVER
--    - Generally compatible with PostgreSQL but syntax may need adjustment
-- 
-- 6. Parameter Syntax:
--    - @ParameterName → PostgreSQL: May convert to $1, $2 or keep named parameters
-- 
-- 7. Data Types:
--    - DECIMAL(18,2) → PostgreSQL: NUMERIC(18,2) or DECIMAL(18,2)
--    - INT → PostgreSQL: INTEGER or INT
--    - NVARCHAR → PostgreSQL: VARCHAR or TEXT
-- 
-- 8. Functions:
--    - ROUND() → PostgreSQL: ROUND() (compatible)
--    - CASE expressions → PostgreSQL: CASE (compatible)
-- 
-- 9. Wildcard SELECT:
--    - p.* in CTEs → PostgreSQL: Compatible but column list preferred
-- 
-- ========================================================================================================
