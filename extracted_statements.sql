/*
========================================================================================================
EXTRACTED SQL STATEMENTS CATALOG
========================================================================================================
Project: AdoCore - ADO.NET Product Management System
Source File: DataAccess/ProductRepository.cs
Database: Microsoft SQL Server
Purpose: Catalog of all SQL statements extracted for migration to PostgreSQL

This file contains all SQL statements from the codebase that need to be converted using the DMS MCP tool.
Each statement is documented with:
- Statement ID (for tracking)
- Source method name and location
- Statement type (Query, Transaction, etc.)
- Original SQL Server syntax
- Parameters used
- Context and business logic description

Total Statements: 7
========================================================================================================
*/

-- ========================================================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ========================================================================================================
-- Source: ProductRepository.cs, Method: GetAllProductsAsync
-- Type: SELECT Query with CTE
-- Purpose: Retrieve all products with price category analysis using window functions
-- Parameters: None
-- Features: CTE (ProductStats), Window Functions (AVG OVER, COUNT OVER), CASE expressions
-- Notes: Uses window functions to calculate average price and total product count for comparison
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
-- Source: ProductRepository.cs, Method: GetProductByIdAsync
-- Type: SELECT Query with CTE
-- Purpose: Retrieve single product by ID with historical price/stock comparison using LAG
-- Parameters: @ProductId (int)
-- Features: CTE (ProductHistory), LAG window function, LEFT JOIN, CASE expression
-- Notes: Uses LAG to get previous price and stock values for trend analysis
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
-- Source: ProductRepository.cs, Method: InsertProductAsync
-- Type: Multi-statement Transaction (INSERT with logging and statistics update)
-- Purpose: Insert new product with history logging and statistics update, return new ID
-- Parameters: @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- Features: Transaction, SCOPE_IDENTITY(), GETDATE(), Variable declaration, Multiple INSERT/UPDATE
-- Notes: Returns the newly inserted ProductId using SCOPE_IDENTITY()
-- Critical: SCOPE_IDENTITY() must be replaced with PostgreSQL RETURNING clause
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with History Logging
-- ========================================================================================================
-- Source: ProductRepository.cs, Method: UpdateProductAsync
-- Type: Multi-statement Transaction (UPDATE with history logging and statistics update)
-- Purpose: Update existing product with history logging and statistics recalculation
-- Parameters: @ProductId (int), @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- Features: Transaction, Variable declaration, SELECT for old values, UPDATE, INSERT for logging
-- Notes: Captures old values before update for audit trail in ProductHistory table
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with Statistics Update
-- ========================================================================================================
-- Source: ProductRepository.cs, Method: DeleteProductAsync
-- Type: Multi-statement Transaction (DELETE with history logging and statistics update)
-- Purpose: Delete product with history logging and statistics recalculation
-- Parameters: @ProductId (int)
-- Features: Transaction, Variable declaration, SELECT for old values, INSERT for logging, DELETE, conditional UPDATE
-- Notes: Logs deletion before removing record, handles edge case when TotalProducts reaches 1
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- ========================================================================================================
-- Source: ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Type: SELECT Query with CTE
-- Purpose: Retrieve products within price range with ranking and percentile analysis
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Features: CTE (RankedProducts), RANK() window function, PERCENT_RANK() window function, BETWEEN, CASE
-- Notes: Uses RANK and PERCENT_RANK for price segmentation (Budget/Mid-Range/Premium)
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Window Functions
-- ========================================================================================================
-- Source: ProductRepository.cs, Method: GetLowStockProductsAsync
-- Type: SELECT Query with CTE
-- Purpose: Retrieve low stock products with stock level analysis using window functions
-- Parameters: @Threshold (int)
-- Features: CTE (StockAnalysis), Multiple window functions (AVG, MIN, MAX OVER), CASE, arithmetic operations
-- Notes: Uses window functions to calculate stock statistics and categorize stock status
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

/*
========================================================================================================
END OF EXTRACTED STATEMENTS CATALOG
========================================================================================================
Summary:
- Total Statements: 7
- Simple SELECT Queries with CTE: 4 (Statements 1, 2, 6, 7)
- Multi-statement Transactions: 3 (Statements 3, 4, 5)
- Window Functions Used: AVG OVER, COUNT OVER, LAG OVER, RANK OVER, PERCENT_RANK OVER, MIN OVER, MAX OVER
- Special Features: SCOPE_IDENTITY, GETDATE, Transactions, CTEs, CASE expressions

Next Steps:
1. Convert each statement using DMS MCP tool (dms-mcp____statement_conversion_tool)
2. Document converted statements in converted_statements.sql
3. Validate equivalency using SQL Equivalency tool (sql-equivalency___validate_sql_equivalence)
4. Re-integrate converted statements back into ProductRepository.cs
========================================================================================================
*/
