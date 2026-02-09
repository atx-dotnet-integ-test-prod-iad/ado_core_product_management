-- =====================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- ADO.NET SQL Server to PostgreSQL Migration
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 7
-- =====================================================================

-- =====================================================================
-- STATEMENT 1
-- Method: GetAllProductsAsync
-- Location: ProductRepository.cs, Lines 38-69
-- Complexity: High - CTE with window functions (AVG OVER, COUNT OVER), CASE expressions, ROUND, INNER JOIN
-- Transaction: No
-- Description: Complex query using CTE with window functions to calculate average price and total products, 
--              then categorizes products based on price comparison to average
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 2
-- Method: GetProductByIdAsync
-- Location: ProductRepository.cs, Lines 80-108
-- Complexity: High - CTE with LAG window function, LEFT JOIN, CASE with calculations
-- Transaction: No
-- Description: Query using CTE with LAG window function to retrieve previous price and stock,
--              calculates price change percentage
-- Parameters: @ProductId (int)
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 3
-- Method: InsertProductAsync
-- Location: ProductRepository.cs, Lines 128-152
-- Complexity: High - Transaction block with DECLARE, BEGIN/COMMIT, SCOPE_IDENTITY(), GETDATE(), 
--             multiple INSERT/UPDATE statements
-- Transaction: Yes - Complete transaction block
-- Description: Transaction that inserts a new product, logs the insertion to history table,
--              updates statistics, and returns the new product ID using SCOPE_IDENTITY()
-- Parameters: @Name (string), @Description (string/NULL), @Price (decimal), @StockQuantity (int)
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 4
-- Method: UpdateProductAsync
-- Location: ProductRepository.cs, Lines 170-199
-- Complexity: High - Transaction block with DECLARE variables, SELECT into variables, UPDATE, 
--             INSERT, GETDATE()
-- Transaction: Yes - Complete transaction block
-- Description: Transaction that stores old values, updates product, logs changes to history,
--              and updates statistics
-- Parameters: @ProductId (int), @Name (string), @Description (string/NULL), @Price (decimal), 
--             @StockQuantity (int)
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 5
-- Method: DeleteProductAsync
-- Location: ProductRepository.cs, Lines 218-252
-- Complexity: High - Transaction block with DECLARE, SELECT into variables, INSERT, DELETE, 
--             UPDATE with CASE expression
-- Transaction: Yes - Complete transaction block
-- Description: Transaction that stores product info, logs deletion, deletes product,
--              and updates statistics with CASE expression for average calculation
-- Parameters: @ProductId (int)
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 6
-- Method: GetProductsByPriceRangeAsync
-- Location: ProductRepository.cs, Lines 262-285
-- Complexity: High - CTE with RANK() and PERCENT_RANK() window functions, CASE expression
-- Transaction: No
-- Description: Query using CTE with ranking window functions to analyze products within
--              a price range and categorize them into price segments
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- =====================================================================
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

-- =====================================================================
-- STATEMENT 7
-- Method: GetLowStockProductsAsync
-- Location: ProductRepository.cs, Lines 295-323
-- Complexity: High - CTE with multiple window functions (AVG, MIN, MAX OVER), CASE expression, 
--             calculations
-- Transaction: No
-- Description: Query using CTE with multiple window functions to analyze stock levels,
--              categorizes stock status, and calculates stock percentage relative to average
-- Parameters: @Threshold (int)
-- =====================================================================
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

-- =====================================================================
-- END OF EXTRACTED STATEMENTS
-- Total: 7 SQL statements
-- Transaction blocks: 3 (Insert, Update, Delete)
-- Query statements: 4 (GetAll, GetById, GetByPriceRange, GetLowStock)
-- =====================================================================
