-- ============================================================
-- Converted SQL Statements Catalog
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Tool Error: Metadata model creation timed out after maximum poll attempts
-- DMS Tool ARN: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
-- Conversion Date: 2026-03-27
-- Total Statements: 15
-- Note: All statements were attempted through DMS MCP tool but it failed with 
--       timeout errors. Manual conversion applied with lowercase schema mapping.
--       The original SQL was already PostgreSQL-compatible (using Npgsql), so
--       lowercase schema mapping is confirmed already in place.
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync - CTE with Window Functions
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync - CTE with LAG Window Function
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync - INSERT with RETURNING
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ============================================================
-- Statement 4: InsertProductAsync - INSERT History for INSERT action
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- ============================================================
-- Statement 5: InsertProductAsync - UPDATE Stats for insert
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 6: UpdateProductAsync - SELECT Old Values (update path)
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- ============================================================
-- Statement 7: UpdateProductAsync - UPDATE Product
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- ============================================================
-- Statement 8: UpdateProductAsync - INSERT History for UPDATE action
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- ============================================================
-- Statement 9: UpdateProductAsync - UPDATE Stats for update
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 10: DeleteProductAsync - SELECT Old Values (delete path)
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- ============================================================
-- Statement 11: DeleteProductAsync - INSERT History for DELETE action
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- ============================================================
-- Statement 12: DeleteProductAsync - DELETE Product
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
DELETE FROM products 
WHERE productid = @ProductId;

-- ============================================================
-- Statement 13: DeleteProductAsync - UPDATE Stats for delete
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
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

-- ============================================================
-- Statement 14: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
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

-- ============================================================
-- Statement 15: GetLowStockProductsAsync - CTE with Window Aggregates
-- DMS Status: FAILED - Metadata model creation timed out
-- Conversion: Manual - lowercase schema confirmed
-- ============================================================
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
