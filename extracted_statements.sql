-- =============================================================================
-- EXTRACTED SQL STATEMENTS FROM PRODUCTREPOSITORY.CS
-- Migration: Microsoft SQL Server to PostgreSQL
-- Date: 2026-01-22
-- Total Statements: 7
-- =============================================================================

-- -----------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- -----------------------------------------------------------------------------
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Range: ~37-71
-- Parameters: None
-- Statement Type: SELECT with CTE and Window Functions
-- Description: Retrieves all products with price statistics using CTE and window functions
--              Includes AVG() OVER(), COUNT() OVER(), and calculated price categories
-- SQL Server Specific Features:
--   - Window functions: AVG() OVER(), COUNT() OVER()
--   - CTE (Common Table Expression)
--   - CASE expressions
--   - ROUND function
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- -----------------------------------------------------------------------------
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Range: ~81-115
-- Parameters: @ProductId (int)
-- Statement Type: SELECT with CTE and LAG Window Function
-- Description: Retrieves a product by ID with historical price and stock changes
--              Uses LAG window function to get previous values
-- SQL Server Specific Features:
--   - LAG() window function
--   - CTE (Common Table Expression)
--   - CASE expression with NULL handling
--   - ROUND function
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with SCOPE_IDENTITY
-- -----------------------------------------------------------------------------
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Range: ~125-156
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Statement Type: INSERT within Transaction with multiple statements
-- Description: Inserts a new product and logs the action to history table
--              Updates product statistics in a transaction
-- SQL Server Specific Features:
--   - DECLARE variable (@NewProductId)
--   - BEGIN TRANSACTION/COMMIT
--   - SCOPE_IDENTITY() function
--   - GETDATE() function (3 occurrences)
--   - Multi-statement transaction block
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with Variable Declarations
-- -----------------------------------------------------------------------------
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Range: ~166-199
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Statement Type: UPDATE within Transaction with multiple statements
-- Description: Updates a product and logs the changes to history table
--              Updates product statistics with old/new value calculations
-- SQL Server Specific Features:
--   - BEGIN TRANSACTION/COMMIT
--   - DECLARE variables (@OldPrice, @OldStock)
--   - GETDATE() function (3 occurrences)
--   - Multi-statement transaction block
--   - Variable assignment with SELECT
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with CASE Expression
-- -----------------------------------------------------------------------------
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Range: ~207-242
-- Parameters: @ProductId (int)
-- Statement Type: DELETE within Transaction with multiple statements
-- Description: Deletes a product after logging to history table
--              Updates product statistics with conditional average calculation
-- SQL Server Specific Features:
--   - BEGIN TRANSACTION/COMMIT
--   - DECLARE variables (@OldPrice, @OldStock)
--   - GETDATE() function (2 occurrences)
--   - CASE expression within UPDATE statement
--   - Multi-statement transaction block
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- -----------------------------------------------------------------------------
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: ~250-276
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Statement Type: SELECT with CTE and Window Functions
-- Description: Retrieves products within a price range with ranking statistics
--              Uses RANK() and PERCENT_RANK() window functions for price analysis
-- SQL Server Specific Features:
--   - CTE (Common Table Expression)
--   - RANK() OVER() window function
--   - PERCENT_RANK() OVER() window function
--   - CASE expression for price segmentation
--   - BETWEEN clause
-- -----------------------------------------------------------------------------

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

-- -----------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- -----------------------------------------------------------------------------
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: ~284-313
-- Parameters: @Threshold (int)
-- Statement Type: SELECT with CTE and Window Functions
-- Description: Retrieves low stock products with statistical analysis
--              Uses multiple window functions for stock level analysis
-- SQL Server Specific Features:
--   - CTE (Common Table Expression)
--   - AVG() OVER() window function
--   - MIN() OVER() window function
--   - MAX() OVER() window function
--   - CASE expression for stock status
--   - ROUND function
-- -----------------------------------------------------------------------------

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

-- =============================================================================
-- EXTRACTION SUMMARY
-- =============================================================================
-- Total Statements Extracted: 7
-- 
-- Statement Types:
--   - SELECT queries with CTEs: 4 (Statements 1, 2, 6, 7)
--   - INSERT transaction blocks: 1 (Statement 3)
--   - UPDATE transaction blocks: 1 (Statement 4)
--   - DELETE transaction blocks: 1 (Statement 5)
--
-- SQL Server Specific Features to Convert:
--   - SCOPE_IDENTITY(): 1 occurrence (Statement 3)
--   - GETDATE(): 8 total occurrences (Statements 3, 4, 5)
--   - BEGIN TRANSACTION/COMMIT: 4 occurrences (Statements 3, 4, 5)
--   - DECLARE variable syntax: 3 statements (Statements 3, 4, 5)
--   - Window functions (LAG, RANK, PERCENT_RANK, AVG, MIN, MAX, COUNT): Multiple occurrences
--   - CTEs (WITH clause): 5 statements
--   - ROUND function: 4 occurrences
--
-- All statements are complete and ready for DMS MCP conversion tool processing.
-- =============================================================================
