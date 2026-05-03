-- PostgreSQL Setup Script for ProductManagement Database
-- Converted from MS SQL Server to PostgreSQL
-- Simple version: Products table, stored procedures (as functions), and sample data

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    productid INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP NULL
);

-- Create Function for Getting All Products (replaces stored procedure sp_GetAllProducts)
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(
    productid INTEGER,
    name VARCHAR,
    description VARCHAR,
    price NUMERIC,
    stockquantity INTEGER,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$;

-- Create Function for Getting Product by ID (replaces stored procedure sp_GetProductById)
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(
    productid INTEGER,
    name VARCHAR,
    description VARCHAR,
    price NUMERIC,
    stockquantity INTEGER,
    createddate TIMESTAMP,
    modifieddate TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$;

-- Create Function for Inserting Product (replaces stored procedure sp_InsertProduct)
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
    RETURNING products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$;

-- Create Function for Updating Product (replaces stored procedure sp_UpdateProduct)
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
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = p_productid;
END;
$$;

-- Create Function for Deleting Product (replaces stored procedure sp_DeleteProduct)
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
