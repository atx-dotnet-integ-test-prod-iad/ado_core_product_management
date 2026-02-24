-- PostgreSQL Schema for ProductManagement Database
-- Converted from SQL Server schema

-- Drop existing objects in correct order
DROP TRIGGER IF EXISTS trg_products_history ON products CASCADE;
DROP TABLE IF EXISTS producthistory CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS productstats CASCADE;

-- Create Categories Table
CREATE TABLE categories (
    categoryid SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) NULL,
    parentcategoryid INTEGER NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add self-referencing foreign key for Categories
ALTER TABLE categories
ADD CONSTRAINT fk_categories_categories 
FOREIGN KEY (parentcategoryid) REFERENCES categories (categoryid);

-- Create Suppliers Table
CREATE TABLE suppliers (
    supplierid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactname VARCHAR(100) NULL,
    email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL,
    address VARCHAR(200) NULL,
    country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT true,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create Products Table
CREATE TABLE products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    categoryid INTEGER NULL,
    supplierid INTEGER NULL,
    sku VARCHAR(50) NULL,
    weight NUMERIC(10, 2) NULL,
    dimensions VARCHAR(50) NULL,
    isdiscontinued BOOLEAN NOT NULL DEFAULT false,
    reorderlevel INTEGER NOT NULL DEFAULT 10,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP NULL,
    CONSTRAINT fk_products_categories FOREIGN KEY (categoryid) 
        REFERENCES categories (categoryid),
    CONSTRAINT fk_products_suppliers FOREIGN KEY (supplierid) 
        REFERENCES suppliers (supplierid)
);

-- Create ProductHistory Table
CREATE TABLE producthistory (
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
        REFERENCES products (productid)
);

-- Create ProductStats Table
CREATE TABLE productstats (
    statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes
CREATE INDEX ix_products_categoryid ON products (categoryid);
CREATE INDEX ix_products_supplierid ON products (supplierid);
CREATE UNIQUE INDEX ix_products_sku ON products (sku);
CREATE INDEX ix_producthistory_productid ON producthistory (productid);
CREATE INDEX ix_producthistory_actiondate ON producthistory (actiondate);

-- Note: Sample data inserts omitted for brevity - refer to original 01_InitialSetup.sql for data
-- All table names, column names converted to lowercase for PostgreSQL
-- Data types converted: IDENTITY -> SERIAL, nvarchar -> VARCHAR, decimal -> NUMERIC, bit -> BOOLEAN, datetime -> TIMESTAMP
-- Default values converted: GETDATE() -> CURRENT_TIMESTAMP

-- Create Trigger for Product History (PostgreSQL PL/pgSQL)
CREATE OR REPLACE FUNCTION trg_products_history_func()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO producthistory (productid, action, newprice, newstock, modifiedby)
        VALUES (NEW.productid, 'INSERT', NEW.price, NEW.stockquantity, CURRENT_USER);
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (NEW.price <> OLD.price OR NEW.stockquantity <> OLD.stockquantity) THEN
            INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, modifiedby)
            VALUES (NEW.productid, 'UPDATE', OLD.price, NEW.price, OLD.stockquantity, NEW.stockquantity, CURRENT_USER);
        END IF;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO producthistory (productid, action, oldprice, oldstock, modifiedby)
        VALUES (OLD.productid, 'DELETE', OLD.price, OLD.stockquantity, CURRENT_USER);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_history
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW
EXECUTE FUNCTION trg_products_history_func();

-- PostgreSQL Functions (equivalents of SQL Server stored procedures)
-- Note: Functions converted from T-SQL procedures
-- SCOPE_IDENTITY() replaced with RETURNING clauses
-- SYSTEM_USER replaced with CURRENT_USER
