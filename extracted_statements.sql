-- ==================================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source Application: AdoCore - Product Management System
-- ==================================================================================
-- This catalog contains all SQL statements extracted from the ADO.NET application
-- for processing through the DMS MCP tool for PostgreSQL conversion.
-- Each statement includes metadata indicating source location and context.
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~41-68
-- Method: GetAllProductsAsync()
-- Purpose: Retrieve all products with price analysis using CTEs and window functions
-- Parameters: None
-- Returns: List of products with price categories and percentage comparisons
-- Transaction: No
-- Complexity: High (CTE, window functions, CASE statements, JOINs)
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
-- STATEMENT 2: GetProductByIdAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~74-105
-- Method: GetProductByIdAsync(int productId)
-- Purpose: Retrieve a specific product with historical price comparison using LAG
-- Parameters: @ProductId (int)
-- Returns: Single product with price change percentage
-- Transaction: No
-- Complexity: High (CTE, LAG window function, self-join, CASE)
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
-- STATEMENT 3: InsertProductAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~111-140
-- Method: InsertProductAsync(Product product)
-- Purpose: Insert new product with transaction, history logging, and statistics update
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Returns: New ProductId
-- Transaction: Yes (BEGIN TRANSACTION / COMMIT)
-- Complexity: Very High (multi-statement transaction, variable declaration, SCOPE_IDENTITY, GETDATE)
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
-- STATEMENT 4: UpdateProductAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~146-183
-- Method: UpdateProductAsync(Product product)
-- Purpose: Update product with transaction, history logging, and statistics update
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Returns: None (ExecuteNonQuery)
-- Transaction: Yes (BEGIN TRANSACTION / COMMIT)
-- Complexity: Very High (multi-statement transaction, variable declarations, GETDATE)
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
-- STATEMENT 5: DeleteProductAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~189-222
-- Method: DeleteProductAsync(int productId)
-- Purpose: Delete product with transaction, history logging, and statistics update
-- Parameters: @ProductId (int)
-- Returns: None (ExecuteNonQuery)
-- Transaction: Yes (BEGIN TRANSACTION / COMMIT)
-- Complexity: Very High (multi-statement transaction, variable declarations, conditional CASE, GETDATE)
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
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~228-256
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Purpose: Retrieve products within a price range with ranking and percentile analysis
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Returns: List of products with price ranks and segments
-- Transaction: No
-- Complexity: High (CTE, RANK, PERCENT_RANK window functions, CASE, BETWEEN)
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~262-291
-- Method: GetLowStockProductsAsync(int threshold)
-- Purpose: Retrieve low stock products with inventory analysis using multiple window functions
-- Parameters: @Threshold (int)
-- Returns: List of low stock products with stock status and percentage comparisons
-- Transaction: No
-- Complexity: High (CTE, multiple window functions - AVG OVER, MIN OVER, MAX OVER, CASE, ROUND)
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
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total Statements: 7
-- Statements with Transactions: 3 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
-- Statements with CTEs: 5
-- Statements with Window Functions: 5
-- Statements with CASE expressions: 5
-- ==================================================================================
