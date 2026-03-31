-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is typically done outside of scripts
-- using: CREATE DATABASE productmanagement;
-- The following is commented out as it requires superuser privileges and
-- cannot be run inside a transaction block.
-- CREATE DATABASE productmanagement;

-- Create products table
CREATE TABLE IF NOT EXISTS products(
    productid SERIAL PRIMARY KEY,
    name varchar(100) NOT NULL,
    description varchar(500) NULL,
    price decimal(18, 2) NOT NULL,
    stockquantity int NOT NULL,
    createddate timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate timestamp NULL
);

-- Create function for getting all products
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE(
    productid int,
    name varchar(100),
    description varchar(500),
    price decimal(18, 2),
    stockquantity int,
    createddate timestamp,
    modifieddate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create function for getting product by ID
CREATE OR REPLACE FUNCTION sp_getproductbyid(p_productid INT)
RETURNS TABLE(
    productid int,
    name varchar(100),
    description varchar(500),
    price decimal(18, 2),
    stockquantity int,
    createddate timestamp,
    modifieddate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate
    FROM products p
    WHERE p.productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create function for inserting product
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name varchar(100),
    p_description varchar(500),
    p_price decimal(18,2),
    p_stockquantity int
)
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

-- Create function for updating product
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid int,
    p_name varchar(100),
    p_description varchar(500),
    p_price decimal(18,2),
    p_stockquantity int
)
RETURNS void AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stockquantity = p_stockquantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = p_productid;
END;
$$ LANGUAGE plpgsql;

-- Create function for deleting product
CREATE OR REPLACE FUNCTION sp_deleteproduct(p_productid int)
RETURNS void AS $$
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
