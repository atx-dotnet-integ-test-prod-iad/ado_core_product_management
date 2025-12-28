-- ========================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Target: PostgreSQL
-- Source: SQL Server (extracted_statements.sql)
-- Date: 2024-12-28
-- CRITICAL NOTE: DMS tool converted table references from "Products" to "productmanagement_dbo.products"
-- This schema transformation MUST be respected in code integration
-- ========================================================================

-- ========================================================================
-- STATEMENT ID: 1
-- SOURCE: GetAllProductsAsync
-- CONVERSION METHOD: DMS_TOOL
-- DMS STATUS: SUCCESS
-- SCHEMA CHANGES: Products → productmanagement_dbo.products
-- NOTES: Window functions, CTEs, CASE expressions all converted successfully
--        Added NULLS FIRST for ORDER BY compatibility
-- ========================================================================

-- ORIGINAL SQL SERVER:
/*
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name
*/

-- CONVERTED POSTGRESQL:
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

-- ========================================================================
-- STATEMENT ID: 2
-- SOURCE: GetProductByIdAsync
-- CONVERSION METHOD: DMS_TOOL
-- DMS STATUS: SUCCESS
-- SCHEMA CHANGES: Products → productmanagement_dbo.products
-- NOTES: LAG window function converted successfully
--        LEFT JOIN → LEFT OUTER JOIN (PostgreSQL explicit syntax)
-- ========================================================================

-- ORIGINAL SQL SERVER:
/*
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
*/

-- CONVERTED POSTGRESQL:
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

-- ========================================================================
-- STATEMENT ID: 3
-- SOURCE: InsertProductAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS STATUS: FAILED - "Statement definition is not valid" (cannot handle DECLARE + transaction blocks)
-- DMS ERROR: Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}
-- MANUAL CONVERSION NOTES:
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → NOW() or CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT → PostgreSQL transaction syntax
--   - DECLARE @Variable → PostgreSQL DECLARE in function context or use RETURNING
--   - Multiple statements require DO block or function
-- SCHEMA CHANGES: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- ========================================================================

-- ORIGINAL SQL SERVER:
/*
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
*/

-- CONVERTED POSTGRESQL (using DO block and RETURNING):
DO $$
DECLARE
    v_NewProductId INT;
BEGIN
    -- Insert the new product and get the generated ID
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1;
    
    -- Return the new product ID (Note: In ADO.NET, this requires FETCH to get result)
    RAISE NOTICE 'New Product ID: %', v_NewProductId;
END $$;

-- ALTERNATIVE SIMPLIFIED VERSION (for ExecuteScalar pattern):
-- This version uses RETURNING clause directly without DO block
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ========================================================================
-- STATEMENT ID: 4
-- SOURCE: UpdateProductAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS STATUS: NOT ATTEMPTED (same pattern as Statement 3 - would fail)
-- MANUAL CONVERSION NOTES:
--   - GETDATE() → NOW()
--   - BEGIN TRANSACTION/COMMIT → implicit in PostgreSQL within function/block
--   - DECLARE variables → PostgreSQL DECLARE in DO block
-- SCHEMA CHANGES: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- ========================================================================

-- ORIGINAL SQL SERVER:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL:
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO v_OldPrice, v_OldStock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = NOW()
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - v_OldPrice + @Price) / totalproducts,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ========================================================================
-- STATEMENT ID: 5
-- SOURCE: DeleteProductAsync
-- CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
-- DMS STATUS: NOT ATTEMPTED (same pattern as Statement 3 - would fail)
-- MANUAL CONVERSION NOTES:
--   - GETDATE() → NOW()
--   - BEGIN TRANSACTION/COMMIT → implicit in PostgreSQL
--   - DECLARE variables → PostgreSQL DECLARE in DO block
-- SCHEMA CHANGES: Products → productmanagement_dbo.products
--                 ProductHistory → productmanagement_dbo.producthistory
--                 ProductStats → productmanagement_dbo.productstats
-- ========================================================================

-- ORIGINAL SQL SERVER:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL:
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO v_OldPrice, v_OldStock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, NOW());
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_OldPrice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = NOW()
    WHERE statid = 1;
END $$;

-- ========================================================================
-- STATEMENT ID: 6
-- SOURCE: GetProductsByPriceRangeAsync
-- CONVERSION METHOD: DMS_TOOL
-- DMS STATUS: SUCCESS
-- SCHEMA CHANGES: Products → productmanagement_dbo.products
-- NOTES: RANK() and PERCENT_RANK() window functions converted successfully
--        BETWEEN clause works identically in PostgreSQL
-- ========================================================================

-- ORIGINAL SQL SERVER:
/*
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
*/

-- CONVERTED POSTGRESQL:
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

-- ========================================================================
-- STATEMENT ID: 7
-- SOURCE: GetLowStockProductsAsync
-- CONVERSION METHOD: DMS_TOOL
-- DMS STATUS: SUCCESS
-- SCHEMA CHANGES: Products → productmanagement_dbo.products
-- NOTES: AVG, MIN, MAX window functions converted successfully
-- ========================================================================

-- ORIGINAL SQL SERVER:
/*
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity
*/

-- CONVERTED POSTGRESQL:
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

-- ========================================================================
-- CONVERSION SUMMARY
-- ========================================================================
-- Total Statements: 7
-- DMS Tool Success: 4 (Statements 1, 2, 6, 7)
-- DMS Tool Failed: 1 (Statement 3 - transaction block with DECLARE)
-- Manual Conversion: 3 (Statements 3, 4, 5 - all transaction blocks)
--
-- Key Schema Transformation (CRITICAL for code integration):
-- ALL table references must be updated from simple names to schema-qualified names:
--   Products → productmanagement_dbo.products
--   ProductHistory → productmanagement_dbo.producthistory
--   ProductStats → productmanagement_dbo.productstats
--
-- Key SQL Server to PostgreSQL Conversions:
-- - SCOPE_IDENTITY() → RETURNING clause
-- - GETDATE() → NOW() or CURRENT_TIMESTAMP
-- - BEGIN TRANSACTION/COMMIT → DO $$ ... END $$; blocks or implicit transactions
-- - DECLARE @ variables → DECLARE v_ variables (in DO blocks)
-- - Column/table names → lowercase (PostgreSQL default)
-- - NULLS FIRST added to ORDER BY for explicit null handling
-- - LEFT JOIN → LEFT OUTER JOIN (more explicit PostgreSQL syntax)
-- ========================================================================
