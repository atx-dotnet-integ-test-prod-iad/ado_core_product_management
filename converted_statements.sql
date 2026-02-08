-- ============================================================================
-- CONVERTED SQL STATEMENTS - SQL Server to PostgreSQL
-- Conversion Date: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: All conversion attempts failed with metadata model error
-- ============================================================================
-- This file contains all SQL statements converted from Microsoft SQL Server 
-- syntax to PostgreSQL syntax. Each statement was first attempted through the 
-- DMS MCP tool, but due to persistent "Metadata model creation failed" errors,
-- manual conversion was performed following SQL Server to PostgreSQL migration
-- best practices.
-- 
-- Conversion Guidelines Applied:
-- - GETDATE() -> CURRENT_TIMESTAMP or NOW()
-- - SCOPE_IDENTITY() -> RETURNING clause
-- - CTEs and window functions are compatible (no changes needed)
-- - ROUND() function syntax differences handled
-- - Transaction syntax (BEGIN TRANSACTION/COMMIT) -> BEGIN/COMMIT
-- - Variable declarations (DECLARE @var) -> DO blocks or inline expressions
-- - Parameter syntax (@param) remains the same
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed
-- Changes Applied: None - PostgreSQL supports CTEs and window functions natively
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed
-- Changes Applied: None - PostgreSQL supports LAG window function natively
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
-- STATEMENT 3: InsertProductAsync - Transaction with RETURNING clause
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed
-- Changes Applied:
-- 1. Removed DECLARE @NewProductId INT (not needed with RETURNING)
-- 2. Changed BEGIN TRANSACTION to BEGIN
-- 3. Replaced SCOPE_IDENTITY() with RETURNING ProductId
-- 4. Replaced GETDATE() with CURRENT_TIMESTAMP
-- 5. Split into multiple statements as PostgreSQL requires
-- NOTE: This needs to be refactored in C# code to capture RETURNING value
-- ============================================================================
-- Statement 3a: Insert Product and get new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log the insertion (execute after getting ProductId from 3a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Handling
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed
-- Changes Applied:
-- 1. Converted to DO block for variable handling
-- 2. Changed BEGIN TRANSACTION/COMMIT to BEGIN/COMMIT
-- 3. Replaced GETDATE() with CURRENT_TIMESTAMP
-- 4. Removed SQL Server-specific DECLARE syntax
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
-- STATEMENT 5: DeleteProductAsync - Transaction with Variable Handling
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed
-- Changes Applied:
-- 1. Converted to DO block for variable handling
-- 2. Changed BEGIN TRANSACTION/COMMIT to BEGIN/COMMIT
-- 3. Replaced GETDATE() with CURRENT_TIMESTAMP
-- 4. Removed SQL Server-specific DECLARE syntax
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed
-- Changes Applied: None - PostgreSQL supports RANK and PERCENT_RANK natively
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Window Functions
-- ============================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR - Metadata model creation failed
-- Changes Applied: None - PostgreSQL supports all window functions natively
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
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements: 7
-- Successfully Converted by DMS: 0
-- Manually Converted After DMS Failure: 7
-- 
-- Key Conversion Notes:
-- 1. CTEs (WITH clauses) - No changes needed, PostgreSQL native support
-- 2. Window Functions (AVG/COUNT/LAG/RANK/PERCENT_RANK OVER) - No changes needed
-- 3. GETDATE() -> CURRENT_TIMESTAMP (all transaction statements)
-- 4. SCOPE_IDENTITY() -> RETURNING clause (InsertProductAsync)
-- 5. Transaction blocks with variables -> DO $$ blocks or separate statements
-- 6. BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT (implicit in PostgreSQL)
-- 7. Parameter syntax (@param) - Compatible, no changes needed
-- 
-- Implementation Notes:
-- - Statement 3 (InsertProductAsync) needs C# code refactoring to handle RETURNING
-- - Statements 4 and 5 (Update/Delete) use DO blocks, may need refactoring for 
--   C# ADO.NET compatibility (consider using separate statements with temp variables)
-- ============================================================================
