-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is typically done outside of SQL scripts
-- using: CREATE DATABASE productmanagement;
-- This script assumes the database already exists and you are connected to it.

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL
);

-- Create Function for Getting All Products (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(
    productid INTEGER,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18,2),
    stockquantity INTEGER,
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

-- Create Function for Getting Product by ID (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(
    productid INTEGER,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18,2),
    stockquantity INTEGER,
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

-- Create Function for Inserting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
)
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

-- Create Function for Updating Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
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

-- Create Function for Deleting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN
        PERFORM sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;
