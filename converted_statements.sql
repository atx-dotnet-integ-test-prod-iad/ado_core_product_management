-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Migration: Microsoft SQL Server to PostgreSQL
-- Source: AdoCore Application
-- Date: 2026-02-09
-- ============================================================================
-- This catalog contains all PostgreSQL converted SQL statements.
-- All statements were attempted through DMS MCP tool but failed with metadata
-- model creation errors. Manual conversions were applied following PostgreSQL
-- best practices and documented in dms_conversion_log.txt
-- ============================================================================

-- ============================================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source File: ProductRepository.cs
-- Method: GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Parameters: None
-- PostgreSQL Parameters: None
-- Changes: Added ::numeric cast for ROUND division, added semicolon
-- ============================================================================

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
    ROUND((p.Price / ps.AvgPrice)::numeric * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ============================================================================
-- CONVERTED STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Source File: ProductRepository.cs
-- Method: GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Parameters: @ProductId
-- PostgreSQL Parameters: @ProductId (Npgsql handles @ parameters)
-- Changes: Added ::numeric cast for complex division, added semicolon
-- ============================================================================

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
            ROUND((((p.Price - ph.PreviousPrice) / ph.PreviousPrice)::numeric) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ============================================================================
-- CONVERTED STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Source File: ProductRepository.cs
-- Method: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Parameters: @Name, @Description, @Price, @StockQuantity
-- PostgreSQL Parameters: @Name, @Description, @Price, @StockQuantity
-- Changes: SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), 
--          Transaction split into multiple ADO.NET commands
-- NOTE: This requires code refactoring to execute as separate commands within
--       an NpgsqlTransaction
-- ============================================================================

-- Command 1: Insert product and return new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Command 2: Insert history (executed with @NewProductId from previous result)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Command 3: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Source File: ProductRepository.cs
-- Method: UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- PostgreSQL Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity,
--                        @OldPrice, @OldStock (from first SELECT)
-- Changes: GETDATE() → NOW(), Transaction split into multiple ADO.NET commands,
--          DECLARE statements removed (handled in C# code)
-- NOTE: This requires code refactoring to execute as separate commands within
--       an NpgsqlTransaction
-- ============================================================================

-- Command 1: Get old values (store in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

-- Command 3: Log history
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Command 4: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Source File: ProductRepository.cs
-- Method: DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Parameters: @ProductId
-- PostgreSQL Parameters: @ProductId, @OldPrice, @OldStock (from first SELECT)
-- Changes: GETDATE() → NOW(), Transaction split into multiple ADO.NET commands,
--          DECLARE statements removed (handled in C# code)
-- NOTE: This requires code refactoring to execute as separate commands within
--       an NpgsqlTransaction
-- ============================================================================

-- Command 1: Get old values (store in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Command 2: Log deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Command 3: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Command 4: Update statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- ============================================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Source File: ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Parameters: @MinPrice, @MaxPrice
-- PostgreSQL Parameters: @MinPrice, @MaxPrice
-- Changes: Added semicolon (minimal changes, highly compatible)
-- ============================================================================

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

-- ============================================================================
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Source File: ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Parameters: @Threshold
-- PostgreSQL Parameters: @Threshold
-- Changes: Added ::numeric cast for ROUND division, added semicolon
-- ============================================================================

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
    ROUND((StockQuantity / AvgStock)::numeric * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements: 7
-- Conversion Method: All MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: All failed with metadata model creation errors
-- ============================================================================
