-- ============================================================================
-- Converted PostgreSQL Statements Catalog
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema mappings obtained from DMS schema_mapping_tool:
--   Products -> productmanagement_dbo.products (all columns lowercase)
--   ProductHistory -> productmanagement_dbo.producthistory (all columns lowercase)
--   ProductStats -> productmanagement_dbo.productstats (all columns lowercase)
-- Note: Schema prefix 'productmanagement_dbo.' is not used in queries as the
--   application should set the search_path in the connection string.
-- Date: 2026-04-09
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Conversion: All identifiers lowercased per DMS schema mapping
-- SQL Server -> PostgreSQL changes: identifiers to lowercase only
-- CTE, window functions, CASE, ROUND all compatible with PostgreSQL
-- ============================================================================

WITH productstats_cte AS (
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
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- Statement 2: GetProductByIdAsync
-- Conversion: All identifiers lowercased per DMS schema mapping
-- SQL Server -> PostgreSQL changes: identifiers to lowercase only
-- CTE with LAG, CASE, ROUND all compatible with PostgreSQL
-- Parameters: @ProductId (Npgsql supports @param syntax natively)
-- ============================================================================

WITH producthistory_cte AS (
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
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- Statement 3: InsertProductAsync
-- Conversion: Major restructuring required
-- SQL Server -> PostgreSQL changes:
--   SCOPE_IDENTITY() -> RETURNING clause with INSERT
--   GETDATE() -> clock_timestamp()
--   BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
--   DECLARE @Variable -> PostgreSQL variable in DO block
--   Multi-statement batch restructured for PostgreSQL compatibility
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Note: Restructured to use INSERT...RETURNING and separate statements
--   executed within C# managed transaction (BeginTransaction/Commit)
-- ============================================================================

INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- (Executed as separate command in C# after retrieving newProductId)
-- INSERT INTO producthistory:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- UPDATE productstats:
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- Conversion: Major restructuring required
-- SQL Server -> PostgreSQL changes:
--   DECLARE @Variable -> Separate SELECT query in C#
--   GETDATE() -> clock_timestamp()
--   BEGIN TRANSACTION/COMMIT -> C# managed transaction
--   Multi-statement batch restructured for PostgreSQL compatibility
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================================

-- Get old values (separate query in C#):
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Update product:
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Log changes:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Update stats:
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- Conversion: Major restructuring required
-- SQL Server -> PostgreSQL changes:
--   DECLARE @Variable -> Separate SELECT query in C#
--   GETDATE() -> clock_timestamp()
--   BEGIN TRANSACTION/COMMIT -> C# managed transaction
--   CASE WHEN in UPDATE compatible with PostgreSQL
-- Parameters: @ProductId
-- ============================================================================

-- Get old values (separate query in C#):
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Log deletion:
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Delete product:
DELETE FROM products 
WHERE productid = @ProductId;

-- Update stats:
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Conversion: All identifiers lowercased per DMS schema mapping
-- SQL Server -> PostgreSQL changes: identifiers to lowercase only
-- CTE with RANK/PERCENT_RANK, BETWEEN, CASE all compatible with PostgreSQL
-- Parameters: @MinPrice, @MaxPrice
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
-- Statement 7: GetLowStockProductsAsync
-- Conversion: All identifiers lowercased per DMS schema mapping
-- SQL Server -> PostgreSQL changes:
--   identifiers to lowercase
--   Added ::numeric cast for integer division to get decimal result
-- CTE with AVG/MIN/MAX OVER(), CASE, ROUND all compatible with PostgreSQL
-- Parameters: @Threshold
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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
