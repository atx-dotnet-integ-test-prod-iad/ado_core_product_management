-- ============================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- Extraction Date: 2026-02-03
-- Source Application: AdoCore - Product Management System
-- Source File: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT ID: STMT-001
-- Source File: DataAccess/ProductRepository.cs:38-70
-- Method: GetAllProductsAsync()
-- Type: SELECT with CTE and Window Functions
-- Complexity: HIGH - CTE with AVG OVER, COUNT OVER, CASE, ROUND
-- Parameters: None
-- Description: Retrieves all products with price statistics using window functions
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
-- STATEMENT ID: STMT-002
-- Source File: DataAccess/ProductRepository.cs:76-106
-- Method: GetProductByIdAsync(int productId)
-- Type: SELECT with CTE and LAG Window Function
-- Complexity: HIGH - CTE with LAG window function, NULL handling, percentage calculation
-- Parameters: @ProductId (int)
-- Description: Retrieves single product with historical price comparison
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
-- STATEMENT ID: STMT-003
-- Source File: DataAccess/ProductRepository.cs:114-138
-- Method: InsertProductAsync(Product product)
-- Type: TRANSACTION - Multi-statement INSERT with SCOPE_IDENTITY() and GETDATE()
-- Complexity: HIGH - Transaction, DECLARE, SCOPE_IDENTITY(), GETDATE(), multiple statements
-- Parameters: @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Description: Inserts new product with history logging and stats update
-- SQL Server Specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT, DECLARE
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
-- STATEMENT ID: STMT-004
-- Source File: DataAccess/ProductRepository.cs:147-178
-- Method: UpdateProductAsync(Product product)
-- Type: TRANSACTION - Multi-statement UPDATE with history logging
-- Complexity: HIGH - Transaction, DECLARE, GETDATE(), variable capture and usage
-- Parameters: @ProductId (int), @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Description: Updates product with history logging and stats recalculation
-- SQL Server Specific: GETDATE(), BEGIN TRANSACTION/COMMIT, DECLARE
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
-- STATEMENT ID: STMT-005
-- Source File: DataAccess/ProductRepository.cs:186-216
-- Method: DeleteProductAsync(int productId)
-- Type: TRANSACTION - Multi-statement DELETE with history logging and stats update
-- Complexity: HIGH - Transaction, DECLARE, GETDATE(), CASE within UPDATE
-- Parameters: @ProductId (int)
-- Description: Deletes product with history logging and stats recalculation
-- SQL Server Specific: GETDATE(), BEGIN TRANSACTION/COMMIT, DECLARE
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
-- STATEMENT ID: STMT-006
-- Source File: DataAccess/ProductRepository.cs:224-246
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Type: SELECT with CTE and Window Functions (RANK, PERCENT_RANK)
-- Complexity: HIGH - CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products in price range with ranking and percentile
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
-- STATEMENT ID: STMT-007
-- Source File: DataAccess/ProductRepository.cs:254-277
-- Method: GetLowStockProductsAsync(int threshold)
-- Type: SELECT with CTE and Multiple Window Functions
-- Complexity: HIGH - CTE with AVG/MIN/MAX OVER, CASE, ROUND, threshold filtering
-- Parameters: @Threshold (int)
-- Description: Retrieves low-stock products with statistical analysis
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
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total Statements Extracted: 7
-- SELECT Statements: 4 (STMT-001, STMT-002, STMT-006, STMT-007)
-- Transaction Blocks: 3 (STMT-003, STMT-004, STMT-005)
-- Statements with CTEs: 5
-- Statements with Window Functions: 4
-- Statements with SCOPE_IDENTITY(): 1 (STMT-003)
-- Statements with GETDATE(): 3 (STMT-003, STMT-004, STMT-005)
-- Statements with Parameters: 6 (all except STMT-001)
-- 
-- SQL Server Specific Constructs Identified:
-- - SCOPE_IDENTITY() - requires conversion to RETURNING clause in PostgreSQL
-- - GETDATE() - requires conversion to NOW() or CURRENT_TIMESTAMP in PostgreSQL
-- - BEGIN TRANSACTION/COMMIT - requires conversion to PostgreSQL transaction syntax
-- - DECLARE - requires conversion to PostgreSQL variable declaration syntax
-- - Window functions (LAG, RANK, PERCENT_RANK, AVG OVER, etc.) - supported in PostgreSQL
-- - CTEs (WITH clause) - supported in PostgreSQL
-- ============================================================================
