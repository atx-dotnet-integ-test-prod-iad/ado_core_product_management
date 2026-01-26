-- ================================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL Version
-- Microsoft SQL Server to PostgreSQL Migration
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- ================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None - SQL is PostgreSQL-compatible
-- Schema Transformations: None
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- ================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None - SQL is PostgreSQL-compatible
-- Schema Transformations: None
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- ================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: 
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Replaced SCOPE_IDENTITY() with RETURNING clause
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Restructured to use RETURNING for new ProductId
-- Schema Transformations: None
-- CRITICAL: This will be split into multiple command executions in C# code
-- ================================================================================

BEGIN;
    -- Insert the new product and return the new ID
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Note: The following statements will be executed separately in C# after capturing the returned ProductId
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- ================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Variable declarations will be handled via separate SELECT in C# code
-- Schema Transformations: None
-- CRITICAL: Variable assignments (@OldPrice, @OldStock) must be handled in C# code
-- ================================================================================

BEGIN;
    -- Store old values for history (to be executed as separate SELECT in C# code)
    -- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes (C# code will pass @OldPrice and @OldStock from previous SELECT)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- ================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - Changed BEGIN TRANSACTION to BEGIN
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Variable declarations will be handled via separate SELECT in C# code
-- Schema Transformations: None
-- CRITICAL: Variable assignments (@OldPrice, @OldStock) must be handled in C# code
-- ================================================================================

BEGIN;
    -- Store product info for history (to be executed as separate SELECT in C# code)
    -- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;
    
    -- Log the deletion (C# code will pass @OldPrice and @OldStock from previous SELECT)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);
    
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
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- ================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None - SQL is PostgreSQL-compatible
-- Schema Transformations: None
-- ================================================================================

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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- ================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None - SQL is PostgreSQL-compatible
-- Schema Transformations: None
-- ================================================================================

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

-- ================================================================================
-- END OF CONVERTED CATALOG
-- ================================================================================
-- Summary:
-- - Total statements converted: 7
-- - Statements requiring no changes: 4 (Statements 1, 2, 6, 7)
-- - Statements with modifications: 3 (Statements 3, 4, 5)
-- - Key conversions applied:
--   * BEGIN TRANSACTION → BEGIN (Statements 3, 4, 5)
--   * GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
--   * SCOPE_IDENTITY() → RETURNING clause (Statement 3)
--   * Variable declarations → Separate SELECT queries in C# (Statements 4, 5)
-- - Schema transformations: None
-- - All table names remain unchanged (Products, ProductHistory, ProductStats)
-- ================================================================================
