-- ===============================================================================
-- CONVERTED SQL STATEMENTS CATALOG FOR MIGRATION
-- Target: PostgreSQL - Converted from SQL Server
-- Conversion Date: Step 2 of Migration Plan
-- Conversion Tool: AWS DMS MCP Tool
-- ===============================================================================

-- -------------------------------------------------------------------------------
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- -------------------------------------------------------------------------------
-- Conversion Status: SUCCESS
-- DMS Tool Status: success
-- Schema Transformation: Products -> productmanagement_dbo.products
-- -------------------------------------------------------------------------------
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

-- -------------------------------------------------------------------------------
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- -------------------------------------------------------------------------------
-- Conversion Status: SUCCESS
-- DMS Tool Status: success
-- Schema Transformation: Products -> productmanagement_dbo.products
-- -------------------------------------------------------------------------------
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

-- -------------------------------------------------------------------------------
-- STATEMENT 3: InsertProductAsync - Transaction Block with INSERT and RETURNING
-- -------------------------------------------------------------------------------
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Tool Status: error
-- DMS Error: Metadata model creation failed: Statement definition is not valid
-- Manual Conversion Applied: Converted to PostgreSQL stored procedure pattern
-- SCOPE_IDENTITY() -> RETURNING clause
-- GETDATE() -> CURRENT_TIMESTAMP
-- BEGIN TRANSACTION/COMMIT removed (handled at application level)
-- Schema Transformation: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- -------------------------------------------------------------------------------
-- Insert the new product and get the ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following statements would be executed in the same transaction in application code:
-- Log the insertion (using the returned productid as @NewProductId)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- -------------------------------------------------------------------------------
-- STATEMENT 4: UpdateProductAsync - Transaction Block with UPDATE and INSERT
-- -------------------------------------------------------------------------------
-- Conversion Status: SUCCESS_WITH_WARNING
-- DMS Tool Status: success
-- Warning: PostgreSQL does not support explicit transaction management commands in functions
-- Note: Transaction management handled at application level, not in SQL
-- Schema Transformation: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- GETDATE() -> clock_timestamp()
-- -------------------------------------------------------------------------------
-- Store old values for history
WITH old_values AS (
    SELECT price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
)
-- Update the product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = clock_timestamp()
WHERE productid = @ProductId;

-- Log the changes (executed separately with old values captured)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- -------------------------------------------------------------------------------
-- STATEMENT 5: DeleteProductAsync - Transaction Block with DELETE and UPDATE
-- -------------------------------------------------------------------------------
-- Conversion Status: SUCCESS_WITH_WARNING
-- DMS Tool Status: success
-- Warning: PostgreSQL does not support explicit transaction management commands in functions
-- Note: Transaction management handled at application level, not in SQL
-- Schema Transformation: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- GETDATE() -> clock_timestamp()
-- -------------------------------------------------------------------------------
-- Store product info for history (captured before delete)
WITH old_values AS (
    SELECT price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
)
-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Delete the product
DELETE FROM productmanagement_dbo.products 
WHERE productid = @ProductId;

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = clock_timestamp()
WHERE statid = 1;

-- -------------------------------------------------------------------------------
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
-- -------------------------------------------------------------------------------
-- Conversion Status: SUCCESS
-- DMS Tool Status: success
-- Schema Transformation: Products -> productmanagement_dbo.products
-- -------------------------------------------------------------------------------
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

-- -------------------------------------------------------------------------------
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- -------------------------------------------------------------------------------
-- Conversion Status: SUCCESS
-- DMS Tool Status: success
-- Schema Transformation: Products -> productmanagement_dbo.products
-- -------------------------------------------------------------------------------
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

-- ===============================================================================
-- END OF CONVERTED SQL STATEMENTS CATALOG
-- Total Statements: 7
-- Successfully Converted by DMS: 6
-- Manually Converted After DMS Failure: 1
-- ===============================================================================
