-- ========================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: Microsoft SQL Server (ADO.NET Application)
-- Target: PostgreSQL Migration
-- Extraction Date: 2026-02-08
-- ========================================

-- ========================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line: 38-68
-- Type: SELECT with CTE, Window Functions, CASE expressions
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
-- STATEMENT 2: GetProductByIdAsync
-- Source File: ProductRepository.cs
-- Method: GetProductByIdAsync
-- Line: 80-106
-- Type: SELECT with CTE, LAG Window Function, CASE expression
-- Parameters: @ProductId (int)
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
-- STATEMENT 3: InsertProductAsync
-- Source File: ProductRepository.cs
-- Method: InsertProductAsync
-- Line: 120-146
-- Type: Transaction Block with INSERT, SCOPE_IDENTITY(), GETDATE()
-- Parameters: @Name, @Description, @Price, @StockQuantity
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
-- STATEMENT 4: UpdateProductAsync
-- Source File: ProductRepository.cs
-- Method: UpdateProductAsync
-- Line: 160-190
-- Type: Transaction Block with UPDATE, Variables, GETDATE()
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
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
-- STATEMENT 5: DeleteProductAsync
-- Source File: ProductRepository.cs
-- Method: DeleteProductAsync
-- Line: 204-237
-- Type: Transaction Block with DELETE, Variables, GETDATE()
-- Parameters: @ProductId
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
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Line: 251-279
-- Type: SELECT with CTE, RANK(), PERCENT_RANK() Window Functions
-- Parameters: @MinPrice, @MaxPrice
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
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Line: 293-323
-- Type: SELECT with CTE, Aggregate Window Functions (AVG, MIN, MAX OVER)
-- Parameters: @Threshold
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
-- Methods with SQL: 7
-- Transaction Blocks: 3 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
-- CTE Queries: 5 (GetAllProductsAsync, GetProductByIdAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
-- Window Functions Used: AVG OVER, COUNT OVER, LAG OVER, RANK OVER, PERCENT_RANK OVER, MIN OVER, MAX OVER
-- SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE()
-- ========================================
