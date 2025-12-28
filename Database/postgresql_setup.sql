-- ================================================================
-- PostgreSQL Database Setup Script for AdoCore Migration
-- ================================================================
-- This script creates the necessary database, schema, and tables
-- required for the migrated ADO.NET application
-- ================================================================

-- Step 1: Create the database (run as postgres superuser)
-- Note: This should be run separately before running the rest of the script
-- CREATE DATABASE "ProductManagement";

-- Connect to the ProductManagement database before continuing
-- \c ProductManagement

-- Step 2: Create the schema
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Step 3: Create the products table
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Step 4: Create the producthistory table
CREATE TABLE IF NOT EXISTS productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice NUMERIC(18, 2),
    newprice NUMERIC(18, 2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (productid) REFERENCES productmanagement_dbo.products(productid) ON DELETE CASCADE
);

-- Step 5: Create the productstats table
CREATE TABLE IF NOT EXISTS productmanagement_dbo.productstats (
    statid SERIAL PRIMARY KEY,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Step 6: Initialize productstats with default row (required by update operations)
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT (statid) DO NOTHING;

-- Step 7: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_price ON productmanagement_dbo.products(price);
CREATE INDEX IF NOT EXISTS idx_products_stockquantity ON productmanagement_dbo.products(stockquantity);
CREATE INDEX IF NOT EXISTS idx_products_modifieddate ON productmanagement_dbo.products(modifieddate);
CREATE INDEX IF NOT EXISTS idx_producthistory_productid ON productmanagement_dbo.producthistory(productid);
CREATE INDEX IF NOT EXISTS idx_producthistory_actiondate ON productmanagement_dbo.producthistory(actiondate);

-- Step 8: Insert sample data for testing
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate, modifieddate)
VALUES 
    ('Laptop Pro 15', 'High-performance laptop with 16GB RAM and 512GB SSD', 1299.99, 25, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Wireless Mouse', 'Ergonomic wireless mouse with 6 buttons', 29.99, 150, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('USB-C Hub', '7-in-1 USB-C hub with HDMI and Ethernet', 49.99, 75, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Mechanical Keyboard', 'RGB mechanical keyboard with brown switches', 89.99, 40, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('4K Monitor 27"', '27-inch 4K IPS monitor with HDR support', 399.99, 15, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Webcam HD', '1080p webcam with built-in microphone', 69.99, 60, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('External SSD 1TB', 'Portable SSD with USB 3.2 Gen 2', 119.99, 45, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Desk Lamp LED', 'Adjustable LED desk lamp with USB charging', 34.99, 100, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Cable Organizer', 'Cable management system for desk setup', 19.99, 200, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Laptop Stand', 'Aluminum laptop stand with adjustable height', 44.99, 80, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- Step 9: Update productstats to reflect initial data
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = (SELECT COUNT(*) FROM productmanagement_dbo.products),
    averageprice = (SELECT AVG(price) FROM productmanagement_dbo.products),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Step 10: Grant necessary permissions
-- Adjust the username 'postgres' to match your application's database user
GRANT USAGE ON SCHEMA productmanagement_dbo TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO postgres;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO postgres;

ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo
GRANT USAGE, SELECT ON SEQUENCES TO postgres;

-- ================================================================
-- Setup Complete
-- ================================================================
-- The database is now ready for the migrated ADO.NET application
-- 
-- Next steps:
-- 1. Update appsettings.json with your PostgreSQL connection details
-- 2. Run the application to test database connectivity
-- 3. Execute application operations to verify SQL statement conversions
-- ================================================================
