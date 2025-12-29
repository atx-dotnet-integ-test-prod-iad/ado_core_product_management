-- =====================================================================
-- SQL Statement Extraction Catalog
-- Source File: ProductRepository.cs
-- Total Statements: 7
-- Extraction Date: Migration to PostgreSQL
-- =====================================================================

-- =====================================================================
-- STATEMENT 1
-- =====================================================================
-- Source Method: GetAllProductsAsync()
-- Line Range: Lines 41-67
-- Statement Type: SELECT with CTE
-- Features: CTE (WITH), Window Functions (AVG OVER, COUNT OVER), CASE statements, Complex JOIN
-- Parameters: None
-- Transaction Context: None (standalone query)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 2
-- =====================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Line Range: Lines 81-107
-- Statement Type: SELECT with CTE
-- Features: CTE (WITH), LAG window function, LEFT JOIN
-- Parameters: @ProductId (int)
-- Transaction Context: None (standalone query)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 3
-- =====================================================================
-- Source Method: InsertProductAsync(Product product)
-- Line Range: Lines 121-143
-- Statement Type: Multi-statement transaction block
-- Features: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), UPDATE, COMMIT, GETDATE()
-- Parameters: @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- Transaction Context: Explicit transaction with BEGIN/COMMIT
-- =====================================================================

DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- =====================================================================
-- STATEMENT 4
-- =====================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Line Range: Lines 157-182
-- Statement Type: Multi-statement transaction block
-- Features: DECLARE, BEGIN TRANSACTION, SELECT, UPDATE, INSERT, COMMIT, GETDATE()
-- Parameters: @ProductId (int), @Name (string), @Description (string/null), @Price (decimal), @StockQuantity (int)
-- Transaction Context: Explicit transaction with BEGIN/COMMIT
-- =====================================================================

BEGIN TRANSACTION;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- =====================================================================
-- STATEMENT 5
-- =====================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Line Range: Lines 196-220
-- Statement Type: Multi-statement transaction block
-- Features: DECLARE, BEGIN TRANSACTION, SELECT, INSERT, DELETE, UPDATE with CASE, COMMIT, GETDATE()
-- Parameters: @ProductId (int)
-- Transaction Context: Explicit transaction with BEGIN/COMMIT
-- =====================================================================

BEGIN TRANSACTION;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
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
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- =====================================================================
-- STATEMENT 6
-- =====================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Range: Lines 227-247
-- Statement Type: SELECT with CTE
-- Features: CTE (WITH), RANK() window function, PERCENT_RANK() window function, CASE statement
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Transaction Context: None (standalone query)
-- =====================================================================

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

-- =====================================================================
-- STATEMENT 7
-- =====================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Line Range: Lines 261-281
-- Statement Type: SELECT with CTE
-- Features: CTE (WITH), Multiple aggregate window functions (AVG, MIN, MAX OVER), CASE statement
-- Parameters: @Threshold (int)
-- Transaction Context: None (standalone query)
-- =====================================================================

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

-- =====================================================================
-- END OF EXTRACTION CATALOG
-- =====================================================================
-- Summary:
-- - Total Statements Extracted: 7
-- - Standalone SELECT queries: 4 (Statements 1, 2, 6, 7)
-- - Transaction blocks: 3 (Statements 3, 4, 5)
-- - Statements with Window Functions: 5 (Statements 1, 2, 6, 7 with various window functions)
-- - Statements with CTEs: 5 (Statements 1, 2, 6, 7)
-- - Statements with SCOPE_IDENTITY(): 1 (Statement 3)
-- - Statements with GETDATE(): 3 (Statements 3, 4, 5)
-- =====================================================================
