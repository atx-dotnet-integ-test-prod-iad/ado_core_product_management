-- ========================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Project: AdoCore - Microsoft SQL Server to PostgreSQL Migration
-- Purpose: Comprehensive catalog of all SQL statements extracted from codebase
-- Total Statements: 7 (as per inventory in plan)
-- Date: Migration Phase 1
-- ========================================

-- ========================================
-- STATEMENT #1: GetAllProductsAsync
-- ========================================
-- Location: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Lines: ~41-71
-- Type: CTE with window functions (AVG OVER, COUNT OVER)
-- Complexity: High
-- Features: CTE, Window Functions, CASE statement, ROUND function
-- Parameters: None
-- ========================================

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

-- ========================================
-- STATEMENT #2: GetProductByIdAsync
-- ========================================
-- Location: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Lines: ~82-112
-- Type: CTE with LAG window function
-- Complexity: High
-- Features: CTE, LAG OVER, CASE statement, parameterized query
-- Parameters: @ProductId (INT)
-- ========================================

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

-- ========================================
-- STATEMENT #3: InsertProductAsync
-- ========================================
-- Location: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Lines: ~121-146
-- Type: Multi-statement transaction with SCOPE_IDENTITY
-- Complexity: High
-- Features: DECLARE, BEGIN TRANSACTION, COMMIT, SCOPE_IDENTITY(), GETDATE(), multi-table insert
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- ========================================

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

-- ========================================
-- STATEMENT #4: UpdateProductAsync
-- ========================================
-- Location: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Lines: ~155-186
-- Type: Multi-statement transaction with DECLARE
-- Complexity: High
-- Features: DECLARE, BEGIN TRANSACTION, COMMIT, GETDATE(), multi-table update
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- ========================================

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

-- ========================================
-- STATEMENT #5: DeleteProductAsync
-- ========================================
-- Location: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Lines: ~195-226
-- Type: Multi-statement transaction with conditional logic
-- Complexity: High
-- Features: DECLARE, BEGIN TRANSACTION, COMMIT, GETDATE(), CASE in UPDATE
-- Parameters: @ProductId (INT)
-- ========================================

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

-- ========================================
-- STATEMENT #6: GetProductsByPriceRangeAsync
-- ========================================
-- Location: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: ~235-258
-- Type: CTE with ranking window functions
-- Complexity: High
-- Features: CTE, RANK OVER, PERCENT_RANK OVER, CASE statement, BETWEEN
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- ========================================

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

-- ========================================
-- STATEMENT #7: GetLowStockProductsAsync
-- ========================================
-- Location: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: ~267-291
-- Type: CTE with multiple window functions
-- Complexity: High
-- Features: CTE, AVG OVER, MIN OVER, MAX OVER, CASE statement, ROUND function
-- Parameters: @Threshold (INT)
-- ========================================

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

-- ========================================
-- EXTRACTION SUMMARY
-- ========================================
-- Total SQL Statements Extracted: 7
-- 
-- Statement Types:
-- - CTEs with Window Functions: 4 (Statements #1, #2, #6, #7)
-- - Multi-statement Transactions: 3 (Statements #3, #4, #5)
--
-- SQL Server Specific Features Requiring Conversion:
-- 1. SCOPE_IDENTITY() - Statement #3
-- 2. GETDATE() - Statements #3, #4, #5
-- 3. BEGIN TRANSACTION / COMMIT syntax - Statements #3, #4, #5
-- 4. DECLARE variable syntax - Statements #3, #4, #5
-- 5. Window functions (AVG OVER, LAG OVER, RANK, PERCENT_RANK, MIN OVER, MAX OVER)
-- 6. ROUND function syntax compatibility
-- 7. CASE statement syntax
--
-- All statements are ready for DMS MCP tool conversion.
-- ========================================
