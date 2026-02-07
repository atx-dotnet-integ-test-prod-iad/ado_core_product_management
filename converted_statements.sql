-- ==================================================================================
-- CONVERTED SQL STATEMENTS - MICROSOFT SQL SERVER TO POSTGRESQL
-- ==================================================================================
-- This file contains all SQL statements converted from SQL Server to PostgreSQL
-- Each statement pair shows original SQL Server syntax and converted PostgreSQL syntax
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ==================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ==================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
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
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ==================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Parameter Conversion: @ProductId → $1
-- ==================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync - Transaction with SCOPE_IDENTITY() and GETDATE()
-- ==================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Parameter Conversion: @Name → $1, @Description → $2, @Price → $3, @StockQuantity → $4
-- Key Changes:
-- - Removed DECLARE @NewProductId INT (PostgreSQL uses RETURNING clause)
-- - Removed BEGIN TRANSACTION/COMMIT (handled at application level)
-- - Replaced SCOPE_IDENTITY() with RETURNING ProductId
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- ==================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ($1, $2, $3, $4)
RETURNING ProductId;

-- Note: The following statements need to be executed separately in the transaction:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (:NewProductId, 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP);

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + $3) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations and GETDATE()
-- ==================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Parameter Conversion: @ProductId → $1, @Name → $2, @Description → $3, @Price → $4, @StockQuantity → $5
-- Key Changes:
-- - Removed BEGIN TRANSACTION/COMMIT (handled at application level)
-- - Removed DECLARE statements (use subqueries or CTEs in PostgreSQL)
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- ==================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = $1
)
UPDATE Products
SET 
    Name = $2,
    Description = $3,
    Price = $4,
    StockQuantity = $5,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = $1;

-- Note: The following statements need to be executed separately in the transaction:
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT $1, 'UPDATE', OldPrice, $4, OldStock, $5, CURRENT_TIMESTAMP
FROM OldValues;

UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues) + $4) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with GETDATE()
-- ==================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Parameter Conversion: @ProductId → $1
-- Key Changes:
-- - Removed BEGIN TRANSACTION/COMMIT (handled at application level)
-- - Removed DECLARE statements (use subqueries or CTEs in PostgreSQL)
-- - Replaced GETDATE() with CURRENT_TIMESTAMP
-- ==================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = $1
)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
SELECT $1, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
FROM OldValues;

DELETE FROM Products 
WHERE ProductId = $1;

UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK() and PERCENT_RANK()
-- ==================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Parameter Conversion: @MinPrice → $1, @MaxPrice → $2
-- ==================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Window Functions
-- ==================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Parameter Conversion: @Threshold → $1
-- ==================================================================================

-- ORIGINAL SQL SERVER STATEMENT:
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

-- CONVERTED POSTGRESQL STATEMENT:
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

-- ==================================================================================
-- CONVERSION SUMMARY
-- ==================================================================================
-- Total Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (All statements)
-- DMS Tool Status: Failed for all statements with metadata model creation error
--
-- Key Conversions Applied:
-- 1. Parameter Syntax: @param → $1, $2, $3, etc. (positional parameters)
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. SCOPE_IDENTITY() → RETURNING clause
-- 4. Variable DECLARE statements → CTEs or subqueries
-- 5. BEGIN TRANSACTION/COMMIT → Handled at application level with Npgsql
-- 6. Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) → Compatible in PostgreSQL
-- 7. CTEs (WITH clauses) → Compatible in PostgreSQL
-- 8. CASE expressions → Compatible in PostgreSQL
-- 9. ROUND function → Compatible in PostgreSQL
--
-- Schema Object Name Changes: None detected
-- All table and column names preserved as-is from SQL Server
-- ==================================================================================
