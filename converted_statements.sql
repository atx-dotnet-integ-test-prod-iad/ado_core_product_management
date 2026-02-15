-- =============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source File: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION (all statements)
-- DMS Error: Metadata model creation failed: Unknown metadata model creation status: RECEIVED
-- =============================================================================

-- =============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION
-- DMS Error: Metadata model creation failed
-- Changes Applied: No syntax changes needed - PostgreSQL supports CTEs, window functions, CASE statements
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION
-- DMS Error: Metadata model creation failed
-- Changes Applied: Parameter syntax remains @parameter (Npgsql supports this), PostgreSQL supports LAG, CTEs, CASE
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: InsertProductAsync
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   1. Removed DECLARE @NewProductId (PostgreSQL uses RETURNING clause)
--   2. Changed BEGIN TRANSACTION to BEGIN (PostgreSQL syntax)
--   3. Changed SCOPE_IDENTITY() to RETURNING ProductId in INSERT statement
--   4. Replaced GETDATE() with CURRENT_TIMESTAMP (PostgreSQL equivalent)
--   5. Transaction now uses DO $$ ... END $$ block with variable declaration
--   6. Combined operations to use RETURNING value directly
-- =============================================================================

DO $$
DECLARE
    v_NewProductId INT;
BEGIN
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Note: The code will need modification to handle this as a stored procedure or use RETURNING in a single statement

-- Alternative simpler approach for ADO.NET code:
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Then subsequent operations in separate commands within the transaction managed by ADO.NET

-- =============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: UpdateProductAsync
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   1. Changed BEGIN TRANSACTION to BEGIN (handled by ADO.NET transaction)
--   2. Variables declared as needed in DO block or handled via ADO.NET
--   3. Replaced GETDATE() with CURRENT_TIMESTAMP
--   4. Transaction control moved to ADO.NET level
-- For ADO.NET, keep as separate statements within transaction
-- =============================================================================

-- Store old values for history
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Update the product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Log the changes
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- Note: Transaction BEGIN/COMMIT handled by NpgsqlTransaction in ADO.NET code

-- =============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: DeleteProductAsync
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION
-- DMS Error: Metadata model creation failed
-- Changes Applied:
--   1. Transaction control handled by ADO.NET
--   2. Replaced GETDATE() with CURRENT_TIMESTAMP
--   3. Separate statements within ADO.NET managed transaction
-- =============================================================================

-- Store product info for history
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Log the deletion
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update product statistics
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

-- Note: Transaction BEGIN/COMMIT handled by NpgsqlTransaction in ADO.NET code

-- =============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION
-- DMS Error: Metadata model creation failed
-- Changes Applied: No syntax changes needed - PostgreSQL supports RANK(), PERCENT_RANK(), CTEs, CASE
-- =============================================================================

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

-- =============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- =============================================================================
-- Source Location: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync
-- Conversion Status: DMS_FAILURE_MANUAL_CONVERSION
-- DMS Error: Metadata model creation failed
-- Changes Applied: No syntax changes needed - PostgreSQL supports window functions (AVG, MIN, MAX OVER), CTEs, CASE
-- =============================================================================

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

-- =============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- =============================================================================
