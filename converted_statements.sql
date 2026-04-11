-- ============================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
--   Products -> products (columns: productid, name, description, price, stockquantity, createddate, modifieddate)
--   ProductHistory -> producthistory (columns: historyid, productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--   ProductStats -> productstats (columns: statid, totalproducts, averageprice, lastupdated)
-- ============================================

-- ============================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with AVG/COUNT OVER, CASE, ROUND, INNER JOIN
-- Changes: Lowercase schema objects, ROUND with ::numeric cast
-- ============================================
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
    ROUND((p.price / ps.avgprice * 100)::numeric, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with LAG, CASE with NULL handling, ROUND
-- Changes: Lowercase schema objects, ROUND with ::numeric cast
-- ============================================
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
            ROUND(((p.price - ph.previousprice) / ph.previousprice * 100)::numeric, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE, SCOPE_IDENTITY(), GETDATE()
-- Changes: Lowercase, DO block with variables, RETURNING, clock_timestamp()
-- ============================================
DO $$
DECLARE
    v_newproductid INTEGER;
BEGIN
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- Note: For the C# integration, the INSERT with RETURNING is used directly
-- to get the new product ID via ExecuteScalarAsync

-- ============================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE()
-- Changes: Lowercase, DO block, clock_timestamp()
-- ============================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
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
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, clock_timestamp());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE, SELECT INTO vars, DELETE, INSERT, UPDATE CASE, GETDATE()
-- Changes: Lowercase, DO block, clock_timestamp()
-- ============================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, clock_timestamp());
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
END $$;

-- ============================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
-- Changes: Lowercase schema objects
-- ============================================
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

-- ============================================
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX OVER, CASE, ROUND
-- Changes: Lowercase schema objects, ROUND with ::numeric cast
-- ============================================
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
    ROUND((stockquantity::numeric / avgstock * 100)::numeric, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
