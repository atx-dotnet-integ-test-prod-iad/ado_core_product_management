-- Create ProductManagement Database
-- Note: In PostgreSQL, CREATE DATABASE must be run separately from psql or a management tool
-- CREATE DATABASE ProductManagement;

-- Create Products Table
CREATE TABLE IF NOT EXISTS products(
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(18, 2) NOT NULL,
    stock_quantity INT NOT NULL,
    created_date TIMESTAMP NOT NULL DEFAULT NOW(),
    modified_date TIMESTAMP NULL
);

-- Create Function for Getting All Products
CREATE OR REPLACE FUNCTION sp_get_all_products()
RETURNS TABLE(product_id INT, name VARCHAR, description VARCHAR, price DECIMAL, stock_quantity INT, created_date TIMESTAMP, modified_date TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_id, p.name, p.description, p.price, p.stock_quantity, p.created_date, p.modified_date
    FROM products p
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_get_product_by_id(p_product_id INT)
RETURNS TABLE(product_id INT, name VARCHAR, description VARCHAR, price DECIMAL, stock_quantity INT, created_date TIMESTAMP, modified_date TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_id, p.name, p.description, p.price, p.stock_quantity, p.created_date, p.modified_date
    FROM products p
    WHERE p.product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product
CREATE OR REPLACE FUNCTION sp_insert_product(p_name VARCHAR, p_description VARCHAR, p_price DECIMAL, p_stock_quantity INT)
RETURNS INT AS $$
DECLARE
    v_product_id INT;
BEGIN
    INSERT INTO products (name, description, price, stock_quantity)
    VALUES (p_name, p_description, p_price, p_stock_quantity)
    RETURNING products.product_id INTO v_product_id;
    
    RETURN v_product_id;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product
CREATE OR REPLACE FUNCTION sp_update_product(p_product_id INT, p_name VARCHAR, p_description VARCHAR, p_price DECIMAL, p_stock_quantity INT)
RETURNS VOID AS $$
BEGIN
    UPDATE products
    SET name = p_name,
        description = p_description,
        price = p_price,
        stock_quantity = p_stock_quantity,
        modified_date = NOW()
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Deleting Product
CREATE OR REPLACE FUNCTION sp_delete_product(p_product_id INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM products
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM products LIMIT 1) THEN
        PERFORM sp_insert_product('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_insert_product('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_insert_product('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;
