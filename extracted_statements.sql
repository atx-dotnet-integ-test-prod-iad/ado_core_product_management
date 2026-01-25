-- ========================================
-- EXTRACTED SQL STATEMENTS FROM PRODUCTREPOSITORY.CS
-- Microsoft SQL Server to PostgreSQL Migration
-- Date: 2026-01-24
-- ========================================

-- ========================================
-- STATEMENT ID: 1
-- SOURCE METHOD: GetAllProductsAsync
-- SOURCE LOCATION: ProductRepository.cs, Line 39
-- STATEMENT TYPE: SELECT
-- SPECIAL FEATURES: Common Table Expressions (CTEs), Window Functions (AVG OVER, COUNT OVER), CASE expressions
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
-- STATEMENT ID: 2
-- SOURCE METHOD: GetProductByIdAsync
-- SOURCE LOCATION: ProductRepository.cs, Line 82
-- STATEMENT TYPE: SELECT
-- SPECIAL FEATURES: Common Table Expressions (CTEs), Window Functions (LAG OVER), CASE expressions, Parameterized query (@ProductId)
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
-- STATEMENT ID: 3
-- SOURCE METHOD: InsertProductAsync
-- SOURCE LOCATION: ProductRepository.cs, Line 121
-- STATEMENT TYPE: INSERT (within TRANSACTION)
-- SPECIAL FEATURES: Transaction Block (BEGIN TRANSACTION/COMMIT), SCOPE_IDENTITY(), GETDATE(), DECLARE variables, Multiple INSERT/UPDATE statements
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
-- STATEMENT ID: 4
-- SOURCE METHOD: UpdateProductAsync
-- SOURCE LOCATION: ProductRepository.cs, Line 155
-- STATEMENT TYPE: UPDATE (within TRANSACTION)
-- SPECIAL FEATURES: Transaction Block (BEGIN TRANSACTION/COMMIT), GETDATE(), DECLARE variables, Multiple SELECT/UPDATE/INSERT statements
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
-- STATEMENT ID: 5
-- SOURCE METHOD: DeleteProductAsync
-- SOURCE LOCATION: ProductRepository.cs, Line 195
-- STATEMENT TYPE: DELETE (within TRANSACTION)
-- SPECIAL FEATURES: Transaction Block (BEGIN TRANSACTION/COMMIT), GETDATE(), DECLARE variables, Multiple SELECT/INSERT/DELETE/UPDATE statements
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
-- STATEMENT ID: 6
-- SOURCE METHOD: GetProductsByPriceRangeAsync
-- SOURCE LOCATION: ProductRepository.cs, Line 240
-- STATEMENT TYPE: SELECT
-- SPECIAL FEATURES: Common Table Expressions (CTEs), Window Functions (RANK OVER, PERCENT_RANK OVER), CASE expressions, Parameterized query (@MinPrice, @MaxPrice)
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
-- STATEMENT ID: 7
-- SOURCE METHOD: GetLowStockProductsAsync
-- SOURCE LOCATION: ProductRepository.cs, Line 270
-- STATEMENT TYPE: SELECT
-- SPECIAL FEATURES: Common Table Expressions (CTEs), Window Functions (AVG OVER, MIN OVER, MAX OVER), CASE expressions, Parameterized query (@Threshold)
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
-- Total Statements Extracted: 7
-- Statement Types:
--   - SELECT: 4 (IDs 1, 2, 6, 7)
--   - INSERT (with transaction): 1 (ID 3)
--   - UPDATE (with transaction): 1 (ID 4)
--   - DELETE (with transaction): 1 (ID 5)
-- 
-- SQL Server-Specific Features Identified:
--   - Common Table Expressions (CTEs): 5 statements
--   - Window Functions: 7 statements total
--     * AVG OVER: 2 statements
--     * COUNT OVER: 1 statement
--     * LAG OVER: 1 statement
--     * RANK OVER: 1 statement
--     * PERCENT_RANK OVER: 1 statement
--     * MIN/MAX OVER: 1 statement
--   - Transaction Blocks (BEGIN TRANSACTION/COMMIT): 3 statements
--   - SCOPE_IDENTITY(): 1 statement
--   - GETDATE(): 5 occurrences across 3 statements
--   - DECLARE variables: 3 statements
--   - CASE expressions: 6 statements
--   - Parameterized queries: 5 statements
-- 
-- Next Steps:
--   1. Pass each statement through DMS MCP tool for PostgreSQL conversion
--   2. Validate each statement pair using SQL Equivalency tool
--   3. Re-integrate converted statements back into ProductRepository.cs
-- ========================================
