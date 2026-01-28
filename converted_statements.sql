-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Format
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS timeout errors)
-- Generated: 2025
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- Source: ProductRepository.cs, Lines 38-68
-- Method: GetAllProductsAsync()
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes: Parameter syntax @param to $param, ROUND precision handling
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
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- Source: ProductRepository.cs, Lines 81-109
-- Method: GetProductByIdAsync(int productId)
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes: Parameter syntax @ProductId to $1
-- ============================================================================
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- Source: ProductRepository.cs, Lines 122-147
-- Method: InsertProductAsync(Product product)
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes: 
--   - Removed DECLARE/SET for @NewProductId
--   - Changed SCOPE_IDENTITY() to RETURNING clause on INSERT
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Parameter syntax @param to $1, $2, $3, $4
--   - Wrapped in DO block for transaction with variable
-- ============================================================================
DO $$
DECLARE 
    v_NewProductId INT;
BEGIN
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES ($1, $2, $3, $4)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + $3) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
    
    -- Return the new product ID (Note: requires refactoring to use RETURNING from function)
END $$;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- Source: ProductRepository.cs, Lines 160-188
-- Method: UpdateProductAsync(Product product)
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - Changed DECLARE syntax to PostgreSQL format
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Parameter syntax @param to $1, $2, $3, $4, $5
--   - Removed BEGIN TRANSACTION/COMMIT (handled at connection level)
-- ============================================================================
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = $1;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = $2,
        Description = $3,
        Price = $4,
        StockQuantity = $5,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = $1;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'UPDATE', v_OldPrice, $4, v_OldStock, $5, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + $4) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- Source: ProductRepository.cs, Lines 201-229
-- Method: DeleteProductAsync(int productId)
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   - Changed DECLARE syntax to PostgreSQL format
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Parameter syntax @ProductId to $1
--   - Removed BEGIN TRANSACTION/COMMIT (handled at connection level)
-- ============================================================================
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = $1;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = $1;
    
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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- Source: ProductRepository.cs, Lines 242-268
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes: Parameter syntax @MinPrice to $1, @MaxPrice to $2
-- ============================================================================
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- Source: ProductRepository.cs, Lines 281-311
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes: Parameter syntax @Threshold to $1
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
