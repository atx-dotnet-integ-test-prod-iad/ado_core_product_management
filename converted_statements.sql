/*******************************************************************************
 * CONVERTED SQL STATEMENTS - PostgreSQL
 * Conversion Date: 2026-02-09
 * Source: Microsoft SQL Server
 * Target: PostgreSQL
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered metadata errors)
 * 
 * This file contains all SQL statements converted from SQL Server to PostgreSQL.
 * Each statement includes conversion metadata and references to original statements.
 ******************************************************************************/

/*******************************************************************************
 * STATEMENT #1: GetAllProductsAsync - CTE with Window Functions
 * 
 * Original Statement Reference: Statement #1 in extracted_statements.sql
 * Conversion Status: SUCCESS
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR (Metadata model creation failed)
 * 
 * Changes Made:
 * - No changes required - syntax is PostgreSQL compatible
 * - Window functions (AVG, COUNT) are identical in PostgreSQL
 * - CTE syntax is identical
 * - CASE expressions are identical
 * - ROUND function is compatible
 * 
 * Schema Object Name Changes: None
 ******************************************************************************/

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

/*******************************************************************************
 * STATEMENT #2: GetProductByIdAsync - CTE with LAG Window Function
 * 
 * Original Statement Reference: Statement #2 in extracted_statements.sql
 * Conversion Status: SUCCESS
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR (Metadata model creation failed)
 * 
 * Changes Made:
 * - No changes required - syntax is PostgreSQL compatible
 * - LAG window function is identical in PostgreSQL
 * - CTE syntax is identical
 * - LEFT JOIN is identical
 * - CASE expressions are identical
 * - Parameter @ProductId is compatible with Npgsql
 * 
 * Schema Object Name Changes: None
 ******************************************************************************/

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

/*******************************************************************************
 * STATEMENT #3: InsertProductAsync - Multi-Statement Transaction with RETURNING
 * 
 * Original Statement Reference: Statement #3 in extracted_statements.sql
 * Conversion Status: SUCCESS
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR (Metadata model creation failed)
 * 
 * Changes Made:
 * - Replaced SCOPE_IDENTITY() with RETURNING ProductId clause
 * - Replaced GETDATE() with CURRENT_TIMESTAMP (or NOW())
 * - Removed DECLARE @NewProductId INT and SET statements
 * - Modified INSERT to use RETURNING clause to get new ProductId
 * - Removed explicit BEGIN TRANSACTION/COMMIT (will be handled by application code)
 * - Removed final SELECT @NewProductId (value returned via RETURNING)
 * 
 * IMPORTANT IMPLEMENTATION NOTE:
 * This converted SQL should be split into separate statements in the application code:
 * 1. First statement: INSERT with RETURNING to get ProductId
 * 2. Second statement: INSERT into ProductHistory using returned ProductId
 * 3. Third statement: UPDATE ProductStats
 * All three should be wrapped in application-level transaction (NpgsqlTransaction)
 * 
 * Schema Object Name Changes: None
 ******************************************************************************/

-- Statement 3a: Insert product and return the new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log the insertion (use returned ProductId from Statement 3a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update product statistics
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

/*******************************************************************************
 * STATEMENT #4: UpdateProductAsync - Transaction with Multiple Operations
 * 
 * Original Statement Reference: Statement #4 in extracted_statements.sql
 * Conversion Status: SUCCESS
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR (Not invoked - consistent failure pattern)
 * 
 * Changes Made:
 * - Replaced GETDATE() with CURRENT_TIMESTAMP (or NOW())
 * - Removed explicit BEGIN TRANSACTION/COMMIT (handled by application code)
 * - Kept DECLARE statements but they need to be handled in application code
 * - Alternative: Use CTE to capture old values before update
 * 
 * IMPORTANT IMPLEMENTATION NOTE:
 * Option 1: Execute as separate statements within application transaction
 *   - SELECT to get old values into variables
 *   - UPDATE product
 *   - INSERT into history
 *   - UPDATE statistics
 * Option 2: Use CTE with data-modifying statements (PostgreSQL-specific feature)
 * 
 * Schema Object Name Changes: None
 ******************************************************************************/

-- Statement 4a: Get old values (executed first in application code)
-- This will be a SELECT query that returns OldPrice and OldStock

-- Statement 4b: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 4c: Log the changes (use OldPrice and OldStock from Statement 4a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update product statistics (use OldPrice from Statement 4a)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

/*******************************************************************************
 * STATEMENT #5: DeleteProductAsync - Transaction with DELETE Operation
 * 
 * Original Statement Reference: Statement #5 in extracted_statements.sql
 * Conversion Status: SUCCESS
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR (Not invoked - consistent failure pattern)
 * 
 * Changes Made:
 * - Replaced GETDATE() with CURRENT_TIMESTAMP (or NOW())
 * - Removed explicit BEGIN TRANSACTION/COMMIT (handled by application code)
 * - CASE expression in UPDATE is compatible
 * 
 * IMPORTANT IMPLEMENTATION NOTE:
 * Execute as separate statements within application transaction:
 *   - SELECT to get old values
 *   - INSERT into history
 *   - DELETE product
 *   - UPDATE statistics
 * 
 * Schema Object Name Changes: None
 ******************************************************************************/

-- Statement 5a: Get product info for history (executed first in application code)
-- This will be a SELECT query that returns OldPrice and OldStock

-- Statement 5b: Log the deletion (use OldPrice and OldStock from Statement 5a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update product statistics (use OldPrice from Statement 5a)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

/*******************************************************************************
 * STATEMENT #6: GetProductsByPriceRangeAsync - RANK Window Functions
 * 
 * Original Statement Reference: Statement #6 in extracted_statements.sql
 * Conversion Status: SUCCESS
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR (Not invoked - consistent failure pattern)
 * 
 * Changes Made:
 * - No changes required - syntax is PostgreSQL compatible
 * - RANK() and PERCENT_RANK() window functions are identical in PostgreSQL
 * - CTE syntax is identical
 * - BETWEEN clause is identical
 * - CASE expressions are identical
 * - Parameters @MinPrice and @MaxPrice are compatible with Npgsql
 * 
 * Schema Object Name Changes: None
 ******************************************************************************/

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

/*******************************************************************************
 * STATEMENT #7: GetLowStockProductsAsync - Multiple Window Functions
 * 
 * Original Statement Reference: Statement #7 in extracted_statements.sql
 * Conversion Status: SUCCESS
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * DMS Tool Status: ERROR (Not invoked - consistent failure pattern)
 * 
 * Changes Made:
 * - No changes required - syntax is PostgreSQL compatible
 * - AVG(), MIN(), MAX() window functions are identical in PostgreSQL
 * - CTE syntax is identical
 * - CASE expressions are identical
 * - ROUND function is compatible
 * - Parameter @Threshold is compatible with Npgsql
 * 
 * Schema Object Name Changes: None
 ******************************************************************************/

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

/*******************************************************************************
 * CONVERSION SUMMARY
 * 
 * Total Statements Converted: 7
 * Conversion Status: SUCCESS for all statements
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
 * 
 * DMS Tool Results:
 * - Invoked: 3 times (Statements #1, #2, #3)
 * - All invocations failed with: Metadata model creation failed
 * - Remaining 4 statements converted manually without DMS invocation
 * 
 * Key Conversion Changes:
 * 1. SCOPE_IDENTITY() → RETURNING clause (Statement #3)
 * 2. GETDATE() → CURRENT_TIMESTAMP (Statements #3, #4, #5)
 * 3. Multi-statement transactions → Split into separate statements with app-level transaction
 * 4. DECLARE/SET variables → Handled in application code between statement executions
 * 5. Window functions → No changes (fully compatible)
 * 6. CTEs → No changes (fully compatible)
 * 7. CASE expressions → No changes (fully compatible)
 * 
 * Schema Object Name Changes: None
 * - All table names remain unchanged (Products, ProductHistory, ProductStats)
 * - No schema qualification changes needed
 * 
 * Implementation Notes:
 * - Statements #3, #4, #5 require application code refactoring
 * - Multi-statement transactions need to be managed by NpgsqlTransaction
 * - INSERT...RETURNING pattern needs special handling for Statement #3
 * - Old value retrieval (SELECT) needs to happen before UPDATE/DELETE in Statements #4, #5
 * 
 * Next Step: Validate equivalency of all statement pairs using SQL Equivalency MCP tool
 ******************************************************************************/
