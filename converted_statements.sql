-- ============================================================================
-- Converted SQL Statements for PostgreSQL (from ProductRepository.cs)
-- Target: PostgreSQL (ProductManagement database via DMS schema mapping)
-- Conversion Date: 2026-04-05
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion did not complete after 15 attempts (timeout)
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
--   dbo.Products -> productmanagement_dbo.products
--   dbo.ProductHistory -> productmanagement_dbo.producthistory
--   dbo.ProductStats -> productmanagement_dbo.productstats
--   All column names -> lowercase
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING clause
--   DECLARE/SET variables -> CTE with RETURNING or subqueries
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Original: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND, ORDER BY
-- Changes: Table/column names to lowercase, schema prefix productmanagement_dbo
--          CTE name changed from ProductStats to productstats_cte to avoid
--          conflict with productmanagement_dbo.productstats table
-- ============================================================================
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
    p.name;

-- ============================================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Original: CTE with LAG window function, LEFT JOIN, CASE, ROUND
-- Changes: Table/column names to lowercase, schema prefix productmanagement_dbo
-- Parameters: @ProductId (Npgsql supports @param syntax)
-- ============================================================================
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
WHERE p.productid = @ProductId;

-- ============================================================================
-- Statement 3: InsertProductAsync (converted)
-- Original: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE(), SELECT
-- Changes: Restructured to use writable CTE with RETURNING clause instead of
--          SCOPE_IDENTITY() and DECLARE/SET. GETDATE() -> clock_timestamp().
--          Transaction management moved to C# code (BeginTransactionAsync/CommitAsync).
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ============================================================================
WITH new_product AS (
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history_insert AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
    FROM new_product
),
stats_update AS (
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1
)
SELECT productid FROM new_product;

-- ============================================================================
-- Statement 4: UpdateProductAsync (converted)
-- Original: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
-- Changes: Restructured to use writable CTE to capture old values and chain
--          operations. GETDATE() -> clock_timestamp().
--          Transaction management moved to C# code.
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================================
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
),
history_insert AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, clock_timestamp()
    FROM old_values
)
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (converted)
-- Original: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
-- Changes: Restructured to use writable CTE. GETDATE() -> clock_timestamp().
--          Transaction management moved to C# code.
-- Parameters: @ProductId
-- ============================================================================
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
),
history_insert AS (
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, clock_timestamp()
    FROM old_values
),
do_delete AS (
    DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId
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

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Original: CTE with RANK() and PERCENT_RANK() window functions, BETWEEN, CASE
-- Changes: Table/column names to lowercase, schema prefix productmanagement_dbo
-- Parameters: @MinPrice, @MaxPrice
-- ============================================================================
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
ORDER BY rp.pricerank;

-- ============================================================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: Table/column names to lowercase, schema prefix productmanagement_dbo
--          Added CAST(stockquantity AS NUMERIC) for integer division fix
-- Parameters: @Threshold
-- ============================================================================
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
ORDER BY stockquantity;
