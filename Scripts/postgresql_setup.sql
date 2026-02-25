/*******************************************************************************
 * POSTGRESQL DATABASE SETUP SCRIPT
 * Migration from MS SQL Server to PostgreSQL
 * Database: productmanagement
 * 
 * This script creates all necessary database objects for the ADO.NET application
 * after migration to PostgreSQL.
 * 
 * Usage:
 *   psql -U postgres -f postgresql_setup.sql
 * 
 * Or connect to PostgreSQL and run:
 *   \i postgresql_setup.sql
 ******************************************************************************/

-- Create the database (if running as superuser)
-- Note: You may need to run this separately if not superuser
-- CREATE DATABASE productmanagement;

-- Connect to the database
\c productmanagement;

-- =============================================================================
-- DROP EXISTING OBJECTS (for clean re-runs)
-- =============================================================================
DROP TABLE IF EXISTS productstats CASCADE;
DROP TABLE IF EXISTS producthistory CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP SEQUENCE IF EXISTS products_productid_seq CASCADE;

-- =============================================================================
-- CREATE SEQUENCES
-- =============================================================================
CREATE SEQUENCE products_productid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- =============================================================================
-- CREATE TABLES
-- =============================================================================

-- Products Table (main table)
CREATE TABLE products (
    productid INTEGER NOT NULL DEFAULT nextval('products_productid_seq'::regclass),
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP,
    CONSTRAINT products_pkey PRIMARY KEY (productid)
);

-- ProductHistory Table (audit log for product changes)
CREATE TABLE producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(20) NOT NULL,
    oldprice DECIMAL(18, 2),
    newprice DECIMAL(18, 2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_producthistory_product FOREIGN KEY (productid) 
        REFERENCES products(productid) ON DELETE CASCADE
);

-- ProductStats Table (aggregate statistics)
CREATE TABLE productstats (
    statid INTEGER PRIMARY KEY,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =============================================================================
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_stockquantity ON products(stockquantity);
CREATE INDEX idx_producthistory_productid ON producthistory(productid);
CREATE INDEX idx_producthistory_actiondate ON producthistory(actiondate);

-- =============================================================================
-- INSERT INITIAL DATA
-- =============================================================================

-- Initialize ProductStats
INSERT INTO productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0.00, CURRENT_TIMESTAMP);

-- Insert Sample Products
INSERT INTO products (name, description, price, stockquantity, createddate)
VALUES 
    ('Laptop', 'High-performance laptop', 999.99, 10, CURRENT_TIMESTAMP),
    ('Mouse', 'Wireless gaming mouse', 49.99, 20, CURRENT_TIMESTAMP),
    ('Keyboard', 'Mechanical keyboard', 129.99, 15, CURRENT_TIMESTAMP),
    ('Monitor', '27-inch 4K display', 399.99, 8, CURRENT_TIMESTAMP),
    ('Headphones', 'Noise-cancelling headphones', 199.99, 12, CURRENT_TIMESTAMP);

-- Update ProductStats based on inserted data
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Log initial product insertions in history
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT 
    productid,
    'INSERT',
    NULL,
    price,
    NULL,
    stockquantity,
    createddate
FROM products;

-- =============================================================================
-- GRANT PERMISSIONS (adjust user as needed)
-- =============================================================================
-- Grant permissions to the application user
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Verify tables created
SELECT 
    tablename, 
    schemaname 
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('products', 'producthistory', 'productstats')
ORDER BY tablename;

-- Verify data inserted
SELECT 'Products' as table_name, COUNT(*) as row_count FROM products
UNION ALL
SELECT 'ProductHistory' as table_name, COUNT(*) as row_count FROM producthistory
UNION ALL
SELECT 'ProductStats' as table_name, COUNT(*) as row_count FROM productstats;

-- Display sample data
SELECT 
    productid,
    name,
    price,
    stockquantity,
    createddate
FROM products
ORDER BY productid;

-- Display statistics
SELECT * FROM productstats;

-- =============================================================================
-- SETUP COMPLETE
-- =============================================================================
\echo 'PostgreSQL database setup completed successfully!'
\echo 'Database: productmanagement'
\echo 'Tables created: products, producthistory, productstats'
\echo ''
\echo 'Connection string format:'
\echo 'Host=localhost;Database=productmanagement;Username=postgres;Password=<your_password>;Port=5432'
