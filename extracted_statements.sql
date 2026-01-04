-- ====================================================================
-- EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
-- SQL Server to PostgreSQL Migration - Statement Catalog
-- ====================================================================
-- Total Statements Extracted: 7
-- Source File: DataAccess/ProductRepository.cs
-- Extraction Date: 2026-01-04
-- ====================================================================

-- ====================================================================
-- STATEMENT 1: GetAllProductsAsync
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync
-- Line Numbers: 38-69
-- Statement Type: SELECT with CTE, Window Functions, CASE expressions
-- Parameters: None
-- Description: Retrieves all products with price category analysis using window functions
-- ====================================================================
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
    p.Name
GO

-- ====================================================================
-- STATEMENT 2: GetProductByIdAsync
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync
-- Line Numbers: 84-107
-- Statement Type: SELECT with CTE, LAG Window Function, CASE expression
-- Parameters: @ProductId (INT)
-- Description: Retrieves product by ID with price change analysis using LAG window function
-- ====================================================================
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
WHERE p.ProductId = @ProductId
GO

-- ====================================================================
-- STATEMENT 3: InsertProductAsync
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync
-- Line Numbers: 123-149
-- Statement Type: Multi-statement Transaction Block (INSERT operations)
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- SQL Server Specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
-- Description: Inserts new product with history logging and statistics update in a transaction
-- ====================================================================
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
GO

-- ====================================================================
-- STATEMENT 4: UpdateProductAsync
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync
-- Line Numbers: 161-194
-- Statement Type: Multi-statement Transaction Block (UPDATE with variable declarations)
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- SQL Server Specific: DECLARE, SET, GETDATE(), BEGIN TRANSACTION/COMMIT
-- Description: Updates product with history logging and statistics update in a transaction
-- ====================================================================
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
GO

-- ====================================================================
-- STATEMENT 5: DeleteProductAsync
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync
-- Line Numbers: 206-239
-- Statement Type: Multi-statement Transaction Block (DELETE with history logging)
-- Parameters: @ProductId (INT)
-- SQL Server Specific: DECLARE, GETDATE(), BEGIN TRANSACTION/COMMIT
-- Description: Deletes product with history logging and statistics update in a transaction
-- ====================================================================
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
GO

-- ====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync
-- Line Numbers: 251-274
-- Statement Type: SELECT with CTE, RANK and PERCENT_RANK Window Functions
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products within price range with ranking and percentile analysis
-- ====================================================================
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
ORDER BY rp.PriceRank
GO

-- ====================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync
-- Line Numbers: 286-313
-- Statement Type: SELECT with CTE, Multiple Window Functions (AVG, MIN, MAX), CASE expression
-- Parameters: @Threshold (INT)
-- Description: Retrieves low stock products with stock level analysis using window functions
-- ====================================================================
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
ORDER BY StockQuantity
GO

-- ====================================================================
-- END OF EXTRACTED STATEMENTS
-- ====================================================================
-- Summary:
-- - Total Statements: 7
-- - Simple SELECT queries: 4 (Statements 1, 2, 6, 7)
-- - Multi-statement Transaction blocks: 3 (Statements 3, 4, 5)
-- - CTEs with Window Functions: 5 (Statements 1, 2, 6, 7 have AVG/LAG/RANK/PERCENT_RANK)
-- - SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE() (in Statements 3, 4, 5)
-- - Transaction Syntax: BEGIN TRANSACTION/COMMIT (in Statements 3, 4, 5)
-- ====================================================================
