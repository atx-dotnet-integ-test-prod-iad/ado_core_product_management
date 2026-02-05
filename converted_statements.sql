-- ============================================================================
-- CONVERTED SQL STATEMENTS TO POSTGRESQL
-- Source File: extracted_statements.sql
-- Conversion Date: 2026-02-04
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1 (CONVERTED)
-- Method: GetAllProductsAsync
-- Original Line: 38-68 in ProductRepository.cs
-- Conversion: Manual (DMS tool failed with metadata model creation error)
-- Changes: None required - PostgreSQL compatible CTE and window functions
-- Parameters: No changes needed (@params not used)
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
-- STATEMENT 2 (CONVERTED)
-- Method: GetProductByIdAsync
-- Original Line: 82-112 in ProductRepository.cs
-- Conversion: Manual (DMS tool failed with metadata model creation error)
-- Changes: @ProductId remains (ADO.NET will handle parameter binding)
-- Note: LAG function is PostgreSQL compatible
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
-- STATEMENT 3 (CONVERTED)
-- Method: InsertProductAsync
-- Original Line: 128-152 in ProductRepository.cs
-- Conversion: Manual (DMS tool failed with metadata model creation error)
-- Major Changes:
--   - Removed DECLARE @NewProductId (not needed in PostgreSQL DO block approach)
--   - Changed SCOPE_IDENTITY() to RETURNING clause approach
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Restructured to use PostgreSQL transaction syntax with DO block
-- Note: This will need code-level changes to handle RETURNING properly
-- ============================================================================
-- PostgreSQL version using RETURNING clause
DO $$
DECLARE
    v_NewProductId INT;
BEGIN
    -- Insert the new product and capture the ID
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Simpler version for ADO.NET usage (recommended):
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Then in separate statements:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4 (CONVERTED)
-- Method: UpdateProductAsync
-- Original Line: 167-196 in ProductRepository.cs
-- Conversion: Manual (DMS tool failed with metadata model creation error)
-- Major Changes:
--   - Converted to PostgreSQL DO block
--   - Changed DECLARE syntax
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Removed BEGIN TRANSACTION/COMMIT (will be handled at code level)
-- ============================================================================
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
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

-- ============================================================================
-- STATEMENT 5 (CONVERTED)
-- Method: DeleteProductAsync
-- Original Line: 211-241 in ProductRepository.cs
-- Conversion: Manual (DMS tool failed with metadata model creation error)
-- Major Changes:
--   - Converted to PostgreSQL DO block
--   - Changed DECLARE syntax
--   - Changed GETDATE() to CURRENT_TIMESTAMP
--   - Removed BEGIN TRANSACTION/COMMIT (will be handled at code level)
-- ============================================================================
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
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

-- ============================================================================
-- STATEMENT 6 (CONVERTED)
-- Method: GetProductsByPriceRangeAsync
-- Original Line: 254-278 in ProductRepository.cs
-- Conversion: Manual (DMS tool failed with metadata model creation error)
-- Changes: None required - RANK() and PERCENT_RANK() are PostgreSQL compatible
-- Parameters: @MinPrice, @MaxPrice remain (ADO.NET handles parameter binding)
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
-- STATEMENT 7 (CONVERTED)
-- Method: GetLowStockProductsAsync
-- Original Line: 292-317 in ProductRepository.cs
-- Conversion: Manual (DMS tool failed with metadata model creation error)
-- Changes: None required - Aggregate window functions are PostgreSQL compatible
-- Parameters: @Threshold remains (ADO.NET handles parameter binding)
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
-- END OF CONVERTED STATEMENTS
-- ============================================================================
