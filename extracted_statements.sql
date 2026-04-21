-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Purpose: Comprehensive catalog of all SQL statements for DMS conversion
-- Total Statements: 7
-- ============================================================================

-- ==========================================================================
-- STATEMENT 1: GetAllProductsAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Parameters: None
-- T-SQL Constructs: CTE (ProductStats), Window Functions (AVG OVER, COUNT OVER),
--                   INNER JOIN, CASE/WHEN, ROUND, ORDER BY
-- ==========================================================================
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

-- ==========================================================================
-- STATEMENT 2: GetProductByIdAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId (INT)
-- T-SQL Constructs: CTE (ProductHistory), Window Functions (LAG OVER),
--                   LEFT JOIN, CASE/WHEN, ROUND, WHERE with parameter
-- ==========================================================================
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

-- ==========================================================================
-- STATEMENT 3: InsertProductAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- T-SQL Constructs: DECLARE, BEGIN TRANSACTION/COMMIT, INSERT INTO,
--                   SCOPE_IDENTITY(), GETDATE(), Variable assignment
-- NOTE: Multi-statement T-SQL block - will be split for PostgreSQL conversion
-- ==========================================================================
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

-- ==========================================================================
-- STATEMENT 4: UpdateProductAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR),
--             @Price (DECIMAL), @StockQuantity (INT)
-- T-SQL Constructs: BEGIN TRANSACTION/COMMIT, DECLARE, Variable assignment,
--                   SELECT into variables, UPDATE, INSERT, GETDATE()
-- NOTE: Multi-statement T-SQL block - will be split for PostgreSQL conversion
-- ==========================================================================
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

-- ==========================================================================
-- STATEMENT 5: DeleteProductAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Parameters: @ProductId (INT)
-- T-SQL Constructs: BEGIN TRANSACTION/COMMIT, DECLARE, Variable assignment,
--                   SELECT into variables, INSERT, DELETE, CASE/WHEN, GETDATE()
-- NOTE: Multi-statement T-SQL block - will be split for PostgreSQL conversion
-- ==========================================================================
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

-- ==========================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- T-SQL Constructs: CTE (RankedProducts), Window Functions (RANK, PERCENT_RANK),
--                   BETWEEN, CASE/WHEN, ORDER BY
-- ==========================================================================
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

-- ==========================================================================
-- STATEMENT 7: GetLowStockProductsAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold (INT)
-- T-SQL Constructs: CTE (StockAnalysis), Window Functions (AVG/MIN/MAX OVER),
--                   CASE/WHEN, ROUND, WHERE, ORDER BY
-- ==========================================================================
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
