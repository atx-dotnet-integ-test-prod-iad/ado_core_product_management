-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- SQL Server to PostgreSQL Migration
-- Source Project: AdoCore
-- Extraction Date: 2026-02-08
-- ============================================================================
-- This file contains all SQL statements extracted from the codebase for 
-- conversion from Microsoft SQL Server syntax to PostgreSQL syntax.
-- Each statement is documented with:
--   - Source file path and line numbers
--   - Method/function name where the statement appears
--   - Statement type (SELECT, INSERT, UPDATE, DELETE, TRANSACTION)
--   - Parameter information
--   - Notes on complexity and special features
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 41-67
-- Method: GetAllProductsAsync()
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Complexity: High - Uses CTE, window functions (AVG OVER, COUNT OVER), CASE expressions
-- Description: Retrieves all products with price category classification based on average price
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 83-107
-- Method: GetProductByIdAsync(int productId)
-- Statement Type: SELECT with CTE and LAG Window Function
-- Parameters: @ProductId (int)
-- Complexity: High - Uses CTE, LAG window function, CASE expressions
-- Description: Retrieves a single product by ID with price history comparison
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
-- STATEMENT 3: InsertProductAsync - Transaction with SCOPE_IDENTITY and GETDATE
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 119-143
-- Method: InsertProductAsync(Product product)
-- Statement Type: INSERT within TRANSACTION block
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Complexity: High - Transaction with variable declarations, SCOPE_IDENTITY(), GETDATE(), multiple inserts and updates
-- Description: Inserts a new product and logs the action in ProductHistory
-- Special Features: Uses SCOPE_IDENTITY() to get newly inserted ID, GETDATE() for timestamps
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
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 159-186
-- Method: UpdateProductAsync(Product product)
-- Statement Type: UPDATE within TRANSACTION block
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Complexity: High - Transaction with variable declarations, GETDATE(), multiple statements
-- Description: Updates an existing product and logs the changes
-- Special Features: Stores old values before update, uses GETDATE() for timestamps
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
-- STATEMENT 5: DeleteProductAsync - Transaction with Variable Declarations
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 202-231
-- Method: DeleteProductAsync(int productId)
-- Statement Type: DELETE within TRANSACTION block
-- Parameters: @ProductId (int)
-- Complexity: High - Transaction with variable declarations, GETDATE(), multiple statements
-- Description: Deletes a product and logs the action
-- Special Features: Stores old values before deletion, CASE expression for average calculation
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 247-270
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Complexity: High - Uses CTE, RANK(), PERCENT_RANK() window functions, CASE expressions
-- Description: Retrieves products within a price range with ranking and percentile information
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Window Functions
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Numbers: 286-312
-- Method: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @Threshold (int)
-- Complexity: High - Uses CTE, multiple window functions (AVG, MIN, MAX OVER), CASE expressions
-- Description: Retrieves products with low stock levels based on threshold
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
-- Total Statements Extracted: 7
-- 
-- Summary:
-- - 4 SELECT statements with CTEs and window functions
-- - 3 Transaction blocks (INSERT, UPDATE, DELETE)
-- - All statements use parameterized queries for security
-- - Complex features include: CTEs, window functions (AVG, COUNT, LAG, RANK, 
--   PERCENT_RANK, MIN, MAX OVER), CASE expressions, SCOPE_IDENTITY(), GETDATE()
-- ============================================================================
