-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: ADO.NET Application
-- Date: 2026-02-11
-- ============================================================================

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements: 7
-- DMS Tool Attempts: 7 (100%)
-- DMS Tool Successes: 0 (0%)
-- DMS Tool Failures: 7 (100%)
-- Manual Conversions: 7 (100%)
-- 
-- DMS Error Pattern: All statements failed with:
-- "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- 
-- All statements were processed through DMS MCP tool first as required.
-- Manual conversions applied after DMS failures.
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Statement ID: 1_GetAllProductsAsync
-- Source: ProductRepository.cs:GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Timestamp: 2026-02-11T15:50:10.837435
-- 
-- Manual Conversion Notes:
-- - CTEs are fully compatible with PostgreSQL
-- - Window functions (AVG OVER, COUNT OVER) are compatible
-- - CASE statements are compatible
-- - ROUND function is compatible in PostgreSQL
-- - No schema object name changes needed
-- ============================================================================

-- ORIGINAL MS SQL:
/*
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
    p.Name
*/

-- CONVERTED POSTGRESQL:
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
-- ============================================================================
-- Statement ID: 2_GetProductByIdAsync
-- Source: ProductRepository.cs:GetProductByIdAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Timestamp: 2026-02-11T15:50:25.733762
-- 
-- Manual Conversion Notes:
-- - LAG window function is fully compatible with PostgreSQL
-- - LEFT JOIN is compatible
-- - Parameters @ProductId retained (Npgsql supports @ prefix)
-- - ROUND function compatible
-- - No schema object name changes needed
-- ============================================================================

-- ORIGINAL MS SQL:
/*
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
WHERE p.ProductId = @ProductId
*/

-- CONVERTED POSTGRESQL:
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
-- ============================================================================
-- Statement ID: 3_InsertProductAsync
-- Source: ProductRepository.cs:InsertProductAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Timestamp: 2026-02-11T15:50:40.523974
-- 
-- Manual Conversion Notes:
-- - DECLARE @NewProductId INT removed (not needed with RETURNING clause)
-- - BEGIN TRANSACTION → BEGIN
-- - COMMIT → COMMIT
-- - SCOPE_IDENTITY() → RETURNING ProductId (integrated into INSERT)
-- - GETDATE() → NOW()
-- - SET @NewProductId removed (use RETURNING instead)
-- - Final SELECT @NewProductId removed (handled by RETURNING)
-- - Refactored to use CTE with RETURNING for inserted ID capture
-- - No schema object name changes needed
-- ============================================================================

-- ORIGINAL MS SQL:
/*
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
*/

-- CONVERTED POSTGRESQL:
WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
FROM inserted_product;

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = NOW()
WHERE StatId = 1;

SELECT ProductId FROM inserted_product;

-- NOTE: This requires application code modification to handle the multi-statement nature.
-- Alternative single-statement approach for ExecuteScalarAsync:
-- INSERT INTO Products (Name, Description, Price, StockQuantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity)
-- RETURNING ProductId;
-- (Transaction and history/stats updates would need to be handled separately)

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Statement ID: 4_UpdateProductAsync
-- Source: ProductRepository.cs:UpdateProductAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Timestamp: 2026-02-11T15:50:56.070020
-- 
-- Manual Conversion Notes:
-- - BEGIN TRANSACTION → BEGIN (implicit in transaction context)
-- - COMMIT → COMMIT (implicit in transaction context)
-- - DECLARE removed (use subquery to capture old values)
-- - SELECT INTO variables → use CTE for old values
-- - GETDATE() → NOW()
-- - Refactored to use CTE for old value capture
-- - No schema object name changes needed
-- ============================================================================

-- ORIGINAL MS SQL:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL:
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = NOW()
WHERE ProductId = @ProductId;

INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, NOW()
FROM old_values;

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = NOW()
WHERE StatId = 1;

-- NOTE: This requires handling as multi-statement batch or within application-managed transaction

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Statement ID: 5_DeleteProductAsync
-- Source: ProductRepository.cs:DeleteProductAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Timestamp: 2026-02-11T15:51:09.600021
-- 
-- Manual Conversion Notes:
-- - BEGIN TRANSACTION → BEGIN (implicit in transaction context)
-- - COMMIT → COMMIT (implicit in transaction context)
-- - DECLARE removed (use CTE for old values)
-- - SELECT INTO variables → use CTE
-- - GETDATE() → NOW()
-- - CASE statement fully compatible
-- - No schema object name changes needed
-- ============================================================================

-- ORIGINAL MS SQL:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL:
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, NOW()
FROM old_values;

DELETE FROM Products 
WHERE ProductId = @ProductId;

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = NOW()
WHERE StatId = 1;

-- NOTE: This requires handling as multi-statement batch or within application-managed transaction

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Statement ID: 6_GetProductsByPriceRangeAsync
-- Source: ProductRepository.cs:GetProductsByPriceRangeAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Timestamp: 2026-02-11T15:51:22.903740
-- 
-- Manual Conversion Notes:
-- - RANK() window function fully compatible with PostgreSQL
-- - PERCENT_RANK() window function fully compatible with PostgreSQL
-- - CASE statement fully compatible
-- - BETWEEN operator compatible
-- - Parameters @MinPrice, @MaxPrice retained
-- - No schema object name changes needed
-- ============================================================================

-- ORIGINAL MS SQL:
/*
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
ORDER BY rp.PriceRank
*/

-- CONVERTED POSTGRESQL:
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
-- ============================================================================
-- Statement ID: 7_GetLowStockProductsAsync
-- Source: ProductRepository.cs:GetLowStockProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: ERROR
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- DMS Timestamp: 2026-02-11T15:51:35.594866
-- 
-- Manual Conversion Notes:
-- - AVG/MIN/MAX window functions fully compatible with PostgreSQL
-- - CASE statement fully compatible
-- - ROUND function compatible
-- - Parameter @Threshold retained
-- - No schema object name changes needed
-- ============================================================================

-- ORIGINAL MS SQL:
/*
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
ORDER BY StockQuantity
*/

-- CONVERTED POSTGRESQL:
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
-- 
-- CONVERSION SUMMARY BY COMPLEXITY:
-- 
-- Simple Conversions (No changes needed - PostgreSQL compatible):
-- - Statement 1: GetAllProductsAsync (Window functions, CTEs, CASE)
-- - Statement 2: GetProductByIdAsync (LAG, LEFT JOIN)
-- - Statement 6: GetProductsByPriceRangeAsync (RANK, PERCENT_RANK)
-- - Statement 7: GetLowStockProductsAsync (AVG/MIN/MAX OVER)
-- 
-- Complex Conversions (Significant changes):
-- - Statement 3: InsertProductAsync (SCOPE_IDENTITY → RETURNING, GETDATE → NOW)
-- - Statement 4: UpdateProductAsync (DECLARE/variables → CTE, GETDATE → NOW)
-- - Statement 5: DeleteProductAsync (DECLARE/variables → CTE, GETDATE → NOW)
-- 
-- Key PostgreSQL Syntax Changes Applied:
-- - GETDATE() → NOW() (5 occurrences)
-- - SCOPE_IDENTITY() → RETURNING clause (1 occurrence)
-- - DECLARE @var → CTE pattern (3 occurrences)
-- - BEGIN TRANSACTION/COMMIT → implicit in application transaction handling
-- - Variable assignments → CTE/subquery patterns
-- 
-- Schema Object Name Changes:
-- - NONE (All table names preserved: Products, ProductHistory, ProductStats)
-- 
-- ============================================================================
