-- NOTE: This script has been migrated to PostgreSQL syntax.
-- Original script was for Microsoft SQL Server.
-- For the full PostgreSQL setup, see Database/Scripts/01_InitialSetup.sql

-- Create ProductManagement Database (run as superuser)
-- CREATE DATABASE ProductManagement;

-- Connect to ProductManagement database before running the rest

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP
);

-- Create function equivalent to sp_GetAllProducts
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE sql
AS $$
    SELECT productid, name, description, price, stockquantity, createddate, modifieddate
    FROM products
    ORDER BY name;
$$;

-- Create function equivalent to sp_GetProductById
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE sql
AS $$
    SELECT productid, name, description, price, stockquantity, createddate, modifieddate
    FROM products
    WHERE productid = p_productid;
$$;

-- Create function equivalent to sp_InsertProduct
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid INTO v_productid;
    RETURN v_productid;
END;
$$;

-- Create function equivalent to sp_UpdateProduct
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid INTEGER, p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS VOID
LANGUAGE sql
AS $$
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = p_productid;
$$;

-- Create function equivalent to sp_DeleteProduct
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
LANGUAGE sql
AS $$
    DELETE FROM products
    WHERE productid = p_productid;
$$;

-- Insert Sample Data
INSERT INTO products (name, description, price, stockquantity)
SELECT 'Laptop', 'High-performance laptop', 999.99, 10
WHERE NOT EXISTS (SELECT 1 FROM products LIMIT 1);

INSERT INTO products (name, description, price, stockquantity)
SELECT 'Mouse', 'Wireless gaming mouse', 49.99, 20
WHERE NOT EXISTS (SELECT 1 FROM products WHERE name = 'Mouse');

INSERT INTO products (name, description, price, stockquantity)
SELECT 'Keyboard', 'Mechanical keyboard', 129.99, 15
WHERE NOT EXISTS (SELECT 1 FROM products WHERE name = 'Keyboard');
