-- =====================================================
-- Converted SQL Statements (MS SQL Server → PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS Schema Mapping Tool (successfully returned target DDL)
-- All statements attempted through DMS tool first, all failed.
-- Manual conversion applied with lowercase schema object names per PostgreSQL conventions.
-- =====================================================

-- =========================================================================
-- SECTION A: ProductRepository.cs Converted SQL Statements
-- =========================================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync
-- =====================================================
-- [CONVERTED PostgreSQL]:
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

-- =====================================================
-- Statement 2: GetProductByIdAsync
-- =====================================================
-- [CONVERTED PostgreSQL]:
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

-- =====================================================
-- Statement 3: InsertProductAsync - INSERT with RETURNING
-- SCOPE_IDENTITY() → RETURNING productid
-- =====================================================
-- [CONVERTED PostgreSQL]:
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- =====================================================
-- Statement 4: InsertProductAsync - INSERT into producthistory
-- GETDATE() → NOW()
-- =====================================================
-- [CONVERTED PostgreSQL]:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- =====================================================
-- Statement 5: InsertProductAsync - UPDATE productstats
-- GETDATE() → NOW()
-- =====================================================
-- [CONVERTED PostgreSQL]:
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 6: UpdateProductAsync - SELECT price/stockquantity
-- =====================================================
-- [CONVERTED PostgreSQL]:
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- =====================================================
-- Statement 7: UpdateProductAsync - UPDATE products
-- GETDATE() → NOW()
-- =====================================================
-- [CONVERTED PostgreSQL]:
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- =====================================================
-- Statement 8: UpdateProductAsync - INSERT into producthistory
-- GETDATE() → NOW()
-- =====================================================
-- [CONVERTED PostgreSQL]:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- =====================================================
-- Statement 9: UpdateProductAsync - UPDATE productstats
-- GETDATE() → NOW()
-- =====================================================
-- [CONVERTED PostgreSQL]:
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 10: DeleteProductAsync - SELECT price/stockquantity
-- =====================================================
-- [CONVERTED PostgreSQL]:
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- =====================================================
-- Statement 11: DeleteProductAsync - INSERT into producthistory
-- GETDATE() → NOW()
-- =====================================================
-- [CONVERTED PostgreSQL]:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- =====================================================
-- Statement 12: DeleteProductAsync - DELETE from products
-- =====================================================
-- [CONVERTED PostgreSQL]:
DELETE FROM products 
WHERE productid = @ProductId;

-- =====================================================
-- Statement 13: DeleteProductAsync - UPDATE productstats with CASE
-- GETDATE() → NOW()
-- =====================================================
-- [CONVERTED PostgreSQL]:
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 14: GetProductsByPriceRangeAsync
-- =====================================================
-- [CONVERTED PostgreSQL]:
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

-- =====================================================
-- Statement 15: GetLowStockProductsAsync
-- CAST(StockQuantity AS DECIMAL) → stockquantity::numeric
-- =====================================================
-- [CONVERTED PostgreSQL]:
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

-- =========================================================================
-- SECTION B: Database/Scripts/01_InitialSetup.sql Converted Statements
-- =========================================================================

-- =====================================================
-- Statement 16: CREATE TABLE categories
-- =====================================================
CREATE TABLE categories(
    categoryid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    parentcategoryid INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);

-- =====================================================
-- Statement 17: ALTER TABLE categories - Add FK
-- =====================================================
ALTER TABLE categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parentcategoryid) REFERENCES categories (categoryid);

-- =====================================================
-- Statement 18: CREATE TABLE suppliers
-- =====================================================
CREATE TABLE suppliers(
    supplierid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(200),
    country VARCHAR(50),
    isactive BOOLEAN NOT NULL DEFAULT TRUE,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);

-- =====================================================
-- Statement 19: CREATE TABLE products
-- =====================================================
CREATE TABLE products(
    productid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18,2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    categoryid INTEGER,
    supplierid INTEGER,
    sku VARCHAR(50),
    weight NUMERIC(10,2),
    dimensions VARCHAR(50),
    isdiscontinued BOOLEAN NOT NULL DEFAULT FALSE,
    reorderlevel INTEGER NOT NULL DEFAULT 10,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid) 
        REFERENCES categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid) 
        REFERENCES suppliers (supplierid)
);

-- =====================================================
-- Statement 20: CREATE TABLE producthistory
-- =====================================================
CREATE TABLE producthistory(
    historyid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice NUMERIC(18,2),
    newprice NUMERIC(18,2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifiedby VARCHAR(100),
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid) 
        REFERENCES products (productid)
);

-- =====================================================
-- Statement 21: CREATE TABLE productstats
-- =====================================================
CREATE TABLE productstats(
    statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18,2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18,2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp()
);

-- =====================================================
-- Statement 22: CREATE INDEX ix_products_categoryid
-- =====================================================
CREATE INDEX ix_products_categoryid ON products (categoryid);

-- =====================================================
-- Statement 23: CREATE INDEX ix_products_supplierid
-- =====================================================
CREATE INDEX ix_products_supplierid ON products (supplierid);

-- =====================================================
-- Statement 24: CREATE UNIQUE INDEX ix_products_sku
-- =====================================================
CREATE UNIQUE INDEX ix_products_sku ON products (sku);

-- =====================================================
-- Statement 25: CREATE INDEX ix_producthistory_productid
-- =====================================================
CREATE INDEX ix_producthistory_productid ON producthistory (productid);

-- =====================================================
-- Statement 26: CREATE INDEX ix_producthistory_actiondate
-- =====================================================
CREATE INDEX ix_producthistory_actiondate ON producthistory (actiondate);

-- =====================================================
-- Statement 27: INSERT categories (Sample Data)
-- =====================================================
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

-- =====================================================
-- Statement 28: INSERT suppliers (Sample Data)
-- =====================================================
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

-- =====================================================
-- Statement 29: INSERT products (Sample Data)
-- =====================================================
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

-- =====================================================
-- Statement 30: INSERT productstats (Initial record)
-- GETDATE() → NOW()
-- =====================================================
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, NOW());

-- =====================================================
-- Statement 31: UPDATE productstats (Initial statistics)
-- GETDATE() → NOW(), IsDiscontinued = 1 → isdiscontinued = true
-- =====================================================
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM products),
    lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = true),
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 32: CREATE TRIGGER → FUNCTION + TRIGGER
-- SYSTEM_USER → current_user
-- =====================================================
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, current_user);
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
        IF (NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity) THEN
            INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, current_user);
        END IF;
        RETURN NEW;
    END IF;
    
    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
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

-- =====================================================
-- Statement 33: CREATE FUNCTION sp_getallproducts (was PROCEDURE)
-- =====================================================
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Statement 34: CREATE FUNCTION sp_getproductbyid (was PROCEDURE)
-- =====================================================
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Statement 35: CREATE FUNCTION sp_insertproduct (was PROCEDURE)
-- SCOPE_IDENTITY() → RETURNING
-- =====================================================
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Statement 36: CREATE FUNCTION sp_updateproduct (was PROCEDURE)
-- GETDATE() → NOW()
-- =====================================================
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid INTEGER, p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS VOID AS $$
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

-- =====================================================
-- Statement 37: CREATE FUNCTION sp_deleteproduct (was PROCEDURE)
-- =====================================================
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- =========================================================================
-- SECTION C: Scripts/01_InitialSetup.sql Converted Statements
-- =========================================================================

-- =====================================================
-- Statement 38: CREATE TABLE products (Scripts version - simpler)
-- =====================================================
CREATE TABLE products(
    productid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18,2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE
);

-- =====================================================
-- Statements 39-43: Same stored procedures as Database/Scripts version
-- (sp_getallproducts, sp_getproductbyid, sp_insertproduct, sp_updateproduct, sp_deleteproduct)
-- See Statements 33-37 above for converted versions.
-- =====================================================

-- =====================================================
-- SUMMARY
-- Total statements converted: 43
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 43)
-- DMS tool attempts: 43 (all failed)
-- Key transformations applied:
--   - All schema object names converted to lowercase
--   - GETDATE() → NOW()
--   - SCOPE_IDENTITY() → RETURNING clause
--   - IDENTITY(1,1) → GENERATED ALWAYS AS IDENTITY
--   - nvarchar → VARCHAR
--   - bit → BOOLEAN
--   - datetime → TIMESTAMP WITHOUT TIME ZONE
--   - SYSTEM_USER → current_user
--   - CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION
--   - Triggers converted to PostgreSQL FUNCTION + TRIGGER pattern
--   - CAST(x AS DECIMAL) → x::numeric
-- =====================================================
