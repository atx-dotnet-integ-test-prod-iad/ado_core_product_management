/*
==============================================================================
CONVERTED SQL STATEMENTS - PostgreSQL
Microsoft SQL Server to PostgreSQL Migration
==============================================================================
Source File: extracted_statements.sql
Conversion Date: 2026-02-04
Total Statements: 7
Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered metadata model errors)
==============================================================================
*/

-- ==============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ==============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversion Notes:
-- - CTE syntax is compatible between SQL Server and PostgreSQL
-- - Window functions (AVG OVER, COUNT OVER) are compatible
-- - ROUND function is compatible
-- - CASE expressions are compatible
-- - No schema name changes needed (Products table name preserved)
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ==============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversion Notes:
-- - CTE syntax is compatible
-- - LAG window function is compatible (standard SQL)
-- - Parameter @ProductId remains compatible (Npgsql supports @ prefix)
-- - LEFT JOIN is compatible
-- - CASE expressions are compatible
-- - ROUND function is compatible
-- - No schema name changes needed
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with RETURNING
-- ==============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversion Notes:
-- - BEGIN TRANSACTION changed to BEGIN
-- - DECLARE @NewProductId INT; removed (using RETURNING clause instead)
-- - SCOPE_IDENTITY() replaced with RETURNING ProductId in INSERT statement
-- - GETDATE() replaced with CURRENT_TIMESTAMP (PostgreSQL standard)
-- - COMMIT remains the same
-- - Variable assignment replaced with PostgreSQL DO block approach for multi-statement transaction
-- - Note: This is restructured to use PostgreSQL's RETURNING clause with CTE for subsequent statements
-- ==============================================================================

WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId
),
history_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1
RETURNING (SELECT ProductId FROM inserted_product);

-- Alternative simpler approach using PostgreSQL's RETURNING:
-- This version is more straightforward and aligns with ADO.NET usage
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: The transaction block and subsequent statements will be handled by 
-- application code using Npgsql transactions and separate commands

-- ==============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction
-- ==============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversion Notes:
-- - BEGIN TRANSACTION changed to BEGIN
-- - DECLARE syntax remains compatible with PostgreSQL
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - Variable assignment (SELECT @OldPrice = Price) syntax is compatible in PostgreSQL
-- - COMMIT remains the same
-- - Using DO block for transaction with variables in PostgreSQL
-- ==============================================================================

DO $$
DECLARE
    old_price DECIMAL(18,2);
    old_stock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO old_price, old_stock
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
    VALUES (@ProductId, 'UPDATE', old_price, @Price, old_stock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - old_price + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Alternative for ADO.NET (transaction managed by application code):
-- Query 1: Get old values
SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Query 2: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Query 3: Log changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Query 4: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ==============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with Deletion
-- ==============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversion Notes:
-- - BEGIN TRANSACTION changed to BEGIN
-- - DECLARE syntax adapted to PostgreSQL
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - Transaction logic preserved
-- - CASE expressions are compatible
-- ==============================================================================

DO $$
DECLARE
    old_price DECIMAL(18,2);
    old_stock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO old_price, old_stock
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', old_price, NULL, old_stock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - old_price) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Alternative for ADO.NET (transaction managed by application code):
-- Query 1: Get old values
SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- Query 2: Log deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Query 3: Delete product
DELETE FROM Products WHERE ProductId = @ProductId;

-- Query 4: Update statistics
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

-- ==============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ==============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversion Notes:
-- - CTE syntax is compatible
-- - RANK() OVER window function is compatible (standard SQL)
-- - PERCENT_RANK() OVER window function is compatible (standard SQL)
-- - BETWEEN operator is compatible
-- - CASE expressions are compatible
-- - No schema name changes needed
-- ==============================================================================

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

-- ==============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Aggregate Window Functions
-- ==============================================================================
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- PostgreSQL Conversion Notes:
-- - CTE syntax is compatible
-- - AVG/MIN/MAX window functions are compatible (standard SQL)
-- - CASE expressions are compatible
-- - ROUND function is compatible
-- - WHERE clause filtering is compatible
-- - No schema name changes needed
-- ==============================================================================

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

-- ==============================================================================
-- END OF CONVERTED STATEMENTS
-- ==============================================================================
-- Summary:
-- Total Statements Converted: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
-- DMS Tool Status: Failed with metadata model creation error for all statements
--
-- Key Conversions Applied:
-- 1. BEGIN TRANSACTION → BEGIN (or removed when using ADO.NET transactions)
-- 2. SCOPE_IDENTITY() → RETURNING clause in INSERT statement
-- 3. GETDATE() → CURRENT_TIMESTAMP
-- 4. DECLARE variable syntax → PostgreSQL DO block format (for transaction statements)
-- 5. Multi-statement transactions → Restructured for PostgreSQL or split into separate commands
--
-- Schema Changes: None (table names preserved as-is)
-- 
-- Compatibility Notes:
-- - CTEs are fully compatible between SQL Server and PostgreSQL
-- - Window functions (LAG, AVG/MIN/MAX OVER, RANK, PERCENT_RANK) are standard SQL
-- - ROUND, CASE, JOIN operations are compatible
-- - Parameter binding with @ prefix is supported by Npgsql
-- ==============================================================================
