-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: AdoCore Application
-- Generated: Migration Phase 1
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ============================================================================
-- File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Lines: 38-68
-- Type: SELECT
-- Features: CTE, Window Functions (AVG OVER, COUNT OVER), CASE expressions, INNER JOIN
-- Description: Retrieves all products with price analysis using ProductStats CTE
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
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ============================================================================
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Lines: 78-108
-- Type: SELECT
-- Features: CTE, LAG Window Function, Parameterized Query, LEFT JOIN
-- Parameters: @ProductId (INT)
-- Description: Retrieves single product with historical price comparison using LAG
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
-- STATEMENT 3: InsertProductAsync - Multi-statement Transaction Block
-- ============================================================================
-- File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Lines: 120-145
-- Type: TRANSACTION (INSERT + INSERT + UPDATE + SELECT)
-- Features: Transaction, SCOPE_IDENTITY(), Multiple INSERTs, UPDATE, GETDATE()
-- Parameters: @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Inserts new product with history logging and statistics update
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
-- STATEMENT 4: UpdateProductAsync - Multi-statement Transaction Block
-- ============================================================================
-- File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Lines: 160-193
-- Type: TRANSACTION (SELECT + UPDATE + INSERT + UPDATE)
-- Features: Transaction, Variable declarations, Multiple statements
-- Parameters: @ProductId (INT), @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Updates product with historical tracking and statistics recalculation
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
-- STATEMENT 5: DeleteProductAsync - Multi-statement Transaction Block
-- ============================================================================
-- File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Lines: 207-239
-- Type: TRANSACTION (SELECT + INSERT + DELETE + UPDATE)
-- Features: Transaction, Variable declarations, Conditional CASE in UPDATE
-- Parameters: @ProductId (INT)
-- Description: Deletes product with history preservation and statistics update
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - SELECT with CTE and Window Functions
-- ============================================================================
-- File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Lines: 249-273
-- Type: SELECT
-- Features: CTE, Window Functions (RANK, PERCENT_RANK), Parameterized Query
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products in price range with ranking and percentile analysis
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
-- STATEMENT 7: GetLowStockProductsAsync - SELECT with CTE and Window Functions
-- ============================================================================
-- File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Lines: 283-313
-- Type: SELECT
-- Features: CTE, Window Functions (AVG, MIN, MAX OVER), Conditional filtering
-- Parameters: @Threshold (INT)
-- Description: Retrieves low stock products with stock level analysis
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
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total SQL Statements Extracted: 7
-- SELECT Statements: 4 (Statements 1, 2, 6, 7)
-- Transaction Blocks: 3 (Statements 3, 4, 5)
-- Statements with CTEs: 6 (All except Statement 3)
-- Statements with Window Functions: 5 (Statements 1, 2, 6, 7, and within CTEs)
-- Parameterized Statements: 6 (All except Statement 1)
-- ============================================================================
