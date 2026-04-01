-- ============================================================
-- Converted SQL Statements for PostgreSQL
-- Source: MS SQL Server -> PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion timeout
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Changes: Table/column names lowercased
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
-- Statement 2: GetProductByIdAsync (Converted)
-- Changes: Table/column names lowercased
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
-- Statement 3: InsertProductAsync (Converted)
-- Changes: SCOPE_IDENTITY() -> lastval(), GETDATE() -> CURRENT_TIMESTAMP,
--          BEGIN TRANSACTION -> BEGIN, Table/column names lowercased
-- ============================================================
BEGIN;
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);

    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- ============================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Changes: DECLARE variables removed - reordered to capture old values via
--          INSERT...SELECT before UPDATE, GETDATE() -> CURRENT_TIMESTAMP,
--          BEGIN TRANSACTION -> BEGIN, Table/column names lowercased
-- ============================================================
BEGIN;
    -- Log the changes (capture old values before update)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, CURRENT_TIMESTAMP
    FROM products WHERE productid = @ProductId;

    -- Update product statistics (use old price from history before updating product)
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT oldprice FROM producthistory WHERE productid = @ProductId AND action = 'UPDATE' ORDER BY actiondate DESC LIMIT 1) + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;

    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Changes: DECLARE variables removed - reordered to capture old values via
--          INSERT...SELECT before DELETE, GETDATE() -> CURRENT_TIMESTAMP,
--          BEGIN TRANSACTION -> BEGIN, Table/column names lowercased
-- ============================================================
BEGIN;
    -- Log the deletion (capture old values before delete)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, CURRENT_TIMESTAMP
    FROM products WHERE productid = @ProductId;

    -- Update product statistics (use old price from history)
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT oldprice FROM producthistory WHERE productid = @ProductId AND action = 'DELETE' ORDER BY actiondate DESC LIMIT 1)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;

    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
COMMIT;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Changes: Table/column names lowercased
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
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Changes: Table/column names lowercased
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
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
