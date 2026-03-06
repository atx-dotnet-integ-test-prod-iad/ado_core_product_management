-- PostgreSQL Initial Setup Script for ProductManagement
-- Converted from MS SQL Server using DMS MCP Tool and manual conversion

-- Create Schema (if not exists)
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create Products Table (if not exists)
CREATE TABLE IF NOT EXISTS productmanagement_dbo.products
(productid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL);

-- Create Function for Getting All Products (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getallproducts()
RETURNS TABLE (productid BIGINT, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM productmanagement_dbo.products p
    ORDER BY p.name;
END;
$$;

-- Create Function for Getting Product by ID (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_getproductbyid(p_productid INTEGER)
RETURNS TABLE (productid BIGINT, name VARCHAR, description VARCHAR, price NUMERIC, stockquantity INTEGER, createddate TIMESTAMP, modifieddate TIMESTAMP)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT pr.productid, pr.name, pr.description, pr.price, pr.stockquantity, pr.createddate, pr.modifieddate
    FROM productmanagement_dbo.products pr
    WHERE pr.productid = p_productid;
END;
$$;

-- Create Function for Inserting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_insertproduct(p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_productid BIGINT;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid INTO v_productid;
    RETURN v_productid;
END;
$$;

-- Create Function for Updating Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_updateproduct(p_productid INTEGER, p_name VARCHAR, p_description VARCHAR, p_price NUMERIC, p_stockquantity INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
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

-- Create Function for Deleting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION productmanagement_dbo.sp_deleteproduct(p_productid INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM productmanagement_dbo.products
    WHERE productid = p_productid;
END;
$$;

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
