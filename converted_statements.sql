-- ============================================================
-- Converted PostgreSQL Statements (from MS SQL Server originals)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
--   Products -> productmanagement_dbo.products (lowercase columns)
--   ProductHistory -> productmanagement_dbo.producthistory (lowercase columns)
--   ProductStats -> productmanagement_dbo.productstats (lowercase columns)
-- Date: 2026-04-16
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync() - PostgreSQL Version
-- Conversion: Table/column names lowercased per DMS schema mapping
-- Schema: productmanagement_dbo
-- ============================================================
WITH ProductStats AS (
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
INNER JOIN ProductStats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================
-- Statement 2: GetProductByIdAsync(int productId) - PostgreSQL Version
-- Conversion: Table/column names lowercased per DMS schema mapping
-- Schema: productmanagement_dbo
-- Parameters: @ProductId (kept for Npgsql compatibility)
-- ============================================================
WITH ProductHistory AS (
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
LEFT JOIN ProductHistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================
-- Statement 3: InsertProductAsync(Product product) - PostgreSQL Version
-- Conversion: SCOPE_IDENTITY() -> RETURNING clause with CTE approach
--   GETDATE() -> clock_timestamp()
--   DECLARE @var -> PostgreSQL DO block not needed, using RETURNING + CTEs
--   Transaction handled at application level by Npgsql
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- NOTE: For ADO.NET integration, this is split into individual statements
--   executed within a C# managed transaction
-- ============================================================
-- Sub-statement 3a: Insert product and get new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Sub-statement 3b: Insert history (uses returned productid as @NewProductId)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Sub-statement 3c: Update stats
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync(Product product) - PostgreSQL Version
-- Conversion: DECLARE @var / SELECT INTO @var -> SELECT INTO local vars
--   GETDATE() -> clock_timestamp()
--   Transaction handled at application level by Npgsql
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- NOTE: For ADO.NET integration, split into individual statements
--   executed within a C# managed transaction
-- ============================================================
-- Sub-statement 4a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Sub-statement 4b: Update product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Sub-statement 4c: Insert history
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Sub-statement 4d: Update stats
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync(int productId) - PostgreSQL Version
-- Conversion: DECLARE @var / SELECT INTO @var -> SELECT INTO local vars
--   GETDATE() -> clock_timestamp()
--   Transaction handled at application level by Npgsql
-- Parameters: @ProductId
-- NOTE: For ADO.NET integration, split into individual statements
--   executed within a C# managed transaction
-- ============================================================
-- Sub-statement 5a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Sub-statement 5b: Insert deletion history
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Sub-statement 5c: Delete product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Sub-statement 5d: Update stats
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice) - PostgreSQL Version
-- Conversion: Table/column names lowercased per DMS schema mapping
-- Schema: productmanagement_dbo
-- Parameters: @MinPrice, @MaxPrice
-- ============================================================
WITH RankedProducts AS (
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
FROM RankedProducts rp
ORDER BY rp.pricerank;

-- ============================================================
-- Statement 7: GetLowStockProductsAsync(int threshold) - PostgreSQL Version
-- Conversion: Table/column names lowercased per DMS schema mapping
--   CAST for integer division handling
-- Schema: productmanagement_dbo
-- Parameters: @Threshold
-- ============================================================
WITH StockAnalysis AS (
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
FROM StockAnalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
