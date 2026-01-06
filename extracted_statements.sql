-- =====================================================================================
-- SQL SERVER TO POSTGRESQL MIGRATION - EXTRACTED SQL STATEMENTS
-- =====================================================================================
-- Source File: ProductRepository.cs
-- Total Statements: 7
-- Extraction Date: 2026-01-06
-- =====================================================================================

-- =====================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- =====================================================================================
-- Method: GetAllProductsAsync()
-- Line Numbers: 40-65
-- Statement Type: SELECT with CTE
-- Features: Common Table Expression (CTE), Window Functions (AVG, COUNT), INNER JOIN, CASE expressions
-- Parameters: None
-- Description: Retrieves all products with price category analysis using window functions
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- =====================================================================================
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: 79-107
-- Statement Type: SELECT with CTE
-- Features: Common Table Expression (CTE), LAG Window Function, LEFT JOIN, CASE expression
-- Parameters: @ProductId (int)
-- Description: Retrieves a product by ID with historical price change analysis using LAG window function
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 3: InsertProductAsync
-- =====================================================================================
-- Method: InsertProductAsync(Product product)
-- Line Numbers: 122-143
-- Statement Type: TRANSACTION with INSERT operations
-- Features: Multi-statement transaction, DECLARE variables, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE()
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Inserts a new product with history logging and statistics update in a transaction
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 4: UpdateProductAsync
-- =====================================================================================
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: 161-189
-- Statement Type: TRANSACTION with UPDATE and INSERT operations
-- Features: Multi-statement transaction, DECLARE variables, BEGIN TRANSACTION/COMMIT, GETDATE()
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Updates an existing product with history logging and statistics update in a transaction
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 5: DeleteProductAsync
-- =====================================================================================
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: 207-239
-- Statement Type: TRANSACTION with DELETE and INSERT operations
-- Features: Multi-statement transaction, DECLARE variables, BEGIN TRANSACTION/COMMIT, GETDATE(), CASE expression
-- Parameters: @ProductId (int)
-- Description: Deletes a product with history logging and statistics update in a transaction
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- =====================================================================================
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 256-274
-- Statement Type: SELECT with CTE
-- Features: Common Table Expression (CTE), RANK and PERCENT_RANK Window Functions, BETWEEN, CASE expression
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products within a price range with ranking and percentile analysis
-- =====================================================================================

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

-- =====================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- =====================================================================================
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 292-316
-- Statement Type: SELECT with CTE
-- Features: Common Table Expression (CTE), Window Functions (AVG, MIN, MAX), CASE expression, WHERE filter
-- Parameters: @Threshold (int)
-- Description: Retrieves products with low stock levels including stock analysis metrics
-- =====================================================================================

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

-- =====================================================================================
-- END OF EXTRACTED SQL STATEMENTS
-- =====================================================================================
-- Summary:
-- - Total Statements Extracted: 7
-- - SELECT Statements: 4
-- - TRANSACTION Statements (INSERT/UPDATE/DELETE): 3
-- - Statements with CTEs: 5
-- - Statements with Window Functions: 5
-- - Statements with Parameters: 6
-- =====================================================================================
