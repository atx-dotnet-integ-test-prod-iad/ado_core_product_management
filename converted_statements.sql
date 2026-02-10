/*******************************************************************************
 * CONVERTED SQL STATEMENTS CATALOG
 * Microsoft SQL Server to PostgreSQL Migration
 * .NET ADO Application - AdoCore Project
 * 
 * This catalog contains all SQL statements after conversion through the DMS MCP
 * tool and manual conversion where DMS failed. Each statement includes:
 * - Original SQL Server statement
 * - Converted PostgreSQL statement
 * - Conversion method (DMS_TOOL or MANUAL_AFTER_DMS_FAILURE)
 * - DMS tool output/error messages
 * - Schema object name changes
 * - Conversion notes
 * 
 * Total Statements: 7
 * Successfully Converted by DMS: 0
 * Manually Converted After DMS Failure: 7
 * Date: Migration Phase - Statement Conversion
 ******************************************************************************/

===============================================================================
STATEMENT 1: GetAllProductsAsync
===============================================================================
Statement ID: 1
Method: GetAllProductsAsync
Conversion Method: MANUAL_AFTER_DMS_FAILURE
Schema Object Changes: None (Products table retained)

--- DMS TOOL OUTPUT ---
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
Timestamp: 2026-02-10T04:11:30.066951
Full Response: {
  "conversion_timestamp": "2026-02-10T04:11:25.755943",
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}

--- ORIGINAL SQL SERVER STATEMENT ---
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
    p.Name;

--- CONVERTED POSTGRESQL STATEMENT ---
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
    ROUND((p.Price / ps.AvgPrice)::numeric * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

--- CONVERSION NOTES ---
- CTE syntax is compatible between SQL Server and PostgreSQL
- Window functions (AVG OVER, COUNT OVER) are compatible
- CASE expressions are compatible
- ROUND function modified: Added ::numeric cast for division result to ensure proper rounding
- INNER JOIN syntax is compatible
- ORDER BY with CASE expression is compatible
- No parameter syntax changes needed (no parameters in this statement)
- Table names unchanged (Products remains Products)


===============================================================================
STATEMENT 2: GetProductByIdAsync
===============================================================================
Statement ID: 2
Method: GetProductByIdAsync
Conversion Method: MANUAL_AFTER_DMS_FAILURE
Schema Object Changes: None (Products table retained)

--- DMS TOOL OUTPUT ---
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
Timestamp: 2026-02-10T04:11:45.426519
Full Response: {
  "conversion_timestamp": "2026-02-10T04:11:41.516301",
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}

--- ORIGINAL SQL SERVER STATEMENT ---
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
WHERE p.ProductId = @ProductId;

--- CONVERTED POSTGRESQL STATEMENT ---
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
            ROUND((((p.Price - ph.PreviousPrice) / ph.PreviousPrice)::numeric) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

--- CONVERSION NOTES ---
- CTE syntax is compatible
- LAG window function is compatible in PostgreSQL
- LEFT JOIN syntax is compatible
- CASE expression with NULL handling is compatible
- Parameter syntax @ProductId is retained (Npgsql supports @ parameters)
- ROUND function modified: Added ::numeric cast for division result
- NULL handling is compatible
- Table names unchanged


===============================================================================
STATEMENT 3: InsertProductAsync
===============================================================================
Statement ID: 3
Method: InsertProductAsync
Conversion Method: MANUAL_AFTER_DMS_FAILURE
Schema Object Changes: None (Products, ProductHistory, ProductStats tables retained)

--- DMS TOOL OUTPUT ---
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
Timestamp: 2026-02-10T04:12:03.065666
Full Response: {
  "conversion_timestamp": "2026-02-10T04:11:59.106575",
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}

--- ORIGINAL SQL SERVER STATEMENT ---
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

--- CONVERTED POSTGRESQL STATEMENT ---
DO $$
DECLARE
    v_NewProductId INT;
BEGIN
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
    
    -- Return the new product ID
    PERFORM v_NewProductId;
END $$;

--- CONVERSION NOTES ---
CRITICAL: This statement requires special handling in application code due to RETURNING clause:
- SQL Server SCOPE_IDENTITY() converted to PostgreSQL RETURNING clause
- DECLARE @variable converted to DECLARE v_variable (PostgreSQL naming convention)
- BEGIN TRANSACTION/COMMIT removed - PostgreSQL handles implicit transactions
- GETDATE() converted to CURRENT_TIMESTAMP (PostgreSQL standard)
- SET @NewProductId = SCOPE_IDENTITY() converted to RETURNING ProductId INTO v_NewProductId
- Parameter syntax @Name, @Description, @Price, @StockQuantity retained
- Table names unchanged
- Final SELECT @NewProductId converted to PERFORM (for DO block)

IMPORTANT: In C# code, this will be restructured to use RETURNING clause directly:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

The other statements will be executed in the same transaction using Npgsql transaction handling.


===============================================================================
STATEMENT 4: UpdateProductAsync
===============================================================================
Statement ID: 4
Method: UpdateProductAsync
Conversion Method: MANUAL_AFTER_DMS_FAILURE
Schema Object Changes: None (Products, ProductHistory, ProductStats tables retained)

--- DMS TOOL OUTPUT ---
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
Timestamp: 2026-02-10T04:12:16.441312
Full Response: {
  "conversion_timestamp": "2026-02-10T04:12:12.660937",
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}

--- ORIGINAL SQL SERVER STATEMENT ---
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

--- CONVERTED POSTGRESQL STATEMENT ---
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', v_OldPrice, @Price, v_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

--- CONVERSION NOTES ---
- DECLARE @variable converted to DECLARE v_variable (PostgreSQL naming convention)
- BEGIN TRANSACTION/COMMIT removed - transactions handled at application level
- SELECT @var = column converted to SELECT column INTO v_var (PostgreSQL syntax)
- GETDATE() converted to CURRENT_TIMESTAMP (all 3 occurrences)
- Parameter syntax retained (@ProductId, @Name, @Description, @Price, @StockQuantity)
- Variable references @OldPrice and @OldStock converted to v_OldPrice and v_OldStock
- Table names unchanged
- All UPDATE and INSERT statements are compatible

IMPORTANT: In C# code, this will use Npgsql transaction handling with separate statements.


===============================================================================
STATEMENT 5: DeleteProductAsync
===============================================================================
Statement ID: 5
Method: DeleteProductAsync
Conversion Method: MANUAL_AFTER_DMS_FAILURE
Schema Object Changes: None (Products, ProductHistory, ProductStats tables retained)

--- DMS TOOL OUTPUT ---
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
Timestamp: 2026-02-10T04:12:31.224706
Full Response: {
  "conversion_timestamp": "2026-02-10T04:12:27.219871",
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}

--- ORIGINAL SQL SERVER STATEMENT ---
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

--- CONVERTED POSTGRESQL STATEMENT ---
DO $$
DECLARE
    v_OldPrice DECIMAL(18,2);
    v_OldStock INT;
BEGIN
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
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

--- CONVERSION NOTES ---
- DECLARE @variable converted to DECLARE v_variable (PostgreSQL naming convention)
- BEGIN TRANSACTION/COMMIT removed - transactions handled at application level
- SELECT @var = column converted to SELECT column INTO v_var (PostgreSQL syntax)
- GETDATE() converted to CURRENT_TIMESTAMP (both occurrences)
- Parameter syntax retained (@ProductId)
- Variable references @OldPrice and @OldStock converted to v_OldPrice and v_OldStock
- DELETE statement syntax is compatible
- CASE expression in UPDATE is compatible
- Table names unchanged

IMPORTANT: In C# code, this will use Npgsql transaction handling with separate statements.


===============================================================================
STATEMENT 6: GetProductsByPriceRangeAsync
===============================================================================
Statement ID: 6
Method: GetProductsByPriceRangeAsync
Conversion Method: MANUAL_AFTER_DMS_FAILURE
Schema Object Changes: None (Products table retained)

--- DMS TOOL OUTPUT ---
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
Timestamp: 2026-02-10T04:12:45.359829
Full Response: {
  "conversion_timestamp": "2026-02-10T04:12:41.506358",
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}

--- ORIGINAL SQL SERVER STATEMENT ---
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
ORDER BY rp.PriceRank;

--- CONVERTED POSTGRESQL STATEMENT ---
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
ORDER BY rp.PriceRank;

--- CONVERSION NOTES ---
- CTE syntax is fully compatible
- RANK() window function is compatible in PostgreSQL
- PERCENT_RANK() window function is compatible in PostgreSQL
- BETWEEN operator syntax is compatible
- CASE expression is compatible
- Parameter syntax retained (@MinPrice, @MaxPrice)
- ORDER BY syntax is compatible
- Table names unchanged
- No changes required - SQL is directly compatible with PostgreSQL


===============================================================================
STATEMENT 7: GetLowStockProductsAsync
===============================================================================
Statement ID: 7
Method: GetLowStockProductsAsync
Conversion Method: MANUAL_AFTER_DMS_FAILURE
Schema Object Changes: None (Products table retained)

--- DMS TOOL OUTPUT ---
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
Timestamp: 2026-02-10T04:12:59.313109
Full Response: {
  "conversion_timestamp": "2026-02-10T04:12:55.278309",
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
}

--- ORIGINAL SQL SERVER STATEMENT ---
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
ORDER BY StockQuantity;

--- CONVERTED POSTGRESQL STATEMENT ---
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
    ROUND(((StockQuantity::numeric / AvgStock) * 100), 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;

--- CONVERSION NOTES ---
- CTE syntax is compatible
- Aggregate window functions (AVG, MIN, MAX with OVER) are compatible
- CASE expression is compatible
- Parameter syntax retained (@Threshold)
- ROUND function modified: Added ::numeric cast for division to ensure proper numeric handling
- WHERE and ORDER BY clauses are compatible
- Table names unchanged


/*******************************************************************************
 * END OF CONVERTED STATEMENTS CATALOG
 * 
 * CONVERSION SUMMARY:
 * ===================
 * Total statements: 7
 * Successfully converted by DMS tool: 0
 * Manually converted after DMS failure: 7
 * 
 * DMS TOOL STATUS:
 * All 7 statements encountered the same DMS error:
 * "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
 * 
 * This error indicates an issue with the DMS service metadata model creation,
 * not with the SQL statements themselves. All statements were manually converted
 * using PostgreSQL best practices and standard SQL Server to PostgreSQL migration
 * patterns.
 * 
 * KEY CONVERSION PATTERNS APPLIED:
 * =================================
 * 1. GETDATE() → CURRENT_TIMESTAMP
 * 2. SCOPE_IDENTITY() → RETURNING clause
 * 3. DECLARE @variable → DECLARE v_variable
 * 4. BEGIN TRANSACTION/COMMIT → Removed (handled at application level)
 * 5. SELECT @var = column → SELECT column INTO v_var
 * 6. Parameter syntax @param → Retained (Npgsql supports it)
 * 7. ROUND with division → Added ::numeric casts where needed
 * 8. Window functions → Fully compatible, no changes needed
 * 9. CTEs → Fully compatible, no changes needed
 * 10. CASE expressions → Fully compatible, no changes needed
 * 
 * SCHEMA OBJECT NAME CHANGES:
 * ===========================
 * None - All table names (Products, ProductHistory, ProductStats) remain unchanged
 * 
 * NEXT STEPS:
 * ===========
 * 1. Validate all statement pairs using SQL Equivalency MCP tool
 * 2. Re-integrate converted statements into ProductRepository.cs
 * 3. Handle transaction blocks appropriately in C# code using Npgsql transactions
 * 4. Test all database operations against PostgreSQL database
 * 
 ******************************************************************************/
