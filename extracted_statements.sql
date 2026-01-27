-- ====================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: ProductRepository.cs
-- Database: Microsoft SQL Server
-- Extraction Date: 2025-01-26
-- Total Statements: 7
-- ====================================================================

-- ====================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Lines: 40-66
-- Type: SELECT with CTE
-- Parameters: None
-- Description: Retrieves all products with average price calculations and categorization
-- Window Functions: AVG() OVER(), COUNT() OVER()
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Lines: 80-110
-- Type: SELECT with CTE
-- Parameters: @ProductId (INT)
-- Description: Retrieves a single product by ID with historical price/stock comparison
-- Window Functions: LAG() OVER (ORDER BY ModifiedDate)
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 3: InsertProductAsync - Transaction with Multiple Statements
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Lines: 124-147
-- Type: TRANSACTION (INSERT statements with SCOPE_IDENTITY)
-- Parameters: @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Inserts a new product and logs to history, updates statistics
-- SQL Server Specific: SCOPE_IDENTITY(), GETDATE(), BEGIN TRANSACTION/COMMIT
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 4: UpdateProductAsync - Transaction with Variable Declarations
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Lines: 161-191
-- Type: TRANSACTION (UPDATE with variable declarations)
-- Parameters: @ProductId (INT), @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), @StockQuantity (INT)
-- Description: Updates product and logs changes to history, updates statistics
-- SQL Server Specific: DECLARE, BEGIN TRANSACTION/COMMIT, GETDATE()
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 5: DeleteProductAsync - Transaction Block with Delete
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Lines: 205-234
-- Type: TRANSACTION (DELETE with logging)
-- Parameters: @ProductId (INT)
-- Description: Deletes a product and logs to history, updates statistics
-- SQL Server Specific: DECLARE, BEGIN TRANSACTION/COMMIT, GETDATE()
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Lines: 248-271
-- Type: SELECT with CTE
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products within a price range with ranking
-- Window Functions: RANK() OVER (ORDER BY Price), PERCENT_RANK() OVER (ORDER BY Price)
-- ====================================================================

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

-- ====================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ====================================================================
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Lines: 285-311
-- Type: SELECT with CTE
-- Parameters: @Threshold (INT)
-- Description: Retrieves products with stock below threshold with stock analysis
-- Window Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
-- ====================================================================

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

-- ====================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total Statements Extracted: 7
-- ====================================================================
