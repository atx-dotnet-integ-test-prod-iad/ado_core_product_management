-- Create ProductManagement Database
-- Note: CREATE DATABASE cannot be run inside a transaction in PostgreSQL
-- Run this separately if needed:
-- CREATE DATABASE productmanagement;

-- Connect to the productmanagement database before running the rest

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    productid SERIAL PRIMARY KEY,
    name varchar(100) NOT NULL,
    description varchar(500) NULL,
    price decimal(18, 2) NOT NULL,
    stockquantity int NOT NULL,
    createddate timestamp NOT NULL DEFAULT NOW(),
    modifieddate timestamp NULL
);

-- Create Stored Procedure (Function) for Getting All Products
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(productid int, name varchar(100), description varchar(500), price decimal(18,2), stockquantity int, createddate timestamp, modifieddate timestamp) AS $$
BEGIN
    RETURN QUERY SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create Stored Procedure (Function) for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid int)
RETURNS TABLE(productid int, name varchar(100), description varchar(500), price decimal(18,2), stockquantity int, createddate timestamp, modifieddate timestamp) AS $$
BEGIN
    RETURN QUERY SELECT pr.productid, pr.name, pr.description, pr.price, pr.stockquantity, pr.createddate, pr.modifieddate
    FROM products pr
    WHERE pr.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Stored Procedure (Function) for Inserting Product
CREATE OR REPLACE FUNCTION sp_insertproduct(p_name varchar(100), p_description varchar(500), p_price decimal(18,2), p_stockquantity int)
RETURNS int AS $$
DECLARE
    v_productid int;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING products.productid INTO v_productid;
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Stored Procedure (Function) for Updating Product
CREATE OR REPLACE FUNCTION sp_updateproduct(p_productid int, p_name varchar(100), p_description varchar(500), p_price decimal(18,2), p_stockquantity int)
RETURNS void AS $$
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

-- Create Stored Procedure (Function) for Deleting Product
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid int)
RETURNS void AS $$
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
