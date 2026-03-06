-- PostgreSQL Setup Script for ProductManagement
-- Converted from MS SQL Server using DMS MCP tool
-- Schema: productmanagement_dbo

-- Create Schema if not exists
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create Products Table
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products
(productid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL);

-- Create Function for Getting All Products (converted from stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p.productid::INTEGER, p.name::VARCHAR, p.description::VARCHAR, p.price::NUMERIC, p.stockquantity::INTEGER, p.createddate::TIMESTAMP, p.modifieddate::TIMESTAMP
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$;

-- Create Function for Getting Product by ID (converted from stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE(productid INTEGER, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT p.productid::INTEGER, p.name::VARCHAR, p.description::VARCHAR, p.price::NUMERIC, p.stockquantity::INTEGER, p.createddate::TIMESTAMP, p.modifieddate::TIMESTAMP
    FROM productmanagement_dbo.products p
    WHERE p.productid = p_productid;
END;
$$;

-- Create Function for Inserting Product (converted from stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
    v_productid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productmanagement_dbo.products.productid INTO v_productid;
    
    RETURN v_productid;
END;
$$;

-- Create Function for Updating Product (converted from stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(
    p_productid INTEGER,
    p_name VARCHAR(100),
    p_description VARCHAR(500),
    p_price NUMERIC(18,2),
    p_stockquantity INTEGER)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE productmanagement_dbo.products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = clock_timestamp()
    WHERE productid = p_productid;
END;
$$;

-- Create Function for Deleting Product (converted from stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$;

-- Insert Sample Data
DO $$ BEGIN
IF NOT EXISTS (SELECT 1 FROM productmanagement_dbo.products LIMIT 1) THEN
    PERFORM productmanagement_dbo.sp_insertproduct('Laptop', 'High-performance laptop', 999.99, 10);
    PERFORM productmanagement_dbo.sp_insertproduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
    PERFORM productmanagement_dbo.sp_insertproduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
END IF;
END $$;
