-- =========================================================================
-- SQL STATEMENT CATALOG - Microsoft SQL Server to PostgreSQL Migration
-- =========================================================================
-- This file contains all SQL statements extracted from the ADO.NET application
-- Each statement is documented with:
--   - Source file and method location
--   - Statement type (SELECT, INSERT, UPDATE, DELETE, TRANSACTION)
--   - SQL Server specific features used
--   - Context and purpose
-- =========================================================================

-- -------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- -------------------------------------------------------------------------
-- Source: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Type: SELECT with CTE
-- Features: CTE, AVG() OVER(), COUNT() OVER(), CASE expressions, ROUND function, INNER JOIN
-- Purpose: Retrieve all products with price statistics and categorization
-- -------------------------------------------------------------------------

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

-- -------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- -------------------------------------------------------------------------
-- Source: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Type: SELECT with CTE and parameterized query
-- Parameters: @ProductId (INT)
-- Features: CTE, LAG() OVER(ORDER BY), LEFT JOIN, CASE expressions, ROUND function
-- Purpose: Retrieve single product by ID with price change history analysis
-- -------------------------------------------------------------------------

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

-- -------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with SCOPE_IDENTITY
-- -------------------------------------------------------------------------
-- Source: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Type: TRANSACTION with INSERT statements
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Features: DECLARE variables, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE(), COMMIT, UPDATE
-- Purpose: Insert new product with history logging and statistics update
-- SQL Server Specific: SCOPE_IDENTITY() for getting last inserted ID, GETDATE() for current timestamp
-- -------------------------------------------------------------------------

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

-- -------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with Variable Storage
-- -------------------------------------------------------------------------
-- Source: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Type: TRANSACTION with UPDATE and INSERT statements
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Features: DECLARE variables, BEGIN TRANSACTION, SELECT INTO variables, UPDATE, INSERT, GETDATE(), COMMIT
-- Purpose: Update product with history logging and statistics recalculation
-- SQL Server Specific: Variable declarations and assignments, GETDATE()
-- -------------------------------------------------------------------------

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

-- -------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with CASE Expression
-- -------------------------------------------------------------------------
-- Source: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Type: TRANSACTION with DELETE, INSERT, and UPDATE statements
-- Parameters: @ProductId (INT)
-- Features: DECLARE variables, BEGIN TRANSACTION, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE(), COMMIT
-- Purpose: Delete product with history logging and statistics recalculation
-- SQL Server Specific: Variable declarations, GETDATE(), CASE in UPDATE
-- -------------------------------------------------------------------------

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

-- -------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- -------------------------------------------------------------------------
-- Source: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Type: SELECT with CTE and parameterized query
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Features: CTE, RANK() OVER(ORDER BY), PERCENT_RANK() OVER(ORDER BY), BETWEEN, CASE expressions
-- Purpose: Retrieve products within price range with ranking and segmentation
-- -------------------------------------------------------------------------

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

-- -------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- -------------------------------------------------------------------------
-- Source: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Type: SELECT with CTE and parameterized query
-- Parameters: @Threshold (INT)
-- Features: CTE, AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE expressions, ROUND function
-- Purpose: Retrieve low stock products with stock analysis and categorization
-- -------------------------------------------------------------------------

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

-- =========================================================================
-- END OF SQL STATEMENT CATALOG
-- =========================================================================
-- Total Statements: 7
-- Transaction Blocks: 3 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
-- Parameterized Queries: 5 (all except GetAllProductsAsync and one part of transactions)
-- 
-- SQL Server Specific Features Identified:
-- - SCOPE_IDENTITY() - Returns last inserted identity value
-- - GETDATE() - Returns current timestamp
-- - @parameter syntax - Named parameters
-- - DECLARE/SET - Variable declarations and assignments
-- - BEGIN TRANSACTION/COMMIT - Transaction control
-- - Window functions: AVG() OVER(), COUNT() OVER(), LAG() OVER(), RANK() OVER(), PERCENT_RANK() OVER(), MIN() OVER(), MAX() OVER()
-- - CTE (Common Table Expressions) with WITH clause
-- - CASE expressions
-- - ROUND function
-- =========================================================================
