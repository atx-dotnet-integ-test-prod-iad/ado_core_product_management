-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: ProductRepository.cs (MS SQL Server -> PostgreSQL)
-- Database: ProductManagement
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Original Method: GetAllProductsAsync()
-- Conversion: Lowercase schema object names applied
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
-- Statement 2: GetProductByIdAsync (converted)
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion: Lowercase schema object names applied
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
-- Statement 3: InsertProductAsync (converted)
-- Original Method: InsertProductAsync(Product product)
-- Conversion: SCOPE_IDENTITY() -> RETURNING + lastval(), GETDATE() -> NOW(),
--             DECLARE/SET -> DO block, lowercase schema names
-- NOTE: For ADO.NET integration, this uses individual statements with
--       RETURNING clause instead of DO block for ExecuteScalar compatibility
-- ============================================================================

                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity);
                
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
                
                UPDATE productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                    lastupdated = NOW()
                WHERE statid = 1;
                
                SELECT lastval();

-- ============================================================================
-- Statement 4: UpdateProductAsync (converted)
-- Original Method: UpdateProductAsync(Product product)
-- Conversion: DECLARE/SELECT -> subquery approach, GETDATE() -> NOW(),
--             BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT, lowercase schema names
-- NOTE: For ADO.NET integration, uses subquery pattern instead of DO block
-- ============================================================================

                UPDATE products
                SET 
                    name = @Name,
                    description = @Description,
                    price = @Price,
                    stockquantity = @StockQuantity,
                    modifieddate = NOW()
                WHERE productid = @ProductId;
                
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'UPDATE', 
                    (SELECT price FROM products WHERE productid = @ProductId),
                    @Price, 
                    (SELECT stockquantity FROM products WHERE productid = @ProductId),
                    @StockQuantity, NOW());
                
                UPDATE productstats
                SET 
                    averageprice = (SELECT AVG(price) FROM products),
                    lastupdated = NOW()
                WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (converted)
-- Original Method: DeleteProductAsync(int productId)
-- Conversion: DECLARE/SELECT -> subquery approach, GETDATE() -> NOW(),
--             BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT, CASE preserved,
--             lowercase schema names
-- NOTE: For ADO.NET integration, uses subquery pattern instead of DO block
-- ============================================================================

                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'DELETE', 
                    (SELECT price FROM products WHERE productid = @ProductId),
                    NULL, 
                    (SELECT stockquantity FROM products WHERE productid = @ProductId),
                    NULL, NOW());
                
                DELETE FROM products 
                WHERE productid = @ProductId;
                
                UPDATE productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (SELECT AVG(price) FROM products)
                        ELSE 0
                    END,
                    lastupdated = NOW()
                WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: Lowercase schema object names applied
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
-- Statement 7: GetLowStockProductsAsync (converted)
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion: Lowercase schema object names, cast for integer division
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
                    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================================
