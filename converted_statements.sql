-- ============================================
-- Converted PostgreSQL Statements for ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS schema_mapping_tool was used to obtain target schema names
-- Schema Mapping: dbo.Products -> productmanagement_dbo.products
--                 dbo.ProductHistory -> productmanagement_dbo.producthistory
--                 dbo.ProductStats -> productmanagement_dbo.productstats
-- ============================================

-- ===========================================================
-- Statement #1: GetAllProductsAsync (Converted)
-- ===========================================================
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

-- ===========================================================
-- Statement #2: GetProductByIdAsync (Converted)
-- ===========================================================
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

-- ===========================================================
-- Statement #3: InsertProductAsync (Converted)
-- SCOPE_IDENTITY() -> lastval() after INSERT with GENERATED ALWAYS AS IDENTITY
-- GETDATE() -> clock_timestamp()
-- BEGIN TRANSACTION/COMMIT -> BEGIN/COMMIT
-- ===========================================================
                BEGIN;
                    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                    OVERRIDING SYSTEM VALUE
                    VALUES (@Name, @Description, @Price, @StockQuantity);
                    
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
                    
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                COMMIT;
                
                SELECT lastval()

-- ===========================================================
-- Statement #4: UpdateProductAsync (Converted)
-- DECLARE variables replaced with subquery-based approach
-- GETDATE() -> clock_timestamp()
-- ===========================================================
                BEGIN;
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', price, @Price, stockquantity, @StockQuantity, clock_timestamp()
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId;
                    
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        averageprice = (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId) + @Price) / totalproducts,
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;

                    UPDATE productmanagement_dbo.products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = clock_timestamp()
                    WHERE productid = @ProductId;
                COMMIT

-- ===========================================================
-- Statement #5: DeleteProductAsync (Converted)
-- DECLARE variables replaced with subquery-based approach
-- GETDATE() -> clock_timestamp()
-- ===========================================================
                BEGIN;
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, clock_timestamp()
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId;
                    
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - (SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId)) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                    
                    DELETE FROM productmanagement_dbo.products 
                    WHERE productid = @ProductId;
                COMMIT

-- ===========================================================
-- Statement #6: GetProductsByPriceRangeAsync (Converted)
-- ===========================================================
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

-- ===========================================================
-- Statement #7: GetLowStockProductsAsync (Converted)
-- ===========================================================
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
                    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity
