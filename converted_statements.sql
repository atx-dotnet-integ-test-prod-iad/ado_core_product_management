-- ================================================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Converted from Microsoft SQL Server
-- Conversion Date: 2026-02-14
-- Total Statements: 7
-- Conversion Method: Manual (DMS tool encountered technical errors)
-- ================================================================================

-- ================================================================================
-- STATEMENT #1: GetAllProductsAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - GetAllProductsAsync()
-- Conversion: Direct compatibility - CTE and window functions work identically
-- Schema Changes: None
-- ================================================================================

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

-- ================================================================================
-- STATEMENT #2: GetProductByIdAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - GetProductByIdAsync(int productId)
-- Conversion: Direct compatibility - LAG window function supported
-- Schema Changes: None
-- ================================================================================

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

-- ================================================================================
-- STATEMENT #3: InsertProductAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - InsertProductAsync(Product product)
-- Conversion: Refactored to use PostgreSQL RETURNING clause, replaced GETDATE() 
--             with CURRENT_TIMESTAMP, removed variables (handled in C# code)
-- Schema Changes: None
-- Note: This will be split into multiple statements in C# code with transaction
-- ================================================================================

-- Insert statement with RETURNING clause (replaces SCOPE_IDENTITY())
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- History logging statement (executed separately with returned ProductId)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Stats update statement (executed separately)
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT #4: UpdateProductAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - UpdateProductAsync(Product product)
-- Conversion: Refactored to multiple statements, replaced GETDATE() with 
--             CURRENT_TIMESTAMP, variables handled in C# code
-- Schema Changes: None
-- Note: These will be executed as separate statements within a transaction in C#
-- ================================================================================

-- Get old values (executed first, values captured in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Update product (executed with @OldPrice and @OldStock from C# variables)
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = @ProductId;

-- Log the update (executed with values from C# variables)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Update statistics (executed with @OldPrice from C# variable)
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ================================================================================
-- STATEMENT #5: DeleteProductAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - DeleteProductAsync(int productId)
-- Conversion: Refactored to multiple statements, replaced GETDATE() with 
--             CURRENT_TIMESTAMP, variables handled in C# code
-- Schema Changes: None
-- Note: These will be executed as separate statements within a transaction in C#
-- ================================================================================

-- Get old values (executed first, values captured in C# variables)
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = @ProductId;

-- Log the deletion (executed before actual delete)
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Delete the product
DELETE FROM Products 
WHERE ProductId = @ProductId;

-- Update statistics with CASE expression (compatible syntax)
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

-- ================================================================================
-- STATEMENT #6: GetProductsByPriceRangeAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - GetProductsByPriceRangeAsync()
-- Conversion: Direct compatibility - RANK and PERCENT_RANK supported
-- Schema Changes: None
-- ================================================================================

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

-- ================================================================================
-- STATEMENT #7: GetLowStockProductsAsync (CONVERTED)
-- Source: DataAccess/ProductRepository.cs - GetLowStockProductsAsync()
-- Conversion: Direct compatibility - All window functions supported
-- Schema Changes: None
-- ================================================================================

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

-- ================================================================================
-- CONVERSION SUMMARY
-- ================================================================================
-- Total Statements: 7
-- Direct Compatibility (no changes): 4 (Statements #1, #2, #6, #7)
-- Refactored for PostgreSQL: 3 (Statements #3, #4, #5)
-- Schema Object Name Changes: None (Products, ProductHistory, ProductStats unchanged)
-- 
-- Key Conversions Applied:
-- 1. SCOPE_IDENTITY() → RETURNING clause in INSERT statements
-- 2. GETDATE() → CURRENT_TIMESTAMP
-- 3. Transaction blocks with variables → Refactored to separate statements with 
--    variable management in C# code (ADO.NET transaction handling)
-- 4. All CTE, window functions, CASE expressions are directly compatible
-- ================================================================================
