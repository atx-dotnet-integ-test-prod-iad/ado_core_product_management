-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7)
-- DMS Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- Schema Mapping Source: DMS schema_mapping_tool (Products->products, ProductHistory->producthistory, ProductStats->productstats)
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All table/column/alias names lowercased, CTE name changed to productstats_cte to avoid conflict with productstats table
-- ============================================================================

-- ORIGINAL (MS SQL):
-- WITH ProductStats AS (SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts FROM Products)
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name

-- CONVERTED (PostgreSQL):
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
                    p.name;

-- ============================================================================
-- Statement 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All table/column names lowercased, CTE name changed to producthistory_cte to avoid conflict with producthistory table
-- ============================================================================

-- ORIGINAL (MS SQL):
-- WITH ProductHistory AS (...) SELECT ... FROM Products p LEFT JOIN ProductHistory ph ... WHERE p.ProductId = @ProductId

-- CONVERTED (PostgreSQL):
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
                WHERE p.productid = @ProductId;

-- ============================================================================
-- Statement 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SCOPE_IDENTITY() -> RETURNING + lastval(), GETDATE() -> clock_timestamp(),
--          BEGIN TRANSACTION -> BEGIN, DECLARE @var -> DO $$ DECLARE v_var
--          All table/column names lowercased
-- ============================================================================

-- ORIGINAL (MS SQL):
-- DECLARE @NewProductId INT; BEGIN TRANSACTION; INSERT INTO Products ... SET @NewProductId = SCOPE_IDENTITY(); ... COMMIT; SELECT @NewProductId;

-- CONVERTED (PostgreSQL):
                DO $$
                DECLARE v_newproductid INTEGER;
                BEGIN
                    -- Insert the new product
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid INTO v_newproductid;
                    
                    -- Log the insertion
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                END $$;
                
                SELECT lastval();

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: BEGIN TRANSACTION -> BEGIN, DECLARE @var -> DO $$ DECLARE v_var,
--          GETDATE() -> clock_timestamp(), SELECT INTO variables syntax updated
--          All table/column names lowercased
-- ============================================================================

-- ORIGINAL (MS SQL):
-- BEGIN TRANSACTION; DECLARE @OldPrice...; SELECT @OldPrice = Price ... UPDATE Products ... COMMIT;

-- CONVERTED (PostgreSQL):
                DO $$
                DECLARE v_oldprice NUMERIC(18,2);
                DECLARE v_oldstock INTEGER;
                BEGIN
                    -- Store old values for history
                    SELECT price, stockquantity INTO v_oldprice, v_oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    -- Update the product
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = clock_timestamp()
                    WHERE productid = @ProductId;
                    
                    -- Log the changes
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, clock_timestamp());
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                END $$;

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Same pattern as Statement 4 - DO $$ block, clock_timestamp(), lowercase
-- ============================================================================

-- ORIGINAL (MS SQL):
-- BEGIN TRANSACTION; DECLARE @OldPrice...; ... DELETE FROM Products ... COMMIT;

-- CONVERTED (PostgreSQL):
                DO $$
                DECLARE v_oldprice NUMERIC(18,2);
                DECLARE v_oldstock INTEGER;
                BEGIN
                    -- Store product info for history
                    SELECT price, stockquantity INTO v_oldprice, v_oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    -- Log the deletion
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, clock_timestamp());
                    
                    -- Delete the product
                    DELETE FROM products 
                    WHERE productid = @ProductId;
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                END $$;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All table/column/alias names lowercased
-- ============================================================================

-- ORIGINAL (MS SQL):
-- WITH RankedProducts AS (...) SELECT rp.*, CASE ... FROM RankedProducts rp ORDER BY rp.PriceRank

-- CONVERTED (PostgreSQL):
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
-- Statement 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All table/column/alias names lowercased, added ::numeric cast for integer division
-- ============================================================================

-- ORIGINAL (MS SQL):
-- WITH StockAnalysis AS (...) SELECT sa.*, CASE ... FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity

-- CONVERTED (PostgreSQL):
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
