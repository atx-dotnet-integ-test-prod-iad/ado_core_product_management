-- ==================================================================================
-- EXTRACTED SQL STATEMENTS FROM MICROSOFT SQL SERVER TO POSTGRESQL MIGRATION
-- ==================================================================================
-- This file contains all SQL statements extracted from the codebase for conversion
-- Each statement is documented with metadata about its source location
-- ==================================================================================

-- ==================================================================================
-- STATEMENT 1: GetAllProductsAsync - CTE with Window Functions
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetAllProductsAsync()
-- Line Number: ~41-67
-- Statement Type: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER)
-- Parameterized: No
-- Description: Retrieves all products with average price comparison using window functions
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductByIdAsync(int productId)
-- Line Number: ~80-106
-- Statement Type: SELECT with CTE, LAG Window Function
-- Parameterized: Yes (@ProductId)
-- Description: Retrieves product by ID with historical price comparison using LAG
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 3: InsertProductAsync - Transaction with SCOPE_IDENTITY() and GETDATE()
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: InsertProductAsync(Product product)
-- Line Number: ~120-143
-- Statement Type: INSERT within TRANSACTION, Uses SCOPE_IDENTITY() and GETDATE()
-- Parameterized: Yes (@Name, @Description, @Price, @StockQuantity)
-- Description: Inserts new product and logs to history with transaction
-- Special Notes: Uses SQL Server specific SCOPE_IDENTITY() and GETDATE() functions
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations and GETDATE()
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: UpdateProductAsync(Product product)
-- Line Number: ~157-184
-- Statement Type: UPDATE within TRANSACTION, Uses GETDATE()
-- Parameterized: Yes (@ProductId, @Name, @Description, @Price, @StockQuantity)
-- Description: Updates product and logs changes to history with transaction
-- Special Notes: Uses SQL Server specific GETDATE() function, declares variables
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction with GETDATE()
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: DeleteProductAsync(int productId)
-- Line Number: ~198-227
-- Statement Type: DELETE within TRANSACTION, Uses GETDATE()
-- Parameterized: Yes (@ProductId)
-- Description: Deletes product and logs to history with transaction
-- Special Notes: Uses SQL Server specific GETDATE() function
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK() and PERCENT_RANK()
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Number: ~233-254
-- Statement Type: SELECT with CTE, RANK() and PERCENT_RANK() Window Functions
-- Parameterized: Yes (@MinPrice, @MaxPrice)
-- Description: Retrieves products in price range with ranking
-- ==================================================================================

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

-- ==================================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Window Functions
-- ==================================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method Name: GetLowStockProductsAsync(int threshold)
-- Line Number: ~272-297
-- Statement Type: SELECT with CTE, Window Functions (AVG, MIN, MAX OVER)
-- Parameterized: Yes (@Threshold)
-- Description: Retrieves low stock products with stock analysis
-- ==================================================================================

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

-- ==================================================================================
-- EXTRACTION SUMMARY
-- ==================================================================================
-- Total Statements Extracted: 7
-- Files Processed: 1 (DataAccess/ProductRepository.cs)
-- Statement Types:
--   - SELECT with CTE: 4
--   - INSERT with TRANSACTION: 1
--   - UPDATE with TRANSACTION: 1
--   - DELETE with TRANSACTION: 1
-- SQL Server Specific Functions Identified:
--   - SCOPE_IDENTITY() (1 occurrence)
--   - GETDATE() (7 occurrences)
-- Window Functions Used:
--   - AVG() OVER()
--   - COUNT() OVER()
--   - LAG() OVER()
--   - RANK() OVER()
--   - PERCENT_RANK() OVER()
--   - MIN() OVER()
--   - MAX() OVER()
-- Parameterized Statements: 6 out of 7
-- ==================================================================================
