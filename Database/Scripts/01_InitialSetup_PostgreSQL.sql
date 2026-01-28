-- PostgreSQL Database Setup Script
-- This script creates the ProductManagement database and all required objects for PostgreSQL

-- Create database (run this separately as a superuser if needed)
-- CREATE DATABASE "ProductManagement";

-- Connect to the database
\c ProductManagement;

-- Drop existing objects in correct order
DROP TRIGGER IF EXISTS trg_Products_History ON Products;
DROP TABLE IF EXISTS ProductHistory CASCADE;
DROP TABLE IF EXISTS Products CASCADE;
DROP TABLE IF EXISTS Categories CASCADE;
DROP TABLE IF EXISTS Suppliers CASCADE;
DROP TABLE IF EXISTS ProductStats CASCADE;

-- Create Categories Table
CREATE TABLE Categories (
    CategoryId SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Description VARCHAR(200),
    ParentCategoryId INTEGER,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add self-referencing foreign key for Categories
ALTER TABLE Categories
ADD CONSTRAINT FK_Categories_Categories 
FOREIGN KEY (ParentCategoryId) REFERENCES Categories (CategoryId);

-- Create Suppliers Table
CREATE TABLE Suppliers (
    SupplierId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    ContactName VARCHAR(100),
    Email VARCHAR(100),
    Phone VARCHAR(20),
    Address VARCHAR(200),
    Country VARCHAR(50),
    IsActive BOOLEAN NOT NULL DEFAULT true,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create Products Table
CREATE TABLE Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500),
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CategoryId INTEGER,
    SupplierId INTEGER,
    SKU VARCHAR(50),
    Weight DECIMAL(10, 2),
    Dimensions VARCHAR(50),
    IsDiscontinued BOOLEAN NOT NULL DEFAULT false,
    ReorderLevel INTEGER NOT NULL DEFAULT 10,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) 
        REFERENCES Categories (CategoryId),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierId) 
        REFERENCES Suppliers (SupplierId)
);

-- Create ProductHistory Table
CREATE TABLE ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(10) NOT NULL,
    OldPrice DECIMAL(18, 2),
    NewPrice DECIMAL(18, 2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedBy VARCHAR(100),
    CONSTRAINT FK_ProductHistory_Products FOREIGN KEY (ProductId) 
        REFERENCES Products (ProductId)
);

-- Create ProductStats Table
CREATE TABLE ProductStats (
    StatId INTEGER PRIMARY KEY DEFAULT 1,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    TotalStockValue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    LowStockCount INTEGER NOT NULL DEFAULT 0,
    DiscontinuedCount INTEGER NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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
VALUES (1, 0, 0, 0, 0, 0, CURRENT_TIMESTAMP);

-- Update initial statistics
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = true),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Create Trigger Function for Product History
CREATE OR REPLACE FUNCTION trg_Products_History_Function()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO ProductHistory (ProductId, Action, NewPrice, NewStock, ModifiedBy)
        VALUES (
            NEW.ProductId,
            'INSERT',
            NEW.Price,
            NEW.StockQuantity,
            CURRENT_USER
        );
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
        IF (NEW.Price <> OLD.Price OR NEW.StockQuantity <> OLD.StockQuantity) THEN
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ModifiedBy)
            VALUES (
                NEW.ProductId,
                'UPDATE',
                OLD.Price,
                NEW.Price,
                OLD.StockQuantity,
                NEW.StockQuantity,
                CURRENT_USER
            );
        END IF;
        RETURN NEW;
    END IF;
    
    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO ProductHistory (ProductId, Action, OldPrice, OldStock, ModifiedBy)
        VALUES (
            OLD.ProductId,
            'DELETE',
            OLD.Price,
            OLD.StockQuantity,
            CURRENT_USER
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create Trigger
CREATE TRIGGER trg_Products_History
AFTER INSERT OR UPDATE OR DELETE ON Products
FOR EACH ROW
EXECUTE FUNCTION trg_Products_History_Function();

-- Create Functions (PostgreSQL equivalent to Stored Procedures)
-- Function for Getting All Products
CREATE OR REPLACE FUNCTION sp_GetAllProducts()
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price DECIMAL(18,2),
    StockQuantity INTEGER,
    CreatedDate TIMESTAMP,
    ModifiedDate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    ORDER BY p.Name;
END;
$$ LANGUAGE plpgsql;

-- Function for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_GetProductById(p_ProductId INTEGER)
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price DECIMAL(18,2),
    StockQuantity INTEGER,
    CreatedDate TIMESTAMP,
    ModifiedDate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    WHERE p.ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Function for Inserting Product
CREATE OR REPLACE FUNCTION sp_InsertProduct(
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price DECIMAL(18,2),
    p_StockQuantity INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    v_ProductId INTEGER;
BEGIN
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (p_Name, p_Description, p_Price, p_StockQuantity)
    RETURNING ProductId INTO v_ProductId;
    
    RETURN v_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Function for Updating Product
CREATE OR REPLACE FUNCTION sp_UpdateProduct(
    p_ProductId INTEGER,
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price DECIMAL(18,2),
    p_StockQuantity INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE Products
    SET Name = p_Name,
        Description = p_Description,
        Price = p_Price,
        StockQuantity = p_StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Function for Deleting Product
CREATE OR REPLACE FUNCTION sp_DeleteProduct(p_ProductId INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM Products
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions (adjust username as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres;
