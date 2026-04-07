-- =====================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed for all 7 statements
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Original: SQL Server CTE with AVG/COUNT OVER, INNER JOIN, CASE, ROUND
-- Changes: lowercase table/column names, ROUND cast for numeric division
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
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Original: SQL Server CTE with LAG, LEFT JOIN, CASE, ROUND
-- Changes: lowercase table/column names, ROUND cast for numeric division
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
-- Statement 3: InsertProductAsync (CONVERTED)
-- Original: SQL Server DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY, GETDATE
-- Changes: Restructured to use multiple statements within C# ADO.NET transaction
--          SCOPE_IDENTITY() -> RETURNING productid / lastval()
--          GETDATE() -> NOW()
--          lowercase table/column names
-- Note: This is split into multiple statements executed within C# BeginTransactionAsync
-- =====================================================
-- Statement 3a: Insert product and get new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion (using @NewProductId from C# after 3a)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Original: SQL Server BEGIN TRANSACTION, DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE
-- Changes: Restructured to use multiple statements within C# ADO.NET transaction
--          GETDATE() -> NOW()
--          lowercase table/column names
-- Note: This is split into multiple statements executed within C# BeginTransactionAsync
-- =====================================================
-- Statement 4a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 4b: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Statement 4c: Log changes (using @OldPrice and @OldStock from C# after 4a)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Original: SQL Server BEGIN TRANSACTION, DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE, GETDATE
-- Changes: Restructured to use multiple statements within C# ADO.NET transaction
--          GETDATE() -> NOW()
--          lowercase table/column names
-- Note: This is split into multiple statements executed within C# BeginTransactionAsync
-- =====================================================
-- Statement 5a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 5b: Log deletion (using @OldPrice and @OldStock from C# after 5a)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete product
DELETE FROM products WHERE productid = @ProductId;

-- Statement 5d: Update statistics
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

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Original: SQL Server CTE with RANK, PERCENT_RANK, BETWEEN, CASE
-- Changes: lowercase table/column names
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
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Original: SQL Server CTE with AVG/MIN/MAX OVER, CASE, ROUND
-- Changes: lowercase table/column names, CAST for numeric division
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
