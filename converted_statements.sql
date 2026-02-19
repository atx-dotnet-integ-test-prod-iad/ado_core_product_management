-- ===================================================================
-- CONVERTED SQL STATEMENTS (MS SQL SERVER TO POSTGRESQL)
-- ===================================================================
-- This file contains all PostgreSQL-converted SQL statements
-- ===================================================================

-- ===================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
-- - Window functions (AVG OVER, COUNT OVER) are compatible with PostgreSQL
-- - ROUND function syntax is compatible
-- - CASE expressions are compatible
-- - INNER JOIN syntax is compatible
-- ===================================================================
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

-- ===================================================================
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
-- - LAG window function is compatible with PostgreSQL
-- - Parameter syntax remains @ProductId (Npgsql supports this)
-- - CASE expressions are compatible
-- - LEFT JOIN syntax is compatible
-- ===================================================================
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

-- ===================================================================
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
-- - DECLARE syntax compatible with PL/pgSQL
-- - BEGIN TRANSACTION removed (PostgreSQL transactions managed by ADO.NET)
-- - SCOPE_IDENTITY() replaced with RETURNING clause on INSERT
-- - GETDATE() replaced with CURRENT_TIMESTAMP or NOW()
-- - COMMIT removed (managed by ADO.NET)
-- - Returns value through RETURNING clause
-- Note: This will need transaction handling at the ADO.NET level
-- ===================================================================
DO $$
DECLARE NewProductId INT;
BEGIN
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId INTO NewProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
    
    -- Return the new product ID
    PERFORM NewProductId;
END $$;

-- Alternative approach for ADO.NET (preferred):
-- Statement 3A: First insert with RETURNING
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Statement 3B: Log insertion (executed after getting ProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3C: Update statistics (executed after logging)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
-- - BEGIN TRANSACTION removed (managed by ADO.NET)
-- - DECLARE DECIMAL(18,2) compatible with PostgreSQL NUMERIC
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - COMMIT removed (managed by ADO.NET)
-- Note: Transaction handling at ADO.NET level
-- ===================================================================
-- Statement 4A: Get old values
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
-- Statement 4B: Update product
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Statement 4C: Log changes (requires OldPrice and OldStock as parameters)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4D: Update statistics
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ===================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
-- - BEGIN TRANSACTION removed (managed by ADO.NET)
-- - DECLARE DECIMAL(18,2) compatible with PostgreSQL NUMERIC
-- - GETDATE() replaced with CURRENT_TIMESTAMP
-- - COMMIT removed (managed by ADO.NET)
-- Note: Transaction handling at ADO.NET level
-- ===================================================================
-- Statement 5A: Get old values
WITH OldValues AS (
    SELECT Price as OldPrice, StockQuantity as OldStock
    FROM Products
    WHERE ProductId = @ProductId
)
-- Statement 5B: Log deletion (requires OldPrice and OldStock as parameters)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5C: Delete product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Statement 5D: Update statistics
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

-- ===================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
-- - RANK() and PERCENT_RANK() window functions are compatible
-- - BETWEEN operator is compatible
-- - CASE expressions are compatible
-- ===================================================================
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

-- ===================================================================
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- PostgreSQL Changes:
-- - AVG, MIN, MAX window functions are compatible with PostgreSQL
-- - CASE expressions are compatible
-- - ROUND function syntax is compatible
-- ===================================================================
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

-- ===================================================================
-- END OF CONVERTED SQL STATEMENTS
-- Total Statements: 7 main queries (Statement 3, 4, 5 split into sub-statements)
-- ===================================================================
