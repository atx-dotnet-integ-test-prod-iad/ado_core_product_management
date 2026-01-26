-- ========================================================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION - MICROSOFT SQL SERVER SYNTAX
-- Source File: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Extraction Date: Migration Phase
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 41-67
-- Method: GetAllProductsAsync()
-- Parameters: None
-- Description: Retrieves all products with calculated average price statistics using CTE and window functions.
--              Uses AVG() OVER(), COUNT() OVER(), CASE statements, and complex ORDER BY logic.
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 80-107
-- Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId (int)
-- Description: Retrieves a single product with historical price and stock tracking using LAG window function.
--              Uses LAG() OVER (ORDER BY ModifiedDate), NULL handling in CASE statements.
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with SCOPE_IDENTITY
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 117-141
-- Method: InsertProductAsync(Product product)
-- Parameters: @Name (string), @Description (string/NULL), @Price (decimal), @StockQuantity (int)
-- Description: Inserts a new product within a transaction, logs the insertion, and updates statistics.
--              Uses DECLARE for variables, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE() function.
--              Returns the new product ID.
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 156-182
-- Method: UpdateProductAsync(Product product)
-- Parameters: @ProductId (int), @Name (string), @Description (string/NULL), @Price (decimal), @StockQuantity (int)
-- Description: Updates an existing product within a transaction, logs the changes, and updates statistics.
--              Uses DECLARE for variables, BEGIN TRANSACTION/COMMIT, GETDATE() function.
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with Conditional Logic
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 192-220
-- Method: DeleteProductAsync(int productId)
-- Parameters: @ProductId (int)
-- Description: Deletes a product within a transaction, logs the deletion, and updates statistics.
--              Uses DECLARE for variables, BEGIN TRANSACTION/COMMIT, GETDATE() function, CASE statement in UPDATE.
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK Window Functions
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 232-254
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products within a price range with ranking and percentile calculations.
--              Uses RANK() OVER(), PERCENT_RANK() OVER(), CASE statements for categorization.
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Aggregate Window Functions
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: 267-293
-- Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold (int)
-- Description: Retrieves products with low stock using aggregate window functions for analysis.
--              Uses AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE statements for categorization.
-- ========================================================================================================

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

-- ========================================================================================================
-- END OF EXTRACTED STATEMENTS
-- ========================================================================================================
-- Summary:
-- - Total Statements: 7
-- - CTEs: 5 (Statements 1, 2, 6, 7)
-- - Transactions: 3 (Statements 3, 4, 5)
-- - Window Functions Used: AVG() OVER(), COUNT() OVER(), LAG() OVER(), RANK() OVER(), PERCENT_RANK() OVER(), MIN() OVER(), MAX() OVER()
-- - SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE()
-- - Parameters: All using @ParameterName syntax
-- ========================================================================================================
