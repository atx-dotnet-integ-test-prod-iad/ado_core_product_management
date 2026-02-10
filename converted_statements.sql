-- ================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- ================================================================
-- This file contains all SQL statements converted from SQL Server to PostgreSQL
-- 
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements)
-- DMS Tool Status: Failed for all statements with error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- 
-- Note: All statements were attempted through DMS MCP tool first as required.
--       Manual conversions follow PostgreSQL best practices for syntax compatibility.
-- ================================================================

-- ================================================================
-- STATEMENT 1: GetAllProductsAsync (MANUAL_AFTER_DMS_FAILURE)
-- ================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync()
-- DMS Status: ERROR - Metadata model creation failed
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None (table names preserved as-is)
-- PostgreSQL Conversions Applied:
--   - Window functions (AVG, COUNT) - Compatible with PostgreSQL, no changes needed
--   - CASE expressions - Compatible with PostgreSQL, no changes needed
--   - CTEs - Compatible with PostgreSQL, no changes needed
--   - ROUND function - Compatible with PostgreSQL, no changes needed
-- ================================================================

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

-- ================================================================
-- STATEMENT 2: GetProductByIdAsync (MANUAL_AFTER_DMS_FAILURE)
-- ================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync(int productId)
-- DMS Status: ERROR - Metadata model creation failed
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None (table names preserved as-is)
-- PostgreSQL Conversions Applied:
--   - LAG window function - Compatible with PostgreSQL, no changes needed
--   - Parameter syntax @ProductId - Compatible with Npgsql, no changes needed
--   - CTEs - Compatible with PostgreSQL, no changes needed
-- ================================================================

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

-- ================================================================
-- STATEMENT 3: InsertProductAsync (MANUAL_AFTER_DMS_FAILURE)
-- ================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: InsertProductAsync(Product product)
-- DMS Status: ERROR - Metadata model creation failed
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None (table names preserved as-is)
-- PostgreSQL Conversions Applied:
--   - DECLARE @NewProductId INT - Removed (not needed with RETURNING clause)
--   - SET @NewProductId = SCOPE_IDENTITY() - Replaced with RETURNING clause
--   - GETDATE() - Replaced with CURRENT_TIMESTAMP (3 occurrences)
--   - BEGIN TRANSACTION/COMMIT - Kept as-is (compatible with PostgreSQL when using ADO.NET transaction handling)
--   - Transaction block maintained for application-level handling
-- ================================================================

INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: The ProductHistory and ProductStats updates need to be handled separately
-- in the application code using the returned ProductId, or combined in a function.
-- For ADO.NET pattern, the transaction handling in C# will manage these operations:

-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ================================================================
-- STATEMENT 4: UpdateProductAsync (MANUAL_AFTER_DMS_FAILURE)
-- ================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: UpdateProductAsync(Product product)
-- DMS Status: ERROR - Metadata model creation failed
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None (table names preserved as-is)
-- PostgreSQL Conversions Applied:
--   - DECLARE variables - Converted to DO block or separate queries
--   - GETDATE() - Replaced with CURRENT_TIMESTAMP (3 occurrences)
--   - BEGIN TRANSACTION/COMMIT - Handled at application level with Npgsql
--   - Variable assignment from SELECT - Needs separate query or DO block
-- ================================================================

-- First query to get old values (executed separately in C# code):
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Update query:
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- History insert (using old values from first query):
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statistics update:
-- UPDATE ProductStats
-- SET 
--     AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ================================================================
-- STATEMENT 5: DeleteProductAsync (MANUAL_AFTER_DMS_FAILURE)
-- ================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: DeleteProductAsync(int productId)
-- DMS Status: ERROR - Metadata model creation failed
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None (table names preserved as-is)
-- PostgreSQL Conversions Applied:
--   - DECLARE variables - Needs separate query or DO block
--   - GETDATE() - Replaced with CURRENT_TIMESTAMP (2 occurrences)
--   - BEGIN TRANSACTION/COMMIT - Handled at application level with Npgsql
--   - Variable assignment from SELECT - Needs separate query
--   - CASE expression - Compatible with PostgreSQL, no changes needed
-- ================================================================

-- First query to get old values (executed separately in C# code):
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- History insert:
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete query:
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statistics update:
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts - 1,
--     AveragePrice = CASE 
--         WHEN TotalProducts > 1 
--         THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
--         ELSE 0
--     END,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (MANUAL_AFTER_DMS_FAILURE)
-- ================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- DMS Status: ERROR - Metadata model creation failed
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None (table names preserved as-is)
-- PostgreSQL Conversions Applied:
--   - RANK() window function - Compatible with PostgreSQL, no changes needed
--   - PERCENT_RANK() window function - Compatible with PostgreSQL, no changes needed
--   - CTEs - Compatible with PostgreSQL, no changes needed
--   - BETWEEN operator - Compatible with PostgreSQL, no changes needed
-- ================================================================

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

-- ================================================================
-- STATEMENT 7: GetLowStockProductsAsync (MANUAL_AFTER_DMS_FAILURE)
-- ================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync(int threshold)
-- DMS Status: ERROR - Metadata model creation failed
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Schema Changes: None (table names preserved as-is)
-- PostgreSQL Conversions Applied:
--   - Window functions (AVG, MIN, MAX) - Compatible with PostgreSQL, no changes needed
--   - CTEs - Compatible with PostgreSQL, no changes needed
--   - ROUND function - Compatible with PostgreSQL, no changes needed
--   - CASE expressions - Compatible with PostgreSQL, no changes needed
-- ================================================================

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

-- ================================================================
-- END OF CONVERTED STATEMENTS
-- ================================================================
-- Summary:
-- - Total Statements: 7
-- - Successfully Converted by DMS: 0
-- - Manually Converted after DMS Failure: 7
-- - Schema Object Name Changes: None
-- 
-- Key PostgreSQL Conversions:
-- 1. SCOPE_IDENTITY() → RETURNING clause in INSERT
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. T-SQL variable declarations → Handled in application code or DO blocks
-- 4. BEGIN TRANSACTION/COMMIT → Handled at application level with Npgsql
-- 5. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) → No changes (compatible)
-- 6. CTEs → No changes (compatible)
-- 7. CASE expressions → No changes (compatible)
-- 8. Parameter syntax @ → No changes (Npgsql handles @parameters)
-- 
-- Note: Transaction blocks with multiple statements need to be split into
-- separate queries and managed at the application level using Npgsql transactions.
-- ================================================================
