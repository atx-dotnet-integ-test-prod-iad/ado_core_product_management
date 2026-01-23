-- ================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Microsoft SQL Server T-SQL Statements for DMS Conversion
-- ================================================================
-- Total Statements: 6
-- Source File: DataAccess/ProductRepository.cs
-- Extraction Date: 2025-01-23
-- ================================================================

-- ================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ================================================================
-- Location: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync, Line: 41-68
-- Type: SELECT with CTE, Window Functions, CASE expressions
-- Complexity: High
-- Features: CTE, AVG OVER, COUNT OVER, CASE WHEN, ROUND, INNER JOIN
-- ================================================================

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

-- ================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ================================================================
-- Location: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync, Line: 84-108
-- Type: SELECT with CTE, LAG Window Function, Parameters
-- Complexity: High
-- Features: CTE, LAG OVER, parameterized query (@ProductId), CASE WHEN, ROUND
-- Parameters: @ProductId (int)
-- ================================================================

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

-- ================================================================
-- STATEMENT 3: InsertProductAsync
-- ================================================================
-- Location: DataAccess/ProductRepository.cs, Method: InsertProductAsync, Line: 125-147
-- Type: Transaction with INSERT, UPDATE, SELECT
-- Complexity: Very High
-- Features: DECLARE variables, BEGIN TRANSACTION/COMMIT, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- T-SQL Specific: DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE()
-- ================================================================

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

-- ================================================================
-- STATEMENT 4: UpdateProductAsync
-- ================================================================
-- Location: DataAccess/ProductRepository.cs, Method: UpdateProductAsync, Line: 162-190
-- Type: Transaction with DECLARE, SELECT, UPDATE, INSERT
-- Complexity: Very High
-- Features: BEGIN TRANSACTION/COMMIT, DECLARE variables, SELECT into variables, UPDATE, INSERT, GETDATE()
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- T-SQL Specific: DECLARE, BEGIN TRANSACTION, SELECT into variables, GETDATE()
-- ================================================================

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

-- ================================================================
-- STATEMENT 5: DeleteProductAsync
-- ================================================================
-- Location: DataAccess/ProductRepository.cs, Method: DeleteProductAsync, Line: 207-234
-- Type: Transaction with DECLARE, SELECT, INSERT, DELETE, UPDATE
-- Complexity: Very High
-- Features: BEGIN TRANSACTION/COMMIT, DECLARE variables, SELECT into variables, DELETE, INSERT, UPDATE with CASE, GETDATE()
-- Parameters: @ProductId (int)
-- T-SQL Specific: DECLARE, BEGIN TRANSACTION, SELECT into variables, CASE in UPDATE, GETDATE()
-- ================================================================

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

-- ================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ================================================================
-- Location: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync, Line: 249-268
-- Type: SELECT with CTE, RANK and PERCENT_RANK Window Functions
-- Complexity: High
-- Features: CTE, RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE WHEN
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- ================================================================

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

-- ================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ================================================================
-- Location: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync, Line: 283-304
-- Type: SELECT with CTE, Multiple Window Functions
-- Complexity: High
-- Features: CTE, AVG OVER, MIN OVER, MAX OVER, CASE WHEN, ROUND
-- Parameters: @Threshold (int)
-- ================================================================

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

-- ================================================================
-- END OF EXTRACTED STATEMENTS
-- ================================================================
-- Total Complex Statements Extracted: 7
-- CTE Usage: 6 statements
-- Window Functions: 6 statements (AVG OVER, COUNT OVER, LAG OVER, RANK, PERCENT_RANK, MIN OVER, MAX OVER)
-- Transaction Blocks: 3 statements (Insert, Update, Delete)
-- T-SQL Specific Constructs: DECLARE, SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
-- Parameterized Queries: 6 statements
-- ================================================================
