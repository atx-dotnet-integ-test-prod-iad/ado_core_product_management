-- ============================================================
-- CONVERTED PostgreSQL STATEMENTS FOR ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Schema: dbo -> productmanagement_dbo (not used in app queries since search_path can be set)
-- Table Mappings: Products->products, ProductHistory->producthistory, ProductStats->productstats
-- All column names converted to lowercase per DMS schema mapping
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Method: GetAllProductsAsync()
-- Changes: All identifiers lowercased per DMS schema mapping
-- Note: CTE, window functions, CASE, JOIN, ROUND all compatible with PostgreSQL
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Method: GetProductByIdAsync(int productId)
-- Changes: All identifiers lowercased, CTE name changed to avoid table name conflict
-- Parameters: @ProductId (Npgsql supports @param syntax)
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync (CONVERTED)
-- Method: InsertProductAsync(Product product)
-- Changes: SCOPE_IDENTITY() -> RETURNING + LASTVAL(), GETDATE() -> clock_timestamp()
-- DECLARE/SET removed, restructured for PostgreSQL compatibility
-- Transaction managed at application level via NpgsqlTransaction
-- Split into 3 separate statements executed sequentially in C#
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ============================================================
-- Statement 3a: Insert product and return new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion (uses @NewProductId from C# after 3a)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Statement 3c: Update product statistics
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Method: UpdateProductAsync(Product product)
-- Changes: DECLARE removed, old values fetched in separate SELECT,
-- GETDATE() -> clock_timestamp(), all identifiers lowercased
-- Transaction managed at application level via NpgsqlTransaction
-- Split into 4 separate statements executed sequentially in C#
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================
-- Statement 4a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 4b: Update the product
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Statement 4c: Log the changes (uses @OldPrice, @OldStock from C# after 4a)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Statement 4d: Update product statistics
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Method: DeleteProductAsync(int productId)
-- Changes: DECLARE removed, old values fetched in separate SELECT,
-- GETDATE() -> clock_timestamp(), all identifiers lowercased
-- Transaction managed at application level via NpgsqlTransaction
-- Split into 4 separate statements executed sequentially in C#
-- Parameters: @ProductId
-- ============================================================
-- Statement 5a: Get old values
SELECT price, stockquantity
FROM products
WHERE productid = @ProductId;

-- Statement 5b: Log the deletion (uses @OldPrice, @OldStock from C# after 5a)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Statement 5c: Delete the product
DELETE FROM products 
WHERE productid = @ProductId;

-- Statement 5d: Update product statistics
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

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Changes: All identifiers lowercased per DMS schema mapping
-- RANK(), PERCENT_RANK(), BETWEEN, CASE all compatible with PostgreSQL
-- Parameters: @MinPrice, @MaxPrice
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
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Method: GetLowStockProductsAsync(int threshold)
-- Changes: All identifiers lowercased per DMS schema mapping
-- AVG/MIN/MAX window functions, CASE, ROUND all compatible with PostgreSQL
-- ROUND needs CAST for integer division in PostgreSQL
-- Parameters: @Threshold
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
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
