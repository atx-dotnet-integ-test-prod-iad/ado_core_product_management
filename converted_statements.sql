-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Equivalents
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Source: DataAccess/ProductRepository.cs
-- Database: ProductManagement
-- Original Schema: dbo -> PostgreSQL: public (default)
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Conversion notes:
--   - Schema objects lowercased for PostgreSQL compatibility
--   - CTE syntax is compatible between SQL Server and PostgreSQL
--   - Window functions (AVG OVER, COUNT OVER) are compatible
--   - ROUND, CASE, INNER JOIN are compatible
-- ============================================================================
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

-- ============================================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Conversion notes:
--   - Schema objects lowercased
--   - LAG window function is compatible
--   - LEFT JOIN, CASE with NULL handling compatible
--   - Parameter syntax @ProductId compatible with Npgsql
-- ============================================================================
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

-- ============================================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Conversion notes:
--   - SCOPE_IDENTITY() replaced with INSERT...RETURNING
--   - GETDATE() -> NOW()
--   - Schema objects lowercased
--   - Restructured: C# code will manage transaction via BeginTransaction
--   - Three separate SQL statements executed sequentially in C# transaction
--   - INSERT returns new productid via RETURNING clause with ExecuteScalarAsync
--   - Second INSERT and UPDATE use returned productid as parameter
-- ============================================================================
-- Part A: Insert product and get new ID (executed via ExecuteScalarAsync)
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Part B: Log the insertion (executed via ExecuteNonQueryAsync, @NewProductId from Part A)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Part C: Update product statistics (executed via ExecuteNonQueryAsync)
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Conversion notes:
--   - DECLARE @var / SELECT @var = col replaced with SELECT INTO in separate query
--   - GETDATE() -> NOW()
--   - Schema objects lowercased
--   - Restructured: C# code will manage transaction via BeginTransaction
--   - Four separate SQL statements executed sequentially in C# transaction
-- ============================================================================
-- Part A: Get old values (executed via ExecuteReaderAsync)
SELECT price as oldprice, stockquantity as oldstock
FROM products
WHERE productid = @ProductId;

-- Part B: Update the product (executed via ExecuteNonQueryAsync)
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- Part C: Log the changes (executed via ExecuteNonQueryAsync)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Part D: Update product statistics (executed via ExecuteNonQueryAsync)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Conversion notes:
--   - DECLARE @var / SELECT @var = col replaced with SELECT INTO in separate query
--   - GETDATE() -> NOW()
--   - Schema objects lowercased
--   - Restructured: C# code will manage transaction via BeginTransaction
--   - Four separate SQL statements executed sequentially in C# transaction
-- ============================================================================
-- Part A: Get old values (executed via ExecuteReaderAsync)
SELECT price as oldprice, stockquantity as oldstock
FROM products
WHERE productid = @ProductId;

-- Part B: Log the deletion (executed via ExecuteNonQueryAsync)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Part C: Delete the product (executed via ExecuteNonQueryAsync)
DELETE FROM products 
WHERE productid = @ProductId;

-- Part D: Update product statistics (executed via ExecuteNonQueryAsync)
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

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Conversion notes:
--   - Schema objects lowercased
--   - RANK(), PERCENT_RANK() window functions are compatible
--   - BETWEEN, CASE are compatible
-- ============================================================================
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

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Conversion notes:
--   - Schema objects lowercased
--   - AVG/MIN/MAX OVER() window functions are compatible
--   - CASE, ROUND are compatible
--   - CAST added for integer division in ROUND
-- ============================================================================
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
