-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: MS SQL Server to PostgreSQL Migration
-- ============================================================================

-- ============================================================================
-- SECTION 1: SQL Statements from ProductRepository.cs
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 1: GetAllProductsAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, method GetAllProductsAsync()
-- Type: CTE with window functions (AVG, COUNT OVER)
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- --------------------------------------------------------------------------
-- Statement 2: GetProductByIdAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, method GetProductByIdAsync()
-- Type: CTE with LAG window function
-- Parameters: @ProductId (int)
-- Transaction: No
-- --------------------------------------------------------------------------
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- --------------------------------------------------------------------------
-- Statement 3: InsertProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, method InsertProductAsync()
-- Type: Transaction block with INSERT + UPDATE
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Transaction: Yes (BEGIN/COMMIT)
-- --------------------------------------------------------------------------
BEGIN;
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);

    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- --------------------------------------------------------------------------
-- Statement 4: UpdateProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, method UpdateProductAsync()
-- Type: Transaction block with INSERT + UPDATE + UPDATE
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Transaction: Yes (BEGIN/COMMIT)
-- --------------------------------------------------------------------------
BEGIN;
    -- Log the changes (capture old values via subquery before update)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products WHERE productid = @ProductId;

    -- Update product statistics (capture old price before update)
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;

    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
COMMIT;

-- --------------------------------------------------------------------------
-- Statement 5: DeleteProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, method DeleteProductAsync()
-- Type: Transaction block with INSERT + UPDATE + DELETE
-- Parameters: @ProductId (int)
-- Transaction: Yes (BEGIN/COMMIT)
-- --------------------------------------------------------------------------
BEGIN;
    -- Log the deletion (capture old values via subquery before delete)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products WHERE productid = @ProductId;

    -- Update product statistics (capture old price before delete)
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;

    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
COMMIT;

-- --------------------------------------------------------------------------
-- Statement 6: GetProductsByPriceRangeAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, method GetProductsByPriceRangeAsync()
-- Type: CTE with RANK, PERCENT_RANK
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Transaction: No
-- --------------------------------------------------------------------------
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- --------------------------------------------------------------------------
-- Statement 7: GetLowStockProductsAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, method GetLowStockProductsAsync()
-- Type: CTE with AVG, MIN, MAX window functions and CAST
-- Parameters: @Threshold (int)
-- Transaction: No
-- --------------------------------------------------------------------------
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;


-- ============================================================================
-- SECTION 2: SQL Statements from Database/Scripts/01_InitialSetup.sql
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 8: CREATE DATABASE with IF NOT EXISTS check
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Database creation
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
BEGIN
    CREATE DATABASE ProductManagement;
END
GO

-- --------------------------------------------------------------------------
-- Statement 9: USE Database
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Database context switch
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
USE ProductManagement;
GO

-- --------------------------------------------------------------------------
-- Statement 10: DROP TRIGGER IF EXISTS
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Drop trigger
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_Products_History]') AND type = 'TR')
BEGIN
    DROP TRIGGER [dbo].[trg_Products_History]
END
GO

-- --------------------------------------------------------------------------
-- Statement 11: DROP TABLE ProductHistory IF EXISTS
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Drop table
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductHistory]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductHistory]
END
GO

-- --------------------------------------------------------------------------
-- Statement 12: DROP TABLE Products IF EXISTS
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Drop table
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Products]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Products]
END
GO

-- --------------------------------------------------------------------------
-- Statement 13: DROP TABLE Categories IF EXISTS
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Drop table
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Categories]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Categories]
END
GO

-- --------------------------------------------------------------------------
-- Statement 14: DROP TABLE Suppliers IF EXISTS
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Drop table
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Suppliers]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Suppliers]
END
GO

-- --------------------------------------------------------------------------
-- Statement 15: DROP TABLE ProductStats IF EXISTS
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Drop table
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductStats]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProductStats]
END
GO

-- --------------------------------------------------------------------------
-- Statement 16: CREATE TABLE Categories
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Create table with IDENTITY, nvarchar, GETDATE()
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE TABLE [dbo].[Categories](
    [CategoryId] [int] IDENTITY(1,1) PRIMARY KEY,
    [Name] [nvarchar](50) NOT NULL,
    [Description] [nvarchar](200) NULL,
    [ParentCategoryId] [int] NULL,
    [CreatedDate] [datetime] NOT NULL DEFAULT GETDATE()
)
GO

-- --------------------------------------------------------------------------
-- Statement 17: ALTER TABLE Categories - Self-referencing FK
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Foreign key constraint
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
ALTER TABLE [dbo].[Categories]
ADD CONSTRAINT [FK_Categories_Categories] 
FOREIGN KEY ([ParentCategoryId]) REFERENCES [dbo].[Categories] ([CategoryId])
GO

-- --------------------------------------------------------------------------
-- Statement 18: CREATE TABLE Suppliers
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Create table with IDENTITY, nvarchar, bit, GETDATE()
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 19: CREATE TABLE Products
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Create table with IDENTITY, nvarchar, bit, decimal, GETDATE(), FK constraints
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 20: CREATE TABLE ProductHistory
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Create table with IDENTITY, GETDATE(), FK
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 21: CREATE TABLE ProductStats
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Create table with GETDATE()
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE TABLE [dbo].[ProductStats](
    [StatId] [int] PRIMARY KEY DEFAULT 1,
    [TotalProducts] [int] NOT NULL DEFAULT 0,
    [AveragePrice] [decimal](18, 2) NOT NULL DEFAULT 0,
    [TotalStockValue] [decimal](18, 2) NOT NULL DEFAULT 0,
    [LowStockCount] [int] NOT NULL DEFAULT 0,
    [DiscontinuedCount] [int] NOT NULL DEFAULT 0,
    [LastUpdated] [datetime] NOT NULL DEFAULT GETDATE()
)
GO

-- --------------------------------------------------------------------------
-- Statement 22: CREATE INDEX IX_Products_CategoryId
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Index creation
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE INDEX [IX_Products_CategoryId] ON [dbo].[Products] ([CategoryId])
GO

-- --------------------------------------------------------------------------
-- Statement 23: CREATE INDEX IX_Products_SupplierId
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Index creation
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE INDEX [IX_Products_SupplierId] ON [dbo].[Products] ([SupplierId])
GO

-- --------------------------------------------------------------------------
-- Statement 24: CREATE UNIQUE INDEX IX_Products_SKU
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Unique index creation
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE UNIQUE INDEX [IX_Products_SKU] ON [dbo].[Products] ([SKU])
GO

-- --------------------------------------------------------------------------
-- Statement 25: CREATE INDEX IX_ProductHistory_ProductId
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Index creation
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE INDEX [IX_ProductHistory_ProductId] ON [dbo].[ProductHistory] ([ProductId])
GO

-- --------------------------------------------------------------------------
-- Statement 26: CREATE INDEX IX_ProductHistory_ActionDate
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Index creation
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE INDEX [IX_ProductHistory_ActionDate] ON [dbo].[ProductHistory] ([ActionDate])
GO

-- --------------------------------------------------------------------------
-- Statement 27: INSERT Sample Categories
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DML - Multi-row INSERT
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 28: INSERT Sample Suppliers
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DML - Multi-row INSERT
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 29: INSERT Sample Products
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DML - Multi-row INSERT with multiple categories
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
INSERT INTO Products (Name, Description, Price, StockQuantity, CategoryId, SupplierId, SKU, Weight, Dimensions, ReorderLevel)
VALUES 
    ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 9, 1, 'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5),
    ('Gaming Beast', 'Gaming laptop with RTX 3080, 32GB RAM', 2499.99, 8, 9, 4, 'LAP-GB-001', 2.5, '15.6" x 11" x 1"', 3),
    ('UltraBook Air', 'Ultra-thin laptop with 12-hour battery', 999.99, 20, 9, 1, 'LAP-UA-001', 1.2, '13" x 8" x 0.5"', 7),
    ('WorkStation Pro', 'Professional workstation with dual monitors', 1999.99, 10, 10, 1, 'DESK-WP-001', 15.0, '18" x 8" x 16"', 4),
    ('Gaming Tower', 'High-end gaming desktop with liquid cooling', 2999.99, 5, 16, 4, 'DESK-GT-001', 20.0, '20" x 10" x 18"', 2),
    ('Mechanical Pro', 'Mechanical keyboard with RGB lighting', 149.99, 30, 11, 2, 'KB-MP-001', 1.2, '17" x 5" x 1.5"', 10),
    ('Wireless Elite', 'Wireless keyboard with numeric pad', 79.99, 25, 11, 2, 'KB-WE-001', 0.8, '18" x 6" x 1"', 8),
    ('Gaming Mouse Pro', 'High-precision gaming mouse', 89.99, 40, 12, 4, 'M-GP-001', 0.3, '5" x 3" x 1.5"', 15),
    ('Wireless Track', 'Wireless mouse with long battery life', 49.99, 35, 12, 2, 'M-WT-001', 0.2, '4" x 2.5" x 1.2"', 12),
    ('Noise Cancelling Pro', 'Premium noise-cancelling headphones', 299.99, 20, 13, 5, 'HP-NC-001', 0.4, '7" x 6" x 3"', 8),
    ('Gaming Headset', '7.1 surround sound gaming headset', 129.99, 25, 13, 4, 'HP-GH-001', 0.5, '8" x 7" x 4"', 10),
    ('Studio Monitors', 'Professional studio monitors', 399.99, 10, 14, 5, 'SP-SM-001', 8.0, '12" x 8" x 10"', 4),
    ('Bluetooth Soundbar', 'Wireless soundbar with subwoofer', 249.99, 15, 14, 5, 'SP-BS-001', 5.0, '36" x 3" x 4"', 6),
    ('SSD Pro 1TB', '1TB external SSD with USB 3.1', 199.99, 30, 15, 6, 'ED-SP-001', 0.2, '4" x 2" x 0.5"', 12),
    ('HDD Backup 4TB', '4TB external HDD for backup', 129.99, 25, 15, 6, 'ED-HB-001', 0.5, '5" x 3" x 1"', 10),
    ('Laser Pro', 'Business laser printer with duplex', 399.99, 12, 18, 7, 'PR-LP-001', 25.0, '18" x 16" x 12"', 5),
    ('Photo Inkjet', 'Photo-quality inkjet printer', 299.99, 15, 18, 7, 'PR-PI-001', 15.0, '16" x 14" x 8"', 6),
    ('WiFi 6 Router', 'High-speed WiFi 6 router', 199.99, 20, 19, 8, 'NET-WR-001', 1.5, '10" x 7" x 2"', 8),
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4)
GO

-- --------------------------------------------------------------------------
-- Statement 30: INSERT Initial ProductStats Record
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DML - Single INSERT with GETDATE()
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, GETDATE())
GO

-- --------------------------------------------------------------------------
-- Statement 31: UPDATE Initial Statistics
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DML - UPDATE with subqueries, GETDATE()
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = 1),
    LastUpdated = GETDATE()
WHERE StatId = 1
GO

-- --------------------------------------------------------------------------
-- Statement 32: CREATE TRIGGER trg_Products_History
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Trigger with SYSTEM_USER, SET NOCOUNT ON
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 33: CREATE OR ALTER PROCEDURE sp_GetAllProducts
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END
GO

-- --------------------------------------------------------------------------
-- Statement 34: CREATE OR ALTER PROCEDURE sp_GetProductById
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure with parameter
-- Parameters: @ProductId INT
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END
GO

-- --------------------------------------------------------------------------
-- Statement 35: CREATE OR ALTER PROCEDURE sp_InsertProduct
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure with SCOPE_IDENTITY()
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 36: CREATE OR ALTER PROCEDURE sp_UpdateProduct
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure with GETDATE()
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 37: CREATE OR ALTER PROCEDURE sp_DeleteProduct
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure
-- Parameters: @ProductId INT
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products
    WHERE ProductId = @ProductId;
END
GO

-- ============================================================================
-- SECTION 3: SQL Statements from Scripts/01_InitialSetup.sql
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 38: CREATE DATABASE (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - Database creation with IF NOT EXISTS
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProductManagement')
BEGIN
    CREATE DATABASE ProductManagement;
END
GO

-- --------------------------------------------------------------------------
-- Statement 39: USE Database (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - Database context switch
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
USE ProductManagement;
GO

-- --------------------------------------------------------------------------
-- Statement 40: CREATE TABLE Products (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - Create table with IF NOT EXISTS, IDENTITY, GETDATE()
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 41: CREATE OR ALTER PROCEDURE sp_GetAllProducts (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    ORDER BY Name;
END
GO

-- --------------------------------------------------------------------------
-- Statement 42: CREATE OR ALTER PROCEDURE sp_GetProductById (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure with parameter
-- Parameters: @ProductId INT
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM Products
    WHERE ProductId = @ProductId;
END
GO

-- --------------------------------------------------------------------------
-- Statement 43: CREATE OR ALTER PROCEDURE sp_InsertProduct (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure with SCOPE_IDENTITY()
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 44: CREATE OR ALTER PROCEDURE sp_UpdateProduct (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure with GETDATE()
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Transaction: No
-- --------------------------------------------------------------------------
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
GO

-- --------------------------------------------------------------------------
-- Statement 45: CREATE OR ALTER PROCEDURE sp_DeleteProduct (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DDL - Stored procedure
-- Parameters: @ProductId INT
-- Transaction: No
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Products
    WHERE ProductId = @ProductId;
END
GO

-- --------------------------------------------------------------------------
-- Statement 46: INSERT Sample Data via Stored Procedures (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql
-- Type: DML - EXEC stored procedures with IF NOT EXISTS check
-- Parameters: None
-- Transaction: No
-- --------------------------------------------------------------------------
IF NOT EXISTS (SELECT TOP 1 1 FROM Products)
BEGIN
    EXEC sp_InsertProduct 'Laptop', 'High-performance laptop', 999.99, 10;
    EXEC sp_InsertProduct 'Mouse', 'Wireless gaming mouse', 49.99, 20;
    EXEC sp_InsertProduct 'Keyboard', 'Mechanical keyboard', 129.99, 15;
END
GO