-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is typically done outside of scripts
-- CREATE DATABASE productmanagement;

-- Create Products Table
CREATE TABLE IF NOT EXISTS products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL
);

-- Create Function for Getting All Products
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE (
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18,2),
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

-- Create Function for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE (
    productid INT,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18,2),
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

-- Create Function for Inserting Product
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
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

-- Create Function for Updating Product
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INT,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
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

-- Create Function for Deleting Product
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

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
