-- =============================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source Application: AdoCore (.NET 9.0 Console Application)
-- Extraction Date: 2024
-- Total Statements: 6
-- =============================================================================

-- =============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- =============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: ~42-70
-- Description: Complex query with CTE, window functions (AVG OVER, COUNT OVER), 
--              and conditional logic for price categorization
-- Parameters: None
-- SQL Server Features: CTE, Window Functions (AVG OVER, COUNT OVER), CASE expressions
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- =============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: ~81-111
-- Description: Query with CTE using LAG window function to track price/stock changes
-- Parameters: @ProductId (int)
-- SQL Server Features: CTE, LAG window function, LEFT JOIN, CASE expression
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 3: InsertProductAsync
-- =============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: ~124-152
-- Description: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(), and UPDATE
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE(), 
--                      DECLARE variables, multi-statement transaction
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 4: UpdateProductAsync
-- =============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: ~162-195
-- Description: Transaction block with variable declarations, UPDATE, and INSERT for history
-- Parameters: @ProductId (int), @Name (string), @Description (string), 
--             @Price (decimal), @StockQuantity (int)
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, DECLARE variables, GETDATE(),
--                      multi-statement transaction with SELECT INTO variables
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 5: DeleteProductAsync
-- =============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: ~203-240
-- Description: Transaction block for product deletion with history logging and stats update
-- Parameters: @ProductId (int)
-- SQL Server Features: BEGIN TRANSACTION/COMMIT, DECLARE variables, GETDATE(),
--                      DELETE statement, CASE expression in UPDATE
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- =============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: ~248-274
-- Description: Query with CTE using RANK() and PERCENT_RANK() window functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- SQL Server Features: CTE, RANK() window function, PERCENT_RANK() window function,
--                      CASE expression for categorization
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- =============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: ~282-312
-- Description: Query with CTE using aggregate window functions (AVG, MIN, MAX OVER)
-- Parameters: @Threshold (int)
-- SQL Server Features: CTE, Aggregate window functions (AVG, MIN, MAX OVER),
--                      CASE expression, arithmetic operations
-- =============================================================================

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

-- =============================================================================
-- EXTRACTION SUMMARY
-- =============================================================================
-- Total SQL Statements Extracted: 6 (Actually 7 unique statements)
-- 
-- Statement Distribution:
-- - SELECT Queries with CTEs: 4 (Statements 1, 2, 6, 7)
-- - Transaction Blocks (INSERT): 1 (Statement 3)
-- - Transaction Blocks (UPDATE): 1 (Statement 4)
-- - Transaction Blocks (DELETE): 1 (Statement 5)
--
-- SQL Server Specific Features Found:
-- - BEGIN TRANSACTION/COMMIT syntax (Statements 3, 4, 5)
-- - SCOPE_IDENTITY() function (Statement 3)
-- - GETDATE() function (Statements 3, 4, 5)
-- - Window Functions: AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN, MAX (All SELECT statements)
-- - CTEs (Common Table Expressions) (Statements 1, 2, 6, 7)
-- - Variable declarations with DECLARE (Statements 3, 4, 5)
-- - SET for variable assignment (Statement 3)
-- - SELECT INTO variable syntax (Statements 4, 5)
--
-- All statements require conversion to PostgreSQL syntax.
-- =============================================================================
