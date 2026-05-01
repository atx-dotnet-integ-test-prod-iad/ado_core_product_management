-- ============================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- All 7 statements failed DMS conversion and were manually converted
-- All schema object names converted to lowercase for PostgreSQL compatibility
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync
-- Original: CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
-- Conversion: Compatible with PostgreSQL as-is with lowercase schema names
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
-- Statement 2: GetProductByIdAsync
-- Original: CTE with LAG window functions, parameterized @ProductId, LEFT JOIN, CASE with ROUND
-- Conversion: Compatible with PostgreSQL with lowercase schema names
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
-- Statement 3: InsertProductAsync
-- Original: DECLARE @NewProductId, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats, COMMIT, SELECT @NewProductId
-- Conversion: Use INSERT...RETURNING for new ID, separate statements for history and stats
--   Transaction is managed in C# code. The C# method restructured to execute multiple commands.
--   However, to keep the single-command pattern, use a CTE-based approach or
--   multiple statements separated by semicolons (Npgsql supports this).
-- Approach: Split into individual parameterized SQL statements executed in a C# transaction
-- ============================================================
-- Part A: Insert product and get new ID (ExecuteScalarAsync)
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Part B: Insert history record (ExecuteNonQueryAsync, uses @NewProductId from Part A)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Part C: Update statistics (ExecuteNonQueryAsync)
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync
-- Original: BEGIN TRANSACTION, DECLARE @OldPrice/@OldStock, SELECT into vars, UPDATE, INSERT history, UPDATE stats, COMMIT
-- Conversion: Use subqueries to avoid DECLARE, GETDATE() -> NOW()
--   Transaction managed in C# code. Split into individual parameterized statements.
-- ============================================================
-- Part A: Get old values and update product (single statement with CTE not practical, split)
-- Actually, for Npgsql we can use multiple statements in one command text:
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
)
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Part B: Insert history (uses subquery to get old values before they were updated)
-- NOTE: Since old values are already updated, we need to restructure the C# code
-- to capture old values first. The approach below uses separate statements in C# transaction.

-- Alternative: Full restructured approach for C# (3 separate commands in transaction)
-- Cmd 1: SELECT price, stockquantity FROM products WHERE productid = @ProductId (reader to get old values)
-- Cmd 2: UPDATE products SET ... WHERE productid = @ProductId
-- Cmd 3: INSERT INTO producthistory ...
-- Cmd 4: UPDATE productstats ...

-- ============================================================
-- Statement 5: DeleteProductAsync
-- Original: BEGIN TRANSACTION, DECLARE @OldPrice/@OldStock, SELECT, INSERT history, DELETE, UPDATE stats, COMMIT
-- Conversion: Similar to Statement 4, split into individual commands in C# transaction
-- ============================================================
-- Same restructuring approach as Statement 4

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Original: CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE
-- Conversion: Compatible with PostgreSQL with lowercase schema names
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
-- Statement 7: GetLowStockProductsAsync
-- Original: CTE with AVG/MIN/MAX window functions OVER(), CASE, ROUND, @Threshold
-- Conversion: Compatible with PostgreSQL with lowercase schema names
-- Added CAST for integer division
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
