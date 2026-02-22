-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: AdoCore Application
-- Conversion Method: Manual (DMS tool failed for all statements)
-- Generated: Migration Phase 2
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex SELECT with CTE and Window Functions
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
-- - Schema objects converted to lowercase: Products -> products, ProductId -> productid, etc.
-- - All PostgreSQL-compatible syntax (CTEs, window functions, CASE) maintained
-- - ROUND function works the same in PostgreSQL
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - SELECT with CTE and LAG Window Function
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
-- - Schema objects converted to lowercase
-- - LAG function is natively supported in PostgreSQL
-- - Parameter @ProductId remains compatible with Npgsql
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-statement Transaction Block
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
-- - Schema objects converted to lowercase
-- - DECLARE statement removed (PostgreSQL handles differently in code)
-- - SCOPE_IDENTITY() replaced with RETURNING clause
-- - GETDATE() replaced with CURRENT_TIMESTAMP or NOW()
-- - Transaction will be handled by Npgsql in C# code
-- - Restructured to use RETURNING for new ID
-- ============================================================================

-- Note: This will be executed as separate statements within a transaction in C# code
-- Statement 3a: Insert product and return ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion (executed after getting productid from above)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-statement Transaction Block
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
-- - Schema objects converted to lowercase
-- - Variables will be handled in C# code instead of SQL variables
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - Transaction will be handled by Npgsql
-- - Split into separate statements for C# execution
-- ============================================================================

-- Statement 4a: Get old values (executed first, values stored in C# variables)
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 4b: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 4c: Log the changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-statement Transaction Block
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
-- - Schema objects converted to lowercase
-- - Variables will be handled in C# code
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - Transaction will be handled by Npgsql
-- - Split into separate statements for C# execution
-- ============================================================================

-- Statement 5a: Get product info for history (executed first, values stored in C# variables)
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 5b: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 5d: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - SELECT with CTE and Window Functions
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
-- - Schema objects converted to lowercase
-- - RANK() and PERCENT_RANK() are natively supported in PostgreSQL
-- - BETWEEN clause works the same
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - SELECT with CTE and Window Functions
-- ============================================================================
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes Applied:
-- - Schema objects converted to lowercase
-- - AVG, MIN, MAX window functions are natively supported in PostgreSQL
-- - ROUND function works the same
-- ============================================================================

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

-- ============================================================================
-- CONVERSION SUMMARY
-- ============================================================================
-- Total Statements Converted: 7
-- Conversion Method: Manual (all DMS conversions failed)
-- Key PostgreSQL Conversions Applied:
-- 1. All schema objects converted to lowercase for PostgreSQL compatibility
-- 2. GETDATE() replaced with CURRENT_TIMESTAMP
-- 3. SCOPE_IDENTITY() replaced with RETURNING clause
-- 4. Transaction blocks restructured for Npgsql execution in C# code
-- 5. SQL Server variables replaced with C# code variable handling
-- 6. All window functions, CTEs, and analytical functions are PostgreSQL-compatible
-- ============================================================================
