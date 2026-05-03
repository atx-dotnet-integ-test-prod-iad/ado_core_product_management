-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- All statements attempted DMS conversion - ALL FAILED with error:
-- "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- Manual conversion applied with lowercase schema object names per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync() 
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL:
-- WITH ProductStats AS (
--     SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts FROM Products
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name;

-- CONVERTED PostgreSQL:
WITH productstats_cte AS (
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
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync()
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL:
-- WITH ProductHistory AS (
--     SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
--     FROM Products WHERE ProductId = @ProductId
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     ph.PreviousPrice, ph.PreviousStock,
--     CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END as PriceChangePercentage
-- FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId WHERE p.ProductId = @ProductId;

-- CONVERTED PostgreSQL:
WITH producthistory_cte AS (
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
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync() - Transaction Block
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp()
-- ============================================================================
-- ORIGINAL MS SQL:
-- DECLARE @NewProductId INT;
-- BEGIN TRANSACTION;
--     INSERT INTO Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity);
--     SET @NewProductId = SCOPE_IDENTITY();
--     INSERT INTO ProductHistory (...) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     UPDATE ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = ..., LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;

-- CONVERTED PostgreSQL (3 separate statements in transaction):
-- Statement 3a: Insert product and return new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Insert history record
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Statement 3c: Update stats
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync() - Transaction Block
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: GETDATE() -> clock_timestamp()
-- ============================================================================
-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
--     SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
--     UPDATE Products SET Name = @Name, ..., ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
--     INSERT INTO ProductHistory (...) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
--     UPDATE ProductStats SET AveragePrice = ..., LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;

-- CONVERTED PostgreSQL (4 separate statements in transaction):
-- Statement 4a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 4b: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Statement 4c: Insert history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Statement 4d: Update stats
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync() - Transaction Block
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: GETDATE() -> clock_timestamp()
-- ============================================================================
-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
--     SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
--     INSERT INTO ProductHistory (...) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
--     DELETE FROM Products WHERE ProductId = @ProductId;
--     UPDATE ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE ... END, LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;

-- CONVERTED PostgreSQL (4 separate statements in transaction):
-- Statement 5a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 5b: Insert history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Statement 5c: Delete product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 5d: Update stats
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync()
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: (CTE with RANK, PERCENT_RANK, BETWEEN)

-- CONVERTED PostgreSQL:
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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync()
-- Source: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: CAST(StockQuantity AS DECIMAL) -> CAST(stockquantity AS NUMERIC)
-- ============================================================================
-- ORIGINAL MS SQL: (CTE with AVG, MIN, MAX window functions, CAST AS DECIMAL)

-- CONVERTED PostgreSQL:
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================================
-- STATEMENT 8: Create Products Table (Simple)
-- Source: Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: IDENTITY(1,1)->GENERATED ALWAYS AS IDENTITY, nvarchar->VARCHAR, datetime->TIMESTAMP, GETDATE()->CURRENT_TIMESTAMP
-- ============================================================================
-- ORIGINAL MS SQL: CREATE TABLE [dbo].[Products](...) with IDENTITY, nvarchar, datetime, GETDATE()

-- CONVERTED PostgreSQL:
CREATE TABLE IF NOT EXISTS products(
    productid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP NULL
);

-- ============================================================================
-- STATEMENT 9: Stored Procedure sp_GetAllProducts
-- Source: Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: PROCEDURE->FUNCTION, SET NOCOUNT ON removed
-- ============================================================================
-- ORIGINAL MS SQL: CREATE OR ALTER PROCEDURE [dbo].[sp_GetAllProducts]

-- CONVERTED PostgreSQL:
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$;

-- ============================================================================
-- STATEMENT 10: Stored Procedure sp_GetProductById
-- Source: Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: CREATE OR ALTER PROCEDURE [dbo].[sp_GetProductById] @ProductId INT

-- CONVERTED PostgreSQL:
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$;

-- ============================================================================
-- STATEMENT 11: Stored Procedure sp_InsertProduct
-- Source: Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: SCOPE_IDENTITY() -> RETURNING, NVARCHAR->VARCHAR
-- ============================================================================
-- ORIGINAL MS SQL: CREATE OR ALTER PROCEDURE [dbo].[sp_InsertProduct] with SCOPE_IDENTITY()

-- CONVERTED PostgreSQL:
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name VARCHAR(100), p_description VARCHAR(500), p_price NUMERIC(18,2), p_stockquantity INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    RETURN v_productid;
END;
$$;

-- ============================================================================
-- STATEMENT 12: Stored Procedure sp_UpdateProduct
-- Source: Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: GETDATE() -> CURRENT_TIMESTAMP, NVARCHAR->VARCHAR
-- ============================================================================
-- ORIGINAL MS SQL: CREATE OR ALTER PROCEDURE [dbo].[sp_UpdateProduct] with GETDATE()

-- CONVERTED PostgreSQL:
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid INTEGER, p_name VARCHAR(100), p_description VARCHAR(500), p_price NUMERIC(18,2), p_stockquantity INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = p_productid;
END;
$$;

-- ============================================================================
-- STATEMENT 13: Stored Procedure sp_DeleteProduct
-- Source: Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: CREATE OR ALTER PROCEDURE [dbo].[sp_DeleteProduct] @ProductId INT

-- CONVERTED PostgreSQL:
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$;

-- ============================================================================
-- STATEMENT 14: Insert Sample Data via Stored Procedure
-- Source: Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: EXEC -> SELECT (function call)
-- ============================================================================
-- ORIGINAL MS SQL: EXEC sp_InsertProduct 'Laptop', 'High-performance laptop', 999.99, 10; (x3)

-- CONVERTED PostgreSQL:
SELECT sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
SELECT sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
SELECT sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);

-- ============================================================================
-- STATEMENT 15: Create Categories Table
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: CREATE TABLE [dbo].[Categories](...) with IDENTITY, nvarchar, datetime, GETDATE()

-- CONVERTED PostgreSQL:
CREATE TABLE IF NOT EXISTS categories(
    categoryid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    parentcategoryid INTEGER NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parentcategoryid) REFERENCES categories (categoryid);

-- ============================================================================
-- STATEMENT 16: Create Suppliers Table
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: bit->BOOLEAN, DEFAULT 1->DEFAULT TRUE
-- ============================================================================
-- ORIGINAL MS SQL: CREATE TABLE [dbo].[Suppliers](...) with IDENTITY, nvarchar, bit, GETDATE()

-- CONVERTED PostgreSQL:
CREATE TABLE IF NOT EXISTS suppliers(
    supplierid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(200) NULL,
    country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT TRUE,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STATEMENT 17: Create Products Table (Complex - with FK references)
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: CREATE TABLE [dbo].[Products](...) with IDENTITY, nvarchar, decimal, bit, FK constraints

-- CONVERTED PostgreSQL:
CREATE TABLE IF NOT EXISTS products(
    productid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP NULL,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid) 
        REFERENCES categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid) 
        REFERENCES suppliers (supplierid)
);

-- ============================================================================
-- STATEMENT 18: Create ProductHistory Table
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: CREATE TABLE [dbo].[ProductHistory](...) with IDENTITY, varchar, decimal, GETDATE(), FK

-- CONVERTED PostgreSQL:
CREATE TABLE IF NOT EXISTS producthistory(
    historyid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice NUMERIC(18, 2) NULL,
    newprice NUMERIC(18, 2) NULL,
    oldstock INTEGER NULL,
    newstock INTEGER NULL,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedby VARCHAR(100) NULL,
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid) 
        REFERENCES products (productid)
);

-- ============================================================================
-- STATEMENT 19: Create ProductStats Table
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: CREATE TABLE [dbo].[ProductStats](...) with defaults, GETDATE()

-- CONVERTED PostgreSQL:
CREATE TABLE IF NOT EXISTS productstats(
    statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STATEMENT 20: Insert Sample Categories
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: INSERT INTO Categories (Name, Description, ParentCategoryId) VALUES (...)

-- CONVERTED PostgreSQL:
INSERT INTO categories (name, description, parentcategoryid)
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

-- ============================================================================
-- STATEMENT 21: Insert Sample Suppliers
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: INSERT INTO Suppliers (Name, ...) VALUES (...)

-- CONVERTED PostgreSQL:
INSERT INTO suppliers (name, contactname, email, phone, address, country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');

-- ============================================================================
-- STATEMENT 22: Insert Sample Products
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
-- ORIGINAL MS SQL: INSERT INTO Products (Name, ...) VALUES (...)

-- CONVERTED PostgreSQL:
INSERT INTO products (name, description, price, stockquantity, categoryid, supplierid, sku, weight, dimensions, reorderlevel)
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

-- ============================================================================
-- STATEMENT 23: Insert Initial Stats Record
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: GETDATE() -> CURRENT_TIMESTAMP
-- ============================================================================
-- ORIGINAL MS SQL: INSERT INTO ProductStats (...) VALUES (1, 0, 0, 0, 0, 0, GETDATE());

-- CONVERTED PostgreSQL:
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, CURRENT_TIMESTAMP);

-- ============================================================================
-- STATEMENT 24: Update Initial Statistics
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: GETDATE() -> CURRENT_TIMESTAMP, IsDiscontinued = 1 -> isdiscontinued = TRUE
-- ============================================================================
-- ORIGINAL MS SQL: UPDATE ProductStats SET ... = (SELECT ...), LastUpdated = GETDATE() WHERE StatId = 1;

-- CONVERTED PostgreSQL:
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM products),
    lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = TRUE),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 25: Create Trigger trg_Products_History
-- Source: Database/Scripts/01_InitialSetup.sql
-- DMS Status: FAILED - Metadata model creation failed
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Key conversions: TRIGGER -> FUNCTION + TRIGGER, SYSTEM_USER -> CURRENT_USER, inserted/deleted -> NEW/OLD with TG_OP
-- ============================================================================
-- ORIGINAL MS SQL: CREATE TRIGGER [dbo].[trg_Products_History] ON [dbo].[Products] AFTER INSERT, UPDATE, DELETE ...

-- CONVERTED PostgreSQL:
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, CURRENT_USER);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity THEN
            INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, CURRENT_USER);
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, CURRENT_USER);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW EXECUTE FUNCTION trg_products_history_func();

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total: 25 statements converted
-- DMS conversion attempts: 25 (all failed)
-- Manual conversions: 25 (all with lowercase schema names)
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- ============================================================================
