-- =========================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Date: 2026-04-04
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed (consistent across all attempts)
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Schema: dbo -> productmanagement_dbo
-- Total Statements: 7
-- =========================================================
-- Schema Mapping Applied (from DMS schema_mapping_tool):
--   Products -> productmanagement_dbo.products (all columns lowercase)
--   ProductHistory -> productmanagement_dbo.producthistory (all columns lowercase)
--   ProductStats -> productmanagement_dbo.productstats (all columns lowercase)
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING clause / lastval()
--   DECLARE @var / BEGIN TRANSACTION / COMMIT -> removed (handled by C# ADO.NET)
-- =========================================================

-- =========================================================
-- CONVERTED STATEMENT 1: GetAllProductsAsync
-- Original Method: GetAllProductsAsync()
-- Conversion: CTE name lowercased, table/column names lowercased, schema prefixed
-- Note: CTE name changed from ProductStats to productstats_cte to avoid conflict with table
-- =========================================================

                WITH productstats_cte AS (
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
                INNER JOIN productstats_cte ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END,
                    p.name

-- =========================================================
-- CONVERTED STATEMENT 2: GetProductByIdAsync
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion: CTE name lowercased, table/column names lowercased, schema prefixed
-- Note: CTE name changed from ProductHistory to producthistory_cte to avoid conflict with table
-- =========================================================

                WITH producthistory_cte AS (
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
                LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
                WHERE p.productid = @ProductId

-- =========================================================
-- CONVERTED STATEMENT 3: InsertProductAsync
-- Original Method: InsertProductAsync(Product product)
-- Conversion: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> clock_timestamp()
-- DECLARE/@var/BEGIN TRANSACTION/COMMIT removed (C# manages transactions)
-- Multi-statement batch split into separate statements executed sequentially
-- The INSERT into products uses RETURNING to get the new ID
-- The C# code uses ExecuteScalarAsync which gets the returned productid
-- =========================================================

                INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid

-- Note: The following statements from the original batch need separate execution in C# code:
-- INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (<returned_id>, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
-- UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp() WHERE statid = 1;

-- ALTERNATIVE: Use a DO block with all statements combined:
-- For C# integration, we use a single statement block with CTEs:

                WITH new_product AS (
                    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid
                ),
                log_history AS (
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
                    FROM new_product
                    RETURNING productid
                ),
                update_stats AS (
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = clock_timestamp()
                    WHERE statid = 1
                    RETURNING statid
                )
                SELECT productid FROM new_product

-- =========================================================
-- CONVERTED STATEMENT 4: UpdateProductAsync
-- Original Method: UpdateProductAsync(Product product)
-- Conversion: DECLARE/@var -> subquery/CTE approach, GETDATE() -> clock_timestamp()
-- BEGIN TRANSACTION/COMMIT removed (C# manages transactions)
-- Used CTEs with data-modifying statements (PostgreSQL writable CTEs)
-- =========================================================

                WITH old_values AS (
                    SELECT price as oldprice, stockquantity as oldstock
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId
                ),
                do_update AS (
                    UPDATE productmanagement_dbo.products
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
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, clock_timestamp()
                    FROM old_values ov
                    RETURNING productid
                )
                UPDATE productmanagement_dbo.productstats
                SET 
                    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
                    lastupdated = clock_timestamp()
                WHERE statid = 1

-- =========================================================
-- CONVERTED STATEMENT 5: DeleteProductAsync
-- Original Method: DeleteProductAsync(int productId)
-- Conversion: DECLARE/@var -> subquery/CTE approach, GETDATE() -> clock_timestamp()
-- BEGIN TRANSACTION/COMMIT removed (C# manages transactions)
-- Used CTEs with data-modifying statements (PostgreSQL writable CTEs)
-- =========================================================

                WITH old_values AS (
                    SELECT price as oldprice, stockquantity as oldstock
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId
                ),
                log_history AS (
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, clock_timestamp()
                    FROM old_values ov
                    RETURNING productid
                ),
                do_delete AS (
                    DELETE FROM productmanagement_dbo.products 
                    WHERE productid = @ProductId
                    RETURNING productid
                )
                UPDATE productmanagement_dbo.productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = clock_timestamp()
                WHERE statid = 1

-- =========================================================
-- CONVERTED STATEMENT 6: GetProductsByPriceRangeAsync
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: CTE/table/column names lowercased, schema prefixed
-- =========================================================

                WITH rankedproducts AS (
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
                FROM rankedproducts rp
                ORDER BY rp.pricerank

-- =========================================================
-- CONVERTED STATEMENT 7: GetLowStockProductsAsync
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion: CTE/table/column names lowercased, schema prefixed
-- Note: Added ::numeric cast for integer division to get decimal result in ROUND
-- =========================================================

                WITH stockanalysis AS (
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
                    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity
