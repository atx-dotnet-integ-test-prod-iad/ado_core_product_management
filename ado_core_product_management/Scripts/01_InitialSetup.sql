-- =============================================================================
-- PostgreSQL Setup Script for AdoCore Product Management
-- Converted from T-SQL (SQL Server) to PostgreSQL
-- =============================================================================
-- NOTE: Database creation is handled outside this script.
--       Connect to the target database before running this script.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Create Products Table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    productid     SERIAL          PRIMARY KEY,
    name          VARCHAR(100)    NOT NULL,
    description   VARCHAR(500)    NULL,
    price         NUMERIC(18, 2)  NOT NULL,
    stockquantity INTEGER         NOT NULL,
    createddate   TIMESTAMP       NOT NULL DEFAULT NOW(),
    modifieddate  TIMESTAMP       NULL
);

-- ---------------------------------------------------------------------------
-- Function: sp_getallproducts
-- Returns all products ordered by name.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_getallproducts()
RETURNS TABLE (
    productid     INTEGER,
    name          VARCHAR(100),
    description   VARCHAR(500),
    price         NUMERIC(18, 2),
    stockquantity INTEGER,
    createddate   TIMESTAMP,
    modifieddate  TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            p.productid,
            p.name,
            p.description,
            p.price,
            p.stockquantity,
            p.createddate,
            p.modifieddate
        FROM products p
        ORDER BY p.name;
END;
$$;

-- ---------------------------------------------------------------------------
-- Function: sp_getproductbyid
-- Returns a single product row matching the given productid.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_getproductbyid(
    p_productid INTEGER
)
RETURNS TABLE (
    productid     INTEGER,
    name          VARCHAR(100),
    description   VARCHAR(500),
    price         NUMERIC(18, 2),
    stockquantity INTEGER,
    createddate   TIMESTAMP,
    modifieddate  TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            p.productid,
            p.name,
            p.description,
            p.price,
            p.stockquantity,
            p.createddate,
            p.modifieddate
        FROM products p
        WHERE p.productid = p_productid;
END;
$$;

-- ---------------------------------------------------------------------------
-- Function: sp_insertproduct
-- Inserts a new product and returns the generated productid.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_insertproduct(
    p_name          VARCHAR(100),
    p_description   VARCHAR(500),
    p_price         NUMERIC(18, 2),
    p_stockquantity INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_productid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (p_name, p_description, p_price, p_stockquantity)
    RETURNING productid INTO v_new_productid;

    RETURN v_new_productid;
END;
$$;

-- ---------------------------------------------------------------------------
-- Function: sp_updateproduct
-- Updates an existing product record identified by productid.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_updateproduct(
    p_productid     INTEGER,
    p_name          VARCHAR(100),
    p_description   VARCHAR(500),
    p_price         NUMERIC(18, 2),
    p_stockquantity INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET name          = p_name,
        description   = p_description,
        price         = p_price,
        stockquantity = p_stockquantity,
        modifieddate  = NOW()
    WHERE productid = p_productid;
END;
$$;

-- ---------------------------------------------------------------------------
-- Function: sp_deleteproduct
-- Deletes a product record identified by productid.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_deleteproduct(
    p_productid INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM products
    WHERE productid = p_productid;
END;
$$;

-- ---------------------------------------------------------------------------
-- Sample Data
-- Inserted only when the products table is empty (idempotent).
-- ---------------------------------------------------------------------------
INSERT INTO products (name, description, price, stockquantity)
SELECT * FROM (VALUES
    ('Laptop',   'High-performance laptop',  999.99::NUMERIC(18,2), 10),
    ('Mouse',    'Wireless gaming mouse',     49.99::NUMERIC(18,2), 20),
    ('Keyboard', 'Mechanical keyboard',      129.99::NUMERIC(18,2), 15)
) AS seed(name, description, price, stockquantity)
WHERE NOT EXISTS (SELECT 1 FROM products LIMIT 1);
