-- ========================================================================================================
-- CONVERTED SQL STATEMENTS FOR POSTGRESQL
-- Generated during migration from Microsoft SQL Server to PostgreSQL using DMS MCP Tool
-- This file contains all PostgreSQL-converted statements from the original SQL Server statements
-- ========================================================================================================

-- ========================================================================================================
-- STATEMENT 1 of 7 - GetAllProductsAsync()
-- ========================================================================================================
-- Conversion Method: DMS_TOOL
-- Conversion Status: SUCCESS
-- Schema Changes: Products → productmanagement_dbo.products (schema prefix added by DMS)
-- Notes: Column names converted to lowercase by DMS, NULLS FIRST added to ORDER BY
-- ========================================================================================================

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

-- ========================================================================================================
-- STATEMENT 2 of 7 - GetProductByIdAsync(int productId)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_TIMEOUT
-- Schema Changes: Products → productmanagement_dbo.products
-- Manual Conversion Notes: DMS timed out, manually converted with PostgreSQL parameter syntax ($1)
-- ========================================================================================================

WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM productmanagement_dbo.products
    WHERE ProductId = $1
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
FROM productmanagement_dbo.products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = $1;

-- ========================================================================================================
-- STATEMENT 3 of 7 - InsertProductAsync(Product product)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_ERROR
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Manual Conversion Notes: DMS rejected statement (not valid), manually converted
-- Key Changes: 
--   - DECLARE/SET → DO block with variable declaration
--   - SCOPE_IDENTITY() → RETURNING clause
--   - GETDATE() → CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT block
-- ========================================================================================================

DO $$
DECLARE
    v_NewProductId INT;
BEGIN
    -- Insert the new product
    INSERT INTO productmanagement_dbo.products (Name, Description, Price, StockQuantity)
    VALUES ($1, $2, $3, $4)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO productmanagement_dbo.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + $3) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Note: For use in C# code, this will need to be restructured to use separate statements
-- with RETURNING clause on INSERT to capture the new ProductId

-- ========================================================================================================
-- STATEMENT 4 of 7 - UpdateProductAsync(Product product)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_TIMEOUT
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Manual Conversion Notes: DMS timed out, manually converted
-- Key Changes:
--   - BEGIN TRANSACTION/COMMIT → Transaction handled by application code
--   - DECLARE variables → local variables in DO block
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Parameters @ProductId → $1, @Name → $2, @Description → $3, @Price → $4, @StockQuantity → $5
-- ========================================================================================================

DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM productmanagement_dbo.products
    WHERE ProductId = $1;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET 
        Name = $2,
        Description = $3,
        Price = $4,
        StockQuantity = $5,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = $1;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'UPDATE', v_OldPrice, $4, v_OldStock, $5, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + $4) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ========================================================================================================
-- STATEMENT 5 of 7 - DeleteProductAsync(int productId)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_TIMEOUT
-- Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
-- Manual Conversion Notes: DMS timed out, manually converted
-- Key Changes:
--   - BEGIN TRANSACTION/COMMIT → Transaction handled by application code
--   - DECLARE variables → local variables in DO block
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Parameter @ProductId → $1
-- ========================================================================================================

DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM productmanagement_dbo.products
    WHERE ProductId = $1;
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE ProductId = $1;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - v_OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ========================================================================================================
-- STATEMENT 6 of 7 - GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_TIMEOUT
-- Schema Changes: Products → productmanagement_dbo.products
-- Manual Conversion Notes: DMS timed out, manually converted
-- Key Changes:
--   - Parameters @MinPrice → $1, @MaxPrice → $2
--   - NULLS FIRST added to ORDER BY for PostgreSQL
-- ========================================================================================================

WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM productmanagement_dbo.products p
    WHERE p.Price BETWEEN $1 AND $2
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank NULLS FIRST;

-- ========================================================================================================
-- STATEMENT 7 of 7 - GetLowStockProductsAsync(int threshold)
-- ========================================================================================================
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Conversion Status: DMS_TIMEOUT
-- Schema Changes: Products → productmanagement_dbo.products
-- Manual Conversion Notes: DMS timed out, manually converted
-- Key Changes:
--   - Parameter @Threshold → $1
--   - NULLS FIRST added to ORDER BY for PostgreSQL
-- ========================================================================================================

WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM productmanagement_dbo.products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity NULLS FIRST;

-- ========================================================================================================
-- END OF CONVERTED SQL STATEMENTS
-- Total Statements: 7
-- DMS Tool Success: 1
-- Manual After DMS Failure: 6
-- Schema Object Name Changes: All table references updated to productmanagement_dbo schema prefix
-- ========================================================================================================
