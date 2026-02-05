-- ========================================================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- ========================================================================================================
-- Purpose: Comprehensive catalog of all SQL statements extracted from the ADO.NET application
--          for conversion from Microsoft SQL Server to PostgreSQL syntax
-- Source Project: AdoCore - Product Management System
-- Total Statements: 7
-- Target Schema: Products, ProductHistory, ProductStats tables
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT #1: GetAllProductsAsync - Complex CTE with Window Functions
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Range: 38-67
-- Statement Type: SELECT with CTE
-- Parameters: None
-- SQL Server Features:
--   - Common Table Expression (CTE): ProductStats
--   - Window Functions: AVG() OVER(), COUNT(*) OVER()
--   - CASE expressions for conditional logic
--   - ROUND() function
--   - INNER JOIN
-- Transaction: No
-- Returns: List<Product>
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
-- STATEMENT #2: GetProductByIdAsync - CTE with LAG Window Function
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Range: 73-104
-- Statement Type: SELECT with CTE and parameterized query
-- Parameters:
--   - @ProductId (INT) - The product identifier to retrieve
-- SQL Server Features:
--   - Common Table Expression (CTE): ProductHistory
--   - Window Function: LAG() OVER (ORDER BY ModifiedDate)
--   - CASE expressions with NULL handling
--   - ROUND() function
--   - LEFT JOIN
-- Transaction: No
-- Returns: Product or null
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
-- STATEMENT #3: InsertProductAsync - Transaction Block with SCOPE_IDENTITY
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Range: 110-136
-- Statement Type: Multi-statement transaction block (INSERT, UPDATE)
-- Parameters:
--   - @Name (VARCHAR) - Product name
--   - @Description (VARCHAR) - Product description (nullable)
--   - @Price (DECIMAL) - Product price
--   - @StockQuantity (INT) - Product stock quantity
-- SQL Server Features:
--   - DECLARE statement for variables (@NewProductId)
--   - BEGIN TRANSACTION / COMMIT
--   - SCOPE_IDENTITY() - Returns last inserted identity value
--   - GETDATE() - Returns current date/time (3 occurrences)
--   - INSERT statements (2)
--   - UPDATE statement
--   - SELECT to return new ID
-- Transaction: Yes
-- Returns: INT (new ProductId)
-- Critical Conversion Note: SCOPE_IDENTITY() must be converted to PostgreSQL RETURNING clause or sequence
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
-- STATEMENT #4: UpdateProductAsync - Transaction Block with Variable Declarations
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Range: 144-174
-- Statement Type: Multi-statement transaction block (SELECT, UPDATE, INSERT)
-- Parameters:
--   - @ProductId (INT) - Product identifier to update
--   - @Name (VARCHAR) - Updated product name
--   - @Description (VARCHAR) - Updated product description (nullable)
--   - @Price (DECIMAL) - Updated product price
--   - @StockQuantity (INT) - Updated stock quantity
-- SQL Server Features:
--   - DECLARE statements for variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT
--   - GETDATE() - Returns current date/time (3 occurrences)
--   - SELECT to retrieve old values
--   - UPDATE statement (2)
--   - INSERT statement
-- Transaction: Yes
-- Returns: void
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
-- STATEMENT #5: DeleteProductAsync - Transaction Block with Conditional CASE Expression
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Range: 180-215
-- Statement Type: Multi-statement transaction block (SELECT, INSERT, DELETE, UPDATE)
-- Parameters:
--   - @ProductId (INT) - Product identifier to delete
-- SQL Server Features:
--   - DECLARE statements for variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT
--   - GETDATE() - Returns current date/time (2 occurrences)
--   - SELECT to retrieve values before deletion
--   - INSERT statement
--   - DELETE statement
--   - UPDATE statement with CASE expression for conditional calculation
-- Transaction: Yes
-- Returns: void
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
-- STATEMENT #6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK Window Functions
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: 221-250
-- Statement Type: SELECT with CTE and parameterized query
-- Parameters:
--   - @MinPrice (DECIMAL) - Minimum price for range filter
--   - @MaxPrice (DECIMAL) - Maximum price for range filter
-- SQL Server Features:
--   - Common Table Expression (CTE): RankedProducts
--   - Window Functions: RANK() OVER (ORDER BY), PERCENT_RANK() OVER (ORDER BY)
--   - BETWEEN clause for range filtering
--   - CASE expression for categorization
-- Transaction: No
-- Returns: List<Product>
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
-- STATEMENT #7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ========================================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: 256-283
-- Statement Type: SELECT with CTE and parameterized query
-- Parameters:
--   - @Threshold (INT) - Stock quantity threshold for filtering
-- SQL Server Features:
--   - Common Table Expression (CTE): StockAnalysis
--   - Window Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
--   - CASE expression for status categorization
--   - ROUND() function
--   - WHERE clause with threshold comparison
-- Transaction: No
-- Returns: List<Product>
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
-- END OF SQL STATEMENT EXTRACTION CATALOG
-- ========================================================================================================
-- Total Statements Cataloged: 7
-- Next Step: Convert each statement using DMS MCP tool (dms-mcp____statement_conversion_tool)
-- ========================================================================================================
