-- ================================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Transformation ID: 20260127_074906_88b581ab
-- Date: 2026-01-27
-- ================================================================================
-- This file contains all SQL statements converted from Microsoft SQL Server
-- syntax to PostgreSQL syntax. Each statement is shown with its original
-- SQL Server version followed by the converted PostgreSQL version.
-- ================================================================================
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- REASON: DMS MCP tool experienced systematic timeout errors during conversion
-- All conversions follow PostgreSQL migration best practices
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ================================================================================
-- Source: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - Window functions: Compatible (AVG, COUNT OVER)
--   - ROUND(): Compatible, no changes needed
--   - CASE expressions: Compatible, no changes needed
-- ================================================================================

-- ORIGINAL SQL SERVER VERSION:
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
    p.Name;
*/

-- CONVERTED POSTGRESQL VERSION:
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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ================================================================================
-- Source: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - LAG() window function: Compatible, no changes needed
--   - Parameters: @ProductId → $1 (PostgreSQL numbered parameters)
--   - ROUND(): Compatible, no changes needed
-- ================================================================================

-- ORIGINAL SQL SERVER VERSION:
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
WHERE p.ProductId = @ProductId;
*/

-- CONVERTED POSTGRESQL VERSION:
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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ================================================================================
-- Source: DataAccess/ProductRepository.cs, Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--   - SCOPE_IDENTITY() → RETURNING clause on INSERT
--   - GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
--   - Eliminated T-SQL variable declarations (@NewProductId)
--   - Restructured to use RETURNING clause for product ID capture
--   - Parameters: @Name → $1, @Description → $2, @Price → $3, @StockQuantity → $4
--   - Combined INSERT...RETURNING with subsequent operations using WITH clause
-- CRITICAL: This requires code-level restructuring to capture RETURNING value
-- ================================================================================

-- ORIGINAL SQL SERVER VERSION:
/*
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
*/

-- CONVERTED POSTGRESQL VERSION:
-- Note: This conversion splits the transaction into separate statements for ADO.NET execution
-- The application code will manage the transaction and capture the RETURNING value

-- Statement 3A: Insert Product with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ($1, $2, $3, $4)
RETURNING ProductId;

-- Statement 3B: Log insertion (to be executed with captured ProductId as $1)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP);

-- Statement 3C: Update statistics (to be executed with Price as $1)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction Block with Variable Storage
-- ================================================================================
-- Source: DataAccess/ProductRepository.cs, Method: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--   - GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
--   - Eliminated T-SQL variable declarations (@OldPrice, @OldStock)
--   - Restructured to use subqueries or CTEs for old value capture
--   - Parameters: @ProductId → $1, @Name → $2, @Description → $3, @Price → $4, @StockQuantity → $5
--   - Combined operations to avoid T-SQL variables
-- CRITICAL: Requires code-level transaction management
-- ================================================================================

-- ORIGINAL SQL SERVER VERSION:
/*
BEGIN TRANSACTION;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL VERSION:
-- Note: Split into separate statements with application-level transaction management

-- Statement 4A: Capture old values (SELECT to be executed and values stored in application)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

-- Statement 4B: Update product
UPDATE Products
SET 
    Name = $1,
    Description = $2,
    Price = $3,
    StockQuantity = $4,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = $5;

-- Statement 4C: Log changes (using captured old values from 4A as $2 and $4)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'UPDATE', $2, $3, $4, $5, CURRENT_TIMESTAMP);

-- Statement 4D: Update statistics (using old price as $2, new price as $1)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - $2 + $1) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with History Logging
-- ================================================================================
-- Source: DataAccess/ProductRepository.cs, Method: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--   - GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
--   - Eliminated T-SQL variable declarations (@OldPrice, @OldStock)
--   - Restructured to capture values before delete
--   - Parameters: @ProductId → $1
--   - CASE expression: Compatible, no changes needed
-- CRITICAL: Requires code-level transaction management
-- ================================================================================

-- ORIGINAL SQL SERVER VERSION:
/*
BEGIN TRANSACTION;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
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
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL VERSION:
-- Note: Split into separate statements with application-level transaction management

-- Statement 5A: Capture product info before deletion
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

-- Statement 5B: Log deletion (using captured values as $2 and $3)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP);

-- Statement 5C: Delete product
DELETE FROM Products 
WHERE ProductId = $1;

-- Statement 5D: Update statistics (using old price as $1)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - $1) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ================================================================================
-- Source: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - RANK() window function: Compatible, no changes needed
--   - PERCENT_RANK() window function: Compatible, no changes needed
--   - Parameters: @MinPrice → $1, @MaxPrice → $2
--   - BETWEEN operator: Compatible, no changes needed
-- ================================================================================

-- ORIGINAL SQL SERVER VERSION:
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
ORDER BY rp.PriceRank;
*/

-- CONVERTED POSTGRESQL VERSION:
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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Aggregate Window Functions
-- ================================================================================
-- Source: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Changes Applied:
--   - CTE syntax: Compatible, no changes needed
--   - AVG(), MIN(), MAX() window functions: Compatible, no changes needed
--   - ROUND(): Compatible, no changes needed
--   - Parameters: @Threshold → $1
--   - CASE expressions: Compatible, no changes needed
-- ================================================================================

-- ORIGINAL SQL SERVER VERSION:
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
ORDER BY StockQuantity;
*/

-- CONVERTED POSTGRESQL VERSION:
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

-- ================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- ================================================================================
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- Key Changes Summary:
--   1. Parameter syntax: @param → $n (numbered parameters)
--   2. Date functions: GETDATE() → CURRENT_TIMESTAMP
--   3. Identity retrieval: SCOPE_IDENTITY() → RETURNING clause
--   4. Transaction syntax: BEGIN TRANSACTION → BEGIN (implicit in application)
--   5. Variable declarations: Eliminated, restructured to use RETURNING or application variables
--   6. CTEs, window functions, CASE: All compatible, no changes needed
-- ================================================================================
