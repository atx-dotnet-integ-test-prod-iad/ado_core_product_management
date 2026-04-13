-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Target Database: PostgreSQL
-- Schema Mapping: dbo -> productmanagement_dbo (from DMS Schema Mapping Tool)
-- Table Mapping: Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
-- Column Mapping: All columns converted to lowercase (from DMS Schema Mapping Tool)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Total Statements: 7
-- ============================================================================

-- ==========================================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Conversion: Applied lowercase schema objects per DMS schema mapping
-- Changes: Products->products, ProductId->productid, Name->name, etc.
--          ROUND function compatible with PostgreSQL (cast to numeric for division)
-- ==========================================================================
WITH productstats_cte AS (
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
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ==========================================================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Conversion: Applied lowercase schema objects per DMS schema mapping
-- Changes: Products->products, ProductId->productid, LAG compatible with PG
--          @ProductId parameter syntax compatible with Npgsql
-- ==========================================================================
WITH producthistory_cte AS (
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
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ==========================================================================
-- Statement 3: InsertProductAsync (Converted)
-- Conversion: SCOPE_IDENTITY() -> RETURNING + currval approach
--             GETDATE() -> clock_timestamp() (per DMS schema mapping)
--             DECLARE/SET -> restructured for PostgreSQL compatibility
--             Transaction block preserved, uses DO block for variable support
-- ==========================================================================
DO $$
DECLARE
    var_newproductid INTEGER;
BEGIN
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO var_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (var_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- NOTE: The DO block above cannot be used directly with Npgsql parameters.
-- The actual implementation in C# will split this into individual statements:
-- 1. INSERT INTO products ... RETURNING productid
-- 2. INSERT INTO producthistory ...
-- 3. UPDATE productstats ...
-- The RETURNING clause replaces SCOPE_IDENTITY()

-- ==========================================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Conversion: DECLARE -> restructured for PostgreSQL
--             GETDATE() -> clock_timestamp()
--             SELECT @var = col -> SELECT col INTO var (PG style)
-- ==========================================================================
DO $$
DECLARE
    var_oldprice NUMERIC(18,2);
    var_oldstock INTEGER;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity
    INTO var_oldprice, var_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_oldprice, @Price, var_oldstock, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - var_oldprice + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- NOTE: Same as Statement 3 - actual C# implementation will use individual statements
-- with Npgsql parameters, handling old values through a SELECT first.

-- ==========================================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Conversion: DECLARE -> restructured for PostgreSQL
--             GETDATE() -> clock_timestamp()
--             CASE expression compatible with PostgreSQL
-- ==========================================================================
DO $$
DECLARE
    var_oldprice NUMERIC(18,2);
    var_oldstock INTEGER;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity
    INTO var_oldprice, var_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_oldprice, NULL, var_oldstock, NULL, clock_timestamp());
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - var_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- NOTE: Same as Statement 3 - actual C# implementation will use individual statements

-- ==========================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Conversion: Applied lowercase schema objects per DMS schema mapping
--             RANK(), PERCENT_RANK(), BETWEEN all compatible with PostgreSQL
-- ==========================================================================
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

-- ==========================================================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Conversion: Applied lowercase schema objects per DMS schema mapping
--             AVG/MIN/MAX window functions compatible with PostgreSQL
--             ROUND function needs cast for integer division in PostgreSQL
-- ==========================================================================
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
