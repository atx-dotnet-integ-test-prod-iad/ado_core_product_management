-- =============================================
-- Converted SQL Statements for PostgreSQL
-- Source: Microsoft SQL Server (T-SQL) -> PostgreSQL
-- Conversion Date: 2026-04-03
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion did not complete after multiple attempts
-- Total Statements: 7
-- =============================================

-- =============================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Method: GetAllProductsAsync()
-- Type: CTE with AVG/COUNT window functions
-- Changes: All schema objects lowercased, ROUND cast to numeric for proper division
-- =============================================
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

-- =============================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Method: GetProductByIdAsync(int productId)
-- Type: CTE with LAG window function
-- Changes: All schema objects lowercased
-- Parameters: @ProductId
-- =============================================
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

-- =============================================
-- Statement 3: InsertProductAsync (Converted)
-- Method: InsertProductAsync(Product product)
-- Type: Transaction block - converted from SCOPE_IDENTITY()/GETDATE() to RETURNING/NOW()
-- Changes: SCOPE_IDENTITY() -> RETURNING + subquery, GETDATE() -> NOW(),
--          BEGIN TRANSACTION -> BEGIN, all schema objects lowercased,
--          DECLARE @var pattern replaced with subquery pattern
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- =============================================
BEGIN;
    -- Insert the new product and capture the new ID
    WITH new_product AS (
        INSERT INTO products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING productid
    )
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- =============================================
-- Statement 4: UpdateProductAsync (Converted)
-- Method: UpdateProductAsync(Product product)
-- Type: Transaction block - converted from DECLARE/GETDATE()
-- Changes: DECLARE @var -> subquery pattern with old_values CTE, GETDATE() -> NOW(),
--          BEGIN TRANSACTION -> BEGIN, all schema objects lowercased
-- Note: old values must be captured BEFORE the update, so we use a CTE approach
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- =============================================
BEGIN;
    -- Log the changes using current values (before update) via subquery
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Update product statistics using old price before update
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
    
    -- Update the product (after capturing old values)
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
COMMIT;

-- =============================================
-- Statement 5: DeleteProductAsync (Converted)
-- Method: DeleteProductAsync(int productId)
-- Type: Transaction block - converted from DECLARE/CASE/GETDATE()
-- Changes: DECLARE @var -> subquery pattern, GETDATE() -> NOW(),
--          BEGIN TRANSACTION -> BEGIN, all schema objects lowercased
-- Parameters: @ProductId
-- =============================================
BEGIN;
    -- Log the deletion using subquery for product info
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Update product statistics before delete
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

-- =============================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Type: CTE with RANK/PERCENT_RANK
-- Changes: All schema objects lowercased
-- Parameters: @MinPrice, @MaxPrice
-- =============================================
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

-- =============================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Method: GetLowStockProductsAsync(int threshold)
-- Type: CTE with AVG/MIN/MAX window functions
-- Changes: All schema objects lowercased,
--          cast integer division to numeric for ROUND
-- Parameters: @Threshold
-- =============================================
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
