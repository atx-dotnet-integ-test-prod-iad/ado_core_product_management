/*
================================================================================
SQL Statement Extraction Catalog
Microsoft SQL Server to PostgreSQL Migration
Source: AdoCore Application - ProductRepository.cs
Extraction Date: 2026-01-06
Total Statements: 7
================================================================================
*/

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 38-64
-- Method: GetAllProductsAsync()
-- Return Type: Task<List<Product>>
-- Parameters: None
-- Transaction Scope: No
-- Statement Type: SELECT with CTE, Window Functions, CASE Expressions
-- Description: Retrieves all products with price analysis using window functions
--              to calculate average price and categorize products as Above/Below/Average
-- Key SQL Features:
--   - CTE (ProductStats)
--   - Window Functions: AVG() OVER(), COUNT() OVER()
--   - CASE expressions for categorization
--   - Complex ORDER BY with CASE
--   - ROUND function
-- Schema Objects Referenced: Products table
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
-- STATEMENT 2: GetProductByIdAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 79-103
-- Method: GetProductByIdAsync(int productId)
-- Return Type: Task<Product>
-- Parameters:
--   @ProductId (INT) - Product identifier to retrieve
-- Transaction Scope: No
-- Statement Type: SELECT with CTE, Window Functions, CASE Expressions
-- Description: Retrieves single product by ID with historical price/stock comparison
--              using LAG window function to access previous values
-- Key SQL Features:
--   - CTE (ProductHistory)
--   - Window Functions: LAG() OVER (ORDER BY)
--   - CASE expression for null handling
--   - LEFT JOIN for optional history
--   - Parameterized query with @ProductId
--   - ROUND function for percentage calculation
-- Schema Objects Referenced: Products table
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
-- STATEMENT 3: InsertProductAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 118-146
-- Method: InsertProductAsync(Product product)
-- Return Type: Task<int>
-- Parameters:
--   @Name (NVARCHAR) - Product name
--   @Description (NVARCHAR) - Product description (nullable)
--   @Price (DECIMAL(18,2)) - Product price
--   @StockQuantity (INT) - Initial stock quantity
-- Transaction Scope: Yes (BEGIN TRANSACTION...COMMIT)
-- Statement Type: INSERT with Transaction, Variable Declaration, SCOPE_IDENTITY
-- Description: Inserts new product with transaction that also logs history and updates stats
-- Key SQL Features:
--   - BEGIN TRANSACTION...COMMIT
--   - DECLARE variable (@NewProductId)
--   - INSERT statement
--   - SCOPE_IDENTITY() for getting inserted ID
--   - GETDATE() function (3 occurrences)
--   - UPDATE statement within transaction
--   - Multiple INSERTs in single transaction
-- Schema Objects Referenced: Products, ProductHistory, ProductStats tables
-- CRITICAL: SCOPE_IDENTITY() must be converted to PostgreSQL RETURNING clause
-- CRITICAL: GETDATE() must be converted to CURRENT_TIMESTAMP or NOW()
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
-- STATEMENT 4: UpdateProductAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 163-196
-- Method: UpdateProductAsync(Product product)
-- Return Type: Task (void)
-- Parameters:
--   @ProductId (INT) - Product identifier to update
--   @Name (NVARCHAR) - New product name
--   @Description (NVARCHAR) - New product description (nullable)
--   @Price (DECIMAL(18,2)) - New product price
--   @StockQuantity (INT) - New stock quantity
-- Transaction Scope: Yes (BEGIN TRANSACTION...COMMIT)
-- Statement Type: UPDATE with Transaction, Variable Declaration
-- Description: Updates product with transaction that also logs changes and updates stats
-- Key SQL Features:
--   - BEGIN TRANSACTION...COMMIT
--   - DECLARE variables (@OldPrice, @OldStock)
--   - SELECT for storing old values
--   - UPDATE statement (2 occurrences)
--   - INSERT for history logging
--   - GETDATE() function (3 occurrences)
-- Schema Objects Referenced: Products, ProductHistory, ProductStats tables
-- CRITICAL: GETDATE() must be converted to CURRENT_TIMESTAMP or NOW()
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
-- STATEMENT 5: DeleteProductAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 208-240
-- Method: DeleteProductAsync(int productId)
-- Return Type: Task (void)
-- Parameters:
--   @ProductId (INT) - Product identifier to delete
-- Transaction Scope: Yes (BEGIN TRANSACTION...COMMIT)
-- Statement Type: DELETE with Transaction, Variable Declaration, CASE Expression
-- Description: Deletes product with transaction that logs deletion and updates stats
-- Key SQL Features:
--   - BEGIN TRANSACTION...COMMIT
--   - DECLARE variables (@OldPrice, @OldStock)
--   - SELECT for storing values before deletion
--   - INSERT for history logging
--   - DELETE statement
--   - UPDATE with CASE expression for conditional logic
--   - GETDATE() function (2 occurrences)
-- Schema Objects Referenced: Products, ProductHistory, ProductStats tables
-- CRITICAL: GETDATE() must be converted to CURRENT_TIMESTAMP or NOW()
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
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 254-282
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Return Type: Task<List<Product>>
-- Parameters:
--   @MinPrice (DECIMAL(18,2)) - Minimum price threshold
--   @MaxPrice (DECIMAL(18,2)) - Maximum price threshold
-- Transaction Scope: No
-- Statement Type: SELECT with CTE, Window Functions (RANK, PERCENT_RANK), CASE Expression
-- Description: Retrieves products within price range with ranking and percentile analysis
-- Key SQL Features:
--   - CTE (RankedProducts)
--   - Window Functions: RANK() OVER (ORDER BY), PERCENT_RANK() OVER (ORDER BY)
--   - BETWEEN clause for range filtering
--   - CASE expression for segmentation
--   - Parameterized query with @MinPrice, @MaxPrice
-- Schema Objects Referenced: Products table
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
-- STATEMENT 7: GetLowStockProductsAsync
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 296-326
-- Method: GetLowStockProductsAsync(int threshold)
-- Return Type: Task<List<Product>>
-- Parameters:
--   @Threshold (INT) - Stock quantity threshold for low stock items
-- Transaction Scope: No
-- Statement Type: SELECT with CTE, Window Functions (AVG, MIN, MAX), CASE Expression
-- Description: Retrieves low stock products with stock analysis using window functions
-- Key SQL Features:
--   - CTE (StockAnalysis)
--   - Window Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE expression for stock status categorization
--   - ROUND function for percentage calculation
--   - WHERE clause filtering
--   - Parameterized query with @Threshold
-- Schema Objects Referenced: Products table
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
Total SQL Statements Extracted: 7

Statement Distribution by Type:
- SELECT Queries: 4 (Statements 1, 2, 6, 7)
- INSERT Transaction Blocks: 1 (Statement 3)
- UPDATE Transaction Blocks: 1 (Statement 4)
- DELETE Transaction Blocks: 1 (Statement 5)

SQL Features Requiring Conversion:
- SCOPE_IDENTITY(): 1 occurrence (Statement 3) → Must convert to RETURNING clause
- GETDATE(): 8 occurrences (Statements 3, 4, 5) → Must convert to CURRENT_TIMESTAMP/NOW()
- BEGIN TRANSACTION/COMMIT: 4 occurrences (Statements 3, 4, 5) → Check PostgreSQL syntax
- Window Functions: 13 occurrences (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX)
- CTEs (Common Table Expressions): 7 occurrences
- CASE Expressions: 11 occurrences
- Variable Declarations (DECLARE/SET): 3 statements (Statements 3, 4, 5)

Schema Objects Referenced:
- Products: All 7 statements
- ProductHistory: Statements 3, 4, 5
- ProductStats: Statements 3, 4, 5

Parameter Bindings:
- @ProductId: Statements 2, 4, 5
- @Name: Statements 3, 4
- @Description: Statements 3, 4
- @Price: Statements 3, 4
- @StockQuantity: Statements 3, 4
- @MinPrice, @MaxPrice: Statement 6
- @Threshold: Statement 7

All statements ready for DMS MCP tool conversion.
================================================================================
*/
