-- PostgreSQL Initial Setup Script for ProductManagement Database
-- Migrated from SQL Server to PostgreSQL

-- Note: Run this script while connected to the 'ProductManagement' database
-- Create the database first with: CREATE DATABASE "ProductManagement";

-- Drop existing objects in correct order (if they exist)
DROP TABLE IF EXISTS producthistory CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS productstats CASCADE;

-- Create Products Table
CREATE TABLE products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL
);

-- Create ProductHistory Table
CREATE TABLE producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INT NOT NULL,
    action VARCHAR(10) NOT NULL,
    oldprice DECIMAL(18, 2) NULL,
    newprice DECIMAL(18, 2) NULL,
    oldstock INT NULL,
    newstock INT NULL,
    actiondate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifiedby VARCHAR(100) NULL,
    CONSTRAINT fk_producthistory_products FOREIGN KEY (productid)
        REFERENCES products (productid)
);

-- Create ProductStats Table
CREATE TABLE productstats (
    statid INT PRIMARY KEY DEFAULT 1,
    totalproducts INT NOT NULL DEFAULT 0,
    averageprice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    lowstockcount INT NOT NULL DEFAULT 0,
    discontinuedcount INT NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create Indexes
CREATE INDEX ix_producthistory_productid ON producthistory (productid);
CREATE INDEX ix_producthistory_actiondate ON producthistory (actiondate);

-- Create function for Getting All Products
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE (
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price DECIMAL(18,2),
    stockquantity INT,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create function for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE (
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price DECIMAL(18,2),
    stockquantity INT,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create function for Inserting Product
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
RETURNS INT AS $$
DECLARE
    v_productid INT;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;

    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- Create function for Updating Product
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INT,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
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

-- Create function for Deleting Product
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data
INSERT INTO products (name, description, price, stockquantity) VALUES
    ('Laptop', 'High-performance laptop', 999.99, 10),
    ('Mouse', 'Wireless gaming mouse', 49.99, 20),
    ('Keyboard', 'Mechanical keyboard', 129.99, 15);

-- Insert initial stats record
INSERT INTO productstats (statid, totalproducts, averageprice, totalstockvalue, lowstockcount, discontinuedcount, lastupdated)
VALUES (1, 0, 0, 0, 0, 0, NOW());

-- Update initial statistics
UPDATE productstats
SET
    totalproducts = (SELECT COUNT(*) FROM products),
    averageprice = (SELECT AVG(price) FROM products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM products),
    lastupdated = NOW()
WHERE statid = 1;
