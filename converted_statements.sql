-- ========================================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- ========================================================================================================
-- Source Application: AdoCore - ADO.NET Product Management System
-- Migration Type: Microsoft SQL Server to PostgreSQL
-- Conversion Date: 2026-02-07
-- Conversion Method: DMS MCP Tool (All failed) + Manual Conversion
-- Total Statements: 7
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions and CASE Statements
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Changes Required: NONE - PostgreSQL compatible as-is
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Changes Required: NONE - PostgreSQL compatible as-is
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with SCOPE_IDENTITY
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Changes Required: SCOPE_IDENTITY() → LASTVAL(), GETDATE() → CURRENT_TIMESTAMP, variable syntax
-- Note: For use in C# code, this needs to be split into separate commands managed by Npgsql transaction
-- ========================================================================================================
DO $$
DECLARE NewProductId INT;
BEGIN
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    NewProductId := LASTVAL();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

SELECT LASTVAL();

-- Alternative conversion for ADO.NET (managed transaction approach without DO block):
-- Note: Transaction will be managed by NpgsqlTransaction in C# code
-- INSERT INTO Products (Name, Description, Price, StockQuantity)
-- VALUES (@Name, @Description, @Price, @StockQuantity)
-- RETURNING ProductId;
--
-- Then use RETURNING ProductId value for subsequent statements:
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
--
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with Variable Declarations
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Changes Required: GETDATE() → CURRENT_TIMESTAMP, variable syntax adjustments
-- Note: For use in C# code, this needs to be split into separate commands managed by Npgsql transaction
-- ========================================================================================================
DO $$
DECLARE OldPrice DECIMAL(18,2);
DECLARE OldStock INT;
BEGIN
    SELECT Price, StockQuantity INTO OldPrice, OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Alternative conversion for ADO.NET (managed transaction approach without DO block):
-- Note: Transaction will be managed by NpgsqlTransaction in C# code
-- First query to get old values:
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;
-- (Store results in C# variables)
--
-- UPDATE Products
-- SET 
--     Name = @Name,
--     Description = @Description,
--     Price = @Price,
--     StockQuantity = @StockQuantity,
--     ModifiedDate = CURRENT_TIMESTAMP
-- WHERE ProductId = @ProductId;
--
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);
--
-- UPDATE ProductStats
-- SET 
--     AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with Conditional Logic
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Changes Required: GETDATE() → CURRENT_TIMESTAMP, variable syntax adjustments
-- Note: For use in C# code, this needs to be split into separate commands managed by Npgsql transaction
-- ========================================================================================================
DO $$
DECLARE OldPrice DECIMAL(18,2);
DECLARE OldStock INT;
BEGIN
    SELECT Price, StockQuantity INTO OldPrice, OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP);
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Alternative conversion for ADO.NET (managed transaction approach without DO block):
-- Note: Transaction will be managed by NpgsqlTransaction in C# code
-- First query to get old values:
-- SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;
-- (Store results in C# variables)
--
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);
--
-- DELETE FROM Products 
-- WHERE ProductId = @ProductId;
--
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts - 1,
--     AveragePrice = CASE 
--         WHEN TotalProducts > 1 
--         THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
--         ELSE 0
--     END,
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK Window Functions
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Changes Required: NONE - PostgreSQL compatible as-is
-- ========================================================================================================
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

-- ========================================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Window Functions and Conditional Categorization
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- DMS Status: ERROR - Metadata model creation failed
-- Changes Required: NONE - PostgreSQL compatible as-is
-- ========================================================================================================
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

-- ========================================================================================================
-- CONVERSION SUMMARY
-- ========================================================================================================
-- Total Statements Converted: 7
-- DMS Tool Successful: 0
-- Manual Conversions: 7
--
-- Key PostgreSQL Function Conversions Applied:
-- - SCOPE_IDENTITY() → LASTVAL() or RETURNING clause (Statement 3)
-- - GETDATE() → CURRENT_TIMESTAMP (Statements 3, 4, 5)
--
-- PostgreSQL-Compatible Without Changes:
-- - CTEs (WITH clauses) - All 6 statements using CTEs
-- - Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX OVER) - Statements 1, 2, 6, 7
-- - CASE expressions - All statements
-- - ROUND function - Statements 1, 2, 7
-- - Transactions (BEGIN/COMMIT) - Statements 3, 4, 5
--
-- Schema Object Names: No changes - Products, ProductHistory, ProductStats remain unchanged
--
-- Implementation Notes for ADO.NET:
-- - Statements 1, 2, 6, 7: Can be used directly in C# with NpgsqlCommand
-- - Statements 3, 4, 5: Multi-statement transactions should be split into individual SQL commands
--   and managed using NpgsqlTransaction in C# code for better control and parameter binding
-- - Use RETURNING clause in INSERT for retrieving auto-generated IDs instead of LASTVAL()
-- - All parameter names (@ProductId, @Name, etc.) are supported by Npgsql
-- ========================================================================================================
