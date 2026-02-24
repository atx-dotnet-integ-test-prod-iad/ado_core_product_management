-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Source File: ProductRepository.cs
-- Total Statements: 7
-- Extraction Date: Microsoft SQL Server to PostgreSQL Migration
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Method: GetAllProductsAsync()
-- Lines: 39-70
-- Type: SELECT with CTE
-- Complexity: High (CTE with window functions, CASE expressions, JOINs)
-- Parameters: None
-- Description: Complex query using CTE with AVG and COUNT window functions,
--              CASE expressions for categorization, and calculated columns.
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
    p.Name

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Method: GetProductByIdAsync(int productId)
-- Lines: 80-111
-- Type: SELECT with CTE and parameterized query
-- Complexity: High (CTE with LAG window function, parameterized query)
-- Parameters: @ProductId (int)
-- Description: Uses CTE with LAG window function to track price/stock changes,
--              includes calculated percentage changes, parameterized WHERE clause.
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
WHERE p.ProductId = @ProductId

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- Method: InsertProductAsync(Product product)
-- Lines: 122-151
-- Type: Multi-statement transaction (INSERT, UPDATE)
-- Complexity: Very High (Transaction with SCOPE_IDENTITY, GETDATE, multiple DML)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Description: Multi-statement transaction including INSERT with SCOPE_IDENTITY,
--              history logging, and statistics updates using GETDATE().
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
-- Method: UpdateProductAsync(Product product)
-- Lines: 164-198
-- Type: Multi-statement transaction (SELECT, UPDATE, INSERT)
-- Complexity: Very High (Transaction with variable declarations, multiple DML)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Description: Complex transaction with variable declarations to store old values,
--              product update, history logging, and statistics recalculation.
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
-- Method: DeleteProductAsync(int productId)
-- Lines: 207-241
-- Type: Multi-statement transaction (SELECT, INSERT, DELETE, UPDATE)
-- Complexity: Very High (Transaction with complex calculations and CASE logic)
-- Parameters: @ProductId
-- Description: Transaction with variable declarations, history logging before deletion,
--              product deletion, and complex average price recalculation with CASE.
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
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: 252-280
-- Type: SELECT with CTE
-- Complexity: High (CTE with RANK, PERCENT_RANK window functions, CASE expression)
-- Parameters: @MinPrice, @MaxPrice
-- Description: Complex query using CTE with RANK and PERCENT_RANK window functions
--              to categorize products into price segments (Budget/Mid-Range/Premium).
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
ORDER BY rp.PriceRank

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: 291-322
-- Type: SELECT with CTE
-- Complexity: High (CTE with multiple aggregate window functions, CASE expressions)
-- Parameters: @Threshold
-- Description: Query using CTE with AVG, MIN, MAX window functions to analyze stock
--              levels, categorize stock status, and calculate percentages.
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
ORDER BY StockQuantity

-- ============================================================================
-- END OF EXTRACTED STATEMENTS
-- ============================================================================
