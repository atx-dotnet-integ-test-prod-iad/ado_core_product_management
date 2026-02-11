-- ===============================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
-- Migration: Microsoft SQL Server to PostgreSQL
-- Target: PostgreSQL Database with Npgsql Driver
-- Date: 2026-02-11
-- ===============================================================================
-- This catalog contains all SQL statements converted to PostgreSQL syntax.
-- Each statement has been processed through the DMS MCP tool or manually
-- converted when DMS tool encountered errors. All conversions are documented
-- in dms_conversion_log.txt with full details.
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: Get All Products with CTE and Window Functions (PostgreSQL)
-- ===============================================================================
-- Source: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - fully compatible
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 2: Get Product By ID with CTE and LAG Window Function (PostgreSQL)
-- ===============================================================================
-- Source: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - fully compatible, @parameter syntax supported by Npgsql
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 3: Insert Product with Transaction (PostgreSQL)
-- ===============================================================================
-- Source: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: 
--   1. Use RETURNING clause instead of SCOPE_IDENTITY()
--   2. Transaction must be split into separate statements in application code
--   3. Subsequent INSERTs/UPDATEs will use the returned ID
-- ===============================================================================

-- Main INSERT with RETURNING (executes within transaction)
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Log the insertion (separate statement, uses returned ProductId from above)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (separate statement)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===============================================================================
-- STATEMENT 4: Update Product with Transaction (PostgreSQL)
-- ===============================================================================
-- Source: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   1. Remove T-SQL DECLARE statements
--   2. Use RETURNING clause to capture old values
--   3. Replace GETDATE() with CURRENT_TIMESTAMP
--   4. Execute as separate statements within transaction
-- ===============================================================================

-- First: Capture old values and update (using RETURNING)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId
RETURNING ProductId;

-- Before update, get old values (in application code, execute SELECT first)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Log the changes (separate statement, using old values captured in app)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (separate statement)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===============================================================================
-- STATEMENT 5: Delete Product with Transaction (PostgreSQL)
-- ===============================================================================
-- Source: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes:
--   1. Capture old values before delete
--   2. Replace GETDATE() with CURRENT_TIMESTAMP
--   3. Execute as separate statements within transaction
-- ===============================================================================

-- First: Get old values before delete (in application code)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Log the deletion (separate statement, using captured values)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product (separate statement)
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update product statistics (separate statement)
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

-- ===============================================================================
-- STATEMENT 6: Get Products By Price Range with CTE and Window Functions (PostgreSQL)
-- ===============================================================================
-- Source: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - fully compatible
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 7: Get Low Stock Products with CTE and Window Functions (PostgreSQL)
-- ===============================================================================
-- Source: GetLowStockProductsAsync(int threshold)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - fully compatible
-- ===============================================================================

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

-- ===============================================================================
-- CONVERSION SUMMARY
-- ===============================================================================
-- Total SQL Operations Converted: 7
--
-- Conversion Methods:
--   - DMS Tool: 0 (tool encountered metadata model creation errors)
--   - Manual After DMS Failure: 7
--
-- Key PostgreSQL Changes Applied:
--   1. SCOPE_IDENTITY() replaced with RETURNING clause (1 statement)
--   2. GETDATE() replaced with CURRENT_TIMESTAMP (3 statements)
--   3. T-SQL DECLARE/SET variables removed, restructured for PostgreSQL (3 statements)
--   4. Transaction handling changed to application-level management (3 statements)
--   5. Most SELECT queries required no changes (4 statements)
--
-- Schema Object Names:
--   - No schema name changes required
--   - All tables remain in default schema (public in PostgreSQL)
--
-- Application Code Impact:
--   - Transaction methods (Insert/Update/Delete) will require code restructuring
--   - SELECT queries can remain largely unchanged
--   - RETURNING clause usage requires capturing results in application
--
-- Next Steps:
--   1. Validate each statement pair with SQL Equivalency tool
--   2. Re-integrate converted statements into ProductRepository.cs
--   3. Update transaction handling in application code
-- ===============================================================================
