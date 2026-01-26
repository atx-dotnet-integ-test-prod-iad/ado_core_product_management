-- ============================================================================
-- Converted SQL Statements (MS SQL Server to PostgreSQL)
-- PostgreSQL Compatible Syntax
-- Date: 2026-01-26
-- Total Statements: 6
-- Conversion Method: Manual after DMS Tool failures (documented in dms_conversion_log.txt)
-- ============================================================================

-- ============================================================================
-- STATEMENT 1 of 6 (CONVERTED)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Statement Type: SELECT with CTE and Window Functions
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - PostgreSQL compatible
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
-- STATEMENT 2 of 6 (CONVERTED)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Statement Type: SELECT with CTE and LAG Window Function
-- Parameters: @ProductId (int)
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - PostgreSQL compatible
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
-- STATEMENT 3 of 6 (CONVERTED)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Statement Type: MULTI-STATEMENT TRANSACTION (INSERT)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- CRITICAL Changes: 
--   - SCOPE_IDENTITY() → RETURNING ProductId
--   - GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
--   - Multi-statement transaction needs ADO.NET level handling
-- ============================================================================

-- FIRST STATEMENT: Insert with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- SECOND STATEMENT: Log the insertion (use returned ProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- THIRD STATEMENT: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4 of 6 (CONVERTED)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Statement Type: MULTI-STATEMENT TRANSACTION (UPDATE)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- CRITICAL Changes:
--   - GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
--   - Variable declarations handled at ADO.NET level
--   - Multi-statement transaction needs ADO.NET level handling
-- ============================================================================

-- FIRST STATEMENT: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- SECOND STATEMENT: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- THIRD STATEMENT: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- FOURTH STATEMENT: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 5 of 6 (CONVERTED)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Statement Type: MULTI-STATEMENT TRANSACTION (DELETE)
-- Parameters: @ProductId
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- CRITICAL Changes:
--   - GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
--   - Variable declarations handled at ADO.NET level
--   - Multi-statement transaction needs ADO.NET level handling
-- ============================================================================

-- FIRST STATEMENT: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- SECOND STATEMENT: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- THIRD STATEMENT: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- FOURTH STATEMENT: Update product statistics
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

-- ============================================================================
-- STATEMENT 6 of 6 (CONVERTED)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT with CTE, RANK and PERCENT_RANK Window Functions
-- Parameters: @MinPrice, @MaxPrice
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - PostgreSQL compatible
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
-- BONUS STATEMENT (CONVERTED - Not counted in main 6)
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: @Threshold
-- Conversion: MANUAL_AFTER_DMS_FAILURE
-- Changes: None required - PostgreSQL compatible
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
-- Total Statements Converted: 6 main + 1 bonus
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE for all statements
-- 
-- Key Conversions Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause (Statement 3)
-- 2. GETDATE() → CURRENT_TIMESTAMP (10 total occurrences in statements 3, 4, 5)
-- 3. Multi-statement transactions split into separate SQL statements for ADO.NET handling
-- 4. CTE and Window functions: No changes required (fully PostgreSQL compatible)
-- 5. CASE expressions: No changes required
-- 6. Parameters: @param syntax compatible with Npgsql
--
-- Schema Object Name Changes: NONE
-- All table names remain unchanged: Products, ProductHistory, ProductStats
--
-- Integration Notes:
-- - Statements 1, 2, 6: Direct replacement, no code changes needed
-- - Statement 3: Requires code restructuring to capture RETURNING value
-- - Statements 4, 5: Require code restructuring to handle multiple statements in transaction
-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
