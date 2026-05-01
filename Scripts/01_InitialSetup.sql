-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is typically done outside of scripts
-- Use: CREATE DATABASE ProductManagement; from psql or pgAdmin

-- Create Products Table
CREATE TABLE IF NOT EXISTS Products(
    ProductId INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500) NULL,
    Price NUMERIC(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT NOW(),
    ModifiedDate TIMESTAMP NULL
);

-- Create Function for Getting All Products
CREATE OR REPLACE FUNCTION sp_GetAllProducts()
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price NUMERIC(18,2),
    StockQuantity INTEGER,
    CreatedDate TIMESTAMP,
    ModifiedDate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    ORDER BY p.Name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID
CREATE OR REPLACE FUNCTION sp_GetProductById(p_ProductId INTEGER)
RETURNS TABLE (
    ProductId INTEGER,
    Name VARCHAR(100),
    Description VARCHAR(500),
    Price NUMERIC(18,2),
    StockQuantity INTEGER,
    CreatedDate TIMESTAMP,
    ModifiedDate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    WHERE p.ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product
CREATE OR REPLACE FUNCTION sp_InsertProduct(
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price NUMERIC(18,2),
    p_StockQuantity INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    v_ProductId INTEGER;
BEGIN
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (p_Name, p_Description, p_Price, p_StockQuantity)
    RETURNING Products.ProductId INTO v_ProductId;
    
    RETURN v_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product
CREATE OR REPLACE FUNCTION sp_UpdateProduct(
    p_ProductId INTEGER,
    p_Name VARCHAR(100),
    p_Description VARCHAR(500),
    p_Price NUMERIC(18,2),
    p_StockQuantity INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE Products
    SET Name = p_Name,
        Description = p_Description,
        Price = p_Price,
        StockQuantity = p_StockQuantity,
        ModifiedDate = NOW()
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Deleting Product
CREATE OR REPLACE FUNCTION sp_DeleteProduct(p_ProductId INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM Products
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Products LIMIT 1) THEN
        PERFORM sp_InsertProduct('Laptop', 'High-performance laptop', 999.99, 10);
        PERFORM sp_InsertProduct('Mouse', 'Wireless gaming mouse', 49.99, 20);
        PERFORM sp_InsertProduct('Keyboard', 'Mechanical keyboard', 129.99, 15);
    END IF;
END $$;
