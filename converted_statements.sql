-- =====================================================
-- Converted SQL Statements Catalog (PostgreSQL)
-- Source: AdoCore .NET Application
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Conversion: Window functions compatible, schema names lowercased
-- =====================================================

-- [PGSQL_STATEMENT_1]
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
-- [END_PGSQL_STATEMENT_1]

-- =====================================================
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Conversion: LAG() compatible, schema names lowercased
-- =====================================================

-- [PGSQL_STATEMENT_2]
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
-- [END_PGSQL_STATEMENT_2]

-- =====================================================
-- Statement 3: InsertProductAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Conversion: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(),
--             DECLARE removed, restructured for PostgreSQL
-- =====================================================

-- [PGSQL_STATEMENT_3]
BEGIN;
    -- Insert the new product and get new ID
    WITH new_product AS (
        INSERT INTO products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING productid
    )
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('products', 'productid'));
-- [END_PGSQL_STATEMENT_3]

-- =====================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Conversion: DECLARE removed, GETDATE() -> NOW(),
--             restructured to use subqueries instead of variables
-- =====================================================

-- [PGSQL_STATEMENT_4]
BEGIN;
    -- Log the changes (capture old values via subquery)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Update product statistics (capture old price via subquery)
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;

    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
COMMIT;
-- [END_PGSQL_STATEMENT_4]

-- =====================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Conversion: DECLARE removed, GETDATE() -> NOW(),
--             restructured to use subqueries instead of variables
-- =====================================================

-- [PGSQL_STATEMENT_5]
BEGIN;
    -- Log the deletion (capture old values via subquery)
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products
    WHERE productid = @ProductId;
    
    -- Update product statistics (capture old price via subquery)
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;

    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
COMMIT;
-- [END_PGSQL_STATEMENT_5]

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: Window functions compatible, schema names lowercased
-- =====================================================

-- [PGSQL_STATEMENT_6]
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
-- [END_PGSQL_STATEMENT_6]

-- =====================================================
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion: Window functions compatible, schema names lowercased,
--             ROUND cast to numeric for integer division fix
-- =====================================================

-- [PGSQL_STATEMENT_7]
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
-- [END_PGSQL_STATEMENT_7]
