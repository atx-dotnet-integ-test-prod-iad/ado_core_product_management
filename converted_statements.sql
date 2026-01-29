-- =====================================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
-- Converted from: extracted_statements.sql (MS SQL Server)
-- Total Statements: 7
-- Conversion Date: 2026-01-29
-- Conversion Method: Manual (after DMS MCP tool failures - see dms_conversion_log.txt)
-- =====================================================================================

-- =====================================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Mapped from: Statement 1 in extracted_statements.sql
-- Conversion Notes: 
--   - CTE and window functions are compatible
--   - No parameter changes needed (query has no parameters)
--   - ROUND function compatible
--   - CASE expressions compatible
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
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Mapped from: Statement 2 in extracted_statements.sql
-- Conversion Notes:
--   - CTE compatible
--   - LAG window function compatible
--   - @ProductId parameter kept (Npgsql supports @ syntax)
--   - LEFT JOIN compatible
--   - ROUND function compatible
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
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Mapped from: Statement 3 in extracted_statements.sql
-- Conversion Notes:
--   - REMOVED: DECLARE @NewProductId (not needed with RETURNING)
--   - REMOVED: SET @NewProductId = SCOPE_IDENTITY()
--   - REMOVED: SELECT @NewProductId (return value from RETURNING)
--   - CHANGED: GETDATE() → NOW()
--   - CHANGED: Use RETURNING clause to get new ID
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - COMMIT → COMMIT (compatible)
--   - Parameters kept as @Name, @Description, @Price, @StockQuantity (Npgsql compatible)
-- IMPORTANT: This will be restructured in code to use RETURNING clause properly
-- =====================================================================================
BEGIN;
    -- Insert the new product and get the ID using RETURNING
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Note: In application code, capture the returned ProductId
    -- Then use it for subsequent operations
    
    -- Log the insertion (using the returned ProductId)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- =====================================================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Mapped from: Statement 4 in extracted_statements.sql
-- Conversion Notes:
--   - CHANGED: GETDATE() → NOW()
--   - BEGIN TRANSACTION → BEGIN
--   - COMMIT → COMMIT
--   - REMOVED: DECLARE statements (will use WITH clause or separate queries in code)
--   - Variable assignments restructured for PostgreSQL
-- IMPORTANT: In code, this will be split into multiple statements
-- =====================================================================================
BEGIN;
    -- Store old values (using a CTE approach or separate SELECT in code)
    -- In PostgreSQL, we'll do this as separate operations in the application code
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = NOW()
    WHERE ProductId = @ProductId;
    
    -- Log the changes (old values will be retrieved in application code before update)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());
    
    -- Update product statistics (old price will be passed as parameter from code)
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- =====================================================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Mapped from: Statement 5 in extracted_statements.sql
-- Conversion Notes:
--   - CHANGED: GETDATE() → NOW()
--   - BEGIN TRANSACTION → BEGIN
--   - COMMIT → COMMIT
--   - REMOVED: DECLARE statements (values retrieved in code before transaction)
-- IMPORTANT: In code, retrieve old values before starting transaction
-- =====================================================================================
BEGIN;
    -- Log the deletion (old values retrieved in application code before transaction)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
    
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
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- =====================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Mapped from: Statement 6 in extracted_statements.sql
-- Conversion Notes:
--   - CTE compatible
--   - RANK() and PERCENT_RANK() window functions compatible
--   - BETWEEN clause compatible
--   - @MinPrice, @MaxPrice parameters kept (Npgsql compatible)
--   - p.* wildcard compatible
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
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Mapped from: Statement 7 in extracted_statements.sql
-- Conversion Notes:
--   - CTE compatible
--   - AVG(), MIN(), MAX() window functions compatible
--   - OVER() clause compatible
--   - @Threshold parameter kept (Npgsql compatible)
--   - ROUND function compatible
--   - p.* wildcard compatible
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
-- CONVERSION SUMMARY
-- =====================================================================================
-- Total Statements Converted: 7
-- Conversion Method: Manual (DMS MCP tool encountered errors for all statements)
-- 
-- Key Conversions Applied:
-- 1. GETDATE() → NOW()
-- 2. SCOPE_IDENTITY() → RETURNING clause
-- 3. BEGIN TRANSACTION → BEGIN
-- 4. DECLARE variables → Handled in application code or CTEs
-- 5. @Parameter syntax → Kept (Npgsql supports @ parameter prefix)
-- 
-- Compatible Features (no changes):
-- - CTEs (WITH clauses)
-- - Window functions (AVG OVER, LAG, RANK, PERCENT_RANK, MIN, MAX, COUNT)
-- - CASE expressions
-- - ROUND function
-- - JOIN operations
-- - BETWEEN clause
-- - Aggregate functions
-- 
-- Schema Objects:
-- No schema object names changed during conversion.
-- All table and column names remain the same.
-- =====================================================================================
