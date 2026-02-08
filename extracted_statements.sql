-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: ADO.NET ProductManagement Application
-- Date: 2024
-- Purpose: Complete catalog of all SQL statements for DMS tool conversion
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 40-68
-- Method: GetAllProductsAsync()
-- Statement Type: SELECT
-- Complexity Level: HIGH
-- Features: CTE (WITH clause), Window Functions (AVG OVER, COUNT OVER), CASE expressions, INNER JOIN
-- Parameters: None
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
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 85-113
-- Method: GetProductByIdAsync(int productId)
-- Statement Type: SELECT
-- Complexity Level: HIGH
-- Features: CTE (WITH clause), Window Function (LAG OVER), LEFT JOIN, CASE expressions
-- Parameters: @ProductId (INT)
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
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction with SCOPE_IDENTITY()
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 125-158
-- Method: InsertProductAsync(Product product)
-- Statement Type: TRANSACTION (INSERT)
-- Complexity Level: HIGH
-- Features: BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE(), Variable declarations
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Special Notes: Multi-statement transaction block with INSERT into multiple tables
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
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with Variable Declarations
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 167-205
-- Method: UpdateProductAsync(Product product)
-- Statement Type: TRANSACTION (UPDATE)
-- Complexity Level: HIGH
-- Features: BEGIN TRANSACTION/COMMIT, Variable declarations, GETDATE()
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Special Notes: Multi-statement transaction with UPDATE and INSERT operations
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
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with Conditional Logic
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 214-250
-- Method: DeleteProductAsync(int productId)
-- Statement Type: TRANSACTION (DELETE)
-- Complexity Level: HIGH
-- Features: BEGIN TRANSACTION/COMMIT, Variable declarations, CASE expressions, GETDATE()
-- Parameters: @ProductId (INT)
-- Special Notes: Multi-statement transaction with DELETE and conditional UPDATE logic
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
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK Window Functions
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 259-285
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Statement Type: SELECT
-- Complexity Level: HIGH
-- Features: CTE (WITH clause), Window Functions (RANK OVER, PERCENT_RANK OVER), CASE expressions, BETWEEN
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
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
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Aggregate Window Functions
-- ============================================================================
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Source Line: 294-321
-- Method: GetLowStockProductsAsync(int threshold)
-- Statement Type: SELECT
-- Complexity Level: HIGH
-- Features: CTE (WITH clause), Window Functions (AVG OVER, MIN OVER, MAX OVER), CASE expressions
-- Parameters: @Threshold (INT)
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

-- ============================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total Statements: 7
-- Statements with CTEs: 5 (Statements 1, 2, 6, 7)
-- Statements with Window Functions: 5 (Statements 1, 2, 6, 7)
-- Transaction Blocks: 3 (Statements 3, 4, 5)
-- Statements with SQL Server specific functions:
--   - SCOPE_IDENTITY(): Statement 3
--   - GETDATE(): Statements 3, 4, 5
-- ============================================================================
