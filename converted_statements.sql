-- ============================================================================
-- Converted SQL Statements (PostgreSQL) from ProductRepository.cs
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- All schema object names converted to lowercase for PostgreSQL compatibility
-- Key conversions: SCOPE_IDENTITY() -> LASTVAL(), GETDATE() -> NOW(),
--                  DECLARE/SET patterns -> inline subqueries, ROUND -> ROUND with CAST
-- Note: Statements 4 and 5 use inline subqueries (not DO $ blocks) for ADO.NET
--       @parameter compatibility. This file reflects the DEPLOYED versions.
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Type: Single SELECT with CTE and Window Functions
-- Parameters: None
-- Conversion: ROUND with integer division fix (CAST to NUMERIC)
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
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Type: Single SELECT with CTE and Window Functions
-- Parameters: @ProductId (int)
-- Conversion: LAG() OVER() compatible, ROUND with CAST
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
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Type: Transaction block with INSERT, LASTVAL(), NOW()
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Conversion: SCOPE_IDENTITY() -> LASTVAL(), GETDATE() -> NOW(),
--             DECLARE @var -> DO block not needed, use LASTVAL() inline
-- ============================================================================

BEGIN;
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (LASTVAL(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT LASTVAL();

-- ============================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Type: Transaction block with inline subqueries, NOW()
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Conversion: DECLARE/SET pattern -> inline subqueries (DO $ blocks
--             incompatible with ADO.NET @parameters), GETDATE() -> NOW()
-- Note: This is the DEPLOYED version using inline subqueries instead of
--       DO $ blocks, matching the actual code in ProductRepository.cs
-- ============================================================================

BEGIN;
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    -- Log the changes (use subqueries for old values)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE',
        (SELECT price FROM products WHERE productid = @ProductId),
        @Price,
        (SELECT stockquantity FROM products WHERE productid = @ProductId),
        @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Type: Transaction block with inline subqueries, NOW(), CASE
-- Parameters: @ProductId
-- Conversion: DECLARE/SET pattern -> inline subqueries (DO $ blocks
--             incompatible with ADO.NET @parameters), GETDATE() -> NOW()
-- Note: This is the DEPLOYED version using inline subqueries instead of
--       DO $ blocks, matching the actual code in ProductRepository.cs.
--       Operations reordered: log + stats update before DELETE to capture
--       old values via subqueries.
-- ============================================================================

BEGIN;
    -- Log the deletion (capture old values via subqueries before delete)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE',
        (SELECT price FROM products WHERE productid = @ProductId),
        NULL,
        (SELECT stockquantity FROM products WHERE productid = @ProductId),
        NULL, NOW());
    
    -- Update product statistics (capture old price via subquery before delete)
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;

    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Type: Single SELECT with CTE and Window Functions
-- Parameters: @MinPrice, @MaxPrice
-- Conversion: RANK()/PERCENT_RANK() compatible, BETWEEN compatible
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
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Type: Single SELECT with CTE and Window Functions
-- Parameters: @Threshold
-- Conversion: AVG/MIN/MAX OVER() compatible, ROUND with CAST for integer division
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
