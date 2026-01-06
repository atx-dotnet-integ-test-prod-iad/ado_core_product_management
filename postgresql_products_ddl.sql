-- PostgreSQL CREATE TABLE for products (for SQL Equivalency validation)
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP NULL
);
