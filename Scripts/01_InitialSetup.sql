-- Create ProductManagement Schema (PostgreSQL equivalent of database creation)
-- Note: Database should be created separately using: CREATE DATABASE ProductManagement;
-- Then connect to the database and run this script.

-- Create schema for migrated objects (matching DMS schema mapping: dbo -> productmanagement_dbo)
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create Products Table
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products(
    productid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE
);

-- Create Function for Getting All Products (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE(
    productid INTEGER,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18,2),
    stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE,
    modifieddate TIMESTAMP WITHOUT TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(
    p_productid INTEGER
)
RETURNS TABLE(
    productid INTEGER,
    name VARCHAR(100),
    description VARCHAR(500),
    price NUMERIC(18,2),
    stockquantity INTEGER,
    createddate TIMESTAMP WITHOUT TIME ZONE,
    modifieddate TIMESTAMP WITHOUT TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productmanagement_dbo.products.productid INTO v_productid;

    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE productmanagement_dbo.products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = NOW()
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Deleting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(
    p_productid INTEGER
)
RETURNS VOID AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM productmanagement_dbo.products LIMIT 1) THEN
        PERFORM productmanagement_dbo.sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM productmanagement_dbo.sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM productmanagement_dbo.sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END;
$$;
