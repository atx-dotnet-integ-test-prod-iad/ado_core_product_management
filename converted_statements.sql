-- =============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: ADO.NET Core SQL Server Application
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema mapping sourced from DMS schema_mapping_tool (successful)
-- =============================================================================

-- =============================================================================
-- STATEMENT 1: GetAllProductsAsync (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Conversion: Lowercase schema object names per DMS schema mapping
-- =============================================================================
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

-- =============================================================================
-- STATEMENT 2: GetProductByIdAsync (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Conversion: Lowercase schema object names per DMS schema mapping
-- =============================================================================
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

-- =============================================================================
-- STATEMENT 3: InsertProductAsync (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Conversion: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp(),
--   DECLARE removed, BEGIN TRANSACTION -> BEGIN, lowercase schema
-- =============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- =============================================================================
-- STATEMENT 4: UpdateProductAsync (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Conversion: GETDATE() -> clock_timestamp(), DECLARE @var pattern removed,
--   lowercase schema names
-- Note: Transaction block with DECLARE variables restructured.
--   The C# code will handle the transaction via Npgsql BeginTransaction.
--   The multi-statement transaction with variable storage is split into
--   separate queries executed within a C# transaction scope.
-- =============================================================================
-- Query 1: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Query 2: Update product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;
-- Query 3: Log changes (uses @OldPrice, @OldStock from C# variables)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
-- Query 4: Update stats
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- =============================================================================
-- STATEMENT 5: DeleteProductAsync (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Conversion: Same pattern as Update - DECLARE removed, GETDATE() -> clock_timestamp(),
--   lowercase schema names, transaction handled in C#
-- =============================================================================
-- Query 1: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- Query 2: Log deletion (uses @OldPrice, @OldStock from C# variables)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
-- Query 3: Delete product
DELETE FROM products WHERE productid = @ProductId;
-- Query 4: Update stats
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

-- =============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: Lowercase schema object names per DMS schema mapping
-- =============================================================================
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

-- =============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (Converted)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion: Lowercase schema object names per DMS schema mapping
-- Note: Added CAST(stockquantity AS NUMERIC) for integer division fix in PostgreSQL
-- =============================================================================
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

-- =============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total statements converted: 7
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7)
-- DMS conversion successes: 0 (all failed with metadata model creation error)
-- Schema mapping from DMS schema_mapping_tool was used to inform conversions
-- =============================================================================
