-- ================================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Target Database: PostgreSQL
-- Conversion Method: DMS MCP Tool + Manual Conversion (where DMS failed)
-- Total Statements: 7
-- Successful DMS Conversions: 6
-- Manual Conversions After DMS Failure: 1
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED BY DMS
-- Original Location: ProductRepository.cs, Lines 38-66
-- DMS Conversion: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products (lowercase, schema prefix)
-- ================================================================================
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED BY DMS
-- Original Location: ProductRepository.cs, Lines 82-111
-- DMS Conversion: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products (lowercase, schema prefix)
-- Parameter: @ProductId remains compatible with Npgsql
-- ================================================================================
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- ================================================================================
-- STATEMENT 3: InsertProductAsync - MANUAL CONVERSION AFTER DMS FAILURE
-- Original Location: ProductRepository.cs, Lines 127-155
-- DMS Conversion: FAILED (Statement definition not valid)
-- Manual Conversion Applied
-- Key Changes:
--   - SCOPE_IDENTITY() → Removed, using RETURNING productid
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Transaction management handled in C# code (NpgsqlTransaction)
--   - Variable declarations removed (not needed with RETURNING)
--   - Schema: Products → productmanagement_dbo.products
--   - Schema: ProductHistory → productmanagement_dbo.producthistory
--   - Schema: ProductStats → productmanagement_dbo.productstats
-- ================================================================================
-- Insert the new product with RETURNING clause
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (executed separately in transaction with returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics (executed separately in transaction)
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED BY DMS WITH WARNINGS
-- Original Location: ProductRepository.cs, Lines 171-203
-- DMS Conversion: SUCCESS with warnings about transaction management
-- Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Note: Transaction management will be handled in C# code
-- Key Changes:
--   - DECLARE @var → DECLARE var_name (removed @ prefix)
--   - GETDATE() → clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT → Handled in C# code
--   - Schema changes applied
-- ================================================================================
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price, stockquantity
    INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
        WHERE statid = 1;
END;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED BY DMS WITH WARNINGS
-- Original Location: ProductRepository.cs, Lines 219-251
-- DMS Conversion: SUCCESS with warnings about transaction management
-- Warning: [7807] PostgreSQL does not support explicit transaction management in functions
-- Note: Transaction management will be handled in C# code
-- Key Changes:
--   - DECLARE @var → DECLARE var_name (removed @ prefix)
--   - GETDATE() → clock_timestamp()
--   - BEGIN TRANSACTION/COMMIT → Handled in C# code
--   - Schema changes applied
-- ================================================================================
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price, stockquantity
    INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, CURRENT_TIMESTAMP);
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = CURRENT_TIMESTAMP
        WHERE statid = 1;
END;

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED BY DMS
-- Original Location: ProductRepository.cs, Lines 267-287
-- DMS Conversion: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products (lowercase, schema prefix)
-- Parameters: @MinPrice, @MaxPrice remain compatible with Npgsql
-- ================================================================================
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED BY DMS
-- Original Location: ProductRepository.cs, Lines 303-328
-- DMS Conversion: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products (lowercase, schema prefix)
-- Parameter: @Threshold remains compatible with Npgsql
-- ================================================================================
WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

-- ================================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ================================================================================
