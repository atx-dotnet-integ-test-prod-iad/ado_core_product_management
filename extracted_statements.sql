-- ============================================================================
-- COMPREHENSIVE SQL STATEMENT CATALOG
-- Extracted from AdoCore Application
-- Format: Original MS SQL Server version + Current PostgreSQL version
-- ============================================================================

-- ============================================================================
-- SECTION 1: ProductRepository.cs - Inline SQL Statements (7 statements)
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 1: GetAllProductsAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, lines ~44-60
-- Type: SELECT with CTE
-- Context: Retrieves all products with price statistics
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
-- (Reconstructed from PostgreSQL by reversing DMS schema mappings)
/*MSSQL_STATEMENT_1*/
WITH ProductStats
AS (SELECT
    ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts
    FROM [dbo].[Products])
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END AS PriceCategory, ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage
    FROM [dbo].[Products] AS p
    INNER JOIN ProductStats AS ps
        ON p.ProductId = ps.ProductId
    ORDER BY
    CASE
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END, p.Name;
/*END_MSSQL_STATEMENT_1*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_1*/
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;
/*END_PGSQL_STATEMENT_1*/

-- --------------------------------------------------------------------------
-- Statement 2: GetProductByIdAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, lines ~68-83
-- Type: SELECT with CTE and parameter
-- Context: Retrieves product by ID with history comparison
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_2*/
WITH ProductHistory
AS (SELECT
    ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE
        WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END AS PriceChangePercentage
    FROM [dbo].[Products] AS p
    LEFT OUTER JOIN ProductHistory AS ph
        ON p.ProductId = ph.ProductId
    WHERE p.ProductId = @ProductId;
/*END_MSSQL_STATEMENT_2*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_2*/
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;
/*END_PGSQL_STATEMENT_2*/

-- --------------------------------------------------------------------------
-- Statement 3: InsertProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, lines ~94-113
-- Type: Transaction block (INSERT + INSERT + UPDATE + SELECT)
-- Context: Inserts a new product with history and stats update
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_3*/
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

SELECT @NewProductId;
/*END_MSSQL_STATEMENT_3*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_3*/
DO $$
DECLARE
    var_newproductid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO var_newproductid;

    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (var_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

SELECT currval(pg_get_serial_sequence('productmanagement_dbo.products', 'productid'));
/*END_PGSQL_STATEMENT_3*/

-- --------------------------------------------------------------------------
-- Statement 4: UpdateProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, lines ~124-145
-- Type: Transaction block (SELECT + UPDATE + INSERT + UPDATE)
-- Context: Updates a product with history logging
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_4*/
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;

/* Store old values for history */
SELECT @OldPrice = Price, @OldStock = StockQuantity
FROM [dbo].[Products]
WHERE ProductId = @ProductId;

/* Update the product */
UPDATE [dbo].[Products]
SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
WHERE ProductId = @ProductId;

/* Log the changes */
INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

/* Update product statistics */
UPDATE [dbo].[ProductStats]
SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE()
WHERE StatId = 1;
/*END_MSSQL_STATEMENT_4*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_4*/
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;
/*END_PGSQL_STATEMENT_4*/

-- --------------------------------------------------------------------------
-- Statement 5: DeleteProductAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, lines ~156-180
-- Type: Transaction block (SELECT + INSERT + DELETE + UPDATE)
-- Context: Deletes a product with history logging
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_5*/
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;

/* Store product info for history */
SELECT @OldPrice = Price, @OldStock = StockQuantity
FROM [dbo].[Products]
WHERE ProductId = @ProductId;

/* Log the deletion */
INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

/* Delete the product */
DELETE FROM [dbo].[Products]
WHERE ProductId = @ProductId;

/* Update product statistics */
UPDATE [dbo].[ProductStats]
SET TotalProducts = TotalProducts - 1, AveragePrice =
CASE
    WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
    ELSE 0
END, LastUpdated = GETDATE()
WHERE StatId = 1;
/*END_MSSQL_STATEMENT_5*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_5*/
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
END $$;
/*END_PGSQL_STATEMENT_5*/

-- --------------------------------------------------------------------------
-- Statement 6: GetProductsByPriceRangeAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, lines ~190-203
-- Type: SELECT with CTE and parameters
-- Context: Retrieves products in a price range with ranking
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_6*/
WITH RankedProducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM [dbo].[Products] AS p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceSegment
    FROM RankedProducts AS rp
    ORDER BY rp.PriceRank;
/*END_MSSQL_STATEMENT_6*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_6*/
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;
/*END_PGSQL_STATEMENT_6*/

-- --------------------------------------------------------------------------
-- Statement 7: GetLowStockProductsAsync
-- Source: sourceCode/DataAccess/ProductRepository.cs, lines ~219-233
-- Type: SELECT with CTE and parameter
-- Context: Retrieves low stock products with analysis
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_7*/
WITH StockAnalysis
AS (SELECT
    p.*, AVG(StockQuantity) OVER () AS AvgStock, MIN(StockQuantity) OVER () AS MinStock, MAX(StockQuantity) OVER () AS MaxStock
    FROM [dbo].[Products] AS p)
SELECT
    sa.*,
    CASE
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS StockStatus, ROUND((CAST(StockQuantity AS DECIMAL) / AvgStock) * 100, 2) AS StockPercentageOfAverage
    FROM StockAnalysis AS sa
    WHERE StockQuantity <= @Threshold
    ORDER BY StockQuantity;
/*END_MSSQL_STATEMENT_7*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_7*/
WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;
/*END_PGSQL_STATEMENT_7*/

-- ============================================================================
-- SECTION 2: Database/Scripts/01_InitialSetup.sql - DDL Statements
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 8: CREATE SCHEMA
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, line 5
-- Type: DDL - CREATE SCHEMA
-- Context: Creates the database schema
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_8*/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
END;
/*END_MSSQL_STATEMENT_8*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_8*/
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;
/*END_PGSQL_STATEMENT_8*/

-- --------------------------------------------------------------------------
-- Statement 9: DROP TRIGGER
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, line 8
-- Type: DDL - DROP TRIGGER
-- Context: Drops existing trigger
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_9*/
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_Products_History')
    DROP TRIGGER [dbo].[trg_Products_History];
/*END_MSSQL_STATEMENT_9*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_9*/
DROP TRIGGER IF EXISTS trg_products_history ON productmanagement_dbo.products;
DROP FUNCTION IF EXISTS productmanagement_dbo.trg_products_history_func();
/*END_PGSQL_STATEMENT_9*/

-- --------------------------------------------------------------------------
-- Statement 10: DROP TABLES
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 10-14
-- Type: DDL - DROP TABLE
-- Context: Drops existing tables in correct order
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_10*/
IF OBJECT_ID('[dbo].[ProductHistory]', 'U') IS NOT NULL DROP TABLE [dbo].[ProductHistory];
IF OBJECT_ID('[dbo].[Products]', 'U') IS NOT NULL DROP TABLE [dbo].[Products];
IF OBJECT_ID('[dbo].[Categories]', 'U') IS NOT NULL DROP TABLE [dbo].[Categories];
IF OBJECT_ID('[dbo].[Suppliers]', 'U') IS NOT NULL DROP TABLE [dbo].[Suppliers];
IF OBJECT_ID('[dbo].[ProductStats]', 'U') IS NOT NULL DROP TABLE [dbo].[ProductStats];
/*END_MSSQL_STATEMENT_10*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_10*/
DROP TABLE IF EXISTS productmanagement_dbo.producthistory;
DROP TABLE IF EXISTS productmanagement_dbo.products CASCADE;
DROP TABLE IF EXISTS productmanagement_dbo.categories CASCADE;
DROP TABLE IF EXISTS productmanagement_dbo.suppliers CASCADE;
DROP TABLE IF EXISTS productmanagement_dbo.productstats;
/*END_PGSQL_STATEMENT_10*/

-- --------------------------------------------------------------------------
-- Statement 11: CREATE TABLE Categories
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 17-23
-- Type: DDL - CREATE TABLE
-- Context: Creates Categories table
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_11*/
CREATE TABLE [dbo].[Categories](
    [CategoryId] INT IDENTITY(1,1) PRIMARY KEY,
    [Name] NVARCHAR(50) NOT NULL,
    [Description] NVARCHAR(200) NULL,
    [ParentCategoryId] INT NULL,
    [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE()
);
/*END_MSSQL_STATEMENT_11*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_11*/
CREATE TABLE productmanagement_dbo.categories(
    categoryid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    parentcategoryid INTEGER NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);
/*END_PGSQL_STATEMENT_11*/

-- --------------------------------------------------------------------------
-- Statement 12: ALTER TABLE Categories (self-referencing FK)
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 26-28
-- Type: DDL - ALTER TABLE
-- Context: Adds self-referencing foreign key
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_12*/
ALTER TABLE [dbo].[Categories]
ADD CONSTRAINT FK_Categories_Categories 
FOREIGN KEY ([ParentCategoryId]) REFERENCES [dbo].[Categories] ([CategoryId]);
/*END_MSSQL_STATEMENT_12*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_12*/
ALTER TABLE productmanagement_dbo.categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parentcategoryid) REFERENCES productmanagement_dbo.categories (categoryid);
/*END_PGSQL_STATEMENT_12*/

-- --------------------------------------------------------------------------
-- Statement 13: CREATE TABLE Suppliers
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 31-40
-- Type: DDL - CREATE TABLE
-- Context: Creates Suppliers table
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_13*/
CREATE TABLE [dbo].[Suppliers](
    [SupplierId] INT IDENTITY(1,1) PRIMARY KEY,
    [Name] NVARCHAR(100) NOT NULL,
    [ContactName] NVARCHAR(100) NULL,
    [Email] NVARCHAR(100) NULL,
    [Phone] NVARCHAR(20) NULL,
    [Address] NVARCHAR(200) NULL,
    [Country] NVARCHAR(50) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE()
);
/*END_MSSQL_STATEMENT_13*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_13*/
CREATE TABLE productmanagement_dbo.suppliers(
    supplierid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(200) NULL,
    country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT TRUE,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);
/*END_PGSQL_STATEMENT_13*/

-- --------------------------------------------------------------------------
-- Statement 14: CREATE TABLE Products
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 43-60
-- Type: DDL - CREATE TABLE
-- Context: Creates Products table with foreign keys
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_14*/
CREATE TABLE [dbo].[Products](
    [ProductId] INT IDENTITY(1,1) PRIMARY KEY,
    [Name] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [Price] DECIMAL(18, 2) NOT NULL,
    [StockQuantity] INT NOT NULL,
    [CategoryId] INT NULL,
    [SupplierId] INT NULL,
    [SKU] NVARCHAR(50) NULL,
    [Weight] DECIMAL(10, 2) NULL,
    [Dimensions] NVARCHAR(50) NULL,
    [IsDiscontinued] BIT NOT NULL DEFAULT 0,
    [ReorderLevel] INT NOT NULL DEFAULT 10,
    [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
    [ModifiedDate] DATETIME NULL,
    CONSTRAINT FK_Products_Categories FOREIGN KEY ([CategoryId]) 
        REFERENCES [dbo].[Categories] ([CategoryId]),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY ([SupplierId]) 
        REFERENCES [dbo].[Suppliers] ([SupplierId])
);
/*END_MSSQL_STATEMENT_14*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_14*/
CREATE TABLE productmanagement_dbo.products(
    productid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    categoryid INTEGER NULL,
    supplierid INTEGER NULL,
    sku VARCHAR(50) NULL,
    weight NUMERIC(10, 2) NULL,
    dimensions VARCHAR(50) NULL,
    isdiscontinued BOOLEAN NOT NULL DEFAULT FALSE,
    reorderlevel INTEGER NOT NULL DEFAULT 10,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid) 
        REFERENCES productmanagement_dbo.categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid) 
        REFERENCES productmanagement_dbo.suppliers (supplierid)
);
/*END_PGSQL_STATEMENT_14*/

-- --------------------------------------------------------------------------
-- Statement 15: CREATE TABLE ProductHistory
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 63-73
-- Type: DDL - CREATE TABLE
-- Context: Creates ProductHistory table
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_15*/
CREATE TABLE [dbo].[ProductHistory](
    [HistoryId] INT IDENTITY(1,1) PRIMARY KEY,
    [ProductId] INT NOT NULL,
    [Action] NVARCHAR(10) NOT NULL,
    [OldPrice] DECIMAL(18, 2) NULL,
    [NewPrice] DECIMAL(18, 2) NULL,
    [OldStock] INT NULL,
    [NewStock] INT NULL,
    [ActionDate] DATETIME NOT NULL DEFAULT GETDATE(),
    [ModifiedBy] NVARCHAR(100) NULL,
    CONSTRAINT FK_ProductHistory_Products FOREIGN KEY ([ProductId]) 
        REFERENCES [dbo].[Products] ([ProductId])
);
/*END_MSSQL_STATEMENT_15*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_15*/
CREATE TABLE productmanagement_dbo.producthistory(
    historyid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice NUMERIC(18, 2) NULL,
    newprice NUMERIC(18, 2) NULL,
    oldstock INTEGER NULL,
    newstock INTEGER NULL,
    actiondate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifiedby VARCHAR(100) NULL,
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid) 
        REFERENCES productmanagement_dbo.products (productid)
);
/*END_PGSQL_STATEMENT_15*/

-- --------------------------------------------------------------------------
-- Statement 16: CREATE TABLE ProductStats
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 76-84
-- Type: DDL - CREATE TABLE
-- Context: Creates ProductStats table
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_16*/
CREATE TABLE [dbo].[ProductStats](
    [StatId] INT PRIMARY KEY DEFAULT 1,
    [TotalProducts] INT NOT NULL DEFAULT 0,
    [AveragePrice] DECIMAL(18, 2) NOT NULL DEFAULT 0,
    [TotalStockValue] DECIMAL(18, 2) NOT NULL DEFAULT 0,
    [LowStockCount] INT NOT NULL DEFAULT 0,
    [DiscontinuedCount] INT NOT NULL DEFAULT 0,
    [LastUpdated] DATETIME NOT NULL DEFAULT GETDATE()
);
/*END_MSSQL_STATEMENT_16*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_16*/
CREATE TABLE productmanagement_dbo.productstats(
    statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);
/*END_PGSQL_STATEMENT_16*/

-- --------------------------------------------------------------------------
-- Statement 17: CREATE INDEX ix_products_categoryid
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, line 87
-- Type: DDL - CREATE INDEX
-- Context: Index on Products.CategoryId
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_17*/
CREATE INDEX IX_Products_CategoryId ON [dbo].[Products] ([CategoryId]);
/*END_MSSQL_STATEMENT_17*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_17*/
CREATE INDEX ix_products_categoryid ON productmanagement_dbo.products (categoryid);
/*END_PGSQL_STATEMENT_17*/

-- --------------------------------------------------------------------------
-- Statement 18: CREATE INDEX ix_products_supplierid
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, line 89
-- Type: DDL - CREATE INDEX
-- Context: Index on Products.SupplierId
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_18*/
CREATE INDEX IX_Products_SupplierId ON [dbo].[Products] ([SupplierId]);
/*END_MSSQL_STATEMENT_18*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_18*/
CREATE INDEX ix_products_supplierid ON productmanagement_dbo.products (supplierid);
/*END_PGSQL_STATEMENT_18*/

-- --------------------------------------------------------------------------
-- Statement 19: CREATE UNIQUE INDEX ix_products_sku
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, line 91
-- Type: DDL - CREATE UNIQUE INDEX
-- Context: Unique index on Products.SKU
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_19*/
CREATE UNIQUE INDEX IX_Products_SKU ON [dbo].[Products] ([SKU]);
/*END_MSSQL_STATEMENT_19*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_19*/
CREATE UNIQUE INDEX ix_products_sku ON productmanagement_dbo.products (sku);
/*END_PGSQL_STATEMENT_19*/

-- --------------------------------------------------------------------------
-- Statement 20: CREATE INDEX ix_producthistory_productid
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, line 93
-- Type: DDL - CREATE INDEX
-- Context: Index on ProductHistory.ProductId
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_20*/
CREATE INDEX IX_ProductHistory_ProductId ON [dbo].[ProductHistory] ([ProductId]);
/*END_MSSQL_STATEMENT_20*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_20*/
CREATE INDEX ix_producthistory_productid ON productmanagement_dbo.producthistory (productid);
/*END_PGSQL_STATEMENT_20*/

-- --------------------------------------------------------------------------
-- Statement 21: CREATE INDEX ix_producthistory_actiondate
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, line 95
-- Type: DDL - CREATE INDEX
-- Context: Index on ProductHistory.ActionDate
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_21*/
CREATE INDEX IX_ProductHistory_ActionDate ON [dbo].[ProductHistory] ([ActionDate]);
/*END_MSSQL_STATEMENT_21*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_21*/
CREATE INDEX ix_producthistory_actiondate ON productmanagement_dbo.producthistory (actiondate);
/*END_PGSQL_STATEMENT_21*/

-- --------------------------------------------------------------------------
-- Statement 22: INSERT Categories
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 98-118
-- Type: DML - INSERT
-- Context: Inserts sample categories
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_22*/
INSERT INTO [dbo].[Categories] ([Name], [Description], [ParentCategoryId])
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
    ('Switches', 'Network switches', 8);
/*END_MSSQL_STATEMENT_22*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_22*/
INSERT INTO productmanagement_dbo.categories (name, description, parentcategoryid)
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
    ('Switches', 'Network switches', 8);
/*END_PGSQL_STATEMENT_22*/

-- --------------------------------------------------------------------------
-- Statement 23: INSERT Suppliers
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 121-129
-- Type: DML - INSERT
-- Context: Inserts sample suppliers
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_23*/
INSERT INTO [dbo].[Suppliers] ([Name], [ContactName], [Email], [Phone], [Address], [Country])
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');
/*END_MSSQL_STATEMENT_23*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_23*/
INSERT INTO productmanagement_dbo.suppliers (name, contactname, email, phone, address, country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');
/*END_PGSQL_STATEMENT_23*/

-- --------------------------------------------------------------------------
-- Statement 24: INSERT Products
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 132-152
-- Type: DML - INSERT
-- Context: Inserts sample products
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_24*/
INSERT INTO [dbo].[Products] ([Name], [Description], [Price], [StockQuantity], [CategoryId], [SupplierId], [SKU], [Weight], [Dimensions], [ReorderLevel])
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
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4);
/*END_MSSQL_STATEMENT_24*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_24*/
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, categoryid, supplierid, sku, weight, dimensions, reorderlevel)
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
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4);
/*END_PGSQL_STATEMENT_24*/

-- --------------------------------------------------------------------------
-- Statement 25: INSERT ProductStats initial record
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 155-156
-- Type: DML - INSERT
-- Context: Inserts initial statistics record
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_25*/
INSERT INTO [dbo].[ProductStats] ([StatId], [TotalProducts], [AveragePrice], [TotalStockValue], [LowStockCount], [DiscontinuedCount], [LastUpdated])
VALUES (1, 0, 0, 0, 0, 0, GETDATE());
/*END_MSSQL_STATEMENT_25*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_25*/
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, clock_timestamp());
/*END_PGSQL_STATEMENT_25*/

-- --------------------------------------------------------------------------
-- Statement 26: UPDATE ProductStats
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 159-165
-- Type: DML - UPDATE with subqueries
-- Context: Updates initial statistics
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_26*/
UPDATE [dbo].[ProductStats]
SET TotalProducts = (SELECT COUNT(*) FROM [dbo].[Products]),
    AveragePrice = (SELECT AVG(Price) FROM [dbo].[Products]),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM [dbo].[Products]),
    LowStockCount = (SELECT COUNT(*) FROM [dbo].[Products] WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM [dbo].[Products] WHERE IsDiscontinued = 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;
/*END_MSSQL_STATEMENT_26*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_26*/
UPDATE productmanagement_dbo.productstats
SET totalproducts = (SELECT COUNT(*) FROM productmanagement_dbo.products),
    averageprice = (SELECT AVG(price) FROM productmanagement_dbo.products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM productmanagement_dbo.products),
    lowstockcount = (SELECT COUNT(*) FROM productmanagement_dbo.products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM productmanagement_dbo.products WHERE isdiscontinued = TRUE),
    lastupdated = clock_timestamp()
WHERE statid = 1;
/*END_PGSQL_STATEMENT_26*/

-- --------------------------------------------------------------------------
-- Statement 27: CREATE TRIGGER FUNCTION trg_products_history_func
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 168-196
-- Type: DDL - CREATE FUNCTION (trigger function)
-- Context: Trigger function for product history tracking
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_27*/
CREATE TRIGGER [dbo].[trg_Products_History]
ON [dbo].[Products]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Handle INSERT
    INSERT INTO [dbo].[ProductHistory] ([ProductId], [Action], [NewPrice], [NewStock], [ModifiedBy])
    SELECT i.ProductId, 'INSERT', i.Price, i.StockQuantity, SYSTEM_USER
    FROM inserted i
    LEFT JOIN deleted d ON i.ProductId = d.ProductId
    WHERE d.ProductId IS NULL;
    
    -- Handle UPDATE
    INSERT INTO [dbo].[ProductHistory] ([ProductId], [Action], [OldPrice], [NewPrice], [OldStock], [NewStock], [ModifiedBy])
    SELECT i.ProductId, 'UPDATE', d.Price, i.Price, d.StockQuantity, i.StockQuantity, SYSTEM_USER
    FROM inserted i
    INNER JOIN deleted d ON i.ProductId = d.ProductId
    WHERE i.Price <> d.Price OR i.StockQuantity <> d.StockQuantity;
    
    -- Handle DELETE
    INSERT INTO [dbo].[ProductHistory] ([ProductId], [Action], [OldPrice], [OldStock], [ModifiedBy])
    SELECT d.ProductId, 'DELETE', d.Price, d.StockQuantity, SYSTEM_USER
    FROM deleted d
    LEFT JOIN inserted i ON d.ProductId = i.ProductId
    WHERE i.ProductId IS NULL;
END;
/*END_MSSQL_STATEMENT_27*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_27*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.trg_products_history_func()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- Handle INSERT
    IF TG_OP = 'INSERT' THEN
        INSERT INTO productmanagement_dbo.producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user);
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE
    IF TG_OP = 'UPDATE' THEN
        IF NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity THEN
            INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, current_user);
        END IF;
        RETURN NEW;
    END IF;
    
    -- Handle DELETE
    IF TG_OP = 'DELETE' THEN
        INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, current_user);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;
/*END_PGSQL_STATEMENT_27*/

-- --------------------------------------------------------------------------
-- Statement 28: CREATE TRIGGER trg_products_history
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 198-200
-- Type: DDL - CREATE TRIGGER
-- Context: Attaches trigger to products table
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
-- (Included in Statement 27 for MS SQL Server as trigger creation includes the body)
/*MSSQL_STATEMENT_28*/
-- Trigger creation is part of Statement 27 in MS SQL Server.
-- In PostgreSQL, trigger and function are separate. This is the trigger attachment.
/*END_MSSQL_STATEMENT_28*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_28*/
CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON productmanagement_dbo.products
FOR EACH ROW EXECUTE FUNCTION productmanagement_dbo.trg_products_history_func();
/*END_PGSQL_STATEMENT_28*/

-- --------------------------------------------------------------------------
-- Statement 29: CREATE FUNCTION sp_getallproducts
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 203-211
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Stored procedure/function to get all products
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_29*/
CREATE PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM [dbo].[Products]
    ORDER BY Name;
END;
/*END_MSSQL_STATEMENT_29*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_29*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p.productid::INTEGER, p.name::VARCHAR, p.description::VARCHAR, p.price::NUMERIC, p.stockquantity::INTEGER, p.createddate::TIMESTAMP, p.modifieddate::TIMESTAMP
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$;
/*END_PGSQL_STATEMENT_29*/

-- --------------------------------------------------------------------------
-- Statement 30: CREATE FUNCTION sp_getproductbyid
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 214-222
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Stored procedure/function to get product by ID
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_30*/
CREATE PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId;
END;
/*END_MSSQL_STATEMENT_30*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_30*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p.productid::INTEGER, p.name::VARCHAR, p.description::VARCHAR, p.price::NUMERIC, p.stockquantity::INTEGER, p.createddate::TIMESTAMP, p.modifieddate::TIMESTAMP
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$;
/*END_PGSQL_STATEMENT_30*/

-- --------------------------------------------------------------------------
-- Statement 31: CREATE FUNCTION sp_insertproduct
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 225-237
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Stored procedure/function to insert a product
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_31*/
CREATE PROCEDURE [dbo].[sp_InsertProduct]
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [dbo].[Products] ([Name], [Description], [Price], [StockQuantity])
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SELECT SCOPE_IDENTITY() AS ProductId;
END;
/*END_MSSQL_STATEMENT_31*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_31*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productmanagement_dbo.products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$;
/*END_PGSQL_STATEMENT_31*/

-- --------------------------------------------------------------------------
-- Statement 32: CREATE FUNCTION sp_updateproduct
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 240-254
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Stored procedure/function to update a product
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_32*/
CREATE PROCEDURE [dbo].[sp_UpdateProduct]
    @ProductId INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [dbo].[Products]
    SET [Name] = @Name,
        [Description] = @Description,
        [Price] = @Price,
        [StockQuantity] = @StockQuantity,
        [ModifiedDate] = GETDATE()
    WHERE [ProductId] = @ProductId;
END;
/*END_MSSQL_STATEMENT_32*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_32*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE productmanagement_dbo.products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = p_productid;
END;
$$;
/*END_PGSQL_STATEMENT_32*/

-- --------------------------------------------------------------------------
-- Statement 33: CREATE FUNCTION sp_deleteproduct
-- Source: sourceCode/Database/Scripts/01_InitialSetup.sql, lines 257-264
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Stored procedure/function to delete a product
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_33*/
CREATE PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [dbo].[Products]
    WHERE [ProductId] = @ProductId;
END;
/*END_MSSQL_STATEMENT_33*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_33*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$;
/*END_PGSQL_STATEMENT_33*/

-- ============================================================================
-- SECTION 3: Scripts/01_InitialSetup.sql - DDL Statements
-- ============================================================================

-- --------------------------------------------------------------------------
-- Statement 34: CREATE SCHEMA (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql, line 5
-- Type: DDL - CREATE SCHEMA
-- Context: Creates the schema (duplicate in Scripts directory)
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_34*/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]')
END;
/*END_MSSQL_STATEMENT_34*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_34*/
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;
/*END_PGSQL_STATEMENT_34*/

-- --------------------------------------------------------------------------
-- Statement 35: CREATE TABLE Products (Scripts version - simplified)
-- Source: sourceCode/Scripts/01_InitialSetup.sql, lines 8-15
-- Type: DDL - CREATE TABLE
-- Context: Creates Products table (simplified version in Scripts directory)
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_35*/
CREATE TABLE [dbo].[Products](
    [ProductId] INT IDENTITY(1,1) PRIMARY KEY,
    [Name] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [Price] DECIMAL(18, 2) NOT NULL,
    [StockQuantity] INT NOT NULL,
    [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
    [ModifiedDate] DATETIME NULL
);
/*END_MSSQL_STATEMENT_35*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_35*/
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products
(productid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL);
/*END_PGSQL_STATEMENT_35*/

-- --------------------------------------------------------------------------
-- Statement 36: CREATE FUNCTION sp_getallproducts (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql, lines 18-26
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Same as Statement 29 (duplicate in Scripts directory)
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_36*/
CREATE PROCEDURE [dbo].[sp_GetAllProducts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM [dbo].[Products]
    ORDER BY Name;
END;
/*END_MSSQL_STATEMENT_36*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_36*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p.productid::INTEGER, p.name::VARCHAR, p.description::VARCHAR, p.price::NUMERIC, p.stockquantity::INTEGER, p.createddate::TIMESTAMP, p.modifieddate::TIMESTAMP
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$;
/*END_PGSQL_STATEMENT_36*/

-- --------------------------------------------------------------------------
-- Statement 37: CREATE FUNCTION sp_getproductbyid (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql, lines 29-37
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Same as Statement 30 (duplicate in Scripts directory)
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_37*/
CREATE PROCEDURE [dbo].[sp_GetProductById]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate
    FROM [dbo].[Products]
    WHERE ProductId = @ProductId;
END;
/*END_MSSQL_STATEMENT_37*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_37*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p.productid::INTEGER, p.name::VARCHAR, p.description::VARCHAR, p.price::NUMERIC, p.stockquantity::INTEGER, p.createddate::TIMESTAMP, p.modifieddate::TIMESTAMP
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$;
/*END_PGSQL_STATEMENT_37*/

-- --------------------------------------------------------------------------
-- Statement 38: CREATE FUNCTION sp_insertproduct (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql, lines 40-52
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Same as Statement 31 (duplicate in Scripts directory)
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_38*/
CREATE PROCEDURE [dbo].[sp_InsertProduct]
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [dbo].[Products] ([Name], [Description], [Price], [StockQuantity])
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SELECT SCOPE_IDENTITY() AS ProductId;
END;
/*END_MSSQL_STATEMENT_38*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_38*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productmanagement_dbo.products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$;
/*END_PGSQL_STATEMENT_38*/

-- --------------------------------------------------------------------------
-- Statement 39: CREATE FUNCTION sp_updateproduct (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql, lines 55-69
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Same as Statement 32 (duplicate in Scripts directory)
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_39*/
CREATE PROCEDURE [dbo].[sp_UpdateProduct]
    @ProductId INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500),
    @Price DECIMAL(18,2),
    @StockQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [dbo].[Products]
    SET [Name] = @Name,
        [Description] = @Description,
        [Price] = @Price,
        [StockQuantity] = @StockQuantity,
        [ModifiedDate] = GETDATE()
    WHERE [ProductId] = @ProductId;
END;
/*END_MSSQL_STATEMENT_39*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_39*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE productmanagement_dbo.products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = p_productid;
END;
$$;
/*END_PGSQL_STATEMENT_39*/

-- --------------------------------------------------------------------------
-- Statement 40: CREATE FUNCTION sp_deleteproduct (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql, lines 72-79
-- Type: DDL - CREATE PROCEDURE/FUNCTION
-- Context: Same as Statement 33 (duplicate in Scripts directory)
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_40*/
CREATE PROCEDURE [dbo].[sp_DeleteProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM [dbo].[Products]
    WHERE [ProductId] = @ProductId;
END;
/*END_MSSQL_STATEMENT_40*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_40*/
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$;
/*END_PGSQL_STATEMENT_40*/

-- --------------------------------------------------------------------------
-- Statement 41: INSERT Sample Data (Scripts version)
-- Source: sourceCode/Scripts/01_InitialSetup.sql, lines 82-88
-- Type: DML - INSERT (via stored procedure)
-- Context: Inserts sample data using stored procedure
-- --------------------------------------------------------------------------

-- ORIGINAL MS SQL SERVER VERSION:
/*MSSQL_STATEMENT_41*/
IF NOT EXISTS (SELECT 1 FROM [dbo].[Products])
BEGIN
    EXEC [dbo].[sp_InsertProduct] @Name = 'Laptop', @Description = 'High-performance laptop', @Price = 999.99, @StockQuantity = 10;
    EXEC [dbo].[sp_InsertProduct] @Name = 'Mouse', @Description = 'Wireless gaming mouse', @Price = 49.99, @StockQuantity = 20;
    EXEC [dbo].[sp_InsertProduct] @Name = 'Keyboard', @Description = 'Mechanical keyboard', @Price = 129.99, @StockQuantity = 15;
END;
/*END_MSSQL_STATEMENT_41*/

-- CURRENT POSTGRESQL VERSION:
/*PGSQL_STATEMENT_41*/
DO $$ BEGIN
IF NOT EXISTS (SELECT 1 FROM productmanagement_dbo.products LIMIT 1) THEN
    PERFORM productmanagement_dbo.sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
    PERFORM productmanagement_dbo.sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
    PERFORM productmanagement_dbo.sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
END IF;
END $$;
/*END_PGSQL_STATEMENT_41*/

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Total statements extracted: 41
-- From ProductRepository.cs: 7 (Statements 1-7)
-- From Database/Scripts/01_InitialSetup.sql: 26 (Statements 8-33)
-- From Scripts/01_InitialSetup.sql: 8 (Statements 34-41)
-- ============================================================================
