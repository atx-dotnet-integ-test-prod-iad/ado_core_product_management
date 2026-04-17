-- =====================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Target Schema: productmanagement_dbo
-- Total Statements: 7
-- =====================================================

-- =====================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with ProductStats, AVG/COUNT window functions, INNER JOIN, CASE, ROUND, ORDER BY
-- Changes: Lowercase table/column names, schema prefix productmanagement_dbo
-- Parameters: None
-- =====================================================

                WITH productstats AS (
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
                INNER JOIN productstats ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END,
                    p.name

-- =====================================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with ProductHistory, LAG window functions, LEFT JOIN, CASE with ROUND
-- Changes: Lowercase table/column names, schema prefix productmanagement_dbo
-- Parameters: @ProductId
-- =====================================================

                WITH producthistory AS (
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
                LEFT JOIN producthistory ph ON p.productid = ph.productid
                WHERE p.productid = @ProductId

-- =====================================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE, SCOPE_IDENTITY(), GETDATE()
-- Changes: Restructured - SCOPE_IDENTITY() replaced with INSERT...RETURNING,
--          GETDATE() replaced with clock_timestamp(),
--          Transaction managed in C# code (BeginTransaction/Commit),
--          Split into individual statements for Npgsql parameter support
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- NOTE: This must be split into multiple commands in C# code
-- =====================================================

-- Command 1: Insert product and get new ID
                INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid

-- Command 2: Insert history (use newProductId from Command 1 result)
                INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp())

-- Command 3: Update stats
                UPDATE productmanagement_dbo.productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                    lastupdated = clock_timestamp()
                WHERE statid = 1

-- =====================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE, SELECT INTO variables, GETDATE()
-- Changes: Restructured - DECLARE/SELECT INTO variables handled via
--          separate SELECT + C# variable capture, GETDATE() replaced with clock_timestamp(),
--          Transaction managed in C# code
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- NOTE: This must be split into multiple commands in C# code
-- =====================================================

-- Command 1: Get old values
                SELECT price, stockquantity
                FROM productmanagement_dbo.products
                WHERE productid = @ProductId

-- Command 2: Update product
                UPDATE productmanagement_dbo.products
                SET 
                    name = @Name,
                    description = @Description,
                    price = @Price,
                    stockquantity = @StockQuantity,
                    modifieddate = clock_timestamp()
                WHERE productid = @ProductId

-- Command 3: Insert history
                INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp())

-- Command 4: Update stats
                UPDATE productmanagement_dbo.productstats
                SET 
                    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
                    lastupdated = clock_timestamp()
                WHERE statid = 1

-- =====================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Original: Transaction block with DECLARE, SELECT INTO variables, GETDATE(), CASE
-- Changes: Restructured similar to UpdateProductAsync,
--          GETDATE() replaced with clock_timestamp(),
--          Transaction managed in C# code
-- Parameters: @ProductId
-- NOTE: This must be split into multiple commands in C# code
-- =====================================================

-- Command 1: Get old values
                SELECT price, stockquantity
                FROM productmanagement_dbo.products
                WHERE productid = @ProductId

-- Command 2: Insert history
                INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp())

-- Command 3: Delete product
                DELETE FROM productmanagement_dbo.products 
                WHERE productid = @ProductId

-- Command 4: Update stats
                UPDATE productmanagement_dbo.productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = clock_timestamp()
                WHERE statid = 1

-- =====================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RankedProducts, RANK/PERCENT_RANK, CASE with BETWEEN
-- Changes: Lowercase table/column names, schema prefix productmanagement_dbo
-- Parameters: @MinPrice, @MaxPrice
-- =====================================================

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

-- =====================================================
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with StockAnalysis, AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: Lowercase table/column names, schema prefix productmanagement_dbo,
--          Added CAST for integer division in ROUND
-- Parameters: @Threshold
-- =====================================================

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
