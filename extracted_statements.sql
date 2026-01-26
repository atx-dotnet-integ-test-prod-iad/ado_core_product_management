-- ========================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Microsoft SQL Server to PostgreSQL Migration
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- ========================================

-- ========================================
-- STATEMENT 1: GetAllProductsAsync
-- ========================================
-- Method: GetAllProductsAsync()
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~37-70
-- Parameters: None
-- Description: Complex CTE with window functions (AVG OVER, COUNT OVER) and CASE statements for price categorization
-- Statement Type: SELECT with CTE
-- ========================================
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
    p.Name

-- ========================================
-- STATEMENT 2: GetProductByIdAsync
-- ========================================
-- Method: GetProductByIdAsync(int productId)
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~82-109
-- Parameters: @ProductId (int)
-- Description: CTE with LAG window function to track previous price and stock values
-- Statement Type: SELECT with CTE and window function
-- ========================================
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
WHERE p.ProductId = @ProductId

-- ========================================
-- STATEMENT 3: InsertProductAsync
-- ========================================
-- Method: InsertProductAsync(Product product)
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~120-145
-- Parameters: @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Description: Multi-statement transaction with SCOPE_IDENTITY() and GETDATE(), inserts product and logs history
-- Statement Type: Multi-statement transaction (INSERT with SCOPE_IDENTITY)
-- Critical Conversion Points: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT syntax
-- ========================================
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

-- ========================================
-- STATEMENT 4: UpdateProductAsync
-- ========================================
-- Method: UpdateProductAsync(Product product)
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~156-185
-- Parameters: @ProductId (int), @Name (nvarchar), @Description (nvarchar), @Price (decimal), @StockQuantity (int)
-- Description: Multi-statement transaction with variable declarations to track old values and update product
-- Statement Type: Multi-statement transaction (UPDATE with variable declarations)
-- Critical Conversion Points: Variable declarations, GETDATE(), BEGIN TRANSACTION/COMMIT syntax
-- ========================================
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

-- ========================================
-- STATEMENT 5: DeleteProductAsync
-- ========================================
-- Method: DeleteProductAsync(int productId)
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~193-224
-- Parameters: @ProductId (int)
-- Description: Multi-statement transaction with variable declarations to log deletion before removing product
-- Statement Type: Multi-statement transaction (DELETE with history logging)
-- Critical Conversion Points: Variable declarations, GETDATE(), BEGIN TRANSACTION/COMMIT syntax
-- ========================================
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

-- ========================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- ========================================
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~232-255
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: CTE with RANK() and PERCENT_RANK() window functions for price segmentation
-- Statement Type: SELECT with CTE and window functions
-- Critical Conversion Points: RANK() and PERCENT_RANK() window functions
-- ========================================
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
ORDER BY rp.PriceRank

-- ========================================
-- STATEMENT 7: GetLowStockProductsAsync
-- ========================================
-- Method: GetLowStockProductsAsync(int threshold)
-- Source File: DataAccess/ProductRepository.cs
-- Line Numbers: ~263-287
-- Parameters: @Threshold (int)
-- Description: CTE with window functions (AVG, MIN, MAX OVER) for stock analysis and categorization
-- Statement Type: SELECT with CTE and aggregate window functions
-- Critical Conversion Points: Window functions with OVER clause
-- ========================================
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
ORDER BY StockQuantity

-- ========================================
-- END OF EXTRACTED STATEMENTS
-- Total Statements Extracted: 7
-- ========================================
