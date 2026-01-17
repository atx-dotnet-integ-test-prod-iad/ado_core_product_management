-- ================================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- ================================================================================================
-- Purpose: Complete catalog of all SQL statements extracted from the codebase for PostgreSQL migration
-- Source Application: AdoCore - Product Management System
-- Total Statements: 7
-- ================================================================================================

-- ================================================================================================
-- STATEMENT 1: GetAllProductsAsync - Product Listing with Statistics
-- ================================================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Number: ~41-68
-- Method Context: GetAllProductsAsync()
-- Statement Type: SELECT (Complex Query)
-- Parameters: None
-- Dynamic Construction: No (Static SQL string)
-- 
-- Description: 
-- Complex CTE query that calculates product statistics including average price and total products.
-- Uses window functions (AVG OVER, COUNT OVER), CASE expressions, INNER JOIN, and computed columns.
-- Returns all products with price categorization and percentage calculations.
-- 
-- SQL Server Features Used:
-- - Common Table Expression (CTE)
-- - Window functions: AVG() OVER(), COUNT(*) OVER()
-- - CASE expressions
-- - INNER JOIN
-- - ROUND function
-- - Computed columns in SELECT
-- 
-- Original SQL Statement:
-- ================================================================================================

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


-- ================================================================================================
-- STATEMENT 2: GetProductByIdAsync - Single Product Retrieval with History
-- ================================================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Number: ~78-106
-- Method Context: GetProductByIdAsync(int productId)
-- Statement Type: SELECT (Parameterized Query)
-- Parameters: 
--   - @ProductId (INT) - Product identifier
-- Dynamic Construction: No (Static SQL string)
-- 
-- Description:
-- CTE query with LAG window function to track previous price and stock values.
-- Uses LEFT JOIN to combine product data with history, calculates price change percentage.
-- Returns single product with historical comparison data.
-- 
-- SQL Server Features Used:
-- - Common Table Expression (CTE)
-- - Window function: LAG() OVER (ORDER BY)
-- - LEFT JOIN
-- - CASE expressions
-- - ROUND function
-- - NULL handling with IS NOT NULL
-- - Parameterized query
-- 
-- Original SQL Statement:
-- ================================================================================================

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


-- ================================================================================================
-- STATEMENT 3: InsertProductAsync - Product Insertion with Transaction
-- ================================================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Number: ~117-145
-- Method Context: InsertProductAsync(Product product)
-- Statement Type: TRANSACTION (Multi-statement: INSERT, UPDATE, SELECT)
-- Parameters:
--   - @Name (NVARCHAR) - Product name
--   - @Description (NVARCHAR, nullable) - Product description
--   - @Price (DECIMAL(18,2)) - Product price
--   - @StockQuantity (INT) - Stock quantity
-- Dynamic Construction: No (Static SQL string)
-- 
-- Description:
-- Multi-statement transaction block that inserts a new product, logs the action to history,
-- updates product statistics, and returns the new product ID.
-- Uses SCOPE_IDENTITY() to retrieve the newly inserted ID and GETDATE() for timestamps.
-- 
-- SQL Server Features Used:
-- - BEGIN TRANSACTION / COMMIT
-- - DECLARE variable (@NewProductId)
-- - INSERT statements (multiple)
-- - SCOPE_IDENTITY() function
-- - SET variable assignment
-- - GETDATE() function
-- - UPDATE with calculations
-- - NULL values in INSERT
-- - Parameterized queries
-- - ExecuteScalarAsync to return value
-- 
-- Original SQL Statement:
-- ================================================================================================

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


-- ================================================================================================
-- STATEMENT 4: UpdateProductAsync - Product Update with Transaction
-- ================================================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Number: ~156-189
-- Method Context: UpdateProductAsync(Product product)
-- Statement Type: TRANSACTION (Multi-statement: SELECT, UPDATE, INSERT)
-- Parameters:
--   - @ProductId (INT) - Product identifier
--   - @Name (NVARCHAR) - Product name
--   - @Description (NVARCHAR, nullable) - Product description
--   - @Price (DECIMAL(18,2)) - Product price
--   - @StockQuantity (INT) - Stock quantity
-- Dynamic Construction: No (Static SQL string)
-- 
-- Description:
-- Multi-statement transaction that retrieves old values, updates the product,
-- logs changes to history, and updates aggregate statistics.
-- Uses variable declarations to store previous values for history tracking.
-- 
-- SQL Server Features Used:
-- - BEGIN TRANSACTION / COMMIT
-- - DECLARE variables (@OldPrice, @OldStock)
-- - SELECT INTO variables
-- - UPDATE statements (multiple)
-- - INSERT for history logging
-- - GETDATE() function
-- - DECIMAL(18,2) data type
-- - WHERE clause filtering
-- - Parameterized queries
-- 
-- Original SQL Statement:
-- ================================================================================================

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


-- ================================================================================================
-- STATEMENT 5: DeleteProductAsync - Product Deletion with Transaction
-- ================================================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Number: ~200-234
-- Method Context: DeleteProductAsync(int productId)
-- Statement Type: TRANSACTION (Multi-statement: SELECT, INSERT, DELETE, UPDATE)
-- Parameters:
--   - @ProductId (INT) - Product identifier
-- Dynamic Construction: No (Static SQL string)
-- 
-- Description:
-- Multi-statement transaction that stores product info, logs the deletion to history,
-- deletes the product, and updates aggregate statistics with conditional logic.
-- Uses CASE expression to handle division by zero when deleting the last product.
-- 
-- SQL Server Features Used:
-- - BEGIN TRANSACTION / COMMIT
-- - DECLARE variables (@OldPrice, @OldStock)
-- - SELECT INTO variables
-- - INSERT for history logging
-- - DELETE statement
-- - UPDATE with CASE expression
-- - Conditional logic for division by zero prevention
-- - GETDATE() function
-- - NULL values in INSERT
-- - DECIMAL(18,2) data type
-- 
-- Original SQL Statement:
-- ================================================================================================

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


-- ================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - Price Range Query with Ranking
-- ================================================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Number: ~245-272
-- Method Context: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT (Complex Query with Window Functions)
-- Parameters:
--   - @MinPrice (DECIMAL) - Minimum price filter
--   - @MaxPrice (DECIMAL) - Maximum price filter
-- Dynamic Construction: No (Static SQL string)
-- 
-- Description:
-- CTE query using RANK() and PERCENT_RANK() window functions to categorize products
-- by price within a specified range. Assigns price segments based on percentile rankings.
-- 
-- SQL Server Features Used:
-- - Common Table Expression (CTE)
-- - Window functions: RANK() OVER (ORDER BY), PERCENT_RANK() OVER (ORDER BY)
-- - BETWEEN clause for range filtering
-- - CASE expression for segmentation
-- - Wildcard selection (p.*)
-- - Parameterized queries
-- 
-- Original SQL Statement:
-- ================================================================================================

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


-- ================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - Stock Analysis with Window Functions
-- ================================================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Line Number: ~283-311
-- Method Context: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT (Complex Query with Multiple Window Functions)
-- Parameters:
--   - @Threshold (INT) - Stock quantity threshold
-- Dynamic Construction: No (Static SQL string)
-- 
-- Description:
-- CTE query using multiple window functions (AVG, MIN, MAX) to analyze stock levels
-- across all products. Calculates stock status categories and percentage comparisons.
-- Filters for products below the threshold and provides comprehensive stock analysis.
-- 
-- SQL Server Features Used:
-- - Common Table Expression (CTE)
-- - Window functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
-- - Wildcard selection (p.*)
-- - CASE expression with complex conditions
-- - Mathematical calculations in SELECT
-- - ROUND function
-- - WHERE clause filtering
-- - ORDER BY
-- - Parameterized queries
-- 
-- Original SQL Statement:
-- ================================================================================================

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


-- ================================================================================================
-- END OF EXTRACTED SQL STATEMENTS
-- ================================================================================================
-- Summary:
-- - Total Statements Extracted: 7
-- - SELECT Queries: 4 (Statements 1, 2, 6, 7)
-- - Transaction Blocks: 3 (Statements 3, 4, 5)
-- - Parameterized Queries: 6 (Statements 2, 3, 4, 5, 6, 7)
-- - CTE Usage: 5 (Statements 1, 2, 6, 7, and historical context in 2)
-- - Window Functions: 6 statements (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK, MIN, MAX)
-- - Complex Features: SCOPE_IDENTITY(), GETDATE(), CASE expressions, JOINs
-- 
-- All statements ready for DMS MCP tool conversion to PostgreSQL syntax.
-- ================================================================================================
