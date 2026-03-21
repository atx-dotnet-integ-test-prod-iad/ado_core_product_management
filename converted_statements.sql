-- ============================================================================
-- Converted SQL Statements - PostgreSQL Syntax
-- Source: MS SQL Server statements from DataAccess/ProductRepository.cs
-- Target: PostgreSQL (converted via DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
-- DMS Tool Status: All 7 statements failed DMS conversion (Metadata model conversion timeout)
-- Schema Mapping Source: DMS Schema Mapping Tool (successful)
--   Products -> products (columns: productid, name, description, price, stockquantity, createddate, modifieddate)
--   ProductHistory -> producthistory (columns: historyid, productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--   ProductStats -> productstats (columns: statid, totalproducts, averageprice, lastupdated)
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All table/column names lowercased per DMS schema mapping
-- ============================================================================

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
                    p.name

-- ============================================================================
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All table/column names lowercased per DMS schema mapping
-- ============================================================================

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
                WHERE p.productid = @ProductId

-- ============================================================================
-- Statement 3: InsertProductAsync (CONVERTED)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: 
--   - SCOPE_IDENTITY() replaced with RETURNING clause and lastval()
--   - GETDATE() replaced with clock_timestamp()
--   - DECLARE @var removed, restructured for PostgreSQL compatibility
--   - BEGIN TRANSACTION/COMMIT removed (handled at C# level with Npgsql)
--   - All table/column names lowercased per DMS schema mapping
-- ============================================================================

                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity);
                    
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
                    
                UPDATE productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                    lastupdated = clock_timestamp()
                WHERE statid = 1;
                
                SELECT lastval();

-- ============================================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes:
--   - DECLARE @var / SELECT @var = col removed, restructured to subqueries
--   - GETDATE() replaced with clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT removed (handled at C# level with Npgsql)
--   - All table/column names lowercased per DMS schema mapping
-- ============================================================================

                UPDATE products
                SET 
                    name = @Name,
                    description = @Description,
                    price = @Price,
                    stockquantity = @StockQuantity,
                    modifieddate = clock_timestamp()
                WHERE productid = @ProductId;
                    
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                SELECT @ProductId, 'UPDATE', 
                    (SELECT price FROM products WHERE productid = @ProductId),
                    @Price,
                    (SELECT stockquantity FROM products WHERE productid = @ProductId),
                    @StockQuantity, clock_timestamp();
                    
                UPDATE productstats
                SET 
                    averageprice = (SELECT AVG(price) FROM products),
                    lastupdated = clock_timestamp()
                WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes:
--   - DECLARE @var / SELECT @var = col removed, restructured to subqueries
--   - GETDATE() replaced with clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT removed (handled at C# level with Npgsql)
--   - All table/column names lowercased per DMS schema mapping
-- ============================================================================

                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, clock_timestamp()
                FROM products WHERE productid = @ProductId;
                    
                DELETE FROM products 
                WHERE productid = @ProductId;
                    
                UPDATE productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (SELECT COALESCE(AVG(price), 0) FROM products)
                        ELSE 0
                    END,
                    lastupdated = clock_timestamp()
                WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All table/column names lowercased per DMS schema mapping
-- ============================================================================

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
                ORDER BY rp.pricerank

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: 
--   - All table/column names lowercased per DMS schema mapping
--   - Added CAST for integer division to avoid truncation in PostgreSQL
-- ============================================================================

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
                ORDER BY stockquantity
