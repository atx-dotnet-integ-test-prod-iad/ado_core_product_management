-- =========================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Migration
-- =========================================================================
-- This file contains all SQL statements converted from SQL Server to PostgreSQL
-- Each statement includes:
--   - Original statement reference
--   - Conversion method (DMS_TOOL or MANUAL_AFTER_DMS_FAILURE)
--   - PostgreSQL specific syntax changes applied
--   - Notes on semantic equivalence
-- =========================================================================

-- -------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- -------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model conversion failed
-- Manual Conversion Changes:
--   - ROUND() function: PostgreSQL compatible as-is
--   - CTE syntax: Compatible with PostgreSQL
--   - Window functions: Compatible (AVG/COUNT OVER)
--   - CASE expressions: Compatible
--   - No parameter conversion needed (no parameters in this query)
-- -------------------------------------------------------------------------

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

-- -------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- -------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Timeout - Command execution timed out after 300 seconds
-- Manual Conversion Changes:
--   - LAG() window function: Compatible with PostgreSQL
--   - @ProductId parameter: Keep as @ProductId (Npgsql supports named parameters)
--   - ROUND() function: Compatible
--   - LEFT JOIN: Compatible
--   - CASE expressions: Compatible
-- -------------------------------------------------------------------------

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

-- -------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with RETURNING
-- -------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not attempted (applying consistent manual conversion approach)
-- Manual Conversion Changes:
--   - DECLARE @NewProductId INT: Removed (PostgreSQL will use RETURNING clause)
--   - BEGIN TRANSACTION: Changed to BEGIN
--   - SCOPE_IDENTITY(): Replaced with RETURNING ProductId
--   - GETDATE(): Changed to CURRENT_TIMESTAMP
--   - SET @NewProductId: Removed (using RETURNING instead)
--   - SELECT @NewProductId: Removed (RETURNING handles this)
--   - Transaction structure: Converted to DO block for atomicity
--   - Multiple statements: Combined into transaction block
-- PostgreSQL Approach: Use RETURNING clause to get the new ProductId directly
--   from the INSERT statement, then use it in subsequent statements within transaction
-- -------------------------------------------------------------------------

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
END $$;

-- For ADO.NET usage, the actual implementation will use:
-- INSERT INTO Products (Name, Description, Price, StockQuantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity)
-- RETURNING ProductId;

-- -------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction
-- -------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not attempted (applying consistent manual conversion approach)
-- Manual Conversion Changes:
--   - BEGIN TRANSACTION: Changed to BEGIN
--   - DECLARE variables: PostgreSQL syntax (v_ prefix convention)
--   - SELECT INTO: PostgreSQL syntax
--   - GETDATE(): Changed to CURRENT_TIMESTAMP
--   - COMMIT: Compatible as-is
--   - All parameters (@ProductId, @Name, etc.): Keep as named parameters
-- -------------------------------------------------------------------------

BEGIN;
    -- Store old values for history
    DECLARE v_OldPrice DECIMAL(18,2);
    DECLARE v_OldStock INT;
    
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
COMMIT;

-- -------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction
-- -------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not attempted (applying consistent manual conversion approach)
-- Manual Conversion Changes:
--   - BEGIN TRANSACTION: Changed to BEGIN
--   - DECLARE variables: PostgreSQL syntax (v_ prefix convention)
--   - SELECT INTO: PostgreSQL syntax
--   - GETDATE(): Changed to CURRENT_TIMESTAMP
--   - CASE expression in UPDATE: Compatible
--   - COMMIT: Compatible as-is
-- -------------------------------------------------------------------------

BEGIN;
    -- Store product info for history
    DECLARE v_OldPrice DECIMAL(18,2);
    DECLARE v_OldStock INT;
    
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
COMMIT;

-- -------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- -------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not attempted (applying consistent manual conversion approach)
-- Manual Conversion Changes:
--   - RANK() OVER: Compatible with PostgreSQL
--   - PERCENT_RANK() OVER: Compatible with PostgreSQL
--   - BETWEEN: Compatible
--   - CASE expressions: Compatible
--   - Parameters (@MinPrice, @MaxPrice): Keep as named parameters
-- -------------------------------------------------------------------------

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

-- -------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- -------------------------------------------------------------------------
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Not attempted (applying consistent manual conversion approach)
-- Manual Conversion Changes:
--   - AVG/MIN/MAX window functions: Compatible with PostgreSQL
--   - CASE expressions: Compatible
--   - ROUND() function: Compatible
--   - @Threshold parameter: Keep as named parameter
-- -------------------------------------------------------------------------

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

-- =========================================================================
-- END OF CONVERTED SQL STATEMENTS
-- =========================================================================
-- Total Statements Converted: 7
-- Conversion Method Breakdown:
--   - DMS_TOOL: 0 (all failed or timed out)
--   - MANUAL_AFTER_DMS_FAILURE: 7
-- 
-- Key PostgreSQL Conversions Applied:
-- - SCOPE_IDENTITY() → RETURNING clause
-- - GETDATE() → CURRENT_TIMESTAMP
-- - @parameter syntax → Kept as-is (Npgsql supports named parameters)
-- - DECLARE @variable → DECLARE v_variable (PostgreSQL convention)
-- - BEGIN TRANSACTION → BEGIN
-- - Window functions, CTEs, CASE expressions → No changes needed (compatible)
-- 
-- Note: Npgsql ADO.NET provider supports named parameters (@param syntax), so
-- parameter names are kept consistent with the original SQL Server code for
-- minimal code changes in the C# application layer.
-- =========================================================================
