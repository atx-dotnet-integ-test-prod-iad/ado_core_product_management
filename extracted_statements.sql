-- ===============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Migration: Microsoft SQL Server to PostgreSQL
-- Source: ADO.NET Application
-- Date: 2026-02-11
-- ===============================================================================
-- This catalog contains ALL SQL statements extracted from the codebase for
-- systematic processing through the DMS MCP tool. Each statement is documented
-- with its source location, method context, and transaction status.
-- ===============================================================================

-- ===============================================================================
-- STATEMENT 1: Get All Products with CTE and Window Functions
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Range: 38-70
-- Transaction Context: None (Single SELECT query)
-- Statement Type: SELECT with CTE
-- Description: Retrieves all products with price statistics using window functions
--              and categorizes products based on average price comparison
-- Parameters: None
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 2: Get Product By ID with CTE and LAG Window Function
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Range: 80-109
-- Transaction Context: None (Single SELECT query)
-- Statement Type: SELECT with CTE and window function
-- Description: Retrieves a single product by ID with historical price/stock
--              comparison using LAG window function
-- Parameters: @ProductId (int)
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 3: Insert Product with Transaction
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Range: 118-146
-- Transaction Context: BEGIN TRANSACTION...COMMIT (Multi-statement transaction)
-- Statement Type: INSERT with transaction and multiple statements
-- Description: Inserts a new product and logs the insertion with product history
--              and statistics updates in a transaction
-- Parameters: @Name (string), @Description (string), @Price (decimal), 
--             @StockQuantity (int)
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 4: Update Product with Transaction
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Range: 156-191
-- Transaction Context: BEGIN TRANSACTION...COMMIT (Multi-statement transaction)
-- Statement Type: UPDATE with transaction and multiple statements
-- Description: Updates an existing product, logs changes to history, and updates
--              statistics, all within a transaction
-- Parameters: @ProductId (int), @Name (string), @Description (string), 
--             @Price (decimal), @StockQuantity (int)
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 5: Delete Product with Transaction
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Range: 199-234
-- Transaction Context: BEGIN TRANSACTION...COMMIT (Multi-statement transaction)
-- Statement Type: DELETE with transaction and multiple statements
-- Description: Deletes a product, logs deletion to history, and updates statistics,
--              all within a transaction
-- Parameters: @ProductId (int)
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 6: Get Products By Price Range with CTE and Window Functions
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: 242-269
-- Transaction Context: None (Single SELECT query)
-- Statement Type: SELECT with CTE and window functions
-- Description: Retrieves products within a price range, ranks them by price,
--              and categorizes them into price segments
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- ===============================================================================

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

-- ===============================================================================
-- STATEMENT 7: Get Low Stock Products with CTE and Window Functions
-- ===============================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: 279-310
-- Transaction Context: None (Single SELECT query)
-- Statement Type: SELECT with CTE and window functions
-- Description: Retrieves products with low stock levels, calculates stock
--              statistics using window functions, and categorizes stock status
-- Parameters: @Threshold (int)
-- ===============================================================================

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

-- ===============================================================================
-- EXTRACTION SUMMARY
-- ===============================================================================
-- Total SQL Operations Extracted: 7
-- 
-- Breakdown by Type:
--   - SELECT queries with CTE: 4 (Statements 1, 2, 6, 7)
--   - INSERT with transaction: 1 (Statement 3)
--   - UPDATE with transaction: 1 (Statement 4)
--   - DELETE with transaction: 1 (Statement 5)
--
-- Features Used:
--   - Common Table Expressions (CTE): 7 statements
--   - Window Functions (OVER, AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX): 7 statements
--   - Transactions (BEGIN/COMMIT): 3 statements
--   - SCOPE_IDENTITY(): 1 statement
--   - GETDATE(): 5 statements
--   - Parameterized queries: 6 statements
--
-- Next Steps:
--   1. Process each statement through DMS MCP tool (dms-mcp____statement_conversion_tool)
--   2. Validate each converted statement pair with SQL Equivalency tool
--   3. Document conversions in converted_statements.sql
--   4. Generate sql_equivalency_validation_report.json
-- ===============================================================================
