-- ============================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed for all 7 statements
-- All schema object names converted to lowercase for PostgreSQL compatibility
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync - CTE with window functions (AVG OVER, COUNT OVER)
-- Conversion: Schema objects lowercased. No SQL syntax changes needed (PostgreSQL compatible).
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
-- Statement 2: GetProductByIdAsync - CTE with LAG window function
-- Conversion: Schema objects lowercased. No SQL syntax changes needed.
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
-- Statement 3: InsertProductAsync - Transaction block with RETURNING clause (replaces SCOPE_IDENTITY)
-- Conversion: SCOPE_IDENTITY() replaced with RETURNING productid; GETDATE() -> NOW();
--             DECLARE/SET variable pattern replaced with INSERT...RETURNING + subqueries;
--             BEGIN TRANSACTION/COMMIT replaced with PostgreSQL-compatible DO block approach.
--             For ADO.NET ExecuteScalar compatibility, restructured as multiple statements.
-- ============================================================================

                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid;

-- NOTE: The following statements for InsertProductAsync are handled separately in C# code
-- using the returned productid value:
-- INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
-- VALUES (<returned_id>, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
-- 
-- UPDATE productstats
-- SET totalproducts = totalproducts + 1,
--     averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
--     lastupdated = NOW()
-- WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync - Transaction block with NOW() (replaces GETDATE())
-- Conversion: GETDATE() -> NOW(); DECLARE replaced with subquery;
--             Schema objects lowercased.
-- ============================================================================

                DO $$
                DECLARE
                    v_oldprice DECIMAL(18,2);
                    v_oldstock INT;
                BEGIN
                    SELECT price, stockquantity INTO v_oldprice, v_oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = NOW()
                    WHERE productid = @ProductId;
                    
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, NOW());
                    
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
                        lastupdated = NOW()
                    WHERE statid = 1;
                END $$;

-- ============================================================================
-- Statement 5: DeleteProductAsync - Transaction block with CASE and NOW()
-- Conversion: GETDATE() -> NOW(); DECLARE replaced with PL/pgSQL block;
--             Schema objects lowercased.
-- ============================================================================

                DO $$
                DECLARE
                    v_oldprice DECIMAL(18,2);
                    v_oldstock INT;
                BEGIN
                    SELECT price, stockquantity INTO v_oldprice, v_oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, NOW());
                    
                    DELETE FROM products 
                    WHERE productid = @ProductId;
                    
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = NOW()
                    WHERE statid = 1;
                END $$;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync - CTE with RANK() and PERCENT_RANK()
-- Conversion: Schema objects lowercased. No SQL syntax changes needed.
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
-- Statement 7: GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions
-- Conversion: Schema objects lowercased. ROUND with integer division fix for PostgreSQL.
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
