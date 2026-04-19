-- =====================================================
-- Converted SQL Statements for PostgreSQL (Npgsql/ADO.NET Compatible)
-- Target: PostgreSQL (productmanagement_dbo schema)
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Schema Mapping Used: Yes (schema_mapping_tool successful)
-- DMS Statement Conversion: Failed (metadata model creation error)
-- Schema: dbo -> productmanagement_dbo
-- Table Mappings:
--   Products -> productmanagement_dbo.products
--   ProductHistory -> productmanagement_dbo.producthistory
--   ProductStats -> productmanagement_dbo.productstats
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Original: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND, ORDER BY CASE
-- Changes: Lowercase table/column names, schema prefix
-- =====================================================
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- =====================================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Original: CTE with LAG window function, LEFT JOIN, CASE with ROUND and NULL handling
-- Changes: Lowercase table/column names, schema prefix
-- =====================================================
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- =====================================================
-- Statement 3: InsertProductAsync (Converted)
-- Original: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
-- Changes: Use WITH ... INSERT RETURNING for new ID, GETDATE() -> NOW(),
--          Split into multi-statement batch for Npgsql compatibility,
--          Lowercase table/column names, schema prefix
-- Note: In C# code, this will be restructured to use individual commands
--       within a C# transaction (BeginTransaction/Commit)
-- =====================================================
-- Part A: Insert product and get new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Part B: Log insertion (executed separately with @NewProductId from Part A)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Part C: Update stats (executed separately)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Original: BEGIN TRANSACTION, DECLARE variables, SELECT into variables, UPDATE, INSERT, GETDATE()
-- Changes: Use subqueries instead of DECLARE variables, GETDATE() -> NOW(),
--          Lowercase table/column names, schema prefix
-- Note: In C# code, individual commands within a C# transaction
-- =====================================================
-- Part A: Get old values (executed first, read in C#)
SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Part B: Update product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Part C: Log changes (uses @OldPrice, @OldStock from Part A read in C#)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Part D: Update stats
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Original: BEGIN TRANSACTION, DECLARE variables, SELECT into variables, DELETE, INSERT, CASE, GETDATE()
-- Changes: Use subqueries instead of DECLARE variables, GETDATE() -> NOW(),
--          Lowercase table/column names, schema prefix
-- Note: In C# code, individual commands within a C# transaction
-- =====================================================
-- Part A: Get old values (executed first, read in C#)
SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Part B: Log deletion (uses @OldPrice, @OldStock from Part A)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Part C: Delete product
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- Part D: Update stats
UPDATE productmanagement_dbo.productstats
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
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Original: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
-- Changes: Lowercase table/column names, schema prefix
-- =====================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
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
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: Lowercase table/column names, schema prefix,
--          Cast integer division to NUMERIC for ROUND
-- =====================================================
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
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
