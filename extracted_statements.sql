/*******************************************************************************
 * EXTRACTED SQL STATEMENTS CATALOG
 * Microsoft SQL Server to PostgreSQL Migration
 * .NET ADO Application - AdoCore Project
 * 
 * This catalog contains all SQL statements extracted from the codebase for
 * conversion through the DMS MCP tool (dms-mcp____statement_conversion_tool).
 * 
 * Total Statements: 7
 * Source File: DataAccess/ProductRepository.cs
 * Date: Migration Phase - Statement Extraction
 ******************************************************************************/

-------------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync
-------------------------------------------------------------------------------
-- Statement ID: 1
-- Location: DataAccess/ProductRepository.cs, lines 38-74, method GetAllProductsAsync
-- Statement Type: SELECT with CTE and window functions
-- Parameters: None
-- Tables Used: Products
-- SQL Server-Specific Features:
--   - Common Table Expression (CTE)
--   - Window functions: AVG() OVER(), COUNT() OVER()
--   - CASE expressions
--   - ROUND function
--   - INNER JOIN with CTE
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync
-------------------------------------------------------------------------------
-- Statement ID: 2
-- Location: DataAccess/ProductRepository.cs, lines 76-126, method GetProductByIdAsync
-- Statement Type: SELECT with CTE and LAG window function
-- Parameters: @ProductId (INT)
-- Tables Used: Products
-- SQL Server-Specific Features:
--   - Common Table Expression (CTE)
--   - LAG() window function with ORDER BY
--   - LEFT JOIN
--   - CASE expression with NULL handling
--   - ROUND function
--   - Parameter syntax: @ProductId
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync
-------------------------------------------------------------------------------
-- Statement ID: 3
-- Location: DataAccess/ProductRepository.cs, lines 128-170, method InsertProductAsync
-- Statement Type: TRANSACTION BLOCK - Multi-statement INSERT with history logging
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Tables Used: Products, ProductHistory, ProductStats
-- SQL Server-Specific Features:
--   - DECLARE variable statement
--   - BEGIN TRANSACTION / COMMIT
--   - SCOPE_IDENTITY() function for retrieving last inserted identity
--   - GETDATE() function (multiple occurrences)
--   - Multi-statement transaction with INSERT and UPDATE operations
--   - Variable assignment: SET @NewProductId
--   - SELECT to return scalar value
--   - Parameter syntax: @Name, @Description, @Price, @StockQuantity
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync
-------------------------------------------------------------------------------
-- Statement ID: 4
-- Location: DataAccess/ProductRepository.cs, lines 172-211, method UpdateProductAsync
-- Statement Type: TRANSACTION BLOCK - Multi-statement UPDATE with history logging
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Tables Used: Products, ProductHistory, ProductStats
-- SQL Server-Specific Features:
--   - DECLARE variable statements (multiple)
--   - BEGIN TRANSACTION / COMMIT
--   - GETDATE() function (multiple occurrences)
--   - Multi-statement SELECT for variable assignment
--   - Complex UPDATE with computed expressions
--   - Multi-table DML within transaction
--   - Parameter syntax: @ProductId, @Name, @Description, @Price, @StockQuantity
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync
-------------------------------------------------------------------------------
-- Statement ID: 5
-- Location: DataAccess/ProductRepository.cs, lines 213-250, method DeleteProductAsync
-- Statement Type: TRANSACTION BLOCK - Multi-statement DELETE with history logging
-- Parameters: @ProductId (INT)
-- Tables Used: Products, ProductHistory, ProductStats
-- SQL Server-Specific Features:
--   - DECLARE variable statements (multiple)
--   - BEGIN TRANSACTION / COMMIT
--   - GETDATE() function (multiple occurrences)
--   - Multi-statement SELECT for variable assignment
--   - DELETE with WHERE clause
--   - Complex UPDATE with CASE expression and conditional logic
--   - Multi-table DML within transaction
--   - Parameter syntax: @ProductId
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync
-------------------------------------------------------------------------------
-- Statement ID: 6
-- Location: DataAccess/ProductRepository.cs, lines 252-283, method GetProductsByPriceRangeAsync
-- Statement Type: SELECT with CTE and ranking window functions
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Tables Used: Products
-- SQL Server-Specific Features:
--   - Common Table Expression (CTE)
--   - RANK() window function with ORDER BY
--   - PERCENT_RANK() window function with ORDER BY
--   - BETWEEN operator for range filtering
--   - CASE expression
--   - Percentage calculations
--   - Parameter syntax: @MinPrice, @MaxPrice
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync
-------------------------------------------------------------------------------
-- Statement ID: 7
-- Location: DataAccess/ProductRepository.cs, lines 285-310, method GetLowStockProductsAsync
-- Statement Type: SELECT with CTE and aggregate window functions
-- Parameters: @Threshold (INT)
-- Tables Used: Products
-- SQL Server-Specific Features:
--   - Common Table Expression (CTE)
--   - Aggregate window functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE expression with computed conditions
--   - ROUND function
--   - Mathematical operations in CASE expressions
--   - Parameter syntax: @Threshold
-------------------------------------------------------------------------------

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

/*******************************************************************************
 * END OF EXTRACTED STATEMENTS CATALOG
 * 
 * Summary:
 * - Total statements extracted: 7
 * - SELECT statements: 4 (Statements 1, 2, 6, 7)
 * - TRANSACTION blocks: 3 (Statements 3, 4, 5)
 * - Statements with CTEs: 5 (Statements 1, 2, 6, 7, and implicitly in others)
 * - Statements with window functions: 5 (Statements 1, 2, 6, 7)
 * - Statements with GETDATE(): 3 (Statements 3, 4, 5)
 * - Statements with SCOPE_IDENTITY(): 1 (Statement 3)
 * - Statements with DECLARE: 3 (Statements 3, 4, 5)
 * 
 * All statements are ready for processing through the DMS MCP tool.
 ******************************************************************************/
