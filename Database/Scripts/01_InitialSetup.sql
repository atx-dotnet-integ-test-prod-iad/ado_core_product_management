-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is done outside of a script context
-- CREATE DATABASE ProductManagement;

-- Drop existing objects in correct order
DROP TRIGGER IF EXISTS trg_Products_History ON Products;
DROP TABLE IF EXISTS ProductHistory CASCADE;
DROP TABLE IF EXISTS Products CASCADE;
DROP TABLE IF EXISTS Categories CASCADE;
DROP TABLE IF EXISTS Suppliers CASCADE;
DROP TABLE IF EXISTS ProductStats CASCADE;

-- Create Categories Table
CREATE TABLE Categories(
    CategoryId SERIAL PRIMARY KEY,
    Name varchar(50) NOT NULL,
    Description varchar(200) NULL,
    ParentCategoryId int NULL,
    CreatedDate timestamp NOT NULL DEFAULT NOW()
);

-- Add self-referencing foreign key for Categories
ALTER TABLE Categories
ADD CONSTRAINT FK_Categories_Categories 
FOREIGN KEY (ParentCategoryId) REFERENCES Categories (CategoryId);

-- Create Suppliers Table
CREATE TABLE Suppliers(
    SupplierId SERIAL PRIMARY KEY,
    Name varchar(100) NOT NULL,
    ContactName varchar(100) NULL,
    Email varchar(100) NULL,
    Phone varchar(20) NULL,
    Address varchar(200) NULL,
    Country varchar(50) NULL,
    IsActive boolean NOT NULL DEFAULT true,
    CreatedDate timestamp NOT NULL DEFAULT NOW()
);

-- Create Products Table
CREATE TABLE Products(
    ProductId SERIAL PRIMARY KEY,
    Name varchar(100) NOT NULL,
    Description varchar(500) NULL,
    Price decimal(18, 2) NOT NULL,
    StockQuantity int NOT NULL,
    CategoryId int NULL,
    SupplierId int NULL,
    SKU varchar(50) NULL,
    Weight decimal(10, 2) NULL,
    Dimensions varchar(50) NULL,
    IsDiscontinued boolean NOT NULL DEFAULT false,
    ReorderLevel int NOT NULL DEFAULT 10,
    CreatedDate timestamp NOT NULL DEFAULT NOW(),
    ModifiedDate timestamp NULL,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) 
        REFERENCES Categories (CategoryId),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierId) 
        REFERENCES Suppliers (SupplierId)
);

-- Create ProductHistory Table
CREATE TABLE ProductHistory(
    HistoryId SERIAL PRIMARY KEY,
    ProductId int NOT NULL,
    Action varchar(10) NOT NULL,
    OldPrice decimal(18, 2) NULL,
    NewPrice decimal(18, 2) NULL,
    OldStock int NULL,
    NewStock int NULL,
    ActionDate timestamp NOT NULL DEFAULT NOW(),
    ModifiedBy varchar(100) NULL,
    CONSTRAINT FK_ProductHistory_Products FOREIGN KEY (ProductId) 
        REFERENCES Products (ProductId)
);

-- Create ProductStats Table
CREATE TABLE ProductStats(
    StatId int PRIMARY KEY DEFAULT 1,
    TotalProducts int NOT NULL DEFAULT 0,
    AveragePrice decimal(18, 2) NOT NULL DEFAULT 0,
    TotalStockValue decimal(18, 2) NOT NULL DEFAULT 0,
    LowStockCount int NOT NULL DEFAULT 0,
    DiscontinuedCount int NOT NULL DEFAULT 0,
    LastUpdated timestamp NOT NULL DEFAULT NOW()
);

-- Create Indexes
CREATE INDEX IX_Products_CategoryId ON Products (CategoryId);

CREATE INDEX IX_Products_SupplierId ON Products (SupplierId);

CREATE UNIQUE INDEX IX_Products_SKU ON Products (SKU);

CREATE INDEX IX_ProductHistory_ProductId ON ProductHistory (ProductId);

CREATE INDEX IX_ProductHistory_ActionDate ON ProductHistory (ActionDate);

-- Insert Sample Categories
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
    ('Switches', 'Network switches', 8);

-- Insert Sample Suppliers
INSERT INTO Suppliers (Name, ContactName, Email, Phone, Address, Country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');

-- Insert Sample Products
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
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4);

-- Insert initial stats record
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, NOW());

-- Update initial statistics
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = true),
    LastUpdated = NOW()
WHERE StatId = 1;

-- Create Trigger Function for Product History (replaces SQL Server trigger)
CREATE OR REPLACE FUNCTION fn_products_history()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO ProductHistory (ProductId, Action, NewPrice, NewStock, ModifiedBy)
        VALUES (NEW.ProductId, 'INSERT', NEW.Price, NEW.StockQuantity, current_user);
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.Price <> NEW.Price OR OLD.StockQuantity <> NEW.StockQuantity) THEN
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ModifiedBy)
            VALUES (NEW.ProductId, 'UPDATE', OLD.Price, NEW.Price, OLD.StockQuantity, NEW.StockQuantity, current_user);
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, OldStock, ModifiedBy)
        VALUES (OLD.ProductId, 'DELETE', OLD.Price, OLD.StockQuantity, current_user);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create Trigger
CREATE TRIGGER trg_Products_History
AFTER INSERT OR UPDATE OR DELETE ON Products
FOR EACH ROW
EXECUTE FUNCTION fn_products_history();

-- Create Function for Getting All Products (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_GetAllProducts()
RETURNS TABLE(
    ProductId int,
    Name varchar(100),
    Description varchar(500),
    Price decimal(18,2),
    StockQuantity int,
    CreatedDate timestamp,
    ModifiedDate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    ORDER BY p.Name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_GetProductById(p_ProductId INT)
RETURNS TABLE(
    ProductId int,
    Name varchar(100),
    Description varchar(500),
    Price decimal(18,2),
    StockQuantity int,
    CreatedDate timestamp,
    ModifiedDate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    WHERE p.ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_InsertProduct(
    p_Name varchar(100),
    p_Description varchar(500),
    p_Price decimal(18,2),
    p_StockQuantity int
) RETURNS int AS $$
DECLARE
    v_ProductId int;
BEGIN
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (p_Name, p_Description, p_Price, p_StockQuantity)
    RETURNING Products.ProductId INTO v_ProductId;
    
    RETURN v_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_UpdateProduct(
    p_ProductId INT,
    p_Name varchar(100),
    p_Description varchar(500),
    p_Price decimal(18,2),
    p_StockQuantity int
) RETURNS void AS $$
BEGIN
    UPDATE Products
    SET Name = p_Name,
        Description = p_Description,
        Price = p_Price,
        StockQuantity = p_StockQuantity,
        ModifiedDate = NOW()
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Deleting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_DeleteProduct(p_ProductId INT)
RETURNS void AS $$
BEGIN
    DELETE FROM Products
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;
