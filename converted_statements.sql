-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Reason: DMS tool failed with "Metadata model creation did not complete after 15 attempts"
-- ============================================================

-- ==============================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original: MS SQL with CTE, window functions, CASE, ROUND, INNER JOIN
-- Changes: Lowercase table/column names, CAST for integer division
-- ==============================================================
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

-- ==============================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original: MS SQL with CTE, LAG window function, LEFT JOIN, ROUND
-- Changes: Lowercase table/column names, CAST for division
-- ==============================================================
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

-- ==============================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original: MS SQL with DECLARE, SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
-- Changes: Lowercase names, SCOPE_IDENTITY() -> RETURNING + lastval(),
--          GETDATE() -> NOW(), DO block for variables
-- ==============================================================
-- Insert the new product
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity);

-- Log the insertion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

SELECT lastval();

-- ==============================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original: MS SQL with DECLARE variables, SELECT INTO variables, GETDATE()
-- Changes: Lowercase names, subqueries for old values, GETDATE() -> NOW()
-- ==============================================================
-- Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Log the changes
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

-- ==============================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original: MS SQL with DECLARE variables, SELECT INTO, DELETE, CASE, GETDATE()
-- Changes: Lowercase names, subqueries for old values, GETDATE() -> NOW()
-- ==============================================================
-- Log the deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', 
    (SELECT price FROM products WHERE productid = @ProductId),
    NULL, 
    (SELECT stockquantity FROM products WHERE productid = @ProductId),
    NULL, NOW());

-- Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Update product statistics
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

-- ==============================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: MS SQL with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
-- Changes: Lowercase table/column names
-- ==============================================================
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

-- ==============================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: MS SQL with CTE, AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: Lowercase table/column names, CAST for integer division
-- ==============================================================
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
