-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is typically done outside of scripts
-- CREATE DATABASE ProductManagement;

-- Drop existing objects in correct order
DROP TRIGGER IF EXISTS trg_products_history ON products;
DROP FUNCTION IF EXISTS trg_products_history_func();
DROP TABLE IF EXISTS producthistory;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS productstats;

-- Create Categories Table
CREATE TABLE categories(
    categoryid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    parentcategoryid INTEGER NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);

-- Add self-referencing foreign key for Categories
ALTER TABLE categories
ADD CONSTRAINT fk_categories_categories
FOREIGN KEY (parentcategoryid) REFERENCES categories (categoryid);

-- Create Suppliers Table
CREATE TABLE suppliers(
    supplierid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(200) NULL,
    country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT TRUE,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);

-- Create Products Table
CREATE TABLE products(
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
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid)
        REFERENCES categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid)
        REFERENCES suppliers (supplierid)
);

-- Create ProductHistory Table
CREATE TABLE producthistory(
    historyid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice NUMERIC(18, 2) NULL,
    newprice NUMERIC(18, 2) NULL,
    oldstock INTEGER NULL,
    newstock INTEGER NULL,
    actiondate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifiedby VARCHAR(100) NULL,
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid)
        REFERENCES products (productid)
);

-- Create ProductStats Table
CREATE TABLE productstats(
    statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);

-- Create Indexes
CREATE INDEX ix_products_categoryid ON products (categoryid);
CREATE INDEX ix_products_supplierid ON products (supplierid);
CREATE UNIQUE INDEX ix_products_sku ON products (sku);
CREATE INDEX ix_producthistory_productid ON producthistory (productid);
CREATE INDEX ix_producthistory_actiondate ON producthistory (actiondate);

-- TODO: Insert sample data in sections to stay within tool limits
-- Insert Sample Categories
INSERT INTO categories (name, description, parentcategoryid) VALUES
    ('Electronics', 'Electronic devices and accessories', NULL),
    ('Computers', 'Computers and related equipment', NULL),
    ('Peripherals', 'Computer peripherals and accessories', NULL),
    ('Audio', 'Audio equipment and accessories', NULL),
    ('Storage', 'Data storage devices', NULL),
    ('Gaming', 'Gaming equipment and accessories', NULL),
    ('Office', 'Office equipment and supplies', NULL),
    ('Networking', 'Networking equipment and accessories', NULL);

-- Update parent category references
UPDATE categories SET parentcategoryid = (SELECT categoryid FROM categories WHERE name = 'Electronics') WHERE name IN ('Computers', 'Peripherals', 'Audio', 'Storage', 'Networking');

-- Insert subcategories
INSERT INTO categories (name, description, parentcategoryid) VALUES
    ('Laptops', 'Portable computers', (SELECT categoryid FROM categories WHERE name = 'Computers')),
    ('Desktops', 'Desktop computers', (SELECT categoryid FROM categories WHERE name = 'Computers')),
    ('Keyboards', 'Computer keyboards', (SELECT categoryid FROM categories WHERE name = 'Peripherals')),
    ('Mice', 'Computer mice and pointing devices', (SELECT categoryid FROM categories WHERE name = 'Peripherals')),
    ('Headphones', 'Audio headphones and headsets', (SELECT categoryid FROM categories WHERE name = 'Audio')),
    ('Speakers', 'Audio speakers', (SELECT categoryid FROM categories WHERE name = 'Audio')),
    ('External Drives', 'External storage devices', (SELECT categoryid FROM categories WHERE name = 'Storage')),
    ('Gaming PCs', 'Gaming computers', (SELECT categoryid FROM categories WHERE name = 'Gaming')),
    ('Gaming Accessories', 'Gaming peripherals', (SELECT categoryid FROM categories WHERE name = 'Gaming')),
    ('Printers', 'Printing devices', (SELECT categoryid FROM categories WHERE name = 'Office')),
    ('Routers', 'Network routers', (SELECT categoryid FROM categories WHERE name = 'Networking')),
    ('Switches', 'Network switches', (SELECT categoryid FROM categories WHERE name = 'Networking'));

-- Insert Sample Suppliers
INSERT INTO suppliers (name, contactname, email, phone, address, country) VALUES
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');

-- Insert Sample Products
INSERT INTO products (name, description, price, stockquantity, categoryid, supplierid, sku, weight, dimensions, reorderlevel) VALUES
    ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15,
        (SELECT categoryid FROM categories WHERE name = 'Laptops'),
        (SELECT supplierid FROM suppliers WHERE name = 'TechGlobal Inc.'),
        'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5),
    ('Gaming Beast', 'Gaming laptop with RTX 3080, 32GB RAM', 2499.99, 8,
        (SELECT categoryid FROM categories WHERE name = 'Laptops'),
        (SELECT supplierid FROM suppliers WHERE name = 'Gaming Gear Co.'),
        'LAP-GB-001', 2.5, '15.6" x 11" x 1"', 3),
    ('UltraBook Air', 'Ultra-thin laptop with 12-hour battery', 999.99, 20,
        (SELECT categoryid FROM categories WHERE name = 'Laptops'),
        (SELECT supplierid FROM suppliers WHERE name = 'TechGlobal Inc.'),
        'LAP-UA-001', 1.2, '13" x 8" x 0.5"', 7),
    ('WorkStation Pro', 'Professional workstation with dual monitors', 1999.99, 10,
        (SELECT categoryid FROM categories WHERE name = 'Desktops'),
        (SELECT supplierid FROM suppliers WHERE name = 'TechGlobal Inc.'),
        'DESK-WP-001', 15.0, '18" x 8" x 16"', 4),
    ('Gaming Tower', 'High-end gaming desktop with liquid cooling', 2999.99, 5,
        (SELECT categoryid FROM categories WHERE name = 'Gaming PCs'),
        (SELECT supplierid FROM suppliers WHERE name = 'Gaming Gear Co.'),
        'DESK-GT-001', 20.0, '20" x 10" x 18"', 2),
    ('Mechanical Pro', 'Mechanical keyboard with RGB lighting', 149.99, 30,
        (SELECT categoryid FROM categories WHERE name = 'Keyboards'),
        (SELECT supplierid FROM suppliers WHERE name = 'ElectroParts Ltd.'),
        'KB-MP-001', 1.2, '17" x 5" x 1.5"', 10),
    ('Wireless Elite', 'Wireless keyboard with numeric pad', 79.99, 25,
        (SELECT categoryid FROM categories WHERE name = 'Keyboards'),
        (SELECT supplierid FROM suppliers WHERE name = 'ElectroParts Ltd.'),
        'KB-WE-001', 0.8, '18" x 6" x 1"', 8),
    ('Gaming Mouse Pro', 'High-precision gaming mouse', 89.99, 40,
        (SELECT categoryid FROM categories WHERE name = 'Mice'),
        (SELECT supplierid FROM suppliers WHERE name = 'Gaming Gear Co.'),
        'M-GP-001', 0.3, '5" x 3" x 1.5"', 15),
    ('Wireless Track', 'Wireless mouse with long battery life', 49.99, 35,
        (SELECT categoryid FROM categories WHERE name = 'Mice'),
        (SELECT supplierid FROM suppliers WHERE name = 'ElectroParts Ltd.'),
        'M-WT-001', 0.2, '4" x 2.5" x 1.2"', 12),
    ('Noise Cancelling Pro', 'Premium noise-cancelling headphones', 299.99, 20,
        (SELECT categoryid FROM categories WHERE name = 'Headphones'),
        (SELECT supplierid FROM suppliers WHERE name = 'AudioTech Systems'),
        'HP-NC-001', 0.4, '7" x 6" x 3"', 8),
    ('Gaming Headset', '7.1 surround sound gaming headset', 129.99, 25,
        (SELECT categoryid FROM categories WHERE name = 'Headphones'),
        (SELECT supplierid FROM suppliers WHERE name = 'Gaming Gear Co.'),
        'HP-GH-001', 0.5, '8" x 7" x 4"', 10),
    ('Studio Monitors', 'Professional studio monitors', 399.99, 10,
        (SELECT categoryid FROM categories WHERE name = 'Speakers'),
        (SELECT supplierid FROM suppliers WHERE name = 'AudioTech Systems'),
        'SP-SM-001', 8.0, '12" x 8" x 10"', 4),
    ('Bluetooth Soundbar', 'Wireless soundbar with subwoofer', 249.99, 15,
        (SELECT categoryid FROM categories WHERE name = 'Speakers'),
        (SELECT supplierid FROM suppliers WHERE name = 'AudioTech Systems'),
        'SP-BS-001', 5.0, '36" x 3" x 4"', 6),
    ('SSD Pro 1TB', '1TB external SSD with USB 3.1', 199.99, 30,
        (SELECT categoryid FROM categories WHERE name = 'External Drives'),
        (SELECT supplierid FROM suppliers WHERE name = 'Storage Solutions'),
        'ED-SP-001', 0.2, '4" x 2" x 0.5"', 12),
    ('HDD Backup 4TB', '4TB external HDD for backup', 129.99, 25,
        (SELECT categoryid FROM categories WHERE name = 'External Drives'),
        (SELECT supplierid FROM suppliers WHERE name = 'Storage Solutions'),
        'ED-HB-001', 0.5, '5" x 3" x 1"', 10),
    ('Laser Pro', 'Business laser printer with duplex', 399.99, 12,
        (SELECT categoryid FROM categories WHERE name = 'Printers'),
        (SELECT supplierid FROM suppliers WHERE name = 'Office Supplies Pro'),
        'PR-LP-001', 25.0, '18" x 16" x 12"', 5),
    ('Photo Inkjet', 'Photo-quality inkjet printer', 299.99, 15,
        (SELECT categoryid FROM categories WHERE name = 'Printers'),
        (SELECT supplierid FROM suppliers WHERE name = 'Office Supplies Pro'),
        'PR-PI-001', 15.0, '16" x 14" x 8"', 6),
    ('WiFi 6 Router', 'High-speed WiFi 6 router', 199.99, 20,
        (SELECT categoryid FROM categories WHERE name = 'Routers'),
        (SELECT supplierid FROM suppliers WHERE name = 'Network Experts'),
        'NET-WR-001', 1.5, '10" x 7" x 2"', 8),
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10,
        (SELECT categoryid FROM categories WHERE name = 'Switches'),
        (SELECT supplierid FROM suppliers WHERE name = 'Network Experts'),
        'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4);

-- Insert initial stats record
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, clock_timestamp());

-- Update initial statistics
UPDATE productstats
SET
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT COALESCE(AVG(price), 0) FROM products),
    totalstockvalue = (SELECT COALESCE(SUM(price * stockquantity), 0) FROM products),
    lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = TRUE),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- Create Trigger Function for Product History
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user);
        RETURN NEW;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF OLD.price <> NEW.price OR OLD.stockquantity <> NEW.stockquantity THEN
            INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, current_user);
        END IF;
        RETURN NEW;
    END IF;
    IF TG_OP = 'DELETE' THEN
        INSERT INTO producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, current_user);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW EXECUTE FUNCTION trg_products_history_func();

-- Create Function for Getting All Products
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE (r_productid INTEGER, r_name VARCHAR, r_description VARCHAR, r_price NUMERIC, r_stockquantity INTEGER, r_createddate TIMESTAMP, r_modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate FROM products p ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE (r_productid INTEGER, r_name VARCHAR, r_description VARCHAR, r_price NUMERIC, r_stockquantity INTEGER, r_createddate TIMESTAMP, r_modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate FROM products p WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS INTEGER AS $$
DECLARE v_productid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity) VALUES (p_name, p_description, p_price, p_stockquantity) RETURNING products.productid INTO v_productid;
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid INTEGER, p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE products SET name = p_name, description = p_description, price = p_price, stockquantity = p_stockquantity, modifieddate = clock_timestamp() WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Deleting Product
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

