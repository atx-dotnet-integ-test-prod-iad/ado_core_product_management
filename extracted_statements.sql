-- ========================================================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Migration: Microsoft SQL Server to PostgreSQL for ADO.NET Application
-- Source File: ProductRepository.cs
-- Extraction Date: 2026-01-27
-- Total Statements: 7
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ========================================================================================================
-- File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Lines: 39-66
-- Statement Type: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE expressions
-- Parameters: None
-- SQL Server Specific Features: Window functions, CTEs
-- Context: Retrieves all products with price analysis using window functions and CTEs
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ========================================================================================================
-- File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Lines: 75-105
-- Statement Type: SELECT with CTE, LAG window function, CASE expression
-- Parameters: @ProductId (int)
-- SQL Server Specific Features: LAG window function, CTEs
-- Context: Retrieves single product with price change analysis using LAG window function
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with SCOPE_IDENTITY and GETDATE
-- ========================================================================================================
-- File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Lines: 114-137
-- Statement Type: INSERT within multi-statement transaction block
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- SQL Server Specific Features: DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE(), COMMIT, SET
-- Context: Inserts new product, logs to history, updates stats - all in transaction
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with Variable Declarations
-- ========================================================================================================
-- File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Lines: 147-179
-- Statement Type: UPDATE within multi-statement transaction block
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- SQL Server Specific Features: BEGIN TRANSACTION, DECLARE, GETDATE(), COMMIT
-- Context: Updates product, logs changes to history, updates stats - all in transaction
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with DELETE Operation
-- ========================================================================================================
-- File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Lines: 187-219
-- Statement Type: DELETE within multi-statement transaction block
-- Parameters: @ProductId (int)
-- SQL Server Specific Features: BEGIN TRANSACTION, DECLARE, GETDATE(), COMMIT, CASE expression
-- Context: Logs deletion, deletes product, updates stats - all in transaction
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - SELECT with RANK and PERCENT_RANK Window Functions
-- ========================================================================================================
-- File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: 227-256
-- Statement Type: SELECT with CTE, RANK(), PERCENT_RANK() window functions, CASE expression
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- SQL Server Specific Features: RANK(), PERCENT_RANK() window functions, CTEs
-- Context: Retrieves products within price range with ranking and percentile analysis
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - SELECT with Multiple Window Functions
-- ========================================================================================================
-- File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: 264-293
-- Statement Type: SELECT with CTE, multiple window functions (AVG, MIN, MAX OVER), CASE expression
-- Parameters: @Threshold (int)
-- SQL Server Specific Features: Multiple window functions (AVG, MIN, MAX OVER), CTEs
-- Context: Retrieves low stock products with stock level analysis using window functions
-- ========================================================================================================

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

-- ========================================================================================================
-- EXTRACTION SUMMARY
-- ========================================================================================================
-- Total SQL Statements Extracted: 7
-- 
-- Statement Breakdown:
--   - Complex SELECT with CTEs and Window Functions: 4 statements
--   - Multi-Statement Transactions (INSERT/UPDATE/DELETE): 3 statements
-- 
-- SQL Server Specific Features Identified:
--   - Window Functions: AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN/MAX OVER
--   - Common Table Expressions (CTEs): WITH clause
--   - Transaction Control: BEGIN TRANSACTION, COMMIT
--   - Variable Declarations: DECLARE, SET
--   - SQL Server Functions: SCOPE_IDENTITY(), GETDATE()
--   - CASE Expressions: Multiple conditional logic statements
--   - ROUND Function: Decimal rounding
-- 
-- All statements require conversion to PostgreSQL syntax via DMS MCP Tool
-- ========================================================================================================
