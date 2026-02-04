/*
==============================================================================
EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
Microsoft SQL Server to PostgreSQL Migration
==============================================================================
Source File: sourceCode/DataAccess/ProductRepository.cs
Extraction Date: 2026-02-04
Total Statements: 7
==============================================================================
*/

-- ==============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ==============================================================================
-- Source Location: ProductRepository.cs, Lines 38-68
-- Method: GetAllProductsAsync()
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Complexity: HIGH (CTE, Window Functions, CASE expressions, aggregates)
-- Tables Referenced: Products
-- Description: Retrieves all products with price analysis using window functions
--              to calculate average price and categorize products relative to average
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ==============================================================================
-- Source Location: ProductRepository.cs, Lines 82-112
-- Method: GetProductByIdAsync(int productId)
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @ProductId (int)
-- Complexity: HIGH (CTE, LAG window function, LEFT JOIN, calculated columns)
-- Tables Referenced: Products
-- Description: Retrieves a single product with historical price and stock comparison
--              using LAG window function to show previous values and calculate changes
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with SCOPE_IDENTITY()
-- ==============================================================================
-- Source Location: ProductRepository.cs, Lines 126-154
-- Method: InsertProductAsync(Product product)
-- Statement Type: TRANSACTION (BEGIN TRANSACTION, INSERT, UPDATE, COMMIT)
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Complexity: HIGH (Transaction block, SCOPE_IDENTITY(), multiple statements, GETDATE())
-- Tables Referenced: Products, ProductHistory, ProductStats
-- Description: Inserts a new product, logs the insertion in history, and updates
--              statistics. Uses SCOPE_IDENTITY() to retrieve the new ID and GETDATE()
--              for timestamps. Transaction ensures atomicity across all operations.
-- SQL Server Specific Features: SCOPE_IDENTITY(), BEGIN TRANSACTION, GETDATE(), DECLARE
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with Variables
-- ==============================================================================
-- Source Location: ProductRepository.cs, Lines 168-206
-- Method: UpdateProductAsync(Product product)
-- Statement Type: TRANSACTION (BEGIN TRANSACTION, UPDATE, INSERT, COMMIT)
-- Parameters: @ProductId (int), @Name (string), @Description (string), 
--             @Price (decimal), @StockQuantity (int)
-- Complexity: HIGH (Transaction block, DECLARE variables, multiple statements, GETDATE())
-- Tables Referenced: Products, ProductHistory, ProductStats
-- Description: Updates product information, captures old values in variables, logs
--              changes to history table, and updates statistics. Transaction ensures
--              all operations complete atomically.
-- SQL Server Specific Features: BEGIN TRANSACTION, GETDATE(), DECLARE
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with Deletion
-- ==============================================================================
-- Source Location: ProductRepository.cs, Lines 220-256
-- Method: DeleteProductAsync(int productId)
-- Statement Type: TRANSACTION (BEGIN TRANSACTION, DELETE, INSERT, UPDATE, COMMIT)
-- Parameters: @ProductId (int)
-- Complexity: HIGH (Transaction block, DECLARE variables, DELETE with history logging)
-- Tables Referenced: Products, ProductHistory, ProductStats
-- Description: Deletes a product after capturing its values for history logging,
--              updates statistics with conditional logic. Transaction ensures
--              atomicity of delete and related operations.
-- SQL Server Specific Features: BEGIN TRANSACTION, GETDATE(), DECLARE
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ==============================================================================
-- Source Location: ProductRepository.cs, Lines 270-298
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Complexity: HIGH (CTE, RANK and PERCENT_RANK window functions, CASE expressions)
-- Tables Referenced: Products
-- Description: Retrieves products within a price range with ranking and percentile
--              calculations. Categorizes products into Budget/Mid-Range/Premium
--              segments based on their price percentile within the range.
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Aggregate Window Functions
-- ==============================================================================
-- Source Location: ProductRepository.cs, Lines 312-346
-- Method: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @Threshold (int)
-- Complexity: HIGH (CTE, AVG/MIN/MAX window functions, CASE expressions, ROUND)
-- Tables Referenced: Products
-- Description: Analyzes stock levels across all products using window functions,
--              identifies low stock items, and categorizes them as Critical/Low/Adequate
--              with percentage comparison to average stock levels.
-- ==============================================================================

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

-- ==============================================================================
-- END OF EXTRACTED STATEMENTS
-- ==============================================================================
-- Summary:
-- Total Statements Extracted: 7
-- SELECT Statements: 4 (Statements 1, 2, 6, 7)
-- TRANSACTION Blocks: 3 (Statements 3, 4, 5)
-- CTEs Used: 5 (Statements 1, 2, 6, 7)
-- Window Functions: 7 uses (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN OVER, MAX OVER)
-- SQL Server Specific Features Requiring Conversion:
--   - SCOPE_IDENTITY() (Statement 3)
--   - BEGIN TRANSACTION (Statements 3, 4, 5)
--   - GETDATE() (Statements 3, 4, 5)
--   - DECLARE variable syntax (Statements 3, 4, 5)
-- ==============================================================================
