-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is typically done outside of scripts
-- CREATE DATABASE productmanagement;

-- Drop existing objects in correct order
DROP TRIGGER IF EXISTS trg_products_history ON products;
DROP TABLE IF EXISTS producthistory;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS productstats;

-- Create Categories Table
CREATE TABLE categories(
    categoryid serial PRIMARY KEY,
    name varchar(50) NOT NULL,
    description varchar(200) NULL,
    parentcategoryid integer NULL,
    createddate timestamp NOT NULL DEFAULT NOW()
);

-- Add self-referencing foreign key for Categories
ALTER TABLE categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parentcategoryid) REFERENCES categories (categoryid);

-- Create Suppliers Table
CREATE TABLE suppliers(
    supplierid serial PRIMARY KEY,
    name varchar(100) NOT NULL,
    contactname varchar(100) NULL,
    email varchar(100) NULL,
    phone varchar(20) NULL,
    address varchar(200) NULL,
    country varchar(50) NULL,
    isactive boolean NOT NULL DEFAULT true,
    createddate timestamp NOT NULL DEFAULT NOW()
);

-- Create Products Table
CREATE TABLE products(
    productid serial PRIMARY KEY,
    name varchar(100) NOT NULL,
    description varchar(500) NULL,
    price numeric(18, 2) NOT NULL,
    stockquantity integer NOT NULL,
    categoryid integer NULL,
    supplierid integer NULL,
    sku varchar(50) NULL,
    weight numeric(10, 2) NULL,
    dimensions varchar(50) NULL,
    isdiscontinued boolean NOT NULL DEFAULT false,
    reorderlevel integer NOT NULL DEFAULT 10,
    createddate timestamp NOT NULL DEFAULT NOW(),
    modifieddate timestamp NULL,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid) 
        REFERENCES categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid) 
        REFERENCES suppliers (supplierid)
);

-- Create ProductHistory Table
CREATE TABLE producthistory(
    historyid serial PRIMARY KEY,
    productid integer NOT NULL,
    action varchar(10) NOT NULL,
    oldprice numeric(18, 2) NULL,
    newprice numeric(18, 2) NULL,
    oldstock integer NULL,
    newstock integer NULL,
    actiondate timestamp NOT NULL DEFAULT NOW(),
    modifiedby varchar(100) NULL,
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid) 
        REFERENCES products (productid)
);

-- Create ProductStats Table
CREATE TABLE productstats(
    statid integer PRIMARY KEY DEFAULT 1,
    totalproducts integer NOT NULL DEFAULT 0,
    averageprice numeric(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue numeric(18, 2) NOT NULL DEFAULT 0,
    lowstockcount integer NOT NULL DEFAULT 0,
    discontinuedcount integer NOT NULL DEFAULT 0,
    lastupdated timestamp NOT NULL DEFAULT NOW()
);

-- Create Indexes
CREATE INDEX ix_products_categoryid ON products (categoryid);

CREATE INDEX ix_products_supplierid ON products (supplierid);

CREATE UNIQUE INDEX ix_products_sku ON products (sku);

CREATE INDEX ix_producthistory_productid ON producthistory (productid);

CREATE INDEX ix_producthistory_actiondate ON producthistory (actiondate);

-- Insert Sample Categories
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

-- Insert Sample Suppliers
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

-- Insert Sample Products
INSERT INTO products (name, description, price, stockquantity, categoryid, supplierid, sku, weight, dimensions, reorderlevel)
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
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, NOW());

-- Update initial statistics
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM products),
    lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = true),
    lastupdated = NOW()
WHERE statid = 1;

-- Create Trigger Function for Product History
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle INSERT
    IF TG_OP = 'INSERT' THEN
        INSERT INTO producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user);
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE
    IF TG_OP = 'UPDATE' THEN
        IF NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity THEN
            INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, current_user);
        END IF;
        RETURN NEW;
    END IF;
    
    -- Handle DELETE
    IF TG_OP = 'DELETE' THEN
        INSERT INTO producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, current_user);
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create Trigger
CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW
EXECUTE FUNCTION trg_products_history_func();

-- Create Function for Getting All Products
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE (
    productid integer,
    name varchar(100),
    description varchar(500),
    price numeric(18,2),
    stockquantity integer,
    createddate timestamp,
    modifieddate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid integer)
RETURNS TABLE (
    productid integer,
    name varchar(100),
    description varchar(500),
    price numeric(18,2),
    stockquantity integer,
    createddate timestamp,
    modifieddate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name varchar(100),
    p_description varchar(500),
    p_price numeric(18,2),
    p_stockquantity integer
)
RETURNS integer AS $$
DECLARE
    v_productid integer;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid integer,
    p_name varchar(100),
    p_description varchar(500),
    p_price numeric(18,2),
    p_stockquantity integer
)
RETURNS void AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = NOW()
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Deleting Product
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid integer)
RETURNS void AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data (only if no products exist)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN
        PERFORM sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;
