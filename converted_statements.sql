-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion timed out after 15+ attempts
-- Schema Mapping Source: DMS Schema Mapping Tool (productmanagement_dbo schema)
-- Total Statements: 7
-- ============================================================================
-- Schema Mapping Applied (from DMS schema_mapping_tool):
--   Products → products (schema: productmanagement_dbo)
--     Columns: productid, name, description, price, stockquantity, createddate, modifieddate
--   ProductHistory → producthistory (schema: productmanagement_dbo)
--     Columns: historyid, productid, action, oldprice, newprice, oldstock, newstock, actiondate
--   ProductStats → productstats (schema: productmanagement_dbo)
--     Columns: statid, totalproducts, averageprice, lastupdated
-- Key Conversions:
--   SCOPE_IDENTITY() → RETURNING clause
--   GETDATE() → NOW()
--   DECLARE/SET @var → DO $$ DECLARE v_var ... END $$
--   BEGIN TRANSACTION/COMMIT → Handled by ADO.NET transaction wrapper
-- ============================================================================

-- ============================================================================
-- Converted Statement 1: GetAllProductsAsync
-- Original: MS SQL Server CTE with window functions
-- Conversion: Lowercase identifiers, CTE alias renamed to avoid conflict with table name
-- ============================================================================
WITH productstatscte AS (
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
INNER JOIN productstatscte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- Converted Statement 2: GetProductByIdAsync
-- Original: MS SQL Server CTE with LAG window functions
-- Conversion: Lowercase identifiers, CTE alias renamed to avoid conflict with table name
-- ============================================================================
WITH producthistorycte AS (
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
LEFT JOIN producthistorycte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- Converted Statement 3: InsertProductAsync
-- Original: MS SQL Server transaction with SCOPE_IDENTITY(), GETDATE()
-- Conversion: RETURNING clause replaces SCOPE_IDENTITY(), NOW() replaces GETDATE()
-- Note: Transaction is handled by ADO.NET BeginTransactionAsync/CommitAsync
-- The C# code uses ExecuteScalarAsync() to get the returned ID
-- ============================================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements from the original InsertProductAsync transaction block
-- cannot be combined into a single SQL string with RETURNING in the same way.
-- They need to be executed as separate commands within the ADO.NET transaction.
-- For the re-integration, the INSERT with RETURNING handles the product creation,
-- and the ProductHistory/ProductStats updates should be separate commands.
-- However, to preserve the single-command pattern of the original code,
-- we use a DO block approach:

-- Full transaction block for InsertProductAsync (alternative for single command execution):
DO $$
DECLARE
    v_newproductid INTEGER;
BEGIN
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================================
-- Converted Statement 4: UpdateProductAsync
-- Original: MS SQL Server transaction with DECLARE/SET, GETDATE()
-- Conversion: DO block with DECLARE, SELECT INTO, NOW() replaces GETDATE()
-- ============================================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, NOW());
    
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================================
-- Converted Statement 5: DeleteProductAsync
-- Original: MS SQL Server transaction with DECLARE/SET, GETDATE(), CASE
-- Conversion: DO block with DECLARE, SELECT INTO, NOW() replaces GETDATE()
-- ============================================================================
DO $$
DECLARE
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, NOW());
    
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ============================================================================
-- Converted Statement 6: GetProductsByPriceRangeAsync
-- Original: MS SQL Server CTE with RANK(), PERCENT_RANK()
-- Conversion: Lowercase identifiers, window functions are PostgreSQL compatible
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
-- Converted Statement 7: GetLowStockProductsAsync
-- Original: MS SQL Server CTE with AVG/MIN/MAX OVER()
-- Conversion: Lowercase identifiers, CAST for integer division fix in PostgreSQL
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
    ROUND(CAST(stockquantity AS NUMERIC) / CAST(avgstock AS NUMERIC) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
