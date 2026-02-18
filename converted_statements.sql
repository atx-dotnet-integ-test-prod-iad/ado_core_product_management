-- =============================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL SYNTAX (UPDATED)
-- =============================================================================
-- Source Project: AdoCore
-- Conversion Method: Manual conversion after DMS tool error + Code-level refactoring
-- Conversion Date: Migration Phase (Updated after T-SQL syntax fixes)
-- Target Database: PostgreSQL
-- Total Statements: 7
-- =============================================================================
-- NOTE: All statements were attempted through DMS MCP tool first.
-- DMS encountered metadata model creation errors, manual conversion applied.
-- Additional refactoring performed to eliminate T-SQL constructs (DECLARE, SCOPE_IDENTITY).
-- =============================================================================

-- =============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- =============================================================================
-- Original: MS SQL Server syntax
-- Converted: PostgreSQL syntax
-- Changes: None required - syntax is compatible
-- Status: PostgreSQL-compatible
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
-- Converted: PostgreSQL syntax (keeping @ProductId for Npgsql compatibility)
-- Changes: None required for SQL syntax - Npgsql handles @parameter translation
-- Status: PostgreSQL-compatible
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 3: InsertProductAsync - Refactored with RETURNING clause
-- =============================================================================
-- Original: Single multi-statement T-SQL block with DECLARE and SCOPE_IDENTITY()
-- Converted: Split into separate statements executed via ADO.NET transaction
-- Changes: 
--   - REMOVED: DECLARE @NewProductId INT (T-SQL construct)
--   - REMOVED: SET @NewProductId = SCOPE_IDENTITY() (T-SQL function)
--   - ADDED: RETURNING ProductId clause on INSERT
--   - Split into 3 separate SQL statements executed in application transaction
--   - Transaction now managed by NpgsqlTransaction in application code
-- Status: PostgreSQL-compatible
-- Implementation: Application-level transaction with 3 separate statements
-- =============================================================================

-- Statement 3a: Insert with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log the insertion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- =============================================================================
-- STATEMENT 4: UpdateProductAsync - Refactored with application-level old value capture
-- =============================================================================
-- Original: Single T-SQL block with DECLARE statements for capturing old values
-- Converted: Split into separate statements with application-level value storage
-- Changes:
--   - REMOVED: DECLARE @OldPrice, DECLARE @OldStock (T-SQL constructs)
--   - Old values now retrieved via SELECT and stored in application variables
--   - Split into 4 separate SQL statements executed in application transaction
--   - Transaction now managed by NpgsqlTransaction in application code
-- Status: PostgreSQL-compatible
-- Implementation: Application-level transaction with 4 separate statements
-- =============================================================================

-- Statement 4a: Retrieve old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 4b: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 4c: Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- =============================================================================
-- STATEMENT 5: DeleteProductAsync - Refactored with application-level old value capture
-- =============================================================================
-- Original: Single T-SQL block with DECLARE statements for capturing old values
-- Converted: Split into separate statements with application-level value storage
-- Changes:
--   - REMOVED: DECLARE @OldPrice, DECLARE @OldStock (T-SQL constructs)
--   - Old values now retrieved via SELECT and stored in application variables
--   - Split into 4 separate SQL statements executed in application transaction
--   - Transaction now managed by NpgsqlTransaction in application code
-- Status: PostgreSQL-compatible
-- Implementation: Application-level transaction with 4 separate statements
-- =============================================================================

-- Statement 5a: Retrieve old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update product statistics
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

-- =============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- =============================================================================
-- Original: MS SQL Server syntax with @MinPrice, @MaxPrice parameters
-- Converted: PostgreSQL syntax (keeping @ parameters for Npgsql compatibility)
-- Changes: None required - syntax is compatible
-- Status: PostgreSQL-compatible
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- =============================================================================
-- Original: MS SQL Server syntax with @Threshold parameter
-- Converted: PostgreSQL syntax (keeping @ parameter for Npgsql compatibility)
-- Changes: None required - syntax is compatible
-- Status: PostgreSQL-compatible
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
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- =============================================================================
-- CONVERSION SUMMARY
-- =============================================================================
-- Total Statements: 7 logical operations
-- PostgreSQL-Compatible Statements: 7 (100%)
-- Statements Requiring Refactoring: 3 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync)
-- 
-- KEY CHANGES:
-- 1. Eliminated all T-SQL DECLARE statements
-- 2. Replaced SCOPE_IDENTITY() with RETURNING clause
-- 3. Moved transaction management from SQL to application code (NpgsqlTransaction)
-- 4. Old value capture moved to application level for UPDATE/DELETE operations
-- 5. All GETDATE() converted to CURRENT_TIMESTAMP (in previous iteration)
-- 6. All syntax now PostgreSQL-compatible and compilable
-- =============================================================================
