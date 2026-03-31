-- ============================================================================
-- Converted SQL Statements for PostgreSQL
-- Target: PostgreSQL 13
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation/conversion did not complete after 15 attempts (timeout)
-- Total Statements: 7
-- ============================================================================

-- =============================================================
-- Statement 1: GetAllProductsAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, method GetAllProductsAsync()
-- Changes: Schema objects to lowercase, compatible with PostgreSQL
-- =============================================================
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

-- =============================================================
-- Statement 2: GetProductByIdAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, method GetProductByIdAsync()
-- Changes: Schema objects to lowercase, LAG window function compatible
-- =============================================================
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

-- =============================================================
-- Statement 3: InsertProductAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, method InsertProductAsync()
-- Changes: SCOPE_IDENTITY() replaced with RETURNING + currval,
--          GETDATE() -> CURRENT_TIMESTAMP, schema objects to lowercase.
--          Transaction block preserved for ADO.NET compatibility.
--          Variable pattern replaced with subquery approach.
-- =============================================================
                BEGIN;
                    -- Insert the new product
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity);
                    
                    -- Log the insertion
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (currval(pg_get_serial_sequence('products', 'productid')), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1;
                COMMIT;
                
                SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- =============================================================
-- Statement 4: UpdateProductAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, method UpdateProductAsync()
-- Changes: DECLARE vars replaced with subquery in INSERT,
--          GETDATE() -> CURRENT_TIMESTAMP, schema objects to lowercase.
--          Transaction block preserved.
-- =============================================================
                BEGIN;
                    -- Update the product
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = CURRENT_TIMESTAMP
                    WHERE productid = @ProductId;
                    
                    -- Log the changes (using subquery for old values from product before update)
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', ph_old.price, @Price, ph_old.stockquantity, @StockQuantity, CURRENT_TIMESTAMP
                    FROM (SELECT price, stockquantity FROM products WHERE productid = @ProductId) ph_old;
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        averageprice = (SELECT AVG(price) FROM products),
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1;
                COMMIT;

-- =============================================================
-- Statement 5: DeleteProductAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, method DeleteProductAsync()
-- Changes: DECLARE vars replaced with subquery in INSERT,
--          GETDATE() -> CURRENT_TIMESTAMP, schema objects to lowercase.
--          CASE in UPDATE preserved. Transaction block preserved.
-- =============================================================
                BEGIN;
                    -- Log the deletion (capture old values via subquery before delete)
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, CURRENT_TIMESTAMP
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
                            THEN (SELECT COALESCE(AVG(price), 0) FROM products)
                            ELSE 0
                        END,
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1;
                COMMIT;

-- =============================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, method GetProductsByPriceRangeAsync()
-- Changes: Schema objects to lowercase, RANK/PERCENT_RANK compatible
-- =============================================================
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

-- =============================================================
-- Statement 7: GetLowStockProductsAsync (Converted to PostgreSQL)
-- Original Location: ProductRepository.cs, method GetLowStockProductsAsync()
-- Changes: Schema objects to lowercase, ROUND with cast for integer division
-- =============================================================
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
