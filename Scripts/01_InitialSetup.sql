-- PostgreSQL Database Setup Script (Simple version)
-- Converted from SQL Server to PostgreSQL
-- Original: Scripts/01_InitialSetup.sql

-- Create schema
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create Products Table
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products(
    productid integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(100) NOT NULL,
    description varchar(500) NULL,
    price decimal(18, 2) NOT NULL,
    stockquantity integer NOT NULL,
    createddate timestamp NOT NULL DEFAULT NOW(),
    modifieddate timestamp NULL
);

-- Create Function for Getting All Products (replacing stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE(
    productid integer,
    name varchar(100),
    description varchar(500),
    price decimal(18,2),
    stockquantity integer,
    createddate timestamp,
    modifieddate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID (replacing stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid integer)
RETURNS TABLE(
    productid integer,
    name varchar(100),
    description varchar(500),
    price decimal(18,2),
    stockquantity integer,
    createddate timestamp,
    modifieddate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product (replacing stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    p_name varchar(100),
    p_description varchar(500),
    p_price decimal(18,2),
    p_stockquantity integer
)
RETURNS integer AS $$
DECLARE
    v_productid integer;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productmanagement_dbo.products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product (replacing stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    p_productid integer,
    p_name varchar(100),
    p_description varchar(500),
    p_price decimal(18,2),
    p_stockquantity integer
)
RETURNS void AS $$
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

-- Create Function for Deleting Product (replacing stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid integer)
RETURNS void AS $$
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
