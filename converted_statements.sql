-- ============================================================
-- Converted SQL Statements for PostgreSQL
-- Target Database: PostgreSQL (ProductManagement)
-- Schema: productmanagement_dbo (from DMS schema mapping)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema mapping source: DMS schema_mapping_tool (successful)
-- Total Statements: 7
-- ============================================================

-- ===========================================
-- Statement 1: GetAllProductsAsync()
-- Location: ProductRepository.cs, GetAllProductsAsync method
-- Conversion: Lowercase schema objects per DMS schema mapping
-- ===========================================
WITH ProductStats AS (
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
INNER JOIN ProductStats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ===========================================
-- Statement 2: GetProductByIdAsync()
-- Location: ProductRepository.cs, GetProductByIdAsync method
-- Conversion: Lowercase schema objects per DMS schema mapping
-- ===========================================
WITH ProductHistory AS (
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
LEFT JOIN ProductHistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ===========================================
-- Statement 3: InsertProductAsync()
-- Location: ProductRepository.cs, InsertProductAsync method
-- Conversion: SCOPE_IDENTITY() replaced with RETURNING, GETDATE() with clock_timestamp()
-- Transaction management moved to C# application level
-- ===========================================
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM new_product
    RETURNING productid
)
SELECT productid FROM new_product;

-- Note: ProductStats update is executed as a separate statement:
-- UPDATE productstats SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp() WHERE statid = 1;

-- ===========================================
-- Statement 4: UpdateProductAsync()
-- Location: ProductRepository.cs, UpdateProductAsync method
-- Conversion: DECLARE/SET replaced with subquery, GETDATE() with clock_timestamp()
-- Transaction management moved to C# application level
-- ===========================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
do_update AS (
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId
    RETURNING productid
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, clock_timestamp()
    FROM old_values ov
    RETURNING productid
)
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ===========================================
-- Statement 5: DeleteProductAsync()
-- Location: ProductRepository.cs, DeleteProductAsync method
-- Conversion: DECLARE/SET replaced with subquery, GETDATE() with clock_timestamp()
-- Transaction management moved to C# application level
-- ===========================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM products
    WHERE productid = @ProductId
),
log_history AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, clock_timestamp()
    FROM old_values ov
    RETURNING productid
),
do_delete AS (
    DELETE FROM products 
    WHERE productid = @ProductId
    RETURNING productid
)
UPDATE productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ===========================================
-- Statement 6: GetProductsByPriceRangeAsync()
-- Location: ProductRepository.cs, GetProductsByPriceRangeAsync method
-- Conversion: Lowercase schema objects per DMS schema mapping
-- ===========================================
WITH RankedProducts AS (
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
FROM RankedProducts rp
ORDER BY rp.pricerank;

-- ===========================================
-- Statement 7: GetLowStockProductsAsync()
-- Location: ProductRepository.cs, GetLowStockProductsAsync method
-- Conversion: Lowercase schema objects, CAST for integer division
-- ===========================================
WITH StockAnalysis AS (
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
FROM StockAnalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
