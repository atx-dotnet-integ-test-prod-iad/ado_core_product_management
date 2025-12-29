-- =====================================================================
-- Converted SQL Statements Catalog
-- Source: ProductRepository.cs (MS SQL Server)
-- Target: PostgreSQL
-- Conversion Method: AWS DMS MCP Tool + Manual Refinement
-- Total Statements: 7
-- =====================================================================

-- =====================================================================
-- STATEMENT 1 - CONVERTED
-- =====================================================================
-- Source Method: GetAllProductsAsync()
-- Original: CTE with window functions (AVG OVER, COUNT OVER), CASE statements
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products (lowercase with schema prefix)
-- Status: Successfully converted by DMS tool
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 2 - CONVERTED
-- =====================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Original: CTE with LAG window function
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Status: Successfully converted by DMS tool
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 3 - CONVERTED (WITH MANUAL REFINEMENT)
-- =====================================================================
-- Source Method: InsertProductAsync(Product product)
-- Original: Multi-statement transaction with INSERT, SCOPE_IDENTITY(), UPDATE
-- Conversion Method: DMS_TOOL + MANUAL_REFINEMENT
-- Schema Changes: All tables → productmanagement_dbo.* (lowercase)
-- Status: DMS tool provided base conversion; manual refinement for SCOPE_IDENTITY() and transactions
-- Notes: 
--   - Transactions handled at application level (C# NpgsqlConnection.BeginTransactionAsync())
--   - SCOPE_IDENTITY() converted to RETURNING clause pattern
--   - GETDATE() → CURRENT_TIMESTAMP (using PostgreSQL standard instead of clock_timestamp for consistency)
-- =====================================================================

INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Secondary statements to be executed after getting the returned productid
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================
-- STATEMENT 4 - CONVERTED (WITH MANUAL REFINEMENT)
-- =====================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Original: Multi-statement transaction with DECLARE, SELECT, UPDATE, INSERT
-- Conversion Method: DMS_TOOL + MANUAL_REFINEMENT
-- Schema Changes: All tables → productmanagement_dbo.* (lowercase)
-- Status: DMS tool provided base conversion; manual refinement for transaction handling
-- Notes:
--   - Transactions handled at application level
--   - Variable handling moved to C# code (will use C# variables instead of SQL DECLARE)
--   - GETDATE() → CURRENT_TIMESTAMP
-- =====================================================================

-- First query: Get old values (to be executed as separate query in C# code)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Second query: Update the product
UPDATE productmanagement_dbo.products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Third query: Log the changes
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Fourth query: Update statistics
UPDATE productmanagement_dbo.productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================
-- STATEMENT 5 - CONVERTED (WITH MANUAL REFINEMENT)
-- =====================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Original: Multi-statement transaction with DECLARE, SELECT, INSERT, DELETE, UPDATE
-- Conversion Method: DMS_TOOL + MANUAL_REFINEMENT
-- Schema Changes: All tables → productmanagement_dbo.* (lowercase)
-- Status: DMS tool provided base conversion; manual refinement for transaction handling
-- Notes:
--   - Transactions handled at application level
--   - Variable handling moved to C# code
--   - GETDATE() → CURRENT_TIMESTAMP
-- =====================================================================

-- First query: Get old values (to be executed as separate query in C# code)
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Second query: Log the deletion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Third query: Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Fourth query: Update statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE 
        WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- =====================================================================
-- STATEMENT 6 - CONVERTED
-- =====================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Original: CTE with RANK() and PERCENT_RANK() window functions
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Status: Successfully converted by DMS tool
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 7 - CONVERTED
-- =====================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Original: CTE with multiple aggregate window functions (AVG, MIN, MAX)
-- Conversion Method: DMS_TOOL
-- Schema Changes: Products → productmanagement_dbo.products
-- Status: Successfully converted by DMS tool
-- =====================================================================

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

-- =====================================================================
-- END OF CONVERTED STATEMENTS
-- =====================================================================
-- Conversion Summary:
-- - Statements successfully converted by DMS tool: 7/7
-- - Statements requiring manual refinement: 3 (Statements 3, 4, 5 for transaction handling)
-- - Schema object renamed: Products → productmanagement_dbo.products (all occurrences)
-- - All identifiers converted to lowercase
-- - GETDATE() → CURRENT_TIMESTAMP (all occurrences)
-- - SCOPE_IDENTITY() → RETURNING clause pattern (Statement 3)
-- - Transaction management moved to application level (C# code)
-- =====================================================================
