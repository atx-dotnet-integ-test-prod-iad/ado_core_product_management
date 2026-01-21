-- ============================================================================
-- CONVERTED SQL STATEMENTS - POSTGRESQL
-- Source: Microsoft SQL Server
-- Target: PostgreSQL
-- Conversion Tool: AWS DMS MCP Statement Conversion Tool
-- Conversion Date: 2024
-- Schema Mapping: dbo -> productmanagement_dbo
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED BY DMS)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Conversion Status: SUCCESS
-- DMS Model: sql-conversion-1768965614
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
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Conversion Status: SUCCESS
-- DMS Model: sql-conversion-1768965748
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
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Statement definition is not valid
-- Manual Conversion Notes:
-- - PostgreSQL doesn't support SCOPE_IDENTITY(); replaced with RETURNING clause
-- - GETDATE() converted to NOW()
-- - Transaction management handled at application level in ADO.NET
-- - Variable declarations removed (handled in application code)
-- ============================================================================
-- Insert the new product and return the new ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Note: The following operations should be executed in the same transaction context
-- They are separated here for clarity but must be called together from the application

-- Log the insertion (using @NewProductId from RETURNING clause)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED BY DMS WITH WARNINGS)
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Conversion Status: SUCCESS
-- DMS Model: sql-conversion-1768965910
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--              functions. Convert your source code manually.]
-- Note: Transaction management removed (handled at application level)
-- ============================================================================
-- Note: Removed BEGIN/COMMIT - transaction managed by application code
-- Store old values for history
SELECT
    price AS var_OldPrice, stockquantity AS var_OldStock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
-- Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = NOW()
    WHERE productid = @ProductId;
    
-- Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());
    
-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = NOW()
    WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED BY DMS WITH WARNINGS)
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Conversion Status: SUCCESS
-- DMS Model: sql-conversion-1768966043
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
--              transaction management commands such as BEGIN TRAN, SAVE TRAN in 
--              functions. Convert your source code manually.]
-- Note: Transaction management removed (handled at application level)
-- ============================================================================
-- Note: Removed BEGIN/COMMIT - transaction managed by application code
-- Store product info for history
SELECT
    price AS var_OldPrice, stockquantity AS var_OldStock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
-- Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
    
-- Delete the product
DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = NOW()
    WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED BY DMS)
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Conversion Status: SUCCESS
-- DMS Model: sql-conversion-1768966176
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
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Conversion Status: SUCCESS
-- DMS Model: sql-conversion-1768966310
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
-- END OF CONVERTED STATEMENTS
-- Total Statements: 7
-- DMS Successful Conversions: 6
-- Manual Conversions After DMS Failure: 1
-- Schema Change: dbo -> productmanagement_dbo
-- Key Transformations:
-- - SCOPE_IDENTITY() -> RETURNING clause
-- - GETDATE() -> NOW()
-- - BEGIN TRANSACTION/COMMIT -> Handled at application level
-- - clock_timestamp() -> NOW() (for consistency)
-- - All table references updated to productmanagement_dbo schema
-- ============================================================================
