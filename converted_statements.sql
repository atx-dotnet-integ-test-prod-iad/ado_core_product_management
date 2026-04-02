-- ============================================
-- Converted PostgreSQL Statements from ProductRepository.cs
-- Source: DataAccess/ProductRepository.cs
-- Conversion Date: 2026-04-02
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion did not complete after 15 attempts (persistent infrastructure timeout)
-- Total Statements: 7
-- ============================================

-- ============================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Conversion notes: Lowercase schema objects, syntax compatible with PostgreSQL
-- ============================================
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

-- ============================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Conversion notes: Lowercase schema objects, LAG window function compatible
-- ============================================
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

-- ============================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Conversion notes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(), 
--   Transaction block converted, DECLARE removed (uses DO block pattern or inline RETURNING)
-- ============================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The ProductHistory insert and ProductStats update are handled
-- as separate statements in the C# code since PostgreSQL doesn't support
-- the same multi-statement transaction pattern with SCOPE_IDENTITY().
-- The C# code captures the returned productid and uses it in subsequent queries.

-- ============================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Conversion notes: DECLARE vars -> subquery pattern, GETDATE() -> NOW()
-- ============================================
DO $$
DECLARE
    _oldprice DECIMAL(18,2);
    _oldstock INT;
BEGIN
    SELECT price, stockquantity INTO _oldprice, _oldstock
    FROM products
    WHERE productid = @ProductId;
    
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', _oldprice, @Price, _oldstock, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - _oldprice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Conversion notes: DECLARE vars -> subquery pattern, GETDATE() -> NOW(), CASE preserved
-- ============================================
DO $$
DECLARE
    _oldprice DECIMAL(18,2);
    _oldstock INT;
BEGIN
    SELECT price, stockquantity INTO _oldprice, _oldstock
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', _oldprice, NULL, _oldstock, NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - _oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Conversion notes: Lowercase schema objects, RANK/PERCENT_RANK compatible
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
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Conversion notes: Lowercase schema objects, CAST for integer division
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
    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
