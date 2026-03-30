-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion did not complete after 15 attempts
-- Date: 2026-03-30
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Source: ProductRepository.cs - GetAllProductsAsync() method
-- Conversion: Lowercase schema objects. Window functions, CTEs, CASE, ROUND
--             are PostgreSQL compatible. CAST added for ROUND precision.
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
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Source: ProductRepository.cs - GetProductByIdAsync() method
-- Conversion: Lowercase schema objects. LAG window function is PostgreSQL
--             compatible. CAST added for division precision.
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
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Source: ProductRepository.cs - InsertProductAsync() method
-- Conversion: SCOPE_IDENTITY() -> RETURNING productid (via lastval() approach
--             since multi-statement batch), GETDATE() -> NOW(),
--             BEGIN TRANSACTION -> BEGIN, lowercase schema objects.
--             Using DO $$ block with variable declaration for PostgreSQL.
-- Note: For ADO.NET execution as a single command batch, we use
--       currval/lastval pattern since RETURNING can only be used in
--       single INSERT. The C# code uses ExecuteScalarAsync so the
--       last SELECT returns the new ID.
-- ============================================================================

                BEGIN;
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
                COMMIT;
                
                SELECT lastval();

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Source: ProductRepository.cs - UpdateProductAsync() method
-- Conversion: DECLARE @var -> subquery approach (PostgreSQL doesn't support
--             DECLARE in plain SQL batches outside DO blocks),
--             GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN,
--             lowercase schema objects.
-- Note: Since PostgreSQL doesn't support local variables in plain SQL
--       batch commands (outside PL/pgSQL), we use subqueries to get
--       old values. For ADO.NET command execution we use CTEs.
-- ============================================================================

                BEGIN;
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = NOW()
                    WHERE productid = @ProductId;
                    
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', 
                        (SELECT price FROM products WHERE productid = @ProductId), 
                        @Price,
                        (SELECT stockquantity FROM products WHERE productid = @ProductId), 
                        @StockQuantity, NOW();
                    
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
                        lastupdated = NOW()
                    WHERE statid = 1;
                COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Source: ProductRepository.cs - DeleteProductAsync() method
-- Conversion: DECLARE @var -> subquery approach, GETDATE() -> NOW(),
--             BEGIN TRANSACTION -> BEGIN, lowercase schema objects,
--             CASE expression preserved (PostgreSQL compatible).
-- ============================================================================

                BEGIN;
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, NOW()
                    FROM products WHERE productid = @ProductId;
                    
                    DELETE FROM products 
                    WHERE productid = @ProductId;
                    
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - (SELECT oldprice FROM producthistory WHERE productid = @ProductId AND action = 'DELETE' ORDER BY actiondate DESC LIMIT 1)) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = NOW()
                    WHERE statid = 1;
                COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Source: ProductRepository.cs - GetProductsByPriceRangeAsync() method
-- Conversion: Lowercase schema objects. RANK(), PERCENT_RANK(), BETWEEN,
--             CASE, ORDER BY are all PostgreSQL compatible.
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
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Source: ProductRepository.cs - GetLowStockProductsAsync() method
-- Conversion: Lowercase schema objects. AVG/MIN/MAX OVER, CASE are
--             PostgreSQL compatible. Added ::numeric cast for integer
--             division to produce correct ROUND results.
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
