-- ===================================================================
-- SQL Statement Extraction Catalog
-- Source: ProductRepository.cs
-- Purpose: Migration from Microsoft SQL Server to PostgreSQL
-- Total Statements: 7
-- ===================================================================

-- ===================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line Range: Approx 43-71
-- Parameters: None
-- Schema Objects: Products, ProductStats (CTE)
-- T-SQL Features: CTE, Window Functions (AVG OVER, COUNT OVER), CASE
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
-- STATEMENT 2: GetProductByIdAsync
-- Source File: ProductRepository.cs
-- Method: GetProductByIdAsync
-- Line Range: Approx 79-107
-- Parameters: @ProductId (int)
-- Schema Objects: Products, ProductHistory (CTE)
-- T-SQL Features: CTE, LAG Window Function, Parameter binding
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
-- STATEMENT 3: InsertProductAsync
-- Source File: ProductRepository.cs
-- Method: InsertProductAsync
-- Line Range: Approx 115-145
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Schema Objects: Products, ProductHistory, ProductStats
-- T-SQL Features: DECLARE, BEGIN TRANSACTION, COMMIT, SCOPE_IDENTITY(), GETDATE()
-- ===================================================================
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

-- ===================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source File: ProductRepository.cs
-- Method: UpdateProductAsync
-- Line Range: Approx 153-191
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Schema Objects: Products, ProductHistory, ProductStats
-- T-SQL Features: DECLARE, BEGIN TRANSACTION, COMMIT, GETDATE()
-- ===================================================================
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

-- ===================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source File: ProductRepository.cs
-- Method: DeleteProductAsync
-- Line Range: Approx 199-235
-- Parameters: @ProductId
-- Schema Objects: Products, ProductHistory, ProductStats
-- T-SQL Features: DECLARE, BEGIN TRANSACTION, COMMIT, GETDATE()
-- ===================================================================
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

-- ===================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Line Range: Approx 243-265
-- Parameters: @MinPrice, @MaxPrice
-- Schema Objects: Products, RankedProducts (CTE)
-- T-SQL Features: CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN
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
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Line Range: Approx 273-301
-- Parameters: @Threshold
-- Schema Objects: Products, StockAnalysis (CTE)
-- T-SQL Features: CTE, Multiple Window Functions (AVG, MIN, MAX OVER)
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
-- END OF EXTRACTION CATALOG
-- ===================================================================
