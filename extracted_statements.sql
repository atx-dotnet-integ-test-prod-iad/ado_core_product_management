-- ============================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Generated: Step 1 of ADO.NET to PostgreSQL Migration
-- Purpose: Comprehensive catalog of all SQL statements for DMS conversion
-- ============================================================================

-- ============================================================================
-- STATEMENTS FROM: ProductRepository.cs
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-001
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Number: ~42-68
-- Statement Type: SELECT
-- Complexity: Complex (CTE with window functions, CASE expressions)
-- Parameters: None
-- Description: Retrieves all products with price comparison analytics
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-002
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Number: ~75-107
-- Statement Type: SELECT
-- Complexity: Complex (CTE with LAG window function, LEFT JOIN)
-- Parameters: @ProductId (int)
-- Description: Retrieves product by ID with historical price comparison
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-003
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Number: ~114-139
-- Statement Type: INSERT with RETURNING
-- Complexity: Complex (Multi-CTE with INSERT, RETURNING, UPDATE)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Description: Inserts product with audit logging and stats update
-- ----------------------------------------------------------------------------
WITH inserted_product AS (
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId, Price, StockQuantity
),
log_insert AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'INSERT', NULL, Price, NULL, StockQuantity, CURRENT_TIMESTAMP
    FROM inserted_product
    RETURNING ProductId
),
update_stats AS (
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + (SELECT Price FROM inserted_product)) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1
    RETURNING StatId
)
SELECT ProductId FROM inserted_product;

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-004
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Number: ~151-180
-- Statement Type: UPDATE
-- Complexity: Complex (Multi-CTE with UPDATE, audit logging)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Description: Updates product with audit logging and stats recalculation
-- ----------------------------------------------------------------------------
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
updated_product AS (
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId
    RETURNING ProductId
),
log_update AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-005
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Number: ~187-216
-- Statement Type: DELETE
-- Complexity: Complex (Multi-CTE with DELETE, audit logging, stats update)
-- Parameters: @ProductId
-- Description: Deletes product with cleanup and stats recalculation
-- ----------------------------------------------------------------------------
WITH old_values AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
),
log_delete AS (
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, CURRENT_TIMESTAMP
    FROM old_values ov
    RETURNING ProductId
),
deleted_product AS (
    DELETE FROM Products 
    WHERE ProductId = @ProductId
    RETURNING ProductId
)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-006
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Number: ~223-245
-- Statement Type: SELECT
-- Complexity: Complex (CTE with RANK() and PERCENT_RANK() window functions)
-- Parameters: @MinPrice, @MaxPrice
-- Description: Retrieves products in price range with ranking analytics
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-007
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Number: ~252-275
-- Statement Type: SELECT
-- Complexity: Complex (CTE with multiple aggregate window functions)
-- Parameters: @Threshold
-- Description: Retrieves low stock products with inventory analytics
-- ----------------------------------------------------------------------------
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
-- STATEMENTS FROM: Scripts/01_InitialSetup.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-008
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE DATABASE
-- Complexity: Simple
-- Parameters: None
-- Description: Create ProductManagement database with existence check
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
BEGIN
    CREATE DATABASE ProductManagement;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-009
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE TABLE
-- Complexity: Medium
-- Parameters: None
-- Description: Create Products table with IDENTITY and constraints
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Products](
        [ProductId] [int] IDENTITY(1,1) PRIMARY KEY,
        [Name] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](500) NULL,
        [Price] [decimal](18, 2) NOT NULL,
        [StockQuantity] [int] NOT NULL,
        [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] [datetime] NULL
    )
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-010
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: None
-- Description: Stored procedure to get all products
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-011
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: @ProductId
-- Description: Stored procedure to get product by ID
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-012
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Description: Stored procedure to insert product
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_InsertProduct]
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SELECT SCOPE_IDENTITY() AS ProductId;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-013
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Description: Stored procedure to update product
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_UpdateProduct]
    @ProductId INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Products
    SET Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-014
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: @ProductId
-- Description: Stored procedure to delete product
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products
    WHERE ProductId = @ProductId;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-015
-- Source File: sourceCode/Scripts/01_InitialSetup.sql
-- Statement Type: DML - Data Check and INSERT
-- Complexity: Simple
-- Parameters: None
-- Description: Insert sample data if table is empty
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT TOP 1 1 FROM Products)
BEGIN
    EXEC sp_InsertProduct 'Laptop', 'High-performance laptop', 999.99, 10;
    EXEC sp_InsertProduct 'Mouse', 'Wireless gaming mouse', 49.99, 20;
    EXEC sp_InsertProduct 'Keyboard', 'Mechanical keyboard', 129.99, 15;
END

-- ============================================================================
-- STATEMENTS FROM: Database/Scripts/01_InitialSetup.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-016
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE DATABASE
-- Complexity: Simple
-- Parameters: None
-- Description: Create ProductManagement database (duplicate of STMT-008)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
BEGIN
    CREATE DATABASE ProductManagement;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-017
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - DROP TRIGGER
-- Complexity: Simple
-- Parameters: None
-- Description: Drop existing trigger if exists
-- ----------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_Products_History]') AND type = 'TR')
BEGIN
    DROP TRIGGER [dbo].[trg_Products_History]
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-018
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - DROP TABLE
-- Complexity: Simple
-- Parameters: None
-- Description: Drop ProductHistory table if exists
-- ----------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductHistory]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductHistory]
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-019
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - DROP TABLE
-- Complexity: Simple
-- Parameters: None
-- Description: Drop Products table if exists
-- ----------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Products]
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-020
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - DROP TABLE
-- Complexity: Simple
-- Parameters: None
-- Description: Drop Categories table if exists
-- ----------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Categories]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Categories]
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-021
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - DROP TABLE
-- Complexity: Simple
-- Parameters: None
-- Description: Drop Suppliers table if exists
-- ----------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Suppliers]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Suppliers]
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-022
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - DROP TABLE
-- Complexity: Simple
-- Parameters: None
-- Description: Drop ProductStats table if exists
-- ----------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductStats]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductStats]
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-023
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE TABLE
-- Complexity: Medium
-- Parameters: None
-- Description: Create Categories table with self-referencing FK
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[Categories](
    [CategoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](50) NOT NULL,
    [Description] [nvarchar](200) NULL,
    [ParentCategoryId] [int] NULL,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE()
)

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-024
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - ALTER TABLE
-- Complexity: Simple
-- Parameters: None
-- Description: Add self-referencing FK to Categories
-- ----------------------------------------------------------------------------
ALTER TABLE [dbo].[Categories]
ADD CONSTRAINT [FK_Categories_Categories] 
FOREIGN KEY ([ParentCategoryId]) REFERENCES [dbo].[Categories] ([CategoryId])

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-025
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE TABLE
-- Complexity: Medium
-- Parameters: None
-- Description: Create Suppliers table
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[Suppliers](
    [SupplierId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](100) NOT NULL,
    [ContactName] [nvarchar](100) NULL,
    [Email] [nvarchar](100) NULL,
    [Phone] [nvarchar](20) NULL,
    [Address] [nvarchar](200) NULL,
    [Country] [nvarchar](50) NULL,
    [IsActive] [bit] NOT NULL DEFAULT 1,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE()
)

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-026
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE TABLE
-- Complexity: Complex
-- Parameters: None
-- Description: Create Products table with FKs and extended fields
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[Products](
    [ProductId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](100) NOT NULL,
    [Description] [nvarchar](500) NULL,
    [Price] [decimal](18, 2) NOT NULL,
    [StockQuantity] [int] NOT NULL,
    [CategoryId] [int] NULL,
    [SupplierId] [int] NULL,
    [SKU] [nvarchar](50) NULL,
    [Weight] [decimal](10, 2) NULL,
    [Dimensions] [nvarchar](50) NULL,
    [IsDiscontinued] [bit] NOT NULL DEFAULT 0,
    [ReorderLevel] [int] NOT NULL DEFAULT 10,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [ModifiedDate] [datetime] NULL,
    CONSTRAINT [FK_Products_Categories] FOREIGN KEY ([CategoryId]) 
        REFERENCES [dbo].[Categories] ([CategoryId]),
    CONSTRAINT [FK_Products_Suppliers] FOREIGN KEY ([SupplierId]) 
        REFERENCES [dbo].[Suppliers] ([SupplierId])
)

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-027
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE TABLE
-- Complexity: Medium
-- Parameters: None
-- Description: Create ProductHistory table with FK
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[ProductHistory](
    [HistoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [ProductId] [int] NOT NULL,
    [Action] [varchar](10) NOT NULL,
    [OldPrice] [decimal](18, 2) NULL,
    [NewPrice] [decimal](18, 2) NULL,
    [OldStock] [int] NULL,
    [NewStock] [int] NULL,
    [ActionDate] [datetime] NOT NULL DEFAULT GETDATE(),
    [ModifiedBy] [nvarchar](100) NULL,
    CONSTRAINT [FK_ProductHistory_Products] FOREIGN KEY ([ProductId]) 
        REFERENCES [dbo].[Products] ([ProductId])
)

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-028
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE TABLE
-- Complexity: Simple
-- Parameters: None
-- Description: Create ProductStats table
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[ProductStats](
    [StatId] [int] PRIMARY KEY DEFAULT 1,
    [TotalProducts] [int] NOT NULL DEFAULT 0,
    [AveragePrice] [decimal](18, 2) NOT NULL DEFAULT 0,
    [TotalStockValue] [decimal](18, 2) NOT NULL DEFAULT 0,
    [LowStockCount] [int] NOT NULL DEFAULT 0,
    [DiscontinuedCount] [int] NOT NULL DEFAULT 0,
    [LastUpdated] [datetime] NOT NULL DEFAULT GETDATE()
)

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-029
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE INDEX
-- Complexity: Simple
-- Parameters: None
-- Description: Create index on Products.CategoryId
-- ----------------------------------------------------------------------------
CREATE INDEX [IX_Products_CategoryId] ON [dbo].[Products] ([CategoryId])

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-030
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE INDEX
-- Complexity: Simple
-- Parameters: None
-- Description: Create index on Products.SupplierId
-- ----------------------------------------------------------------------------
CREATE INDEX [IX_Products_SupplierId] ON [dbo].[Products] ([SupplierId])

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-031
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE UNIQUE INDEX
-- Complexity: Simple
-- Parameters: None
-- Description: Create unique index on Products.SKU
-- ----------------------------------------------------------------------------
CREATE UNIQUE INDEX [IX_Products_SKU] ON [dbo].[Products] ([SKU])

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-032
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE INDEX
-- Complexity: Simple
-- Parameters: None
-- Description: Create index on ProductHistory.ProductId
-- ----------------------------------------------------------------------------
CREATE INDEX [IX_ProductHistory_ProductId] ON [dbo].[ProductHistory] ([ProductId])

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-033
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE INDEX
-- Complexity: Simple
-- Parameters: None
-- Description: Create index on ProductHistory.ActionDate
-- ----------------------------------------------------------------------------
CREATE INDEX [IX_ProductHistory_ActionDate] ON [dbo].[ProductHistory] ([ActionDate])

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-034
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DML - INSERT
-- Complexity: Simple
-- Parameters: None
-- Description: Insert sample categories
-- ----------------------------------------------------------------------------
INSERT INTO Categories (Name, Description, ParentCategoryId)
VALUES 
    ('Electronics', 'Electronic devices and accessories', NULL),
    ('Computers', 'Computers and related equipment', 1),
    ('Peripherals', 'Computer peripherals and accessories', 1),
    ('Audio', 'Audio equipment and accessories', 1),
    ('Storage', 'Data storage devices', 1),
    ('Gaming', 'Gaming equipment and accessories', NULL),
    ('Office', 'Office equipment and supplies', NULL),
    ('Networking', 'Networking equipment and accessories', 1),
    ('Laptops', 'Portable computers', 2),
    ('Desktops', 'Desktop computers', 2),
    ('Keyboards', 'Computer keyboards', 3),
    ('Mice', 'Computer mice and pointing devices', 3),
    ('Headphones', 'Audio headphones and headsets', 4),
    ('Speakers', 'Audio speakers', 4),
    ('External Drives', 'External storage devices', 5),
    ('Gaming PCs', 'Gaming computers', 6),
    ('Gaming Accessories', 'Gaming peripherals', 6),
    ('Printers', 'Printing devices', 7),
    ('Routers', 'Network routers', 8),
    ('Switches', 'Network switches', 8)

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-035
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DML - INSERT
-- Complexity: Simple
-- Parameters: None
-- Description: Insert sample suppliers
-- ----------------------------------------------------------------------------
INSERT INTO Suppliers (Name, ContactName, Email, Phone, Address, Country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA')

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-036
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DML - INSERT
-- Complexity: Medium (multiple rows with calculations)
-- Parameters: None
-- Description: Insert sample products with extended attributes
-- ----------------------------------------------------------------------------
INSERT INTO Products (Name, Description, Price, StockQuantity, CategoryId, SupplierId, SKU, Weight, Dimensions, ReorderLevel)
VALUES 
    -- Laptops
    ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 9, 1, 'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5),
    ('Gaming Beast', 'Gaming laptop with RTX 3080, 32GB RAM', 2499.99, 8, 9, 4, 'LAP-GB-001', 2.5, '15.6" x 11" x 1"', 3),
    ('UltraBook Air', 'Ultra-thin laptop with 12-hour battery', 999.99, 20, 9, 1, 'LAP-UA-001', 1.2, '13" x 8" x 0.5"', 7),
    -- Desktops
    ('WorkStation Pro', 'Professional workstation with dual monitors', 1999.99, 10, 10, 1, 'DESK-WP-001', 15.0, '18" x 8" x 16"', 4),
    ('Gaming Tower', 'High-end gaming desktop with liquid cooling', 2999.99, 5, 16, 4, 'DESK-GT-001', 20.0, '20" x 10" x 18"', 2),
    -- Keyboards
    ('Mechanical Pro', 'Mechanical keyboard with RGB lighting', 149.99, 30, 11, 2, 'KB-MP-001', 1.2, '17" x 5" x 1.5"', 10),
    ('Wireless Elite', 'Wireless keyboard with numeric pad', 79.99, 25, 11, 2, 'KB-WE-001', 0.8, '18" x 6" x 1"', 8),
    -- Mice
    ('Gaming Mouse Pro', 'High-precision gaming mouse', 89.99, 40, 12, 4, 'M-GP-001', 0.3, '5" x 3" x 1.5"', 15),
    ('Wireless Track', 'Wireless mouse with long battery life', 49.99, 35, 12, 2, 'M-WT-001', 0.2, '4" x 2.5" x 1.2"', 12),
    -- Headphones
    ('Noise Cancelling Pro', 'Premium noise-cancelling headphones', 299.99, 20, 13, 5, 'HP-NC-001', 0.4, '7" x 6" x 3"', 8),
    ('Gaming Headset', '7.1 surround sound gaming headset', 129.99, 25, 13, 4, 'HP-GH-001', 0.5, '8" x 7" x 4"', 10),
    -- Speakers
    ('Studio Monitors', 'Professional studio monitors', 399.99, 10, 14, 5, 'SP-SM-001', 8.0, '12" x 8" x 10"', 4),
    ('Bluetooth Soundbar', 'Wireless soundbar with subwoofer', 249.99, 15, 14, 5, 'SP-BS-001', 5.0, '36" x 3" x 4"', 6),
    -- External Drives
    ('SSD Pro 1TB', '1TB external SSD with USB 3.1', 199.99, 30, 15, 6, 'ED-SP-001', 0.2, '4" x 2" x 0.5"', 12),
    ('HDD Backup 4TB', '4TB external HDD for backup', 129.99, 25, 15, 6, 'ED-HB-001', 0.5, '5" x 3" x 1"', 10),
    -- Printers
    ('Laser Pro', 'Business laser printer with duplex', 399.99, 12, 18, 7, 'PR-LP-001', 25.0, '18" x 16" x 12"', 5),
    ('Photo Inkjet', 'Photo-quality inkjet printer', 299.99, 15, 18, 7, 'PR-PI-001', 15.0, '16" x 14" x 8"', 6),
    -- Networking
    ('WiFi 6 Router', 'High-speed WiFi 6 router', 199.99, 20, 19, 8, 'NET-WR-001', 1.5, '10" x 7" x 2"', 8),
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4)

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-037
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DML - INSERT
-- Complexity: Simple
-- Parameters: None
-- Description: Insert initial stats record
-- ----------------------------------------------------------------------------
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, GETDATE())

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-038
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DML - UPDATE
-- Complexity: Medium (with subqueries)
-- Parameters: None
-- Description: Update initial statistics with calculated values
-- ----------------------------------------------------------------------------
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = 1),
    LastUpdated = GETDATE()
WHERE StatId = 1

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-039
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE TRIGGER
-- Complexity: Complex (multi-branch logic with INSERT/UPDATE/DELETE)
-- Parameters: None
-- Description: Trigger for automatic product history tracking
-- ----------------------------------------------------------------------------
CREATE TRIGGER [dbo].[trg_Products_History]
ON [dbo].[Products]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Handle INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ProductHistory (ProductId, Action, NewPrice, NewStock, ModifiedBy)
        SELECT 
            ProductId,
            'INSERT',
            Price,
            StockQuantity,
            SYSTEM_USER
        FROM inserted;
    END
    
    -- Handle UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ModifiedBy)
        SELECT 
            i.ProductId,
            'UPDATE',
            d.Price,
            i.Price,
            d.StockQuantity,
            i.StockQuantity,
            SYSTEM_USER
        FROM inserted i
        INNER JOIN deleted d ON i.ProductId = d.ProductId
        WHERE i.Price <> d.Price OR i.StockQuantity <> d.StockQuantity;
    END
    
    -- Handle DELETE
    IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, OldStock, ModifiedBy)
        SELECT 
            ProductId,
            'DELETE',
            Price,
            StockQuantity,
            SYSTEM_USER
        FROM deleted;
    END
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-040
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: None
-- Description: Stored procedure to get all products (duplicate of STMT-010)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-041
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: @ProductId
-- Description: Stored procedure to get product by ID (duplicate of STMT-011)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-042
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Description: Stored procedure to insert product (duplicate of STMT-012)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_InsertProduct]
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SELECT SCOPE_IDENTITY() AS ProductId;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-043
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Description: Stored procedure to update product (duplicate of STMT-013)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_UpdateProduct]
    @ProductId INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Products
    SET Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
END

-- ----------------------------------------------------------------------------
-- STATEMENT ID: STMT-044
-- Source File: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Statement Type: DDL - CREATE PROCEDURE
-- Complexity: Simple
-- Parameters: @ProductId
-- Description: Stored procedure to delete product (duplicate of STMT-014)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products
    WHERE ProductId = @ProductId;
END

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
-- Total Statements Extracted: 44
-- From ProductRepository.cs: 7 statements
-- From Scripts/01_InitialSetup.sql: 8 statements
-- From Database/Scripts/01_InitialSetup.sql: 29 statements
--
-- Complexity Distribution:
-- - Simple: 32 statements
-- - Medium: 5 statements
-- - Complex: 7 statements
--
-- Statement Types:
-- - SELECT: 7 statements
-- - INSERT: 4 statements (1 with RETURNING)
-- - UPDATE: 2 statements
-- - DELETE: 1 statement
-- - CREATE TABLE: 6 statements
-- - CREATE PROCEDURE: 10 statements
-- - CREATE INDEX: 5 statements
-- - CREATE TRIGGER: 1 statement
-- - DROP statements: 5 statements
-- - Other DDL: 3 statements
-- ============================================================================
