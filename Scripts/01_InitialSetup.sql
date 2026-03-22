-- Create ProductManagement Database (connect to this database directly in PostgreSQL)
-- Note: In PostgreSQL, database creation is typically done outside of script execution
-- SELECT 'CREATE DATABASE ProductManagement' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ProductManagement')\gexec

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INT NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP NULL
);

-- Create Function for Getting All Products (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(productid INT, name VARCHAR, description VARCHAR, price DECIMAL, stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE sql
AS $$
    SELECT productid, name, description, price, stockquantity, createddate, modifieddate
    FROM products
    ORDER BY name;
$$;

-- Create Function for Getting Product by ID (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE(productid INT, name VARCHAR, description VARCHAR, price DECIMAL, stockquantity INT, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE sql
AS $$
    SELECT productid, name, description, price, stockquantity, createddate, modifieddate
    FROM products
    WHERE productid = p_productid;
$$;

-- Create Function for Inserting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
RETURNS INT
LANGUAGE sql
AS $$
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid;
$$;

-- Create Function for Updating Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INT,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price DECIMAL(18,2),
    p_stockquantity INT
)
RETURNS VOID
LANGUAGE sql
AS $$
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = NOW()
    WHERE productid = p_productid;
$$;

-- Create Function for Deleting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INT)
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
