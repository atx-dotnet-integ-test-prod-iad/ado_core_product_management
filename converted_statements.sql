-- ============================================================================
-- Converted SQL Statements - PostgreSQL equivalents
-- Source: MS SQL Server statements from DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Schema: dbo -> productmanagement_dbo (tables/columns lowercase)
-- ============================================================================

-- ==========================================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with AVG/COUNT window functions, CASE WHEN, ROUND, INNER JOIN
-- Changes: Table/column names to lowercase, schema prefix productmanagement_dbo
-- ==========================================================================

                WITH ProductStats AS (
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
                INNER JOIN ProductStats ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END,
                    p.name;

-- ==========================================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with LAG window function, LEFT JOIN, CASE WHEN, ROUND
-- Changes: Table/column names to lowercase, schema prefix productmanagement_dbo
-- ==========================================================================

                WITH ProductHistory AS (
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
                LEFT JOIN ProductHistory ph ON p.productid = ph.productid
                WHERE p.productid = @ProductId;

-- ==========================================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original: Transaction with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
-- Changes: SCOPE_IDENTITY() -> RETURNING + CTE approach, GETDATE() -> clock_timestamp(),
--          Table/column names lowercase, schema prefix productmanagement_dbo
-- Note: Restructured to use INSERT...RETURNING with CTEs for PostgreSQL compatibility
-- ==========================================================================

                WITH new_product AS (
                    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid
                ),
                log_history AS (
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
                    FROM new_product
                ),
                update_stats AS (
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = clock_timestamp()
                    WHERE statid = 1
                )
                SELECT productid FROM new_product;

-- ==========================================================================
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE vars, SELECT into vars, UPDATE, INSERT history, UPDATE stats
-- Changes: DECLARE/@var -> subquery/CTE approach, GETDATE() -> clock_timestamp(),
--          Table/column names lowercase, schema prefix productmanagement_dbo
-- Note: Restructured to use CTEs to capture old values and perform updates
-- ==========================================================================

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
                )
                UPDATE productmanagement_dbo.productstats
                SET 
                    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
                    lastupdated = clock_timestamp()
                WHERE statid = 1;

-- ==========================================================================
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE vars, SELECT into vars, INSERT history, DELETE, UPDATE stats
-- Changes: DECLARE/@var -> CTE approach, GETDATE() -> clock_timestamp(),
--          Table/column names lowercase, schema prefix productmanagement_dbo
-- Note: Restructured to use CTEs to capture old values before delete
-- ==========================================================================

                WITH old_values AS (
                    SELECT price as oldprice, stockquantity as oldstock
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId
                ),
                log_history AS (
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, clock_timestamp()
                    FROM old_values ov
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
                WHERE statid = 1;

-- ==========================================================================
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK, PERCENT_RANK window functions, CASE WHEN
-- Changes: Table/column names to lowercase, schema prefix productmanagement_dbo
-- ==========================================================================

                WITH RankedProducts AS (
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
                FROM RankedProducts rp
                ORDER BY rp.pricerank;

-- ==========================================================================
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX window functions, CASE WHEN, ROUND
-- Changes: Table/column names to lowercase, schema prefix productmanagement_dbo,
--          Added CAST for integer division in ROUND
-- ==========================================================================

                WITH StockAnalysis AS (
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
                    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
                FROM StockAnalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- Total: 7 SQL statements converted to PostgreSQL
-- ============================================================================
