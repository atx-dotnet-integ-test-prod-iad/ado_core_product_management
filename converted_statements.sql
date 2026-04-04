-- ============================================================================
-- Converted SQL Statements Catalog (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation did not complete after multiple attempts
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Schema Mappings Applied:
--   Products -> products (schema: productmanagement_dbo)
--   ProductHistory -> producthistory (schema: productmanagement_dbo)
--   ProductStats -> productstats (schema: productmanagement_dbo)
--   All column names -> lowercase
--   GETDATE() -> NOW()
--   SCOPE_IDENTITY() -> RETURNING clause
--   DECLARE variables -> subqueries/CTEs
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Original MS SQL: CTE with AVG/COUNT window functions
-- Conversion: Lowercase all identifiers, ROUND syntax compatible
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
                    p.name

-- ============================================================================
-- Statement 2: GetProductByIdAsync (Converted)
-- Original MS SQL: CTE with LAG window function
-- Conversion: Lowercase all identifiers
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
                WHERE p.productid = @ProductId

-- ============================================================================
-- Statement 3: InsertProductAsync (Converted)
-- Original MS SQL: Transaction with SCOPE_IDENTITY(), GETDATE()
-- Conversion: Use INSERT...RETURNING with CTEs, NOW() for GETDATE()
-- Note: Restructured to use WITH...INSERT pattern and separate statements
-- ============================================================================

                WITH new_product AS (
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid
                ),
                log_insertion AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
                    FROM new_product
                ),
                update_stats AS (
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = NOW()
                    WHERE statid = 1
                )
                SELECT productid FROM new_product

-- ============================================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Original MS SQL: Transaction with DECLARE variables, GETDATE()
-- Conversion: Use CTEs to capture old values, NOW() for GETDATE()
-- ============================================================================

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
                        modifieddate = NOW()
                    WHERE productid = @ProductId
                ),
                log_changes AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, NOW()
                    FROM old_values ov
                )
                UPDATE productstats
                SET 
                    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
                    lastupdated = NOW()
                WHERE statid = 1

-- ============================================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Original MS SQL: Transaction with DECLARE variables, CASE, GETDATE()
-- Conversion: Use CTEs to capture old values, NOW() for GETDATE()
-- ============================================================================

                WITH old_values AS (
                    SELECT price as oldprice, stockquantity as oldstock
                    FROM products
                    WHERE productid = @ProductId
                ),
                log_deletion AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, NOW()
                    FROM old_values ov
                ),
                do_delete AS (
                    DELETE FROM products 
                    WHERE productid = @ProductId
                )
                UPDATE productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = NOW()
                WHERE statid = 1

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Original MS SQL: CTE with RANK/PERCENT_RANK
-- Conversion: Lowercase all identifiers
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
                ORDER BY rp.pricerank

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Original MS SQL: CTE with AVG/MIN/MAX window functions
-- Conversion: Lowercase all identifiers, cast for ROUND compatibility
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
                    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- Total Statements: 7
-- All converted with method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure: Metadata model creation/conversion timeout
-- Schema mappings obtained from DMS schema_mapping_tool
-- ============================================================================
