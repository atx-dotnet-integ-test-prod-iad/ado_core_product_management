-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: SQL Server to PostgreSQL Migration
-- Extraction Date: 2026-04-11
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Lines: ~42-66 (const string sql declaration)
-- Parameters: None
-- SQL Server Specific Features: CTE, INNER JOIN, CASE, ROUND, Window Functions (AVG OVER, COUNT OVER)
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Lines: ~74-99 (const string sql declaration)
-- Parameters: @ProductId (int)
-- SQL Server Specific Features: CTE, LAG Window Function, CASE, ROUND, LEFT JOIN
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Lines: ~113-134 (const string sql declaration)
-- Parameters: @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- SQL Server Specific Features: DECLARE, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE(), INSERT, UPDATE
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Lines: ~148-177 (const string sql declaration)
-- Parameters: @ProductId (int), @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- SQL Server Specific Features: BEGIN TRANSACTION/COMMIT, DECLARE, SELECT INTO variables, GETDATE(), INSERT, UPDATE
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Lines: ~193-222 (const string sql declaration)
-- Parameters: @ProductId (int)
-- SQL Server Specific Features: BEGIN TRANSACTION/COMMIT, DECLARE, SELECT INTO variables, GETDATE(), INSERT, DELETE, UPDATE, CASE WHEN
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: ~230-249 (const string sql declaration)
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- SQL Server Specific Features: CTE, RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE
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
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: ~265-284 (const string sql declaration)
-- Parameters: @Threshold (int)
-- SQL Server Specific Features: CTE, AVG/MIN/MAX OVER(), CASE, ROUND
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
-- REFERENCE: Table DDL from Database/Scripts/01_InitialSetup.sql
-- These are used for equivalency validation context
-- ============================================================================
-- Products Table:
--   CREATE TABLE [dbo].[Products](
--       [ProductId] [int] IDENTITY(1,1) PRIMARY KEY,
--       [Name] [nvarchar](100) NOT NULL,
--       [Description] [nvarchar](500) NULL,
--       [Price] [decimal](18, 2) NOT NULL,
--       [StockQuantity] [int] NOT NULL,
--       [CategoryId] [int] NULL,
--       [SupplierId] [int] NULL,
--       [SKU] [nvarchar](50) NULL,
--       [Weight] [decimal](10, 2) NULL,
--       [Dimensions] [nvarchar](50) NULL,
--       [IsDiscontinued] [bit] NOT NULL DEFAULT 0,
--       [ReorderLevel] [int] NOT NULL DEFAULT 10,
--       [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
--       [ModifiedDate] [datetime] NULL
--   )
--
-- ProductHistory Table:
--   CREATE TABLE [dbo].[ProductHistory](
--       [HistoryId] [int] IDENTITY(1,1) PRIMARY KEY,
--       [ProductId] [int] NOT NULL,
--       [Action] [varchar](10) NOT NULL,
--       [OldPrice] [decimal](18, 2) NULL,
--       [NewPrice] [decimal](18, 2) NULL,
--       [OldStock] [int] NULL,
--       [NewStock] [int] NULL,
--       [ActionDate] [datetime] NOT NULL DEFAULT GETDATE(),
--       [ModifiedBy] [nvarchar](100) NULL
--   )
--
-- ProductStats Table:
--   CREATE TABLE [dbo].[ProductStats](
--       [StatId] [int] PRIMARY KEY DEFAULT 1,
--       [TotalProducts] [int] NOT NULL DEFAULT 0,
--       [AveragePrice] [decimal](18, 2) NOT NULL DEFAULT 0,
--       [TotalStockValue] [decimal](18, 2) NOT NULL DEFAULT 0,
--       [LowStockCount] [int] NOT NULL DEFAULT 0,
--       [DiscontinuedCount] [int] NOT NULL DEFAULT 0,
--       [LastUpdated] [datetime] NOT NULL DEFAULT GETDATE()
--   )
