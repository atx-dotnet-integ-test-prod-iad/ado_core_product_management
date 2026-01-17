-- ===============================================================================
-- SQL Statement Extraction Catalog for PostgreSQL Migration
-- Source: ProductRepository.cs (AdoCore.DataAccess namespace)
-- Total Statements: 7
-- Extraction Date: 2026-01-17
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions (AVG OVER, COUNT OVER)
-- ===============================================================================
-- Method: GetAllProductsAsync()
-- File: DataAccess/ProductRepository.cs
-- Line Range: 42-66
-- Parameters: None
-- Transaction Context: None
-- SQL Server Specific Features:
--   - CTE (WITH ProductStats AS)
--   - Window functions: AVG(Price) OVER(), COUNT(*) OVER()
--   - CASE expressions
--   - ROUND function
-- Description: Retrieves all products with price statistics and categorization
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ===============================================================================
-- Method: GetProductByIdAsync(int productId)
-- File: DataAccess/ProductRepository.cs
-- Line Range: 77-105
-- Parameters: @ProductId (int)
-- Transaction Context: None
-- SQL Server Specific Features:
--   - CTE (WITH ProductHistory AS)
--   - Window function: LAG(Price) OVER (ORDER BY ModifiedDate)
--   - Window function: LAG(StockQuantity) OVER (ORDER BY ModifiedDate)
--   - CASE expressions
--   - ROUND function
-- Description: Retrieves product by ID with historical price and stock information
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with SCOPE_IDENTITY and GETDATE
-- ===============================================================================
-- Method: InsertProductAsync(Product product)
-- File: DataAccess/ProductRepository.cs
-- Line Range: 123-148
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Transaction Context: BEGIN TRANSACTION / COMMIT
-- SQL Server Specific Features:
--   - SCOPE_IDENTITY() - Returns last identity value inserted
--   - GETDATE() - Returns current date/time (appears 3 times)
--   - BEGIN TRANSACTION / COMMIT syntax
--   - Variable declarations with DECLARE @NewProductId INT
--   - SET @NewProductId = SCOPE_IDENTITY()
--   - Multi-statement transaction block
-- Description: Inserts new product, logs to history, updates statistics, returns new ID
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with GETDATE
-- ===============================================================================
-- Method: UpdateProductAsync(Product product)
-- File: DataAccess/ProductRepository.cs
-- Line Range: 161-189
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Transaction Context: BEGIN TRANSACTION / COMMIT
-- SQL Server Specific Features:
--   - GETDATE() - Returns current date/time (appears 3 times)
--   - BEGIN TRANSACTION / COMMIT syntax
--   - Variable declarations with DECLARE
--   - Multi-statement transaction block
--   - DECIMAL(18,2) data type
-- Description: Updates product, logs changes to history, updates statistics
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with GETDATE
-- ===============================================================================
-- Method: DeleteProductAsync(int productId)
-- File: DataAccess/ProductRepository.cs
-- Line Range: 204-232
-- Parameters: @ProductId
-- Transaction Context: BEGIN TRANSACTION / COMMIT
-- SQL Server Specific Features:
--   - GETDATE() - Returns current date/time (appears 2 times)
--   - BEGIN TRANSACTION / COMMIT syntax
--   - Variable declarations with DECLARE
--   - Multi-statement transaction block
--   - DECIMAL(18,2) data type
--   - Complex CASE expression for average calculation
-- Description: Deletes product, logs to history, updates statistics
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK Window Functions
-- ===============================================================================
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- File: DataAccess/ProductRepository.cs
-- Line Range: 249-265
-- Parameters: @MinPrice, @MaxPrice
-- Transaction Context: None
-- SQL Server Specific Features:
--   - CTE (WITH RankedProducts AS)
--   - Window function: RANK() OVER (ORDER BY p.Price)
--   - Window function: PERCENT_RANK() OVER (ORDER BY p.Price)
--   - CASE expressions
--   - BETWEEN operator
-- Description: Retrieves products within price range with ranking and percentile information
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ===============================================================================
-- Method: GetLowStockProductsAsync(int threshold)
-- File: DataAccess/ProductRepository.cs
-- Line Range: 284-302
-- Parameters: @Threshold
-- Transaction Context: None
-- SQL Server Specific Features:
--   - CTE (WITH StockAnalysis AS)
--   - Window functions: AVG(StockQuantity) OVER()
--   - Window functions: MIN(StockQuantity) OVER()
--   - Window functions: MAX(StockQuantity) OVER()
--   - CASE expressions
--   - ROUND function
-- Description: Retrieves products below stock threshold with stock analysis
-- ===============================================================================

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

-- ===============================================================================
-- EXTRACTION SUMMARY
-- ===============================================================================
-- Total SQL Statements Extracted: 7
-- 
-- Statements by Category:
--   - SELECT with CTEs and Window Functions: 4 (Statements 1, 2, 6, 7)
--   - Multi-Statement Transactions (INSERT): 1 (Statement 3)
--   - Multi-Statement Transactions (UPDATE): 1 (Statement 4)
--   - Multi-Statement Transactions (DELETE): 1 (Statement 5)
-- 
-- SQL Server Specific Features Requiring Conversion:
--   1. SCOPE_IDENTITY() - Used in Statement 3 (needs RETURNING clause conversion)
--   2. GETDATE() - Used in Statements 3, 4, 5 (needs NOW() or CURRENT_TIMESTAMP)
--   3. BEGIN TRANSACTION/COMMIT - Used in Statements 3, 4, 5 (PostgreSQL syntax)
--   4. Window Functions - All statements use standard SQL window functions (should be compatible)
--   5. CTEs - All statements use standard SQL CTEs (should be compatible)
--   6. DECLARE/SET variables - Used in Statements 3, 4, 5 (PostgreSQL uses different syntax)
--   7. DECIMAL(18,2) - Used in Statements 4, 5 (PostgreSQL uses NUMERIC or DECIMAL)
-- 
-- Parameters Used:
--   - @ProductId (Statements 2)
--   - @Name, @Description, @Price, @StockQuantity (Statements 3, 4)
--   - @MinPrice, @MaxPrice (Statement 6)
--   - @Threshold (Statement 7)
-- 
-- Tables Referenced:
--   - Products (Primary table in all statements)
--   - ProductHistory (Statements 3, 4, 5)
--   - ProductStats (Statements 3, 4, 5)
-- ===============================================================================
