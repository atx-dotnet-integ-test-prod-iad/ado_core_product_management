-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: ADO.NET Application
-- Date: 2026-02-11
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Statement ID: 1_GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: GetAllProductsAsync()
-- Line Range: ~42-68
-- Description: Complex CTE query with window functions (AVG OVER, COUNT OVER), 
--              CASE statements, and ROUND functions for product listing with price analysis
-- Parameters: None
-- Transaction Context: No explicit transaction
-- Returns: Multiple rows (all products with statistics)
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
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Statement ID: 2_GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: GetProductByIdAsync(int productId)
-- Line Range: ~84-110
-- Description: CTE with LAG window functions for historical price/stock comparison,
--              LEFT JOIN, parameterized query for single product retrieval
-- Parameters: 
--   @ProductId (INT) - Product identifier to retrieve
-- Transaction Context: No explicit transaction
-- Returns: Single row (one product with history)
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
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Statement ID: 3_InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: InsertProductAsync(Product product)
-- Line Range: ~122-151
-- Description: Multi-statement transaction with BEGIN TRANSACTION/COMMIT,
--              INSERT with SCOPE_IDENTITY() for new product ID retrieval,
--              UPDATE with GETDATE() for timestamps, ProductHistory logging
-- Parameters:
--   @Name (NVARCHAR) - Product name
--   @Description (NVARCHAR) - Product description (nullable)
--   @Price (DECIMAL(18,2)) - Product price
--   @StockQuantity (INT) - Initial stock quantity
-- Transaction Context: Explicit BEGIN TRANSACTION...COMMIT block
-- Returns: Scalar value (new product ID)
-- Special Notes: Uses SCOPE_IDENTITY() to get last inserted ID
--                Uses GETDATE() for current timestamp
--                Variable declaration with DECLARE @NewProductId
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Statement ID: 4_UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: UpdateProductAsync(Product product)
-- Line Range: ~158-198
-- Description: Multi-statement transaction with variable declarations,
--              SELECT for retrieving old values, UPDATE for product modification,
--              INSERT into history table for audit trail
-- Parameters:
--   @ProductId (INT) - Product identifier to update
--   @Name (NVARCHAR) - Updated product name
--   @Description (NVARCHAR) - Updated product description (nullable)
--   @Price (DECIMAL(18,2)) - Updated product price
--   @StockQuantity (INT) - Updated stock quantity
-- Transaction Context: Explicit BEGIN TRANSACTION...COMMIT block
-- Returns: No return value (ExecuteNonQueryAsync)
-- Special Notes: Uses DECLARE for @OldPrice and @OldStock variables
--                Uses GETDATE() for timestamps
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Statement ID: 5_DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: DeleteProductAsync(int productId)
-- Line Range: ~205-244
-- Description: Multi-statement transaction with variable declarations,
--              INSERT into history for audit, DELETE operation,
--              UPDATE with CASE expression for statistics recalculation
-- Parameters:
--   @ProductId (INT) - Product identifier to delete
-- Transaction Context: Explicit BEGIN TRANSACTION...COMMIT block
-- Returns: No return value (ExecuteNonQueryAsync)
-- Special Notes: Uses DECLARE for @OldPrice and @OldStock variables
--                Uses GETDATE() for timestamps
--                CASE expression in UPDATE for conditional average calculation
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Statement ID: 6_GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: ~251-280
-- Description: CTE with RANK() and PERCENT_RANK() window functions for price analysis,
--              CASE statement for price segmentation, parameterized query with range
-- Parameters:
--   @MinPrice (DECIMAL(18,2)) - Minimum price for range filter
--   @MaxPrice (DECIMAL(18,2)) - Maximum price for range filter
-- Transaction Context: No explicit transaction
-- Returns: Multiple rows (products within price range with rankings)
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Statement ID: 7_GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Line Range: ~287-318
-- Description: CTE with multiple window functions (AVG, MIN, MAX OVER) for stock analysis,
--              CASE statement for stock status categorization, ROUND function
-- Parameters:
--   @Threshold (INT) - Maximum stock quantity to include
-- Transaction Context: No explicit transaction
-- Returns: Multiple rows (low stock products with analysis)
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
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ============================================================================
-- END OF EXTRACTED STATEMENTS
-- ============================================================================
-- Summary:
-- Total Statements Extracted: 7
-- Statements with Parameters: 5 (Statements 2, 3, 4, 5, 6, 7)
-- Statements with Transactions: 3 (Statements 3, 4, 5)
-- Statements with Window Functions: 5 (Statements 1, 2, 6, 7)
-- Statements with CTEs: 5 (Statements 1, 2, 6, 7)
-- Statements with Variables: 3 (Statements 3, 4, 5)
--
-- Key SQL Server Features Identified:
-- - SCOPE_IDENTITY() - Statement 3
-- - GETDATE() - Statements 3, 4, 5
-- - DECLARE variable syntax - Statements 3, 4, 5
-- - BEGIN TRANSACTION/COMMIT - Statements 3, 4, 5
-- - Window functions: AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN, MAX
-- - CASE expressions
-- - ROUND function
-- - CTEs (WITH clauses)
-- ============================================================================
