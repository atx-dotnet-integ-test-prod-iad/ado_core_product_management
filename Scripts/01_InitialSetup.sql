-- Create ProductManagement Database
-- Note: In PostgreSQL, database creation is done outside of a script context
-- CREATE DATABASE ProductManagement;

-- Create Products Table
CREATE TABLE IF NOT EXISTS Products(
    ProductId SERIAL PRIMARY KEY,
    Name varchar(100) NOT NULL,
    Description varchar(500) NULL,
    Price decimal(18, 2) NOT NULL,
    StockQuantity int NOT NULL,
    CreatedDate timestamp NOT NULL DEFAULT NOW(),
    ModifiedDate timestamp NULL
);

-- Create Function for Getting All Products (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_GetAllProducts()
RETURNS TABLE(
    ProductId int,
    Name varchar(100),
    Description varchar(500),
    Price decimal(18,2),
    StockQuantity int,
    CreatedDate timestamp,
    ModifiedDate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    ORDER BY p.Name;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Getting Product by ID (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_GetProductById(p_ProductId INT)
RETURNS TABLE(
    ProductId int,
    Name varchar(100),
    Description varchar(500),
    Price decimal(18,2),
    StockQuantity int,
    CreatedDate timestamp,
    ModifiedDate timestamp
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate
    FROM Products p
    WHERE p.ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Inserting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_InsertProduct(
    p_Name varchar(100),
    p_Description varchar(500),
    p_Price decimal(18,2),
    p_StockQuantity int
) RETURNS int AS $$
DECLARE
    v_ProductId int;
BEGIN
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (p_Name, p_Description, p_Price, p_StockQuantity)
    RETURNING Products.ProductId INTO v_ProductId;
    
    RETURN v_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Create Function for Updating Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_UpdateProduct(
    p_ProductId INT,
    p_Name varchar(100),
    p_Description varchar(500),
    p_Price decimal(18,2),
    p_StockQuantity int
) RETURNS void AS $$
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

-- Create Function for Deleting Product (replaces stored procedure)
CREATE OR REPLACE FUNCTION sp_DeleteProduct(p_ProductId INT)
RETURNS void AS $$
BEGIN
    DELETE FROM Products
    WHERE ProductId = p_ProductId;
END;
$$ LANGUAGE plpgsql;

-- Insert Sample Data
INSERT INTO Products (Name, Description, Price, StockQuantity)
SELECT 'Laptop', 'High-performance laptop', 999.99, 10
WHERE NOT EXISTS (SELECT 1 FROM Products LIMIT 1);

INSERT INTO Products (Name, Description, Price, StockQuantity)
SELECT 'Mouse', 'Wireless gaming mouse', 49.99, 20
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Mouse');

INSERT INTO Products (Name, Description, Price, StockQuantity)
SELECT 'Keyboard', 'Mechanical keyboard', 129.99, 15
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE Name = 'Keyboard');
