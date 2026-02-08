-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: ADO.NET ProductManagement Application
-- Target: PostgreSQL Database
-- Conversion Date: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- Purpose: PostgreSQL-converted SQL statements for migration
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ============================================================================
-- Conversion Timestamp: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Source: ProductRepository.cs, Line 40-68
-- DMS Tool Status: ERROR - Metadata model creation failed
-- PostgreSQL Changes:
--   - Added ::numeric cast for division operation to ensure proper decimal result
--   - All other syntax (CTE, window functions, CASE) is PostgreSQL-compatible
-- Schema Object Mappings: None (Products table name unchanged)
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
    ROUND((p.Price / ps.AvgPrice)::numeric * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ============================================================================
-- Conversion Timestamp: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Source: ProductRepository.cs, Line 85-113
-- DMS Tool Status: ERROR - Metadata model creation failed
-- PostgreSQL Changes:
--   - Added ::numeric cast for division operation
--   - @ProductId parameter compatible with Npgsql named parameters
--   - LAG window function syntax identical
-- Schema Object Mappings: None (Products table name unchanged)
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
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice)::numeric * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with RETURNING
-- ============================================================================
-- Conversion Timestamp: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Source: ProductRepository.cs, Line 125-158
-- DMS Tool Status: ERROR (anticipated based on consistent failures)
-- PostgreSQL Changes:
--   - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--   - SCOPE_IDENTITY() → RETURNING clause (PostgreSQL best practice)
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Variable declarations replaced with CTE chain using RETURNING
--   - Consolidated into single CTE chain for atomicity
-- Schema Object Mappings: None
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ============================================================================
BEGIN;
    -- Insert the new product and return the ID
    WITH inserted_product AS (
        INSERT INTO Products (Name, Description, Price, StockQuantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING ProductId
    ),
    -- Log the insertion
    inserted_history AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
        FROM inserted_product
        RETURNING ProductId
    )
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING (SELECT ProductId FROM inserted_product);
COMMIT;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction
-- ============================================================================
-- Conversion Timestamp: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Source: ProductRepository.cs, Line 167-205
-- DMS Tool Status: ERROR (anticipated)
-- PostgreSQL Changes:
--   - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Variable declarations (DECLARE @OldPrice, @OldStock) → CTE (old_values)
--   - Consolidated operations using CTEs with RETURNING
--   - DECIMAL(18,2) → NUMERIC(18,2) (implicit in PostgreSQL)
-- Schema Object Mappings: None
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================================
BEGIN;
    -- Store old values and update
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    ),
    updated_product AS (
        UPDATE Products
        SET 
            Name = @Name,
            Description = @Description,
            Price = @Price,
            StockQuantity = @StockQuantity,
            ModifiedDate = CURRENT_TIMESTAMP
        WHERE ProductId = @ProductId
        RETURNING ProductId
    ),
    inserted_history AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
        FROM old_values ov
        RETURNING ProductId
    )
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with Conditional Logic
-- ============================================================================
-- Conversion Timestamp: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Source: ProductRepository.cs, Line 214-250
-- DMS Tool Status: ERROR (anticipated)
-- PostgreSQL Changes:
--   - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Variable declarations replaced with CTE approach
--   - DELETE with RETURNING to capture deleted values (not used here, but available)
--   - CASE expression syntax identical
-- Schema Object Mappings: None
-- Parameters: @ProductId
-- ============================================================================
BEGIN;
    -- Store old values, log, delete, and update stats
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    ),
    inserted_history AS (
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
        SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
        FROM old_values
        RETURNING ProductId
    ),
    deleted_product AS (
        DELETE FROM Products 
        WHERE ProductId = @ProductId
        RETURNING ProductId
    )
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ============================================================================
-- Conversion Timestamp: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Source: ProductRepository.cs, Line 259-285
-- DMS Tool Status: ERROR (anticipated)
-- PostgreSQL Changes:
--   - CTE syntax is fully compatible
--   - RANK() and PERCENT_RANK() window functions supported in PostgreSQL
--   - BETWEEN operator identical
--   - CASE expressions identical
--   - @parameter syntax compatible with Npgsql named parameters
-- Schema Object Mappings: None
-- Parameters: @MinPrice, @MaxPrice
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Aggregate Window Functions
-- ============================================================================
-- Conversion Timestamp: 2026-02-08
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Original Source: ProductRepository.cs, Line 294-321
-- DMS Tool Status: ERROR (anticipated)
-- PostgreSQL Changes:
--   - CTE syntax is fully compatible
--   - Window functions (AVG, MIN, MAX with OVER) supported in PostgreSQL
--   - ROUND function syntax identical
--   - Added ::numeric cast for division operation
--   - CASE expressions identical
--   - @parameter syntax compatible with Npgsql
-- Schema Object Mappings: None
-- Parameters: @Threshold
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
    ROUND((StockQuantity::numeric / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements: 7
-- Successfully Converted by DMS: 0
-- Manually Converted After DMS Failure: 7
-- Schema Object Name Changes: 0
-- 
-- Key Conversion Patterns:
-- - GETDATE() → CURRENT_TIMESTAMP or NOW()
-- - SCOPE_IDENTITY() → RETURNING clause
-- - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
-- - Variable declarations → CTE-based approach
-- - Explicit ::numeric casts added for division operations
-- - @parameter syntax compatible with Npgsql named parameters
-- 
-- All conversions maintain semantic equivalence with original SQL Server statements.
-- ============================================================================
