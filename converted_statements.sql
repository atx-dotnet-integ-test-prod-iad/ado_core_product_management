-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
-- Source: Microsoft SQL Server to PostgreSQL Migration via AWS DMS
-- Date: 2024-12-31
-- Total Statements: 7
-- Schema Mapping: dbo -> productmanagement_dbo
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED BY DMS)
-- Original Method: GetAllProductsAsync()
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- ============================================================================
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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED BY DMS)
-- Original Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId (int)
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- ============================================================================
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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (MANUAL CONVERSION AFTER DMS FAILURE)
-- Original Method: InsertProductAsync(Product product)
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Statement definition is not valid (multi-statement transaction with DECLARE not supported)
-- Manual Conversion Notes: 
--   - Transaction management handled at ADO.NET level (BeginTransactionAsync)
--   - SCOPE_IDENTITY() replaced with RETURNING clause
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Schema updated: Products -> productmanagement_dbo.products
--   - Schema updated: ProductHistory -> productmanagement_dbo.producthistory
--   - Schema updated: ProductStats -> productmanagement_dbo.productstats
-- ============================================================================
-- Insert the new product
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Log the insertion (executed with returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED BY DMS WITH WARNINGS)
-- Original Method: UpdateProductAsync(Product product)
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management (BEGIN TRAN) in functions
-- Note: Transaction handled at ADO.NET level (BeginTransactionAsync)
-- Schema Changes: Products -> productmanagement_dbo.products
--                 ProductHistory -> productmanagement_dbo.producthistory
--                 ProductStats -> productmanagement_dbo.productstats
-- ============================================================================
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED BY DMS WITH WARNINGS)
-- Original Method: DeleteProductAsync(int productId)
-- Parameters: @ProductId (int)
-- Conversion Status: SUCCESS_WITH_WARNINGS
-- DMS Warning: [7807] PostgreSQL does not support explicit transaction management (BEGIN TRAN) in functions
-- Note: Transaction handled at ADO.NET level (BeginTransactionAsync)
-- Schema Changes: Products -> productmanagement_dbo.products
--                 ProductHistory -> productmanagement_dbo.producthistory
--                 ProductStats -> productmanagement_dbo.productstats
-- ============================================================================
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED BY DMS)
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- ============================================================================
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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED BY DMS)
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold (int)
-- Conversion Status: SUCCESS
-- Schema Changes: Products -> productmanagement_dbo.products
-- ============================================================================
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

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- Total Statements Converted: 7
-- DMS Success: 6
-- Manual Conversion: 1 (InsertProductAsync due to DMS validation error)
-- ============================================================================
