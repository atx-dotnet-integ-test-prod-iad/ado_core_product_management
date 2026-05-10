-- ============================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- All statements converted manually with lowercase schema object names
-- ============================================================

-- Statement 1: GetAllProductsAsync (SELECT with CTE and window functions)
-- Location: ProductRepository.cs, GetAllProductsAsync method
-- Conversion: Schema objects lowercased. ROUND() compatible with PostgreSQL.
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

-- Statement 2: GetProductByIdAsync (SELECT with CTE and LAG window function)
-- Location: ProductRepository.cs, GetProductByIdAsync method
-- Conversion: Schema objects lowercased. LAG() and window functions compatible with PostgreSQL.
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

-- Statement 3: InsertProductAsync (Transaction with INSERT RETURNING, INSERT, UPDATE)
-- Location: ProductRepository.cs, InsertProductAsync method
-- Conversion: SCOPE_IDENTITY() replaced with RETURNING clause.
--             GETDATE() replaced with NOW().
--             DECLARE/SET replaced with PostgreSQL transaction pattern in code.
--             Transaction managed in application code via NpgsqlTransaction.
-- Part A: Insert with RETURNING
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Part B: History and stats update
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- Statement 4: UpdateProductAsync (Transaction with SELECT INTO, UPDATE, INSERT, UPDATE)
-- Location: ProductRepository.cs, UpdateProductAsync method
-- Conversion: DECLARE/SET pattern replaced with SELECT INTO in app code.
--             GETDATE() replaced with NOW().
--             Transaction managed in application code via NpgsqlTransaction.
-- Part A: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Part B: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Part C: History and stats
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- Statement 5: DeleteProductAsync (Transaction with SELECT, INSERT, DELETE, UPDATE)
-- Location: ProductRepository.cs, DeleteProductAsync method
-- Conversion: DECLARE/SET pattern replaced with SELECT INTO in app code.
--             GETDATE() replaced with NOW().
--             Transaction managed in application code via NpgsqlTransaction.
-- Part A: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Part B: Log deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Part C: Delete product
DELETE FROM products 
WHERE productid = @ProductId;

-- Part D: Update stats
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

-- Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE and RANK/PERCENT_RANK)
-- Location: ProductRepository.cs, GetProductsByPriceRangeAsync method
-- Conversion: Schema objects lowercased. RANK() and PERCENT_RANK() compatible with PostgreSQL.
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

-- Statement 7: GetLowStockProductsAsync (SELECT with CTE and AVG/MIN/MAX window functions)
-- Location: ProductRepository.cs, GetLowStockProductsAsync method
-- Conversion: Schema objects lowercased. Added ::numeric cast for integer division in ROUND().
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
