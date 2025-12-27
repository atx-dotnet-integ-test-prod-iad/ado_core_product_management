-- ========================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: ProductRepository.cs
-- Total Statements: 6
-- ========================================

-- ========================================
-- STATEMENT 1: GetAllProductsAsync
-- ========================================
-- Statement ID: STMT_001
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Number: ~38-69
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Description: Retrieves all products with price category analysis using CTE and window functions (AVG, COUNT OVER)
-- Complexity: Medium - CTE with window functions, CASE expressions
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
-- ========================================
-- Statement ID: STMT_002
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Line Number: ~76-108
-- Statement Type: SELECT with CTE and LAG Window Function
-- Parameters: @ProductId (INT)
-- Description: Retrieves single product with price history using LAG window function to track previous values
-- Complexity: Medium - CTE with LAG window function, conditional CASE expression
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
-- ========================================
-- Statement ID: STMT_003
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Line Number: ~118-148
-- Statement Type: TRANSACTION with INSERT, SCOPE_IDENTITY, UPDATE
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Inserts new product with transaction including history logging and statistics update
-- Complexity: High - Transaction block with variable, SCOPE_IDENTITY(), GETDATE() functions
-- SQL Server Specific: SCOPE_IDENTITY(), GETDATE(), DECLARE variable syntax
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
-- ========================================
-- Statement ID: STMT_004
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Line Number: ~157-191
-- Statement Type: TRANSACTION with DECLARE, SELECT, UPDATE, INSERT
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Updates product with transaction including storing old values and logging to history
-- Complexity: High - Transaction with variable declarations, multiple DML statements
-- SQL Server Specific: DECLARE variables, GETDATE() function
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
-- ========================================
-- Statement ID: STMT_005
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Line Number: ~199-233
-- Statement Type: TRANSACTION with DECLARE, SELECT, INSERT, DELETE, UPDATE
-- Parameters: @ProductId (INT)
-- Description: Deletes product with transaction including history logging and statistics update with CASE logic
-- Complexity: High - Transaction with variable declarations, DELETE and conditional UPDATE
-- SQL Server Specific: DECLARE variables, GETDATE() function, CASE expression in UPDATE
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
-- ========================================
-- Statement ID: STMT_006
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Line Number: ~241-271
-- Statement Type: SELECT with CTE, RANK and PERCENT_RANK Window Functions
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products in price range with ranking and percentile calculations
-- Complexity: Medium - CTE with RANK() and PERCENT_RANK() window functions, BETWEEN operator
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
-- ========================================
-- Statement ID: STMT_007
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Line Number: ~279-309
-- Statement Type: SELECT with CTE and Multiple Window Functions
-- Parameters: @Threshold (INT)
-- Description: Retrieves low stock products with stock analysis using multiple window functions (AVG, MIN, MAX)
-- Complexity: Medium - CTE with multiple window functions, conditional CASE expression
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
-- SELECT Statements: 4 (STMT_001, STMT_002, STMT_006, STMT_007)
-- INSERT Statements: 1 (within STMT_003 transaction)
-- UPDATE Statements: 1 (within STMT_004 transaction)
-- DELETE Statements: 1 (within STMT_005 transaction)
-- Transaction Blocks: 3 (STMT_003, STMT_004, STMT_005)
-- CTEs Used: 5
-- Window Functions Used: Multiple (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER)
-- SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE()
-- Parameterized Queries: 5 (STMT_002, STMT_003, STMT_004, STMT_005, STMT_006, STMT_007)
--
-- NOTES:
-- - All statements extracted maintain original formatting and structure
-- - Parameters are documented with data types
-- - Transaction blocks extracted as complete units
-- - SQL Server specific syntax identified for conversion priority
-- - Line numbers are approximate references to source file
-- ========================================
