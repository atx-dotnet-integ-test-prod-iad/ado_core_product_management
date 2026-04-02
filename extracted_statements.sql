-- ============================================================================
-- Extracted SQL Statements from ProductRepository.cs
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Method: GetAllProductsAsync()
-- Location: ProductRepository.cs, approximately lines 43-67
-- Parameters: None
-- Description: Complex SELECT with CTE (ProductStats), window functions, 
--              INNER JOIN, CASE, ROUND, ORDER BY with CASE
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
-- Statement 2: GetProductByIdAsync
-- Method: GetProductByIdAsync(int productId)
-- Location: ProductRepository.cs, approximately lines 78-101
-- Parameters: @ProductId (INT)
-- Description: Complex SELECT with CTE (ProductHistory), window functions (LAG),
--              LEFT JOIN, CASE with NULL handling, ROUND
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
-- Statement 3: InsertProductAsync
-- Method: InsertProductAsync(Product product)
-- Location: ProductRepository.cs, approximately lines 113-133
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), 
--             @StockQuantity (INT)
-- Description: Transaction block with DECLARE, BEGIN TRANSACTION, INSERT (Products),
--              SCOPE_IDENTITY, INSERT (ProductHistory), UPDATE (ProductStats), COMMIT, SELECT
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
-- Statement 4: UpdateProductAsync
-- Method: UpdateProductAsync(Product product)
-- Location: ProductRepository.cs, approximately lines 145-173
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), 
--             @Price (DECIMAL), @StockQuantity (INT)
-- Description: Transaction block with DECLARE, SELECT INTO variables, 
--              UPDATE (Products) with GETDATE, INSERT (ProductHistory), 
--              UPDATE (ProductStats), COMMIT
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
-- Statement 5: DeleteProductAsync
-- Method: DeleteProductAsync(int productId)
-- Location: ProductRepository.cs, approximately lines 185-213
-- Parameters: @ProductId (INT)
-- Description: Transaction block with DECLARE, SELECT INTO variables, 
--              INSERT (ProductHistory), DELETE (Products), 
--              UPDATE (ProductStats) with CASE, COMMIT
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
-- Statement 6: GetProductsByPriceRangeAsync
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Location: ProductRepository.cs, approximately lines 218-237
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Complex SELECT with CTE (RankedProducts), window functions 
--              (RANK, PERCENT_RANK), BETWEEN, CASE, ORDER BY
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
-- Statement 7: GetLowStockProductsAsync
-- Method: GetLowStockProductsAsync(int threshold)
-- Location: ProductRepository.cs, approximately lines 252-271
-- Parameters: @Threshold (INT)
-- Description: Complex SELECT with CTE (StockAnalysis), window functions 
--              (AVG, MIN, MAX OVER), CASE, ROUND, WHERE, ORDER BY
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
-- Additional Reference: SQL Scripts (not embedded in application code)
-- ============================================================================
-- Scripts/01_InitialSetup.sql - Contains DDL, stored procedures, sample data
-- Database/Scripts/01_InitialSetup.sql - Contains DDL, triggers, stored procedures,
--   categories, suppliers, products sample data, indexes
-- These scripts define the schema that the application SQL statements reference:
--   Tables: Products, ProductHistory, ProductStats, Categories, Suppliers
--   Stored Procedures: sp_GetAllProducts, sp_GetProductById, sp_InsertProduct,
--                      sp_UpdateProduct, sp_DeleteProduct
--   Trigger: trg_Products_History
-- ============================================================================
