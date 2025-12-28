-- ========================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: ADO.NET Application (ProductRepository.cs)
-- Purpose: Catalog of all SQL Server statements for DMS conversion
-- Date: 2024
-- ========================================================================

-- ========================================================================
-- STATEMENT ID: 1
-- SOURCE FILE: DataAccess/ProductRepository.cs
-- METHOD: GetAllProductsAsync
-- LINE RANGE: 40-67
-- STATEMENT TYPE: SELECT with CTE and Window Functions
-- PARAMETERS: None
-- SQL SERVER FEATURES:
--   - Common Table Expression (WITH clause)
--   - Window functions (AVG OVER, COUNT OVER)
--   - CASE expressions
--   - INNER JOIN
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
    p.Name;

-- ========================================================================
-- STATEMENT ID: 2
-- SOURCE FILE: DataAccess/ProductRepository.cs
-- METHOD: GetProductByIdAsync
-- LINE RANGE: 82-110
-- STATEMENT TYPE: SELECT with CTE and LAG Window Function
-- PARAMETERS: @ProductId (INT)
-- SQL SERVER FEATURES:
--   - Common Table Expression (WITH clause)
--   - LAG window function for historical price tracking
--   - LEFT JOIN
--   - CASE expression for calculations
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
WHERE p.ProductId = @ProductId;

-- ========================================================================
-- STATEMENT ID: 3
-- SOURCE FILE: DataAccess/ProductRepository.cs
-- METHOD: InsertProductAsync
-- LINE RANGE: 124-145
-- STATEMENT TYPE: TRANSACTION with INSERT operations
-- PARAMETERS: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- SQL SERVER FEATURES:
--   - DECLARE statement for variables
--   - BEGIN TRANSACTION/COMMIT
--   - SCOPE_IDENTITY() for retrieving auto-increment value
--   - GETDATE() for current timestamp
--   - Multiple table inserts in transaction
--   - SELECT to return identity value
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
-- STATEMENT ID: 4
-- SOURCE FILE: DataAccess/ProductRepository.cs
-- METHOD: UpdateProductAsync
-- LINE RANGE: 160-188
-- STATEMENT TYPE: TRANSACTION with UPDATE operations
-- PARAMETERS: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- SQL SERVER FEATURES:
--   - BEGIN TRANSACTION/COMMIT
--   - DECLARE statements for variables
--   - SELECT into variables
--   - UPDATE statement
--   - INSERT for history logging
--   - GETDATE() for current timestamp
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
-- STATEMENT ID: 5
-- SOURCE FILE: DataAccess/ProductRepository.cs
-- METHOD: DeleteProductAsync
-- LINE RANGE: 202-232
-- STATEMENT TYPE: TRANSACTION with DELETE operations
-- PARAMETERS: @ProductId (INT)
-- SQL SERVER FEATURES:
--   - BEGIN TRANSACTION/COMMIT
--   - DECLARE statements for variables
--   - SELECT into variables
--   - INSERT for history logging
--   - DELETE statement
--   - UPDATE with CASE expression
--   - GETDATE() for current timestamp
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
-- STATEMENT ID: 6
-- SOURCE FILE: DataAccess/ProductRepository.cs
-- METHOD: GetProductsByPriceRangeAsync
-- LINE RANGE: 247-266
-- STATEMENT TYPE: SELECT with CTE and Window Functions
-- PARAMETERS: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- SQL SERVER FEATURES:
--   - Common Table Expression (WITH clause)
--   - RANK() window function
--   - PERCENT_RANK() window function
--   - BETWEEN for range filtering
--   - CASE expression
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
ORDER BY rp.PriceRank;

-- ========================================================================
-- STATEMENT ID: 7
-- SOURCE FILE: DataAccess/ProductRepository.cs
-- METHOD: GetLowStockProductsAsync
-- LINE RANGE: 281-303
-- STATEMENT TYPE: SELECT with CTE and Aggregation Window Functions
-- PARAMETERS: @Threshold (INT)
-- SQL SERVER FEATURES:
--   - Common Table Expression (WITH clause)
--   - AVG window function
--   - MIN window function
--   - MAX window function
--   - CASE expression
--   - ROUND function
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
ORDER BY StockQuantity;

-- ========================================================================
-- SUMMARY
-- ========================================================================
-- Total Statements Extracted: 7
-- SELECT Statements: 4 (IDs: 1, 2, 6, 7)
-- INSERT Transactions: 1 (ID: 3)
-- UPDATE Transactions: 1 (ID: 4)
-- DELETE Transactions: 1 (ID: 5)
--
-- SQL Server-Specific Features Identified:
-- - SCOPE_IDENTITY() (ID: 3)
-- - GETDATE() (IDs: 3, 4, 5)
-- - Window Functions: AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN, MAX (IDs: 1, 2, 6, 7)
-- - Common Table Expressions (IDs: 1, 2, 6, 7)
-- - Transaction Blocks (IDs: 3, 4, 5)
-- - DECLARE statements (IDs: 3, 4, 5)
-- - CASE expressions (IDs: 1, 2, 5, 6, 7)
-- ========================================================================
