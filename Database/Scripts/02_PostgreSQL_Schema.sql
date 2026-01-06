-- PostgreSQL Schema for Product Management
-- Converted from SQL Server schema for equivalency testing

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Drop existing tables in correct order (for recreate)
DROP TABLE IF EXISTS productmanagement_dbo.producthistory CASCADE;
DROP TABLE IF EXISTS productmanagement_dbo.products CASCADE;
DROP TABLE IF EXISTS productmanagement_dbo.productstats CASCADE;

-- Create Products Table (matches DMS conversion naming: productmanagement_dbo.products)
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP NULL
);

-- Create ProductHistory Table
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice NUMERIC(18, 2) NULL,
    newprice NUMERIC(18, 2) NULL,
    oldstock INTEGER NULL,
    newstock INTEGER NULL,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedby VARCHAR(100) NULL,
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid) 
        REFERENCES productmanagement_dbo.products (productid)
);

-- Create ProductStats Table
CREATE TABLE productmanagement_dbo.productstats (
    statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes (matching SQL Server indexes)
CREATE INDEX ix_products_name ON productmanagement_dbo.products (name);
CREATE INDEX ix_producthistory_productid ON productmanagement_dbo.producthistory (productid);
CREATE INDEX ix_producthistory_actiondate ON productmanagement_dbo.producthistory (actiondate);

-- Insert initial stats record
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, CURRENT_TIMESTAMP);

COMMENT ON TABLE productmanagement_dbo.products IS 'Product catalog table - migrated from SQL Server dbo.Products';
COMMENT ON TABLE productmanagement_dbo.producthistory IS 'Product change history - migrated from SQL Server dbo.ProductHistory';
COMMENT ON TABLE productmanagement_dbo.productstats IS 'Product statistics - migrated from SQL Server dbo.ProductStats';
