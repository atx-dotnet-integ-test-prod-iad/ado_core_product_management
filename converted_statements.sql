-- ==================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- ==================================================================================
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool timeout for all statements)
-- Conversion Date: 2026-01-31
-- Target Database: PostgreSQL
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ==================================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model conversion timeout
-- Changes Applied:
--   - No syntax changes needed (CTEs, window functions, CASE, ROUND are PostgreSQL compatible)
--   - Parameter syntax @ is supported by Npgsql
-- Schema Object Changes: None
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ==================================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model conversion timeout
-- Changes Applied:
--   - No syntax changes needed (LAG window function, LEFT JOIN are PostgreSQL compatible)
--   - ROUND function syntax identical
--   - Parameter @ProductId supported by Npgsql
-- Schema Object Changes: None
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ==================================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model conversion timeout
-- Changes Applied:
--   - Replaced SCOPE_IDENTITY() with RETURNING clause in INSERT
--   - Replaced GETDATE() with CURRENT_TIMESTAMP (3 occurrences)
--   - Removed explicit BEGIN TRANSACTION/COMMIT (handled by ADO.NET transaction)
--   - Removed DECLARE and SELECT statements (RETURNING handles ID return)
-- CRITICAL CODE CHANGE REQUIRED: C# code must be updated to handle RETURNING clause
-- Schema Object Changes: None
-- ==================================================================================

-- Insert the new product and return the new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Log the insertion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction Block with DECLARE
-- ==================================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model conversion timeout
-- Changes Applied:
--   - Removed DECLARE statements (use PostgreSQL DO block or handle in multiple commands)
--   - Replaced GETDATE() with CURRENT_TIMESTAMP (3 occurrences)
--   - Removed explicit BEGIN TRANSACTION/COMMIT (handled by ADO.NET transaction)
--   - Split into multiple statements to handle old value capture
-- CRITICAL CODE CHANGE REQUIRED: C# code must handle multiple statements or use DO block
-- Schema Object Changes: None
-- ==================================================================================

-- Store old values for history (executed first in transaction)
SELECT Price, StockQuantity
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
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction Block with DELETE
-- ==================================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model conversion timeout
-- Changes Applied:
--   - Removed DECLARE statements (handle in C# code or use DO block)
--   - Replaced GETDATE() with CURRENT_TIMESTAMP (2 occurrences)
--   - Removed explicit BEGIN TRANSACTION/COMMIT (handled by ADO.NET transaction)
--   - Split into multiple statements
-- CRITICAL CODE CHANGE REQUIRED: C# code must handle multiple statements
-- Schema Object Changes: None
-- ==================================================================================

-- Store product info for history (executed first in transaction)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

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
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - SELECT with RANK and PERCENT_RANK
-- ==================================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model conversion timeout
-- Changes Applied:
--   - No syntax changes needed (RANK, PERCENT_RANK window functions are PostgreSQL compatible)
--   - BETWEEN operator identical
--   - Parameters @MinPrice, @MaxPrice supported by Npgsql
-- Schema Object Changes: None
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - SELECT with Multiple Window Functions
-- ==================================================================================
-- Original Source: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: Error - Metadata model conversion timeout
-- Changes Applied:
--   - No syntax changes needed (AVG, MIN, MAX window functions are PostgreSQL compatible)
--   - ROUND function syntax identical
--   - Parameter @Threshold supported by Npgsql
-- Schema Object Changes: None
-- ==================================================================================

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

-- ==================================================================================
-- END OF CONVERTED STATEMENTS
-- ==================================================================================
-- Summary:
-- - Total Statements: 7
-- - Successfully Converted by DMS: 0 (all timeout errors)
-- - Manually Converted After DMS Failure: 7
-- - Statements Requiring No Changes: 4 (Statements 1, 2, 6, 7)
-- - Statements Requiring Syntax Changes: 3 (Statements 3, 4, 5)
--
-- Key Conversions Applied:
-- - SCOPE_IDENTITY() → RETURNING clause (Statement 3)
-- - GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
-- - BEGIN TRANSACTION/COMMIT removed (ADO.NET handles transactions)
-- - DECLARE statements removed (handle in C# code)
-- - Multi-statement transactions split for clarity
--
-- Schema Object Names: No changes (all table names remain: Products, ProductHistory, ProductStats)
--
-- Critical Code Integration Notes:
-- - Statement 3: C# code must read RETURNING value from INSERT
-- - Statements 4 & 5: C# code must execute SELECT first, capture values, pass to subsequent statements
-- - All transaction statements: Wrap in ADO.NET transaction (BeginTransactionAsync/CommitAsync)
-- ==================================================================================
