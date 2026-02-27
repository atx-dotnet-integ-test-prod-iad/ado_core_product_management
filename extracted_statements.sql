-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source Application: AdoCore (.NET ADO.NET Application)
-- Database: Microsoft SQL Server (ProductManagement)
-- Purpose: Comprehensive catalog of all SQL statements for DMS conversion
-- ============================================================================

-- ============================================================================
-- SECTION 1: INLINE SQL STATEMENTS FROM ProductRepository.cs
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Lines: ~47-70
-- Type: SELECT with CTE, Window Functions, CASE, ROUND, INNER JOIN, ORDER BY
-- --------------------------------------------------------------------------
-- ORIGINAL MS SQL:
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

-- --------------------------------------------------------------------------
-- Statement 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Lines: ~82-110
-- Type: SELECT with CTE, LAG window function, parameterized (@ProductId), CASE, ROUND
-- --------------------------------------------------------------------------
-- ORIGINAL MS SQL:
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

-- --------------------------------------------------------------------------
-- Statement 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Lines: ~122-142
-- Type: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- --------------------------------------------------------------------------
-- ORIGINAL MS SQL:
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

-- --------------------------------------------------------------------------
-- Statement 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Lines: ~157-183
-- Type: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- --------------------------------------------------------------------------
-- ORIGINAL MS SQL:
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

-- --------------------------------------------------------------------------
-- Statement 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Lines: ~195-228
-- Type: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
-- Parameters: @ProductId
-- --------------------------------------------------------------------------
-- ORIGINAL MS SQL:
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

-- --------------------------------------------------------------------------
-- Statement 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: ~240-258
-- Type: SELECT with CTE, RANK, PERCENT_RANK, BETWEEN, CASE
-- Parameters: @MinPrice, @MaxPrice
-- --------------------------------------------------------------------------
-- ORIGINAL MS SQL:
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

-- --------------------------------------------------------------------------
-- Statement 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: ~275-297
-- Type: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
-- Parameters: @Threshold
-- --------------------------------------------------------------------------
-- ORIGINAL MS SQL:
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
-- SECTION 2: SQL SCRIPT FILES
-- ============================================================================

-- --------------------------------------------------------------------------
-- Script File: Scripts/01_InitialSetup.sql
-- Contains: CREATE DATABASE, CREATE TABLE, stored procedures, INSERT sample data
-- --------------------------------------------------------------------------
-- (Full script content preserved in original file)

-- --------------------------------------------------------------------------
-- Script File: Database/Scripts/01_InitialSetup.sql
-- Contains: Full schema - CREATE TABLE (Products, ProductHistory, Categories,
--           Suppliers, ProductStats), indexes, triggers, stored procedures,
--           sample data
-- --------------------------------------------------------------------------
-- (Full script content preserved in original file)

-- ============================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total Inline SQL Statements: 7
-- Total Script Files: 2
-- ============================================================================
