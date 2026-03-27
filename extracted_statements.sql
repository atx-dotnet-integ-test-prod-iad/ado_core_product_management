-- =====================================================
-- EXTRACTED MS SQL SERVER STATEMENTS CATALOG
-- Source: AdoCore .NET Application
-- Extraction Date: 2026-03-26
-- Total Statements: 9
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Location: GetAllProductsAsync() method
-- Type: SELECT with CTE, Window Functions, CASE, ROUND, INNER JOIN
-- Complexity: Hard
-- DMS Attempt: FAILED - Metadata model conversion timeout after 15 attempts
-- =====================================================
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM [dbo].[Products]
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
FROM [dbo].[Products] p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- =====================================================
-- Statement 2: GetProductByIdAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Location: GetProductByIdAsync() method
-- Type: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
-- Parameters: @ProductId
-- Complexity: Hard
-- DMS Attempt: FAILED - Metadata model creation timeout after 15 attempts
-- =====================================================
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM [dbo].[Products]
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
FROM [dbo].[Products] p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- =====================================================
-- Statement 3: InsertProductAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Location: InsertProductAsync() method
-- Type: Transaction with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Complexity: Medium
-- DMS Attempt: FAILED - Metadata model creation timeout after 15 attempts
-- =====================================================
BEGIN TRANSACTION;

DECLARE @NewProductId INT;

INSERT INTO [dbo].[Products] (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity);

SET @NewProductId = SCOPE_IDENTITY();

INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());

UPDATE [dbo].[ProductStats]
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;

COMMIT TRANSACTION;

SELECT @NewProductId;

-- =====================================================
-- Statement 4: UpdateProductAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Location: UpdateProductAsync() method
-- Type: Transaction with DECLARE variables, SELECT INTO, UPDATE, INSERT, GETDATE()
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Complexity: Medium
-- DMS Attempt: FAILED - Metadata model creation timeout after 15 attempts
-- =====================================================
BEGIN TRANSACTION;

DECLARE @OldPrice DECIMAL(18,2);
DECLARE @OldStock INT;

SELECT @OldPrice = Price, @OldStock = StockQuantity
FROM [dbo].[Products]
WHERE ProductId = @ProductId;

INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

UPDATE [dbo].[ProductStats]
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = GETDATE()
WHERE StatId = 1;

UPDATE [dbo].[Products]
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = GETDATE()
WHERE ProductId = @ProductId;

COMMIT TRANSACTION;

-- =====================================================
-- Statement 5: DeleteProductAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Location: DeleteProductAsync() method
-- Type: Transaction with DECLARE variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
-- Parameters: @ProductId
-- Complexity: Medium
-- DMS Attempt: FAILED - Metadata model creation timeout after 15 attempts
-- =====================================================
BEGIN TRANSACTION;

DECLARE @OldPrice DECIMAL(18,2);
DECLARE @OldStock INT;

SELECT @OldPrice = Price, @OldStock = StockQuantity
FROM [dbo].[Products]
WHERE ProductId = @ProductId;

INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

UPDATE [dbo].[ProductStats]
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = GETDATE()
WHERE StatId = 1;

DELETE FROM [dbo].[Products]
WHERE ProductId = @ProductId;

COMMIT TRANSACTION;

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Location: GetProductsByPriceRangeAsync() method
-- Type: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
-- Parameters: @MinPrice, @MaxPrice
-- Complexity: Hard
-- DMS Attempt: FAILED - Metadata model creation timeout after 15 attempts
-- =====================================================
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM [dbo].[Products] p
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

-- =====================================================
-- Statement 7: GetLowStockProductsAsync
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Location: GetLowStockProductsAsync() method
-- Type: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
-- Parameters: @Threshold
-- Complexity: Hard
-- DMS Attempt: FAILED - Metadata model creation timeout after 15 attempts
-- =====================================================
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM [dbo].[Products] p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND(CAST(StockQuantity AS NUMERIC) / CAST(AvgStock AS NUMERIC) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

-- =====================================================
-- Statement 8: CREATE TABLE Products
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Location: DDL section
-- Type: DDL with IDENTITY, NVARCHAR, DATETIME, GETDATE()
-- Complexity: Easy
-- DMS Attempt: FAILED - Metadata model creation timeout after 15 attempts
-- =====================================================
CREATE TABLE [dbo].[Products](
    [ProductId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](100) NOT NULL,
    [Description] [nvarchar](500) NULL,
    [Price] [decimal](18, 2) NOT NULL,
    [StockQuantity] [int] NOT NULL,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [ModifiedDate] [datetime] NULL
);

-- =====================================================
-- Statement 9: sp_GetAllProducts body (stored procedure)
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Location: Stored procedure definition
-- Type: Simple SELECT inside stored procedure
-- Complexity: Easy
-- DMS Attempt: FAILED - Metadata model creation timeout after 15 attempts
-- =====================================================
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
FROM [dbo].[Products] p
ORDER BY p.Name;
