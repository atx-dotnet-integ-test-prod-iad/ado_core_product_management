-- ==================================================================================
-- EXTRACTED SQL STATEMENTS FROM MICROSOFT SQL SERVER ADO.NET APPLICATION
-- ==================================================================================
-- Total Statements: 7
-- Source File: DataAccess/ProductRepository.cs
-- Extraction Date: 2026-01-31
-- Purpose: Catalog all SQL statements for conversion to PostgreSQL
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Range: 40-68
-- Statement Type: SELECT with CTE
-- Parameters: None
-- Features Used:
--   - Common Table Expression (CTE)
--   - Window Functions: AVG() OVER(), COUNT(*) OVER()
--   - INNER JOIN
--   - CASE expressions (multiple)
--   - ROUND function
--   - ORDER BY with CASE
-- Transaction Context: None (single statement)
-- ==================================================================================

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
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Range: 84-110
-- Statement Type: SELECT with CTE
-- Parameters:
--   @ProductId (INT) - Product identifier to retrieve
-- Features Used:
--   - Common Table Expression (CTE)
--   - LAG() window function (2 instances)
--   - LEFT JOIN
--   - CASE expression with calculation
--   - ROUND function
--   - Parameterized query
-- Transaction Context: None (single statement)
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Range: 124-148
-- Statement Type: INSERT with Transaction
-- Parameters:
--   @Name (NVARCHAR) - Product name
--   @Description (NVARCHAR) - Product description
--   @Price (DECIMAL) - Product price
--   @StockQuantity (INT) - Initial stock quantity
-- Features Used:
--   - DECLARE variable (@NewProductId)
--   - BEGIN TRANSACTION / COMMIT
--   - INSERT statement (2 instances)
--   - SCOPE_IDENTITY() function (SQL Server specific)
--   - GETDATE() function (3 instances)
--   - UPDATE statement
--   - SELECT to return new ID
-- Transaction Context: Explicit transaction wrapping INSERT, logging, and stats update
-- Critical Conversion Note: SCOPE_IDENTITY() must be converted to PostgreSQL RETURNING clause
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction Block with DECLARE
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Range: 162-192
-- Statement Type: UPDATE with Transaction
-- Parameters:
--   @ProductId (INT) - Product identifier to update
--   @Name (NVARCHAR) - Updated product name
--   @Description (NVARCHAR) - Updated product description
--   @Price (DECIMAL) - Updated product price
--   @StockQuantity (INT) - Updated stock quantity
-- Features Used:
--   - DECLARE variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT
--   - SELECT to capture old values
--   - UPDATE statement (2 instances)
--   - INSERT into history table
--   - GETDATE() function (3 instances)
-- Transaction Context: Explicit transaction wrapping value capture, update, logging, and stats
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction Block with DELETE
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Range: 206-234
-- Statement Type: DELETE with Transaction
-- Parameters:
--   @ProductId (INT) - Product identifier to delete
-- Features Used:
--   - DECLARE variables (@OldPrice, @OldStock)
--   - BEGIN TRANSACTION / COMMIT
--   - SELECT to capture values before deletion
--   - INSERT into history table
--   - DELETE statement
--   - UPDATE statement with CASE expression
--   - GETDATE() function (2 instances)
-- Transaction Context: Explicit transaction wrapping value capture, logging, deletion, and stats
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - SELECT with RANK and PERCENT_RANK
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: 248-272
-- Statement Type: SELECT with CTE
-- Parameters:
--   @MinPrice (DECIMAL) - Minimum price in range
--   @MaxPrice (DECIMAL) - Maximum price in range
-- Features Used:
--   - Common Table Expression (CTE)
--   - RANK() window function
--   - PERCENT_RANK() window function
--   - BETWEEN operator
--   - CASE expression
--   - ORDER BY
-- Transaction Context: None (single statement)
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - SELECT with Multiple Window Functions
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Range: 286-312
-- Statement Type: SELECT with CTE
-- Parameters:
--   @Threshold (INT) - Stock quantity threshold for filtering
-- Features Used:
--   - Common Table Expression (CTE)
--   - AVG() window function
--   - MIN() window function
--   - MAX() window function
--   - CASE expression
--   - ROUND function
--   - WHERE clause filtering
--   - ORDER BY
-- Transaction Context: None (single statement)
-- ==================================================================================

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

-- ==================================================================================
-- END OF EXTRACTED STATEMENTS
-- ==================================================================================
-- Summary:
-- - Total Statements: 7
-- - SELECT Queries: 4 (Statements 1, 2, 6, 7)
-- - INSERT Transactions: 1 (Statement 3)
-- - UPDATE Transactions: 1 (Statement 4)
-- - DELETE Transactions: 1 (Statement 5)
-- - Statements with CTEs: 5 (Statements 1, 2, 6, 7, plus 2 in transaction blocks)
-- - Statements with Window Functions: 5
-- - Statements with Parameters: 5 (Statements 2, 3, 4, 5, 6, 7)
-- - Statements in Explicit Transactions: 3 (Statements 3, 4, 5)
--
-- Key SQL Server Features Requiring Conversion:
-- - SCOPE_IDENTITY() → PostgreSQL RETURNING clause
-- - GETDATE() → CURRENT_TIMESTAMP or NOW()
-- - BEGIN TRANSACTION/COMMIT → PostgreSQL transaction syntax
-- - DECLARE variable syntax → PostgreSQL variable syntax
-- - Window functions syntax (verify PostgreSQL compatibility)
-- - CTE syntax (generally compatible but verify)
-- ==================================================================================
