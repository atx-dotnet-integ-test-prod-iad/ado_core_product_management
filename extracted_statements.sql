-- ================================================================================================
-- EXTRACTED SQL STATEMENTS FOR DMS CONVERSION
-- Source File: ProductRepository.cs
-- Total Statements: 7
-- Extraction Date: 2025-01-22
-- ================================================================================================

-- ================================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Method: GetAllProductsAsync()
-- Line Numbers: 38-70
-- Type: Complex CTE with window functions and joins
-- Features: CTE, AVG() OVER(), COUNT() OVER(), INNER JOIN, CASE expressions, ROUND()
-- ================================================================================================
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

-- ================================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: 84-115
-- Type: CTE with LAG window function
-- Features: CTE, LAG() OVER(), LEFT JOIN, parameterized query (@ProductId), NULL handling
-- Parameters: @ProductId (int)
-- ================================================================================================
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

-- ================================================================================================
-- STATEMENT 3: InsertProductAsync
-- Method: InsertProductAsync(Product product)
-- Line Numbers: 127-154
-- Type: Multi-statement transaction with INSERT and UPDATE
-- Features: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE, COMMIT
-- SQL Server Specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT syntax
-- Parameters: @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- Returns: @NewProductId (int)
-- ================================================================================================
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

-- ================================================================================================
-- STATEMENT 4: UpdateProductAsync
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: 169-203
-- Type: Multi-statement transaction with DECLARE, SELECT, UPDATE, INSERT
-- Features: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE(), COMMIT
-- SQL Server Specific: GETDATE(), BEGIN TRANSACTION/COMMIT syntax, variable declarations
-- Parameters: @ProductId (int), @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- ================================================================================================
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

-- ================================================================================================
-- STATEMENT 5: DeleteProductAsync
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: 217-252
-- Type: Multi-statement transaction with DELETE and UPDATE
-- Features: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE, GETDATE(), COMMIT
-- SQL Server Specific: GETDATE(), BEGIN TRANSACTION/COMMIT syntax, variable declarations
-- Parameters: @ProductId (int)
-- ================================================================================================
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

-- ================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 266-292
-- Type: CTE with RANK and PERCENT_RANK window functions
-- Features: CTE, RANK() OVER(), PERCENT_RANK() OVER(), CASE expression
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- ================================================================================================
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

-- ================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 306-335
-- Type: CTE with multiple window aggregate functions
-- Features: CTE, AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE expression, ROUND()
-- Parameters: @Threshold (int)
-- ================================================================================================
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

-- ================================================================================================
-- EXTRACTION SUMMARY
-- ================================================================================================
-- Total SQL Statements Extracted: 7
-- Simple SELECT Statements: 4 (Statements 1, 2, 6, 7)
-- Complex Transaction Blocks: 3 (Statements 3, 4, 5)
-- Statements with CTEs: 6 (All except Statement 3)
-- Statements with Window Functions: 6 (All except Statement 3)
-- Statements with SQL Server-specific functions: 3 (Statements 3, 4, 5 - SCOPE_IDENTITY, GETDATE)
-- Parameterized Statements: 6 (All except Statement 1)
-- 
-- SQL Server-Specific Features Requiring Conversion:
-- - SCOPE_IDENTITY() in Statement 3 -> PostgreSQL RETURNING clause or currval()/lastval()
-- - GETDATE() in Statements 3, 4, 5 -> PostgreSQL NOW() or CURRENT_TIMESTAMP
-- - BEGIN TRANSACTION/COMMIT syntax in Statements 3, 4, 5 -> PostgreSQL BEGIN/COMMIT
-- - T-SQL variable declarations (DECLARE @Variable) -> PostgreSQL variable handling
-- - Parameter syntax @ParameterName -> PostgreSQL $1, $2, etc. or named parameters
-- 
-- Tables Referenced:
-- - Products (primary table)
-- - ProductHistory (history logging)
-- - ProductStats (statistics tracking)
-- ================================================================================================
