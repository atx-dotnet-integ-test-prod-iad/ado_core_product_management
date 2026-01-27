-- ================================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: ADO.NET Application - ProductRepository.cs
-- ================================================================================
-- This file contains all SQL statements extracted from the application code
-- for systematic conversion to PostgreSQL syntax using the DMS MCP tool.
-- Each statement is documented with its source location and context.
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: Approximately lines 41-68
-- Statement Type: SELECT with CTE
-- Parameters: None
-- Description: Retrieves all products with price analysis using window functions.
--              Uses CTE (ProductStats) with AVG() and COUNT() window functions,
--              CASE expressions for categorization, and ROUND() for percentage calculations.
-- Key SQL Server Features:
--   - Common Table Expression (CTE)
--   - Window functions: AVG() OVER(), COUNT() OVER()
--   - CASE expressions
--   - ROUND() function
--   - INNER JOIN between CTE and table
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: Approximately lines 84-113
-- Statement Type: SELECT with CTE
-- Parameters: @ProductId (INT)
-- Description: Retrieves a single product by ID with historical price and stock comparison.
--              Uses LAG() window function to get previous values and calculates
--              percentage change for price.
-- Key SQL Server Features:
--   - Common Table Expression (CTE)
--   - LAG() window function with ORDER BY
--   - LEFT JOIN to CTE
--   - CASE expression for NULL handling
--   - ROUND() for percentage calculation
--   - Parameterized query with @ProductId
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: Approximately lines 126-153
-- Statement Type: Transaction Block (INSERT, INSERT, UPDATE, SELECT)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Description: Inserts a new product and logs the action to history table, then updates
--              product statistics. Returns the new ProductId.
-- Key SQL Server Features:
--   - T-SQL DECLARE statement for variables (@NewProductId)
--   - BEGIN TRANSACTION / COMMIT
--   - SCOPE_IDENTITY() to get last inserted identity value
--   - GETDATE() function (3 occurrences)
--   - Multi-table INSERT and UPDATE operations
--   - Variable assignment with SET
--   - SELECT to return scalar value
-- CRITICAL: This is the most complex conversion requiring restructuring for PostgreSQL
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variable Storage
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: Approximately lines 171-202
-- Statement Type: Transaction Block (SELECT, UPDATE, INSERT, UPDATE)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Description: Updates a product and logs changes to history, then updates statistics.
--              Stores old values in variables for historical tracking.
-- Key SQL Server Features:
--   - T-SQL DECLARE statements for variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT
--   - GETDATE() function (3 occurrences)
--   - SELECT with multiple variable assignments
--   - Multi-table UPDATE and INSERT operations
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with History Logging
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: Approximately lines 218-252
-- Statement Type: Transaction Block (SELECT, INSERT, DELETE, UPDATE)
-- Parameters: @ProductId
-- Description: Deletes a product after logging the action and updates statistics.
--              Stores product info in variables before deletion for history.
-- Key SQL Server Features:
--   - T-SQL DECLARE statements for variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT
--   - GETDATE() function (2 occurrences)
--   - SELECT with multiple variable assignments
--   - DELETE statement
--   - UPDATE with CASE expression for conditional logic
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: Approximately lines 268-291
-- Statement Type: SELECT with CTE
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products within a price range with ranking and percentile analysis.
--              Uses RANK() and PERCENT_RANK() window functions, BETWEEN for range filtering.
-- Key SQL Server Features:
--   - Common Table Expression (CTE)
--   - RANK() window function
--   - PERCENT_RANK() window function
--   - BETWEEN operator for range filtering
--   - CASE expression for segmentation
--   - Parameterized query with @MinPrice and @MaxPrice
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Aggregate Window Functions
-- ================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: Approximately lines 307-333
-- Statement Type: SELECT with CTE
-- Parameters: @Threshold (INT)
-- Description: Retrieves products with low stock levels and provides stock analysis
--              using multiple aggregate window functions.
-- Key SQL Server Features:
--   - Common Table Expression (CTE)
--   - Multiple aggregate window functions: AVG(), MIN(), MAX() OVER()
--   - CASE expression for status categorization
--   - ROUND() function for percentage calculation
--   - WHERE clause filtering with parameter
-- ================================================================================

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

-- ================================================================================
-- END OF EXTRACTED SQL STATEMENTS
-- ================================================================================
-- Total Statements: 7
-- Ready for conversion to PostgreSQL using DMS MCP tool
-- ================================================================================
