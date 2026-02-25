-- PostgreSQL Database Setup Script for AdoCore Product Management System
-- This script creates the required database schema for the migrated application
-- Database: productmanagement
-- Generated: February 25, 2026

-- =============================================================================
-- 1. DATABASE CREATION (Run as superuser if database doesn't exist)
-- =============================================================================

-- Uncomment the following lines if creating a new database:
-- DROP DATABASE IF EXISTS productmanagement;
-- CREATE DATABASE productmanagement
--     WITH 
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1;

-- Connect to the database
\c productmanagement;

-- =============================================================================
-- 2. TABLE CREATION
-- =============================================================================

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS producthistory CASCADE;
DROP TABLE IF EXISTS productstats CASCADE;
DROP TABLE IF EXISTS products CASCADE;

-- -----------------------------------------------------------------------------
-- Table: products
-- Description: Main product catalog table
-- -----------------------------------------------------------------------------
CREATE TABLE products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(18,2) NOT NULL CHECK (price >= 0),
    stockquantity INTEGER NOT NULL DEFAULT 0 CHECK (stockquantity >= 0),
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for products table
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_stockquantity ON products(stockquantity);
CREATE INDEX idx_products_modifieddate ON products(modifieddate);

-- -----------------------------------------------------------------------------
-- Table: producthistory
-- Description: Audit log for all product changes (INSERT, UPDATE, DELETE)
-- -----------------------------------------------------------------------------
CREATE TABLE producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    oldprice DECIMAL(18,2),
    newprice DECIMAL(18,2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_producthistory_product FOREIGN KEY (productid) 
        REFERENCES products(productid) ON DELETE CASCADE
);

-- Indexes for producthistory table
CREATE INDEX idx_producthistory_productid ON producthistory(productid);
CREATE INDEX idx_producthistory_action ON producthistory(action);
CREATE INDEX idx_producthistory_actiondate ON producthistory(actiondate);

-- -----------------------------------------------------------------------------
-- Table: productstats
-- Description: Aggregate statistics about products
-- -----------------------------------------------------------------------------
CREATE TABLE productstats (
    statid INTEGER PRIMARY KEY,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice DECIMAL(18,2) NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Initialize the stats record
INSERT INTO productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP);

-- =============================================================================
-- 3. SAMPLE DATA (Optional - for testing)
-- =============================================================================

-- Insert sample products
INSERT INTO products (name, description, price, stockquantity, createddate, modifieddate)
VALUES 
    ('Laptop Pro 15', 'High-performance laptop with 15-inch display', 1299.99, 50, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Wireless Mouse', 'Ergonomic wireless mouse with USB receiver', 29.99, 150, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('USB-C Hub', '7-in-1 USB-C hub with HDMI, USB 3.0, and SD card reader', 49.99, 75, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Mechanical Keyboard', 'RGB mechanical keyboard with blue switches', 89.99, 45, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Monitor 27"', '27-inch 4K IPS monitor with HDR support', 399.99, 30, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Webcam HD', '1080p HD webcam with built-in microphone', 69.99, 80, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('External SSD 1TB', 'Portable 1TB SSD with USB 3.2 Gen 2', 119.99, 60, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Desk Lamp LED', 'Adjustable LED desk lamp with touch control', 39.99, 100, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Noise-Cancelling Headphones', 'Premium wireless headphones with active noise cancellation', 249.99, 25, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Laptop Stand', 'Aluminum laptop stand with adjustable height', 34.99, 120, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Insert initial history records for sample products
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
-- 4. VERIFICATION QUERIES
-- =============================================================================

-- Verify table creation
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    AND table_name IN ('products', 'producthistory', 'productstats')
ORDER BY table_name;

-- Verify data
SELECT 'products' as table_name, COUNT(*) as row_count FROM products
UNION ALL
SELECT 'producthistory', COUNT(*) FROM producthistory
UNION ALL
SELECT 'productstats', COUNT(*) FROM productstats;

-- Verify statistics
SELECT * FROM productstats;

-- Test window functions (used in GetAllProductsAsync)
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
    p.price,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory
FROM products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY p.price DESC
LIMIT 5;

-- =============================================================================
-- 5. TROUBLESHOOTING QUERIES
-- =============================================================================

-- Check table structures
\d products
\d producthistory
\d productstats

-- Check indexes
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
    AND tablename IN ('products', 'producthistory', 'productstats')
ORDER BY tablename, indexname;

-- Check foreign keys
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name IN ('products', 'producthistory', 'productstats');

-- =============================================================================
-- Setup complete!
-- =============================================================================

-- To run this script:
-- psql -U postgres -f setup_postgresql_schema.sql

COMMIT;
