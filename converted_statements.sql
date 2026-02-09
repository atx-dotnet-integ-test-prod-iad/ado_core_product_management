-- =====================================================================
-- CONVERTED SQL STATEMENTS (PostgreSQL)
-- ADO.NET SQL Server to PostgreSQL Migration
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- Total Statements: 7
-- DMS Tool Status: All 7 statements failed with metadata model creation error
-- =====================================================================

-- =====================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: ProductRepository.cs, GetAllProductsAsync, Lines 38-69
-- Changes: No changes needed - PostgreSQL fully supports CTE and window functions
-- Schema Changes: None (Products table name unchanged)
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
    p.Name;

-- =====================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: ProductRepository.cs, GetProductByIdAsync, Lines 80-108
-- Changes: No changes needed - LAG window function fully supported in PostgreSQL
-- Schema Changes: None (Products table name unchanged)
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
WHERE p.ProductId = @ProductId;

-- =====================================================================
-- STATEMENT 3: InsertProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: ProductRepository.cs, InsertProductAsync, Lines 128-152
-- Changes: 
--   - Removed DECLARE @NewProductId INT (not needed with RETURNING)
--   - Removed BEGIN TRANSACTION/COMMIT (handled by NpgsqlTransaction at code level)
--   - Changed SCOPE_IDENTITY() to RETURNING ProductId
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Split into multiple commands to be executed sequentially in transaction
-- Schema Changes: None (Products, ProductHistory, ProductStats unchanged)
-- Note: This will be executed as 3 separate commands within a transaction in the code
-- =====================================================================
-- Command 1: Insert product and get new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Command 2: Log the insertion (executed after getting @NewProductId from RETURNING)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Command 3: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- =====================================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: ProductRepository.cs, UpdateProductAsync, Lines 170-199
-- Changes:
--   - Removed BEGIN TRANSACTION/COMMIT (handled by NpgsqlTransaction at code level)
--   - Converted to DO block with PL/pgSQL for variable handling
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - All operations in single DO block
-- Schema Changes: None (Products, ProductHistory, ProductStats unchanged)
-- =====================================================================
DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity
    INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- =====================================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: ProductRepository.cs, DeleteProductAsync, Lines 218-252
-- Changes:
--   - Removed BEGIN TRANSACTION/COMMIT (handled by NpgsqlTransaction at code level)
--   - Converted to DO block with PL/pgSQL for variable handling
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - All operations in single DO block
-- Schema Changes: None (Products, ProductHistory, ProductStats unchanged)
-- =====================================================================
DO $$
DECLARE 
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity
    INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - v_OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- =====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: ProductRepository.cs, GetProductsByPriceRangeAsync, Lines 262-285
-- Changes: No changes needed - RANK and PERCENT_RANK fully supported in PostgreSQL
-- Schema Changes: None (Products table name unchanged)
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
ORDER BY rp.PriceRank;

-- =====================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Method: ProductRepository.cs, GetLowStockProductsAsync, Lines 295-323
-- Changes: No changes needed - Window functions fully supported in PostgreSQL
-- Schema Changes: None (Products table name unchanged)
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
ORDER BY StockQuantity;

-- =====================================================================
-- CONVERSION SUMMARY
-- =====================================================================
-- Total Statements Converted: 7
-- DMS Tool Successful: 0
-- Manual Conversions: 7
-- 
-- Statements 1, 2, 6, 7: No changes - fully compatible with PostgreSQL
-- Statement 3: Split into multiple commands, SCOPE_IDENTITY() -> RETURNING, GETDATE() -> CURRENT_TIMESTAMP
-- Statements 4, 5: Converted to DO blocks with PL/pgSQL, GETDATE() -> CURRENT_TIMESTAMP
--
-- Schema Changes: NONE
-- All table names unchanged: Products, ProductHistory, ProductStats
-- =====================================================================
