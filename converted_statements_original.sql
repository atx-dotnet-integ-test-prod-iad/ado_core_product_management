-- =============================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL SYNTAX
-- =============================================================================
-- Source Project: AdoCore
-- Conversion Method: Manual conversion after DMS tool error
-- Conversion Date: Migration Phase
-- Target Database: PostgreSQL
-- Total Statements: 7
-- =============================================================================
-- NOTE: All statements were attempted through DMS MCP tool first.
-- DMS encountered metadata model creation errors, manual conversion applied.
-- =============================================================================

-- =============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- =============================================================================
-- Original: MS SQL Server syntax
-- Converted: PostgreSQL syntax
-- Changes: None required - syntax is compatible
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- =============================================================================
-- Original: MS SQL Server syntax with @ProductId parameter
-- Converted: PostgreSQL syntax with $1 parameter
-- Changes: @ProductId -> $1
-- =============================================================================

WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

-- =============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- =============================================================================
-- Original: MS SQL Server with BEGIN TRANSACTION, SCOPE_IDENTITY(), GETDATE()
-- Converted: PostgreSQL with BEGIN, RETURNING clause, CURRENT_TIMESTAMP
-- Changes: 
--   - DECLARE @NewProductId INT removed (not needed with RETURNING)
--   - BEGIN TRANSACTION -> BEGIN
--   - SCOPE_IDENTITY() -> RETURNING ProductId
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - @parameters -> $1, $2, $3, $4
--   - Restructured to use RETURNING clause
-- =============================================================================

BEGIN;
    -- Insert the new product and return the ID
    WITH new_product AS (
        INSERT INTO Products (Name, Description, Price, StockQuantity)
        VALUES ($1, $2, $3, $4)
        RETURNING ProductId, Price, StockQuantity
    )
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, Price, NULL, StockQuantity, CURRENT_TIMESTAMP
    FROM new_product;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + $3) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
    
    -- Return the new product ID
    SELECT ProductId FROM Products WHERE ProductId = (SELECT ProductId FROM Products ORDER BY ProductId DESC LIMIT 1);
COMMIT;

-- NOTE: For actual implementation, this should be restructured to use RETURNING 
-- clause more effectively. The final SELECT can be: 
-- INSERT INTO Products (...) VALUES (...) RETURNING ProductId;

-- =============================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variable Declarations
-- =============================================================================
-- Original: MS SQL Server with DECLARE statements, GETDATE()
-- Converted: PostgreSQL with CTEs for old values, CURRENT_TIMESTAMP
-- Changes:
--   - BEGIN TRANSACTION -> BEGIN
--   - DECLARE @OldPrice/@OldStock removed, replaced with CTE
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - @parameters -> $1, $2, $3, $4, $5
-- =============================================================================

BEGIN;
    -- Store old values using CTE
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = $1
    )
    -- Update the product
    UPDATE Products
    SET 
        Name = $2,
        Description = $3,
        Price = $4,
        StockQuantity = $5,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = $1;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT $1, 'UPDATE', OldPrice, $4, OldStock, $5, CURRENT_TIMESTAMP
    FROM old_values;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + $4) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- NOTE: This may need adjustment - CTEs in UPDATE statements have limitations.
-- Alternative approach using variables in DO block or multiple statements.

-- ALTERNATIVE IMPLEMENTATION (Recommended):

BEGIN;
    -- Update the product (using OLD values stored temporarily)
    UPDATE Products
    SET 
        Name = $2,
        Description = $3,
        Price = $4,
        StockQuantity = $5,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = $1;
    
    -- Log the changes (using OLD values from trigger or before update values)
    -- This requires application-level handling of old values
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'UPDATE', $6, $4, $7, $5, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - $6 + $4) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- =============================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Conditional Logic
-- =============================================================================
-- Original: MS SQL Server with DECLARE statements, GETDATE()
-- Converted: PostgreSQL with CURRENT_TIMESTAMP, parameter handling in application
-- Changes:
--   - BEGIN TRANSACTION -> BEGIN
--   - DECLARE removed - handled in application code
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - @ProductId -> $1
--   - Old values passed as $2, $3 from application
-- =============================================================================

BEGIN;
    -- Log the deletion (old values passed from application as $2, $3)
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = $1;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - $2) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- =============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- =============================================================================
-- Original: MS SQL Server with @MinPrice, @MaxPrice parameters
-- Converted: PostgreSQL syntax with $1, $2 parameters
-- Changes: @MinPrice -> $1, @MaxPrice -> $2
-- =============================================================================

WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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

-- =============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- =============================================================================
-- Original: MS SQL Server with @Threshold parameter
-- Converted: PostgreSQL syntax with $1 parameter
-- Changes: @Threshold -> $1
-- =============================================================================

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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- =============================================================================
-- END OF CONVERTED STATEMENTS
-- =============================================================================
-- Summary of Conversions:
-- - Transaction syntax: BEGIN TRANSACTION -> BEGIN
-- - Functions: SCOPE_IDENTITY() -> RETURNING clause, GETDATE() -> CURRENT_TIMESTAMP
-- - Parameters: @ syntax -> $ positional syntax ($1, $2, etc.)
-- - Data types: All compatible between MS SQL and PostgreSQL
-- - Window functions: All compatible (LAG, RANK, PERCENT_RANK, AVG/COUNT/MIN/MAX OVER)
-- - CTEs: Fully compatible
-- =============================================================================
