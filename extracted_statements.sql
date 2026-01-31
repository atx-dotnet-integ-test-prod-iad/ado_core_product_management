-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Source: ProductRepository.cs
-- Total Statements: 7
-- Extraction Date: 2026-01-31
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Numbers: ~42-67
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Usage Pattern: Inline const string, parameterized query execution
-- Description: Complex query using CTE with AVG() OVER() and COUNT() OVER() 
--              window functions, CASE expressions for price categorization,
--              and conditional ORDER BY logic
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Line Numbers: ~79-102
-- Statement Type: SELECT with CTE, LAG Window Function, and LEFT JOIN
-- Parameters: @ProductId (int)
-- Usage Pattern: Inline const string, parameterized query with SqlParameter
-- Description: Query using CTE with LAG() OVER() window function to retrieve
--              previous price and stock values, LEFT JOIN with product data,
--              and calculated price change percentage
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Line Numbers: ~114-138
-- Statement Type: Transaction Block with INSERT, SCOPE_IDENTITY(), and GETDATE()
-- Parameters: @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Usage Pattern: Inline const string, transaction block with multiple DML operations
-- Description: Transaction containing product insertion, retrieval of new ID
--              using SCOPE_IDENTITY(), logging to ProductHistory table, and
--              updating ProductStats table with GETDATE() function calls
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Line Numbers: ~148-178
-- Statement Type: Transaction Block with DECLARE, SELECT, UPDATE, INSERT
-- Parameters: @ProductId (int), @Name (nvarchar), @Description (nvarchar), 
--             @Price (decimal), @StockQuantity (int)
-- Usage Pattern: Inline const string, transaction with variable declarations
-- Description: Transaction with DECLARE statements for old values, SELECT to
--              capture current values, UPDATE to modify product, INSERT for
--              history logging, and UPDATE for statistics with GETDATE() calls
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Line Numbers: ~188-217
-- Statement Type: Transaction Block with DECLARE, SELECT, INSERT, DELETE, UPDATE with CASE
-- Parameters: @ProductId (int)
-- Usage Pattern: Inline const string, transaction with conditional CASE logic
-- Description: Transaction with DECLARE statements, SELECT to capture values,
--              INSERT for history logging, DELETE operation, and UPDATE with
--              CASE expression for conditional average calculation and GETDATE()
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Line Numbers: ~227-249
-- Statement Type: SELECT with CTE, RANK() and PERCENT_RANK() Window Functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Usage Pattern: Inline const string, parameterized query
-- Description: Query using CTE with RANK() and PERCENT_RANK() window functions
--              over price ordering, filtering by price range, and CASE expression
--              for price segmentation (Budget/Mid-Range/Premium)
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Line Numbers: ~259-281
-- Statement Type: SELECT with CTE and Aggregate Window Functions
-- Parameters: @Threshold (int)
-- Usage Pattern: Inline const string, parameterized query
-- Description: Query using CTE with AVG(), MIN(), and MAX() aggregate window
--              functions over stock quantities, filtering by threshold, CASE
--              expression for stock status categorization, and calculated
--              stock percentage relative to average
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
-- END OF EXTRACTED SQL STATEMENTS
-- ============================================================================
-- Summary:
-- - Total statements extracted: 7
-- - Statements with CTEs: 5 (GetAllProductsAsync, GetProductByIdAsync, 
--                              GetProductsByPriceRangeAsync, GetLowStockProductsAsync)
-- - Statements with transactions: 3 (InsertProductAsync, UpdateProductAsync, 
--                                    DeleteProductAsync)
-- - Statements with window functions: 5 (all SELECT queries)
-- - SQL Server specific functions to convert:
--   * SCOPE_IDENTITY() -> PostgreSQL RETURNING clause
--   * GETDATE() -> NOW() or CURRENT_TIMESTAMP
-- - Window functions to validate:
--   * AVG() OVER(), COUNT() OVER()
--   * LAG() OVER()
--   * RANK() OVER(), PERCENT_RANK() OVER()
--   * MIN() OVER(), MAX() OVER()
-- ============================================================================
