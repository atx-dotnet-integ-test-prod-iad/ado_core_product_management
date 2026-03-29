-- ============================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Target: PostgreSQL 13 (postgres database)
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation did not complete after 15 attempts
-- All schema object names converted to lowercase for PostgreSQL compatibility
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (converted from MS SQL)
-- Conversion: lowercase schema objects, ROUND cast for PostgreSQL
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
-- Statement 2: GetProductByIdAsync (converted from MS SQL)
-- Conversion: lowercase schema objects, LAG window function compatible
-- Parameters: @ProductId (kept as-is for C# parameter binding)
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
-- Statement 3: InsertProductAsync (converted from MS SQL)
-- Conversion: Transaction block rewritten for PostgreSQL. 
--   SCOPE_IDENTITY() removed - uses INSERT...RETURNING productid for first INSERT.
--   Subsequent INSERTs and UPDATEs executed as separate commands in C# transaction.
--   GETDATE() -> NOW(), lowercase schema objects.
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- 
-- Part A: Insert product and return new ID
-- ============================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Part B: Log the insertion (executed after Part A, with newProductId from RETURNING)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Part C: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync (converted from MS SQL)
-- Conversion: Transaction block rewritten for PostgreSQL.
--   DECLARE/@variable pattern replaced with SELECT INTO + separate statements in C# transaction.
--   GETDATE() -> NOW(), lowercase schema objects.
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
--
-- Part A: Get old values
-- ============================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Part B: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Part C: Log the changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Part D: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync (converted from MS SQL)
-- Conversion: Transaction block rewritten for PostgreSQL.
--   DECLARE/@variable pattern replaced with SELECT + separate statements in C# transaction.
--   GETDATE() -> NOW(), lowercase schema objects.
-- Parameters: @ProductId
--
-- Part A: Get old values
-- ============================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Part B: Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Part C: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Part D: Update product statistics
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
-- Statement 6: GetProductsByPriceRangeAsync (converted from MS SQL)
-- Conversion: lowercase schema objects, RANK/PERCENT_RANK compatible
-- Parameters: @MinPrice, @MaxPrice
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
-- Statement 7: GetLowStockProductsAsync (converted from MS SQL)
-- Conversion: lowercase schema objects, ROUND cast for integer division
-- Parameters: @Threshold
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
