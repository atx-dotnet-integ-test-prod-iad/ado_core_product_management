-- =====================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: AdoCore .NET Application
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- All 7 DMS attempts failed with metadata model conversion/creation timeout errors
-- =====================================================

-- =====================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model conversion did not complete after 15 attempts
-- Conversion: Manual with lowercase schema objects
-- =====================================================

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

-- =====================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model conversion did not complete after 15 attempts
-- Conversion: Manual with lowercase schema objects
-- =====================================================

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

-- =====================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Statement definition is not valid
-- Conversion: Manual with lowercase schema objects
-- Key changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(),
--   BEGIN TRANSACTION -> BEGIN, restructured to use RETURNING clause
-- =====================================================

INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The ProductHistory insert and ProductStats update are handled
-- as separate commands in the application code after getting the new productid.
-- ProductHistory insert:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
-- ProductStats update:
-- UPDATE productstats SET totalproducts = totalproducts + 1,
--   averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--   lastupdated = NOW() WHERE statid = 1;

-- =====================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model conversion did not complete after 15 attempts
-- Conversion: Manual with lowercase schema objects
-- Key changes: DECLARE @var -> application variables, GETDATE() -> NOW(),
--   BEGIN TRANSACTION -> BEGIN
-- =====================================================

BEGIN;
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- =====================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model conversion did not complete after 15 attempts
-- Conversion: Manual with lowercase schema objects
-- Key changes: DECLARE @var -> application variables, GETDATE() -> NOW(),
--   BEGIN TRANSACTION -> BEGIN
-- =====================================================

BEGIN;
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- =====================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation did not complete after 15 attempts
-- Conversion: Manual with lowercase schema objects
-- =====================================================

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

-- =====================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- DMS Status: FAILED - Metadata model creation did not complete after 15 attempts
-- Conversion: Manual with lowercase schema objects
-- Key changes: Added ::numeric cast for integer division in ROUND
-- =====================================================

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
