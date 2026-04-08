-- =============================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- All schema object names converted to lowercase for PostgreSQL compatibility.
-- GETDATE() -> NOW(), SCOPE_IDENTITY() -> lastval(), DECLARE @var -> using DO blocks or subqueries
-- =============================================================================

-- =============================================================================
-- Statement 1: GetAllProductsAsync - CTE with window functions
-- Conversion: Schema objects lowercased. SQL syntax is PostgreSQL-compatible.
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
-- Statement 2: GetProductByIdAsync - CTE with LAG window functions
-- Conversion: Schema objects lowercased. SQL syntax is PostgreSQL-compatible.
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
-- Statement 3: InsertProductAsync - Writable CTE with INSERT RETURNING/NOW()
-- Conversion: SCOPE_IDENTITY() replaced with INSERT...RETURNING in writable CTE,
--   GETDATE() -> NOW(), transaction replaced with single CTE statement, DECLARE removed.
-- =============================================================================
                WITH new_product AS (
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid
                ),
                insert_history AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
                    FROM new_product
                    RETURNING productid
                ),
                update_stats AS (
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = NOW()
                    WHERE statid = 1
                    RETURNING statid
                )
                SELECT productid FROM new_product;

-- =============================================================================
-- Statement 4: UpdateProductAsync - Writable CTE with NOW()
-- Conversion: GETDATE() -> NOW(), DECLARE variables replaced with CTE approach,
--   schema objects lowercased, transaction replaced with single writable CTE.
-- =============================================================================
                WITH old_values AS (
                    SELECT price, stockquantity
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
                ),
                insert_history AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', ov.price, @Price, ov.stockquantity, @StockQuantity, NOW()
                    FROM old_values ov
                )
                UPDATE productstats
                SET 
                    averageprice = (averageprice * totalproducts - (SELECT price FROM old_values) + @Price) / totalproducts,
                    lastupdated = NOW()
                WHERE statid = 1;

-- =============================================================================
-- Statement 5: DeleteProductAsync - Writable CTE with NOW()/CASE
-- Conversion: GETDATE() -> NOW(), DECLARE variables replaced with CTE approach,
--   schema objects lowercased, transaction replaced with single writable CTE.
-- =============================================================================
                WITH old_values AS (
                    SELECT price, stockquantity
                    FROM products
                    WHERE productid = @ProductId
                ),
                insert_history AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', ov.price, NULL, ov.stockquantity, NULL, NOW()
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
                        THEN (averageprice * totalproducts - (SELECT price FROM old_values)) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = NOW()
                WHERE statid = 1;

-- =============================================================================
-- Statement 6: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- Conversion: Schema objects lowercased. SQL syntax is PostgreSQL-compatible.
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
-- Statement 7: GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions
-- Conversion: Schema objects lowercased. SQL syntax is PostgreSQL-compatible.
-- ROUND requires explicit cast of integer division to numeric in PostgreSQL.
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
