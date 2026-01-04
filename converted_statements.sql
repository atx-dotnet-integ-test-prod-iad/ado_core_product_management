/*
================================================================================
CONVERTED SQL STATEMENTS CATALOG
PostgreSQL Conversion via AWS DMS MCP Tool
================================================================================
Total Statements: 7
Conversion Date: 2026-01-04
Target Database: PostgreSQL (via Npgsql 8.0.5)
Schema Transformation: dbo -> productmanagement_dbo
================================================================================
*/

-- ============================================================================
-- STATEMENT ID: SQL_001_CONVERTED
-- ORIGINAL: GetAllProductsAsync - SELECT with CTE and window functions
-- DMS CONVERSION: SUCCESS
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products
-- KEY CHANGES: Lowercase identifiers, added NULLS FIRST to ORDER BY
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
-- STATEMENT ID: SQL_002_CONVERTED
-- ORIGINAL: GetProductByIdAsync - SELECT with CTE and LAG window function
-- DMS CONVERSION: SUCCESS
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products
-- KEY CHANGES: Lowercase identifiers, LEFT JOIN -> LEFT OUTER JOIN, preserved @ProductId parameter
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
-- STATEMENT ID: SQL_003_CONVERTED
-- ORIGINAL: InsertProductAsync - INSERT with transaction and SCOPE_IDENTITY()
-- DMS CONVERSION: FAILED - Statement definition not valid for multi-statement transaction block
-- MANUAL CONVERSION: Applied PostgreSQL transaction pattern for ADO.NET
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- KEY CHANGES:
--   - Removed DECLARE @NewProductId (managed in C# code)
--   - Removed BEGIN TRANSACTION/COMMIT (managed by NpgsqlTransaction object)
--   - SCOPE_IDENTITY() replaced with RETURNING clause in INSERT
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Split into 3 separate statements to be executed within C# transaction
-- ============================================================================
-- Statement 3a: Insert product and return ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion (executed after Statement 3a, using returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT ID: SQL_004_CONVERTED
-- ORIGINAL: UpdateProductAsync - UPDATE with transaction
-- DMS CONVERSION: SUCCESS with CRITICAL warning - Transaction management must be manual
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- KEY CHANGES:
--   - Removed BEGIN TRANSACTION/COMMIT (managed by NpgsqlTransaction object)
--   - Removed DECLARE statements (use C# variables or CTEs)
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Split into separate statements to be executed within C# transaction
-- ============================================================================
-- Statement 4a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 4b: Update the product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 4c: Log the changes (executed after 4a and 4b, using values from 4a)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT ID: SQL_005_CONVERTED
-- ORIGINAL: DeleteProductAsync - DELETE with transaction
-- DMS CONVERSION: SUCCESS with CRITICAL warning - Transaction management must be manual
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products, ProductHistory -> productmanagement_dbo.producthistory, ProductStats -> productmanagement_dbo.productstats
-- KEY CHANGES:
--   - Removed BEGIN TRANSACTION/COMMIT (managed by NpgsqlTransaction object)
--   - Removed DECLARE statements (use C# variables or CTEs)
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Split into separate statements to be executed within C# transaction
-- ============================================================================
-- Statement 5a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5b: Log the deletion (executed after 5a, using values from 5a)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete the product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5d: Update product statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, averageprice =
CASE
    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
    ELSE 0
END, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT ID: SQL_006_CONVERTED
-- ORIGINAL: GetProductsByPriceRangeAsync - SELECT with CTE and RANK/PERCENT_RANK
-- DMS CONVERSION: SUCCESS
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products
-- KEY CHANGES: Lowercase identifiers, added NULLS FIRST to ORDER BY, preserved parameters
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
-- STATEMENT ID: SQL_007_CONVERTED
-- ORIGINAL: GetLowStockProductsAsync - SELECT with CTE and window functions
-- DMS CONVERSION: SUCCESS
-- SCHEMA CHANGES: Products -> productmanagement_dbo.products
-- KEY CHANGES: Lowercase identifiers, added NULLS FIRST to ORDER BY, preserved @Threshold parameter
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

/*
================================================================================
CONVERSION SUMMARY
================================================================================
Total Statements Converted: 7

DMS Conversion Results:
- Successful with no warnings: 4 statements (SQL_001, SQL_002, SQL_006, SQL_007)
- Successful with warnings: 2 statements (SQL_004, SQL_005) - transaction management warnings
- Failed (manual conversion required): 1 statement (SQL_003) - invalid multi-statement definition

Schema Object Name Changes (ALL instances):
- Schema: dbo -> productmanagement_dbo
- Table: Products -> productmanagement_dbo.products
- Table: ProductHistory -> productmanagement_dbo.producthistory
- Table: ProductStats -> productmanagement_dbo.productstats
- Column names: ALL converted to lowercase (e.g., ProductId -> productid, StockQuantity -> stockquantity)

PostgreSQL-Specific Syntax Applied:
- GETDATE() -> CURRENT_TIMESTAMP
- SCOPE_IDENTITY() -> RETURNING clause
- ORDER BY with NULLS FIRST handling
- Transaction management moved to ADO.NET transaction objects
- DECLARE statements removed (incompatible with ADO.NET execution model)
- Multi-statement transactions split into individual statements executed within C# transaction context

Parameters Preserved:
- All @ parameters maintained (Npgsql supports MS SQL parameter syntax)
- @ProductId, @Name, @Description, @Price, @StockQuantity, @MinPrice, @MaxPrice, @Threshold

CRITICAL NOTE FOR CODE INTEGRATION:
The schema has been transformed to productmanagement_dbo. When re-integrating these statements
into ProductRepository.cs, ALL table references MUST use the new schema-qualified names.
Do NOT use the original unqualified table names (Products, ProductHistory, ProductStats).
================================================================================
*/
