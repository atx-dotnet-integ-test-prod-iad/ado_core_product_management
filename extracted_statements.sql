-- =============================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Database: Microsoft SQL Server
-- Total SQL Statement Blocks: 7
-- =============================================================================

-- =============================================================================
-- STATEMENT BLOCK 1: GetAllProductsAsync
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync, Lines: 42-70
-- SQL Type: SELECT (Complex CTE with Window Functions)
-- Parameters: None
-- Description: Retrieves all products with price category analysis using CTE and window functions (AVG, COUNT)
-- Key SQL Server Features: CTE, Window Functions (AVG OVER, COUNT OVER), CASE statements, ROUND function
-- =============================================================================

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

-- =============================================================================
-- STATEMENT BLOCK 2: GetProductByIdAsync
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync, Lines: 83-109
-- SQL Type: SELECT (Complex CTE with LAG Window Function)
-- Parameters: @ProductId (INT)
-- Description: Retrieves single product by ID with price history using LAG window function
-- Key SQL Server Features: CTE, Window Function (LAG OVER), CASE statement, ROUND function
-- =============================================================================

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

-- =============================================================================
-- STATEMENT BLOCK 3: InsertProductAsync
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: InsertProductAsync, Lines: 124-150
-- SQL Type: TRANSACTION (INSERT with SCOPE_IDENTITY and history logging)
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Inserts new product with transaction, logs to history, updates statistics
-- Key SQL Server Features: DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE(), COMMIT, Multi-statement transaction
-- =============================================================================

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

-- =============================================================================
-- STATEMENT BLOCK 4: UpdateProductAsync
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: UpdateProductAsync, Lines: 163-193
-- SQL Type: TRANSACTION (UPDATE with history logging)
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Updates existing product with transaction, logs changes to history, updates statistics
-- Key SQL Server Features: DECLARE, BEGIN TRANSACTION, GETDATE(), COMMIT, Multi-statement transaction
-- =============================================================================

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

-- =============================================================================
-- STATEMENT BLOCK 5: DeleteProductAsync
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: DeleteProductAsync, Lines: 203-232
-- SQL Type: TRANSACTION (DELETE with history logging)
-- Parameters: @ProductId (INT)
-- Description: Deletes product with transaction, logs deletion to history, updates statistics
-- Key SQL Server Features: DECLARE, BEGIN TRANSACTION, GETDATE(), CASE statement, COMMIT, Multi-statement transaction
-- =============================================================================

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

-- =============================================================================
-- STATEMENT BLOCK 6: GetProductsByPriceRangeAsync
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync, Lines: 242-267
-- SQL Type: SELECT (Complex CTE with Window Functions for Ranking)
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products in price range with ranking and percentile analysis
-- Key SQL Server Features: CTE, Window Functions (RANK OVER, PERCENT_RANK OVER), CASE statement, BETWEEN
-- =============================================================================

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

-- =============================================================================
-- STATEMENT BLOCK 7: GetLowStockProductsAsync
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync, Lines: 281-309
-- SQL Type: SELECT (Complex CTE with Window Functions for Stock Analysis)
-- Parameters: @Threshold (INT)
-- Description: Retrieves low stock products with statistical analysis using window functions
-- Key SQL Server Features: CTE, Window Functions (AVG OVER, MIN OVER, MAX OVER), CASE statement, ROUND function
-- =============================================================================

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
-- END OF SQL STATEMENT EXTRACTION CATALOG
-- =============================================================================
-- Summary:
-- - Total Statement Blocks Extracted: 7
-- - SELECT Statements: 4 (Blocks 1, 2, 6, 7)
-- - Transaction Blocks: 3 (Blocks 3, 4, 5)
-- - CTEs Used: 6 (Blocks 1, 2, 6, 7 use CTEs)
-- - Window Functions: 6 statements use window functions
-- - SQL Server Specific Features to Convert:
--   * SCOPE_IDENTITY() (Block 3)
--   * GETDATE() (Blocks 3, 4, 5)
--   * BEGIN TRANSACTION / COMMIT (Blocks 3, 4, 5)
--   * DECLARE variable syntax (Blocks 3, 4, 5)
--   * Window function syntax (potential differences in PostgreSQL)
-- =============================================================================
