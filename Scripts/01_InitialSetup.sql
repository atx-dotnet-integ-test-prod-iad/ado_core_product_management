-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is typically done outside of scripts
-- CREATE DATABASE productmanagement; -- Run separately if needed

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    productid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL
);

-- Create Function for Getting All Products (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE (
    productid INTEGER,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18, 2),
    stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE,
    modifieddate TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE sql
AS $$
    SELECT productid, name, description, price, stockquantity, createddate, modifieddate
    FROM products
    ORDER BY name;
$$;

-- Create Function for Getting Product by ID (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE (
    productid INTEGER,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18, 2),
    stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE,
    modifieddate TIMESTAMP WITHOUT TIME ZONE
)
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
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
)
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

-- Create Function for Updating Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = NOW()
    WHERE productid = p_productid;
END;
$$;

-- Create Function for Deleting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN
        PERFORM sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END;
$$;
