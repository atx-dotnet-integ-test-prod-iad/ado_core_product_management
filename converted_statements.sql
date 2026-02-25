-- ========================================================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL EQUIVALENTS
-- ========================================================================================================
-- This file contains all SQL statements converted to PostgreSQL syntax.
-- Each statement is mapped to its original from extracted_statements.sql
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (All 7 statements)
-- DMS Tool Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ========================================================================================================

-- ========================================================================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE, Window Functions
-- ========================================================================================================
-- Original Statement: Statement 1 from extracted_statements.sql
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- PostgreSQL Changes Applied:
--   - Schema objects to lowercase: Products -> products, ProductStats -> productstats (CTE)
--   - All column names to lowercase: ProductId -> productid, Name -> name, etc.
--   - ROUND() function compatible with PostgreSQL
-- ========================================================================================================

WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ========================================================================================================
-- CONVERTED STATEMENT 2: GetProductByIdAsync - SELECT with CTE, LAG Window Function
-- ========================================================================================================
-- Original Statement: Statement 2 from extracted_statements.sql
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- PostgreSQL Changes Applied:
--   - Schema objects to lowercase: Products -> products, ProductHistory -> producthistory (CTE)
--   - All column names to lowercase
--   - LAG() window function compatible with PostgreSQL
--   - Parameter @ProductId remains compatible with Npgsql
-- ========================================================================================================

WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ========================================================================================================
-- CONVERTED STATEMENT 3: InsertProductAsync - Transaction Block with INSERT and RETURNING
-- ========================================================================================================
-- Original Statement: Statement 3 from extracted_statements.sql
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- PostgreSQL Changes Applied:
--   - Schema objects to lowercase: Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
--   - All column names to lowercase
--   - BEGIN TRANSACTION -> BEGIN
--   - DECLARE @NewProductId INT -> Removed (using RETURNING clause instead)
--   - SET @NewProductId = SCOPE_IDENTITY() -> Replaced with RETURNING clause
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - INSERT with RETURNING productid to get new ID
--   - Using DO block with variables for PostgreSQL transaction pattern
-- ========================================================================================================

DO $$
DECLARE
    new_product_id INT;
BEGIN
    -- Insert the new product and get the ID
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO new_product_id;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (new_product_id, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product ID
    PERFORM new_product_id;
END $$;

-- ========================================================================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync - Transaction Block with SELECT, UPDATE, INSERT
-- ========================================================================================================
-- Original Statement: Statement 4 from extracted_statements.sql
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- PostgreSQL Changes Applied:
--   - Schema objects to lowercase: Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
--   - All column names to lowercase
--   - BEGIN TRANSACTION -> BEGIN (implicit in DO block)
--   - DECLARE @Variable DECIMAL/INT -> PostgreSQL variable syntax
--   - SELECT @Var = Column -> SELECT Column INTO var
--   - GETDATE() -> CURRENT_TIMESTAMP
-- ========================================================================================================

DO $$
DECLARE
    old_price DECIMAL(18,2);
    old_stock INT;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO old_price, old_stock
    FROM products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', old_price, @Price, old_stock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - old_price + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ========================================================================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync - Transaction Block with SELECT, INSERT, DELETE, UPDATE
-- ========================================================================================================
-- Original Statement: Statement 5 from extracted_statements.sql
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- PostgreSQL Changes Applied:
--   - Schema objects to lowercase: Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
--   - All column names to lowercase
--   - BEGIN TRANSACTION -> BEGIN (implicit in DO block)
--   - DECLARE variables with PostgreSQL syntax
--   - GETDATE() -> CURRENT_TIMESTAMP
-- ========================================================================================================

DO $$
DECLARE
    old_price DECIMAL(18,2);
    old_stock INT;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO old_price, old_stock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', old_price, NULL, old_stock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - old_price) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ========================================================================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK() and PERCENT_RANK()
-- ========================================================================================================
-- Original Statement: Statement 6 from extracted_statements.sql
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- PostgreSQL Changes Applied:
--   - Schema objects to lowercase: Products -> products, RankedProducts -> rankedproducts (CTE)
--   - All column names to lowercase
--   - RANK() and PERCENT_RANK() window functions compatible with PostgreSQL
-- ========================================================================================================

WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- ========================================================================================================
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ========================================================================================================
-- Original Statement: Statement 7 from extracted_statements.sql
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- PostgreSQL Changes Applied:
--   - Schema objects to lowercase: Products -> products, StockAnalysis -> stockanalysis (CTE)
--   - All column names to lowercase
--   - AVG(), MIN(), MAX() window functions compatible with PostgreSQL
--   - ROUND() function compatible with PostgreSQL
-- ========================================================================================================

WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ========================================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- ========================================================================================================
-- Total Statements Converted: 7
-- Conversion Method: All statements manually converted due to DMS tool failure
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Manual Conversion Approach: Applied lowercase schema object names and PostgreSQL-specific syntax
-- Key PostgreSQL Syntax Changes:
--   - SCOPE_IDENTITY() -> RETURNING clause
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION -> BEGIN (or implicit in DO blocks)
--   - Variable declarations using PostgreSQL syntax
--   - Table/column names to lowercase for PostgreSQL naming conventions
-- ========================================================================================================
