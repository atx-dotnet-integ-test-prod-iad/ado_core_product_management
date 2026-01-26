-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Conversion Method: Manual conversion after DMS tool timeout failures
-- All statements were submitted to DMS tool but encountered service issues
-- Converted using PostgreSQL best practices and syntax compatibility
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Original: SQL Server CTE with window functions
-- PostgreSQL Conversion: Direct conversion - PostgreSQL supports same CTE and window function syntax
-- Changes: None required - PostgreSQL-compatible syntax
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
-- STATEMENT 2: GetProductByIdAsync
-- Original: SQL Server CTE with LAG window function
-- PostgreSQL Conversion: Direct conversion - PostgreSQL supports LAG and same syntax
-- Changes: None required - PostgreSQL-compatible syntax
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
-- STATEMENT 3: InsertProductAsync
-- Original: SQL Server transaction with SCOPE_IDENTITY() and GETDATE()
-- PostgreSQL Conversion: Major changes for PostgreSQL compatibility
-- Changes:
--   1. DECLARE @NewProductId INT -> DO $$ DECLARE v_NewProductId INT block syntax
--   2. BEGIN TRANSACTION -> BEGIN (implicit in DO block or can use BEGIN/COMMIT)
--   3. SCOPE_IDENTITY() -> RETURNING clause pattern for getting inserted ID
--   4. GETDATE() -> CURRENT_TIMESTAMP or NOW()
--   5. SET @NewProductId -> INTO v_NewProductId
--   6. SELECT @NewProductId -> Handled via RETURNING in INSERT
-- Note: This needs to be restructured as a function or use RETURNING clause
-- ============================================================================
DO $$
DECLARE 
    v_NewProductId INT;
BEGIN
    -- Insert the new product and get the ID
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
    
    -- Return the new product ID (Note: In actual code, this will use ExecuteScalarAsync with RETURNING)
END $$;

-- Alternative for direct execution (preferred for ADO.NET):
-- Use a single INSERT with RETURNING and handle subsequent operations separately
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Original: SQL Server transaction with DECLARE, SELECT into variables, GETDATE()
-- PostgreSQL Conversion: Convert to DO block with PostgreSQL variable syntax
-- Changes:
--   1. BEGIN TRANSACTION -> BEGIN in DO block
--   2. DECLARE @OldPrice DECIMAL(18,2) -> DECLARE v_OldPrice NUMERIC(18,2)
--   3. SELECT @OldPrice = Price -> SELECT Price INTO v_OldPrice
--   4. GETDATE() -> CURRENT_TIMESTAMP
--   5. Variable references @OldPrice -> v_OldPrice
--   6. COMMIT -> COMMIT in DO block
-- ============================================================================
DO $$
DECLARE 
    v_OldPrice NUMERIC(18,2);
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
-- STATEMENT 5: DeleteProductAsync
-- Original: SQL Server transaction with DECLARE, SELECT into variables, GETDATE()
-- PostgreSQL Conversion: Convert to DO block with PostgreSQL variable syntax
-- Changes: Same as Statement 4 - DECLARE syntax, variable naming, GETDATE() conversion
-- ============================================================================
DO $$
DECLARE 
    v_OldPrice NUMERIC(18,2);
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
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Original: SQL Server CTE with RANK() and PERCENT_RANK() window functions
-- PostgreSQL Conversion: Direct conversion - PostgreSQL supports same syntax
-- Changes: None required - PostgreSQL-compatible syntax
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
-- STATEMENT 7: GetLowStockProductsAsync
-- Original: SQL Server CTE with multiple window functions (AVG, MIN, MAX OVER)
-- PostgreSQL Conversion: Direct conversion - PostgreSQL supports same syntax
-- Changes: None required - PostgreSQL-compatible syntax
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
-- IMPORTANT NOTES FOR CODE INTEGRATION:
-- ============================================================================
-- 1. Statements 3, 4, 5 use DO $$ blocks which are for direct PostgreSQL execution
--    In ADO.NET code, these should be split into multiple commands or use explicit transactions
-- 2. For InsertProductAsync (Statement 3), use RETURNING clause approach:
--    Execute: INSERT INTO Products (...) VALUES (...) RETURNING ProductId
--    Then execute subsequent INSERT/UPDATE statements in the same transaction
-- 3. Parameter syntax @ is compatible with Npgsql when using named parameters
-- 4. CURRENT_TIMESTAMP can be used directly, or NOW() function
-- 5. Transaction handling in ADO.NET: Use NpgsqlTransaction with BEGIN/COMMIT/ROLLBACK
-- 6. All decimal types converted to NUMERIC in PostgreSQL (compatible with DECIMAL)
-- ============================================================================
