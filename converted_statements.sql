-- =========================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- DMS Successful: 6
-- DMS Failed (Manual Conversion): 1 (Statement 3)
-- =========================================================================

-- =========================================================================
-- Statement 1: GetAllProductsAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS
-- =========================================================================
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

-- =========================================================================
-- Statement 2: GetProductByIdAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS
-- =========================================================================
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

-- =========================================================================
-- Statement 3: InsertProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Status: ERROR - "Statement definition is not valid."
-- DMS Error: Metadata model creation failed: Statement definition is not valid.
-- Manual Conversion Notes: 
--   - SCOPE_IDENTITY() replaced with lastval() (PostgreSQL equivalent)
--   - GETDATE() replaced with clock_timestamp() (consistent with DMS conversions)
--   - BEGIN TRANSACTION/COMMIT removed (managed by C# code via NpgsqlTransaction)
--   - DECLARE/@variable replaced with DO block or inline approach
--   - Schema objects lowercased with productmanagement_dbo schema prefix
-- =========================================================================
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity);

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp()
WHERE statid = 1;

SELECT lastval();

-- =========================================================================
-- Statement 4: UpdateProductAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS (with warning 7807 - transaction management)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support 
--   explicit transaction management commands such as BEGIN TRAN, SAVE TRAN 
--   in functions. Convert your source code manually.]
-- Note: Transaction management handled by C# code via NpgsqlTransaction.
--   The DMS-provided SQL body is used, excluding the DECLARE/BEGIN/END block.
-- =========================================================================
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
    WHERE productid = @ProductId;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- =========================================================================
-- Statement 5: DeleteProductAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS (with warning 7807 - transaction management)
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support 
--   explicit transaction management commands such as BEGIN TRAN, SAVE TRAN 
--   in functions. Convert your source code manually.]
-- Note: Transaction management handled by C# code via NpgsqlTransaction.
-- =========================================================================
SELECT
    price, stockquantity
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

DELETE FROM productmanagement_dbo.products
    WHERE productid = @ProductId;

UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = clock_timestamp()
    WHERE statid = 1;

-- =========================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS
-- =========================================================================
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

-- =========================================================================
-- Statement 7: GetLowStockProductsAsync
-- Conversion Method: DMS_TOOL
-- DMS Status: SUCCESS
-- =========================================================================
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
