-- ==================================================================================
-- SQL Statement Extraction Catalog for Microsoft SQL Server to PostgreSQL Migration
-- ==================================================================================
-- This catalog contains all SQL statements extracted from the ADO.NET application
-- for processing through the DMS MCP tool and SQL Equivalency validation.
-- 
-- Total Statements: 7
-- Source File: DataAccess/ProductRepository.cs
-- Extraction Date: 2024
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync - SELECT with CTE and window functions
-- ==================================================================================
-- Statement ID: STMT_001
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: GetAllProductsAsync()
-- Line Range: ~40-67
-- SQL Type: SELECT
-- Parameters: None
-- Description: Retrieves all products with price category analysis using CTE and window functions
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG function
-- ==================================================================================
-- Statement ID: STMT_002
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: GetProductByIdAsync(int productId)
-- Line Range: ~79-107
-- SQL Type: SELECT
-- Parameters: @ProductId (INT)
-- Description: Retrieves a single product with historical price comparison using LAG window function
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-statement transaction with INSERT, SET, UPDATE
-- ==================================================================================
-- Statement ID: STMT_003
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: InsertProductAsync(Product product)
-- Line Range: ~121-146
-- SQL Type: TRANSACTION (INSERT + UPDATE)
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Inserts a new product, logs history, updates statistics - all within transaction
-- Special Note: Uses SCOPE_IDENTITY() to retrieve inserted ID, GETDATE() for timestamps
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-statement transaction with DECLARE, SELECT, UPDATE, INSERT
-- ==================================================================================
-- Statement ID: STMT_004
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: UpdateProductAsync(Product product)
-- Line Range: ~158-191
-- SQL Type: TRANSACTION (SELECT + UPDATE + INSERT)
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Updates product, captures old values, logs history, updates statistics - all within transaction
-- Special Note: Uses GETDATE() for timestamps, DECLARE for temporary variables
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-statement transaction with DECLARE, SELECT, INSERT, DELETE, UPDATE
-- ==================================================================================
-- Statement ID: STMT_005
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: DeleteProductAsync(int productId)
-- Line Range: ~203-237
-- SQL Type: TRANSACTION (SELECT + INSERT + DELETE + UPDATE)
-- Parameters: @ProductId (INT)
-- Description: Deletes product after logging history and updating statistics - all within transaction
-- Special Note: Uses GETDATE() for timestamps, DECLARE for temporary variables, complex CASE in UPDATE
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - SELECT with CTE, RANK, and PERCENT_RANK
-- ==================================================================================
-- Statement ID: STMT_006
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: ~249-272
-- SQL Type: SELECT
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products within price range with ranking and percentile analysis
-- Special Note: Uses window functions RANK() and PERCENT_RANK()
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - SELECT with CTE and window functions
-- ==================================================================================
-- Statement ID: STMT_007
-- Source File: DataAccess/ProductRepository.cs
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Line Range: ~284-309
-- SQL Type: SELECT
-- Parameters: @Threshold (INT)
-- Description: Retrieves low stock products with stock level analysis using window functions
-- Special Note: Uses multiple window functions AVG(), MIN(), MAX() for stock analysis
-- ==================================================================================

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

-- ==================================================================================
-- END OF EXTRACTION CATALOG
-- ==================================================================================
-- Summary:
-- Total Statements Extracted: 7
-- - SELECT statements: 4 (STMT_001, STMT_002, STMT_006, STMT_007)
-- - Transaction blocks: 3 (STMT_003, STMT_004, STMT_005)
-- 
-- All statements are syntactically complete and ready for DMS MCP tool processing.
-- Parameter placeholders preserved using @ParameterName format.
-- ==================================================================================
