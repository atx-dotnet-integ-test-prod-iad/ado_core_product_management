-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Date: 2026-02-26
-- ============================================================================

-- ==========================================================================
-- Statement 1: GetAllProductsAsync (Converted to PostgreSQL)
-- Location: ProductRepository.cs, GetAllProductsAsync() method
-- Changes: Schema objects converted to lowercase
-- ==========================================================================
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

-- ==========================================================================
-- Statement 2: GetProductByIdAsync (Converted to PostgreSQL)
-- Location: ProductRepository.cs, GetProductByIdAsync() method
-- Parameters: @ProductId
-- Changes: Schema objects converted to lowercase
-- ==========================================================================
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

-- ==========================================================================
-- Statement 3: InsertProductAsync (Converted to PostgreSQL)
-- Location: ProductRepository.cs, InsertProductAsync() method
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Type: Transaction block
-- Changes: SCOPE_IDENTITY() -> RETURNING + CTE, GETDATE() -> NOW(), 
--          DECLARE removed, lowercase schema objects,
--          Transaction restructured for PostgreSQL compatibility
-- ==========================================================================
BEGIN;
    WITH new_product AS (
        INSERT INTO products (name, description, price, stockquantity)
        VALUES (@Name, @Description, @Price, @StockQuantity)
        RETURNING productid
    )
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product;

    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- ==========================================================================
-- Statement 4: UpdateProductAsync (Converted to PostgreSQL)
-- Location: ProductRepository.cs, UpdateProductAsync() method
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Type: Transaction block
-- Changes: DECLARE removed, variable assignment via subquery,
--          GETDATE() -> NOW(), lowercase schema objects
-- ==========================================================================
BEGIN;
    -- Store old values and update in a single operation
    WITH old_values AS (
        SELECT price AS oldprice, stockquantity AS oldstock
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
            modifieddate = NOW()
        WHERE productid = @ProductId
        RETURNING productid
    )
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, NOW()
    FROM old_values ov;

    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ==========================================================================
-- Statement 5: DeleteProductAsync (Converted to PostgreSQL)
-- Location: ProductRepository.cs, DeleteProductAsync() method
-- Parameters: @ProductId
-- Type: Transaction block
-- Changes: DECLARE removed, variable assignment via subquery,
--          GETDATE() -> NOW(), lowercase schema objects
-- ==========================================================================
BEGIN;
    -- Log the deletion using values from the product before deleting
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
    FROM products
    WHERE productid = @ProductId;

    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;

    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT COALESCE(oldprice, 0) FROM producthistory WHERE productid = @ProductId AND action = 'DELETE' ORDER BY actiondate DESC LIMIT 1)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
COMMIT;

-- ==========================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted to PostgreSQL)
-- Location: ProductRepository.cs, GetProductsByPriceRangeAsync() method
-- Parameters: @MinPrice, @MaxPrice
-- Changes: Schema objects converted to lowercase
-- ==========================================================================
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

-- ==========================================================================
-- Statement 7: GetLowStockProductsAsync (Converted to PostgreSQL)
-- Location: ProductRepository.cs, GetLowStockProductsAsync() method
-- Parameters: @Threshold
-- Changes: Schema objects converted to lowercase, ROUND cast for integer division
-- ==========================================================================
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
