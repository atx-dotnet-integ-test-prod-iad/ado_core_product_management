/*******************************************************************************
 * CONVERTED SQL STATEMENTS CATALOG - PostgreSQL
 * Microsoft SQL Server to PostgreSQL Migration
 * 
 * This file contains all SQL statements converted to PostgreSQL syntax.
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered consistent errors)
 * 
 * Total Statement Groups: 7
 * Source: extracted_statements.sql
 * Date: 2026-01-30
 * 
 * IMPORTANT: For ADO.NET usage, transaction blocks will be managed by NpgsqlTransaction
 * at the application level, not within the SQL statements themselves.
 *******************************************************************************/

/*******************************************************************************
 * STATEMENT GROUP 1: GetAllProductsAsync - CONVERTED
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes: None required - PostgreSQL syntax compatible
 *******************************************************************************/
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
 * STATEMENT GROUP 2: GetProductByIdAsync - CONVERTED
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes: None required - PostgreSQL syntax compatible
 *******************************************************************************/
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
 * STATEMENT GROUP 3: InsertProductAsync - CONVERTED
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * CRITICAL Changes: 
 * - Multi-statement transaction split into separate statements
 * - SCOPE_IDENTITY() replaced with RETURNING clause pattern
 * - GETDATE() replaced with CURRENT_TIMESTAMP
 * - Transaction management handled at application level with NpgsqlTransaction
 * 
 * IMPLEMENTATION NOTE: These statements will be executed within a C# 
 * NpgsqlTransaction block. The application will:
 * 1. Begin transaction
 * 2. Execute statement 3a and capture ProductId
 * 3. Execute statement 3b with captured ProductId
 * 4. Execute statement 3c with captured ProductId and @Price
 * 5. Commit or rollback transaction
 *******************************************************************************/

-- Statement 3a: Insert product and return new ID
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3b: Log the insertion (executed with @NewProductId from previous RETURNING)
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
 * STATEMENT GROUP 4: UpdateProductAsync - CONVERTED
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * CRITICAL Changes:
 * - Multi-statement transaction split into separate statements
 * - Variable declarations removed (handled in C# code)
 * - GETDATE() replaced with CURRENT_TIMESTAMP
 * - Transaction management handled at application level with NpgsqlTransaction
 * 
 * IMPLEMENTATION NOTE: These statements will be executed within a C#
 * NpgsqlTransaction block. The application will:
 * 1. Begin transaction
 * 2. Execute statement 4a to retrieve old values
 * 3. Execute statement 4b to update product
 * 4. Execute statement 4c to log history
 * 5. Execute statement 4d to update statistics
 * 6. Commit or rollback transaction
 *******************************************************************************/

-- Statement 4a: Get old values
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 4b: Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 4c: Log the changes (with @OldPrice and @OldStock from 4a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update product statistics (with @OldPrice from 4a)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

/*******************************************************************************
 * STATEMENT GROUP 5: DeleteProductAsync - CONVERTED
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * CRITICAL Changes:
 * - Multi-statement transaction split into separate statements
 * - Variable declarations removed (handled in C# code)
 * - GETDATE() replaced with CURRENT_TIMESTAMP
 * - Transaction management handled at application level with NpgsqlTransaction
 * 
 * IMPLEMENTATION NOTE: These statements will be executed within a C#
 * NpgsqlTransaction block. The application will:
 * 1. Begin transaction
 * 2. Execute statement 5a to retrieve old values
 * 3. Execute statement 5b to log deletion
 * 4. Execute statement 5c to delete product
 * 5. Execute statement 5d to update statistics
 * 6. Commit or rollback transaction
 *******************************************************************************/

-- Statement 5a: Get product info for history
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Statement 5b: Log the deletion (with @OldPrice and @OldStock from 5a)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5d: Update product statistics (with @OldPrice from 5a)
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
 * STATEMENT GROUP 6: GetProductsByPriceRangeAsync - CONVERTED
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes: None required - PostgreSQL syntax compatible
 *******************************************************************************/
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
 * STATEMENT GROUP 7: GetLowStockProductsAsync - CONVERTED
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes: None required - PostgreSQL syntax compatible
 *******************************************************************************/
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
 * END OF CONVERTED SQL STATEMENTS
 * 
 * Conversion Summary:
 * - Statement Groups 1, 2, 6, 7: No changes required - PostgreSQL compatible
 * - Statement Groups 3, 4, 5: Split into multiple statements for ADO.NET usage
 * - Key conversions applied:
 *   - SCOPE_IDENTITY() → RETURNING ProductId
 *   - GETDATE() → CURRENT_TIMESTAMP  
 *   - Transaction blocks removed (handled at application level)
 *   - All window functions, CTEs, and CASE expressions compatible
 *   - Parameter syntax (@param) remains compatible with Npgsql
 * 
 * All statements are ready for integration into ProductRepository.cs with
 * Npgsql and NpgsqlTransaction.
 *******************************************************************************/
