-- ========================================
-- SQL STATEMENTS EXTRACTED FROM CODEBASE
-- Microsoft SQL Server to PostgreSQL Migration
-- ========================================
-- Total Statements: 7
-- Extraction Date: Phase 1 - SQL Extraction
-- Source: AdoCore .NET Application
-- ========================================

-- ========================================
-- STATEMENT 1: GetAllProductsAsync
-- ========================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Context: ~38-70
-- Method: GetAllProductsAsync()
-- Query Type: SELECT with CTE and Window Functions
-- Features: CTE, AVG() OVER(), COUNT(*) OVER(), INNER JOIN, CASE expressions
-- Parameters: None
-- ========================================
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

-- ========================================
-- STATEMENT 2: GetProductByIdAsync
-- ========================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Context: ~75-105
-- Method: GetProductByIdAsync(int productId)
-- Query Type: SELECT with CTE and LAG Window Function
-- Features: CTE, LAG() OVER(), LEFT JOIN, parameterized query
-- Parameters: @ProductId (int)
-- ========================================
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

-- ========================================
-- STATEMENT 3: InsertProductAsync
-- ========================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Context: ~110-146
-- Method: InsertProductAsync(Product product)
-- Query Type: INSERT with Transaction, Multiple DML operations
-- Features: Transaction block, DECLARE variable, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE(), multiple INSERT/UPDATE
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ========================================
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

-- ========================================
-- STATEMENT 4: UpdateProductAsync
-- ========================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Context: ~151-190
-- Method: UpdateProductAsync(Product product)
-- Query Type: UPDATE with Transaction, Multiple DML operations
-- Features: Transaction block, DECLARE variables, BEGIN TRANSACTION/COMMIT, GETDATE(), SELECT/UPDATE/INSERT
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ========================================
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

-- ========================================
-- STATEMENT 5: DeleteProductAsync
-- ========================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Context: ~195-234
-- Method: DeleteProductAsync(int productId)
-- Query Type: DELETE with Transaction, Multiple DML operations
-- Features: Transaction block, DECLARE variables, BEGIN TRANSACTION/COMMIT, GETDATE(), SELECT/INSERT/DELETE/UPDATE, CASE expression
-- Parameters: @ProductId
-- ========================================
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

-- ========================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ========================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Context: ~239-268
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Query Type: SELECT with CTE and Window Functions (RANK, PERCENT_RANK)
-- Features: CTE, RANK() OVER(), PERCENT_RANK() OVER(), BETWEEN, CASE expression
-- Parameters: @MinPrice, @MaxPrice
-- ========================================
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

-- ========================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ========================================
-- Source File: DataAccess/ProductRepository.cs
-- Line Context: ~273-302
-- Method: GetLowStockProductsAsync(int threshold)
-- Query Type: SELECT with CTE and Multiple Window Functions
-- Features: CTE, AVG() OVER(), MIN() OVER(), MAX() OVER(), CASE expression, ROUND()
-- Parameters: @Threshold
-- ========================================
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

-- ========================================
-- EXTRACTION SUMMARY
-- ========================================
-- Total SQL Statements Extracted: 7
-- Complex Features Found:
--   - Common Table Expressions (CTEs): 5
--   - Window Functions (LAG, RANK, PERCENT_RANK, AVG OVER, COUNT OVER, MIN OVER, MAX OVER): 7
--   - Transaction Blocks (BEGIN TRANSACTION/COMMIT): 3
--   - SCOPE_IDENTITY() usage: 1
--   - GETDATE() usage: 6
--   - Parameterized Queries: 6
--
-- Files Scanned:
--   - DataAccess/ProductRepository.cs: 7 SQL statements found
--   - Business/ProductService.cs: No SQL statements (business logic only)
--   - CLI/CommandLineInterface.cs: No SQL statements (uses service layer)
--   - CLI/InteractiveMenu.cs: No SQL statements (uses service layer)
--
-- Next Step: Convert each statement using DMS MCP Tool
-- ========================================
