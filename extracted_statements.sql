/*
================================================================================
SQL STATEMENT EXTRACTION CATALOG
Microsoft SQL Server to PostgreSQL Migration
================================================================================
Total Statements: 7
Source File: ProductRepository.cs
Extraction Date: 2026-01-04
================================================================================
*/

-- ============================================================================
-- STATEMENT ID: SQL_001
-- SOURCE FILE: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- SOURCE METHOD: GetAllProductsAsync
-- LINE RANGE: 42-68
-- STATEMENT TYPE: SELECT with CTE
-- COMPLEXITY: Medium (CTE with window functions, CASE expressions)
-- FEATURES: WITH clause, AVG() OVER(), COUNT() OVER(), INNER JOIN, CASE WHEN, ROUND(), ORDER BY with CASE
-- PARAMETERS: None
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
-- STATEMENT ID: SQL_002
-- SOURCE FILE: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- SOURCE METHOD: GetProductByIdAsync
-- LINE RANGE: 83-111
-- STATEMENT TYPE: SELECT with CTE
-- COMPLEXITY: Medium (CTE with LAG window function, LEFT JOIN, parameterized)
-- FEATURES: WITH clause, LAG() OVER(), LEFT JOIN, CASE WHEN, ROUND(), WHERE with parameter
-- PARAMETERS: @ProductId (int)
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
-- STATEMENT ID: SQL_003
-- SOURCE FILE: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- SOURCE METHOD: InsertProductAsync
-- LINE RANGE: 127-151
-- STATEMENT TYPE: INSERT with TRANSACTION
-- COMPLEXITY: High (Multi-statement transaction with SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE())
-- FEATURES: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE, COMMIT, SELECT
-- PARAMETERS: @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- MS SQL SPECIFIC: SCOPE_IDENTITY(), GETDATE()
-- ============================================================================
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

-- ============================================================================
-- STATEMENT ID: SQL_004
-- SOURCE FILE: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- SOURCE METHOD: UpdateProductAsync
-- LINE RANGE: 168-198
-- STATEMENT TYPE: UPDATE with TRANSACTION
-- COMPLEXITY: High (Multi-statement transaction with DECLARE, SELECT, UPDATE, INSERT, GETDATE())
-- FEATURES: BEGIN TRANSACTION, DECLARE, SELECT, UPDATE, INSERT, GETDATE(), COMMIT
-- PARAMETERS: @ProductId (int), @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- MS SQL SPECIFIC: GETDATE()
-- ============================================================================
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

-- ============================================================================
-- STATEMENT ID: SQL_005
-- SOURCE FILE: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- SOURCE METHOD: DeleteProductAsync
-- LINE RANGE: 215-244
-- STATEMENT TYPE: DELETE with TRANSACTION
-- COMPLEXITY: High (Multi-statement transaction with DECLARE, SELECT, INSERT, DELETE, UPDATE, GETDATE(), CASE)
-- FEATURES: BEGIN TRANSACTION, DECLARE, SELECT, INSERT, DELETE, UPDATE, CASE WHEN, GETDATE(), COMMIT
-- PARAMETERS: @ProductId (int)
-- MS SQL SPECIFIC: GETDATE()
-- ============================================================================
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

-- ============================================================================
-- STATEMENT ID: SQL_006
-- SOURCE FILE: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- SOURCE METHOD: GetProductsByPriceRangeAsync
-- LINE RANGE: 252-276
-- STATEMENT TYPE: SELECT with CTE
-- COMPLEXITY: Medium (CTE with window functions RANK and PERCENT_RANK, CASE WHEN)
-- FEATURES: WITH clause, RANK() OVER(), PERCENT_RANK() OVER(), WHERE BETWEEN, CASE WHEN, ORDER BY
-- PARAMETERS: @MinPrice (decimal), @MaxPrice (decimal)
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
-- STATEMENT ID: SQL_007
-- SOURCE FILE: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- SOURCE METHOD: GetLowStockProductsAsync
-- LINE RANGE: 291-318
-- STATEMENT TYPE: SELECT with CTE
-- COMPLEXITY: Medium (CTE with multiple window functions, CASE WHEN, ROUND())
-- FEATURES: WITH clause, AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE WHEN, ROUND(), WHERE, ORDER BY
-- PARAMETERS: @Threshold (int)
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

/*
================================================================================
EXTRACTION SUMMARY
================================================================================
Total Statements Extracted: 7

Statement Classification:
- SELECT with CTE: 4 statements (SQL_001, SQL_002, SQL_006, SQL_007)
- INSERT with Transaction: 1 statement (SQL_003)
- UPDATE with Transaction: 1 statement (SQL_004)
- DELETE with Transaction: 1 statement (SQL_005)

Complexity Distribution:
- Medium Complexity: 4 statements (window functions, CTEs)
- High Complexity: 3 statements (multi-statement transactions)

MS SQL Specific Features Requiring Conversion:
- SCOPE_IDENTITY() in SQL_003 -> requires PostgreSQL RETURNING clause or LASTVAL()
- GETDATE() in SQL_003, SQL_004, SQL_005 -> requires NOW() or CURRENT_TIMESTAMP

Parameterized Statements: 6 out of 7
- SQL_001: No parameters
- SQL_002: 1 parameter (@ProductId)
- SQL_003: 4 parameters (@Name, @Description, @Price, @StockQuantity)
- SQL_004: 5 parameters (@ProductId, @Name, @Description, @Price, @StockQuantity)
- SQL_005: 1 parameter (@ProductId)
- SQL_006: 2 parameters (@MinPrice, @MaxPrice)
- SQL_007: 1 parameter (@Threshold)

Window Functions Used:
- AVG() OVER(): SQL_001, SQL_007
- COUNT() OVER(): SQL_001
- LAG() OVER(): SQL_002
- RANK() OVER(): SQL_006
- PERCENT_RANK() OVER(): SQL_006
- MIN() OVER(): SQL_007
- MAX() OVER(): SQL_007

All statements ready for DMS MCP tool conversion.
================================================================================
*/
