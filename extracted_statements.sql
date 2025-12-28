-- ============================================================
-- SQL STATEMENTS EXTRACTION CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Date: 2024-12-28
-- Source: ProductRepository.cs
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 39-69
-- Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Description: Complex CTE with AVG() OVER() and COUNT() OVER() window functions
-- ============================================================
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

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 80-109
-- Type: SELECT with CTE and LAG Window Function
-- Parameters: @ProductId (int)
-- Description: CTE with LAG() OVER() window function to track historical changes
-- ============================================================
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

-- ============================================================
-- STATEMENT 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 118-143
-- Type: Multi-statement Transaction (INSERT with SCOPE_IDENTITY, GETDATE)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Description: Transaction with INSERT, SCOPE_IDENTITY(), GETDATE(), and ProductHistory logging
-- ============================================================
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

-- ============================================================
-- STATEMENT 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 159-191
-- Type: Multi-statement Transaction (UPDATE with GETDATE)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Description: Transaction with UPDATE, history logging, and statistics update
-- ============================================================
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

-- ============================================================
-- STATEMENT 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 203-232
-- Type: Multi-statement Transaction (DELETE with GETDATE)
-- Parameters: @ProductId
-- Description: Transaction with DELETE, history logging, and statistics update
-- ============================================================
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

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 243-269
-- Type: SELECT with CTE, RANK() and PERCENT_RANK() Window Functions
-- Parameters: @MinPrice, @MaxPrice
-- Description: CTE with RANK() and PERCENT_RANK() window functions for price segmentation
-- ============================================================
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

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Lines: 284-313
-- Type: SELECT with CTE, AVG(), MIN(), MAX() Window Functions
-- Parameters: @Threshold
-- Description: CTE with AVG(), MIN(), MAX() window functions for stock analysis
-- ============================================================
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

-- ============================================================
-- SUMMARY
-- ============================================================
-- Total Statements: 7
-- - Complex SELECTs with CTEs and Window Functions: 4
-- - Multi-statement Transactions: 3
-- - Window Functions Used: AVG() OVER(), COUNT() OVER(), LAG() OVER(), 
--                          RANK(), PERCENT_RANK(), MIN() OVER(), MAX() OVER()
-- - SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION
-- - Parameters: Named parameters with @ prefix
-- ============================================================
