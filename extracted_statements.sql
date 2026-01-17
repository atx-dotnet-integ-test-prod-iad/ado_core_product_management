-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Purpose: Comprehensive documentation of all SQL statements from ProductRepository.cs
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source Method: GetAllProductsAsync()
-- Location: ProductRepository.cs, Line 38
-- Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Complexity: High (CTE, window functions, CASE statements, complex ordering)
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
-- Source Method: GetProductByIdAsync(int productId)
-- Location: ProductRepository.cs, Line 78
-- Type: SELECT with CTE and LAG Window Function
-- Parameters: 
--   @ProductId (int) - Product identifier
-- Complexity: High (CTE, LAG window function, complex CASE expressions)
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
-- Source Method: InsertProductAsync(Product product)
-- Location: ProductRepository.cs, Line 116
-- Type: Multi-Statement Transaction (INSERT + LOG + UPDATE)
-- Parameters: 
--   @Name (string) - Product name
--   @Description (string, nullable) - Product description
--   @Price (decimal) - Product price
--   @StockQuantity (int) - Stock quantity
-- Complexity: Very High (Transaction, SCOPE_IDENTITY, GETDATE, multiple statements)
-- SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE()
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
-- Source Method: UpdateProductAsync(Product product)
-- Location: ProductRepository.cs, Line 142
-- Type: Multi-Statement Transaction (SELECT + UPDATE + INSERT)
-- Parameters: 
--   @ProductId (int) - Product identifier
--   @Name (string) - Product name
--   @Description (string, nullable) - Product description
--   @Price (decimal) - Product price
--   @StockQuantity (int) - Stock quantity
-- Complexity: Very High (Transaction, variable declarations, multiple statements)
-- SQL Server Specific Functions: GETDATE()
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
-- Source Method: DeleteProductAsync(int productId)
-- Location: ProductRepository.cs, Line 176
-- Type: Multi-Statement Transaction (SELECT + INSERT + DELETE + UPDATE)
-- Parameters: 
--   @ProductId (int) - Product identifier
-- Complexity: Very High (Transaction, variable declarations, conditional logic)
-- SQL Server Specific Functions: GETDATE()
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
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Location: ProductRepository.cs, Line 211
-- Type: SELECT with CTE and Window Functions
-- Parameters: 
--   @MinPrice (decimal) - Minimum price for range
--   @MaxPrice (decimal) - Maximum price for range
-- Complexity: High (CTE, RANK, PERCENT_RANK window functions, complex CASE)
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
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Location: ProductRepository.cs, Line 241
-- Type: SELECT with CTE and Window Functions
-- Parameters: 
--   @Threshold (int) - Stock quantity threshold
-- Complexity: High (CTE, AVG/MIN/MAX window functions, complex CASE)
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
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total Statements Extracted: 7
-- Simple SELECT Queries: 0
-- Complex SELECT with CTE/Window Functions: 4 (Statements 1, 2, 6, 7)
-- Multi-Statement Transactions: 3 (Statements 3, 4, 5)
-- SQL Server Specific Functions to Convert:
--   - SCOPE_IDENTITY() (Statement 3) → PostgreSQL RETURNING or sequence
--   - GETDATE() (Statements 3, 4, 5) → NOW() or CURRENT_TIMESTAMP
-- Window Functions Used: AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN OVER, MAX OVER
-- Transaction Blocks: 3 (BEGIN TRANSACTION...COMMIT)
-- Variable Declarations: Multiple DECLARE statements in transactions
-- ============================================================================
