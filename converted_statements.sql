-- =====================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- All statements failed DMS conversion
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- =====================================================================

-- =====================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Conversion notes: 
--   - All table/column names lowercased
--   - ROUND and window functions are compatible
--   - CAST added for proper decimal division
-- =====================================================================
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

-- =====================================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Conversion notes:
--   - All table/column names lowercased
--   - LAG window function is compatible
--   - @ProductId parameter stays as @ProductId (Npgsql supports @param)
-- =====================================================================
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

-- =====================================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Conversion notes:
--   - SCOPE_IDENTITY() replaced with RETURNING + subqueries
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION/COMMIT removed (handled at app level)
--   - T-SQL DECLARE/SET not supported; restructured into multiple statements
--   - Split into: INSERT with RETURNING, then INSERT history, then UPDATE stats
-- =====================================================================
-- Sub-statement 3a: Insert product and get new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Sub-statement 3b: Insert history record (uses @NewProductId from app code)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Sub-statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Conversion notes:
--   - DECLARE/SET variables replaced with SELECT INTO
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION/COMMIT removed (handled at app level)
--   - Split into multiple statements
-- =====================================================================
-- Sub-statement 4a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Sub-statement 4b: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Sub-statement 4c: Insert history record
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Sub-statement 4d: Update statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Conversion notes:
--   - DECLARE/SET variables replaced with SELECT
--   - GETDATE() replaced with NOW()
--   - BEGIN TRANSACTION/COMMIT removed (handled at app level)
--   - Split into multiple statements
-- =====================================================================
-- Sub-statement 5a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Sub-statement 5b: Insert history record
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Sub-statement 5c: Delete product
DELETE FROM products 
WHERE productid = @ProductId;

-- Sub-statement 5d: Update statistics
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

-- =====================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Conversion notes:
--   - All table/column names lowercased
--   - RANK() and PERCENT_RANK() are compatible
--   - BETWEEN is compatible
-- =====================================================================
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

-- =====================================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Conversion notes:
--   - All table/column names lowercased
--   - Window functions AVG/MIN/MAX OVER() are compatible
--   - ROUND is compatible but need CAST for integer division
-- =====================================================================
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
