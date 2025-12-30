-- ===============================================
-- SQL Statement Extraction Catalog
-- ADO.NET Application Migration from SQL Server to PostgreSQL
-- Total Statements: 7
-- ===============================================

-- ===============================================
-- Statement 1: GetAllProductsAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: 38-69
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: None
-- Description: Retrieves all products with price statistics using Common Table Expression (CTE) 
--              and window functions (AVG OVER, COUNT OVER). Includes calculated fields for 
--              price category and percentage of average.
-- ===============================================
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

-- ===============================================
-- Statement 2: GetProductByIdAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: 83-108
-- Statement Type: SELECT with CTE and LAG Window Function
-- Parameters: @ProductId (int)
-- Description: Retrieves a single product by ID with historical price information using 
--              CTE and LAG window function to access previous price and stock values.
--              Calculates price change percentage.
-- ===============================================
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

-- ===============================================
-- Statement 3: InsertProductAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: 121-142
-- Statement Type: Multi-Statement Transaction (INSERT with SCOPE_IDENTITY)
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Inserts a new product within a transaction. Uses SCOPE_IDENTITY() to get 
--              the new product ID, logs the insertion to ProductHistory, and updates 
--              ProductStats. Uses GETDATE() for timestamps.
-- ===============================================
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

-- ===============================================
-- Statement 4: UpdateProductAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: 155-181
-- Statement Type: Multi-Statement Transaction (UPDATE with variable declarations)
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: Updates a product within a transaction. Stores old values in variables,
--              updates the product, logs the changes to ProductHistory, and updates 
--              ProductStats. Uses GETDATE() for timestamps.
-- ===============================================
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

-- ===============================================
-- Statement 5: DeleteProductAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: 194-222
-- Statement Type: Multi-Statement Transaction (DELETE with variable declarations)
-- Parameters: @ProductId (int)
-- Description: Deletes a product within a transaction. Stores old values in variables,
--              logs the deletion to ProductHistory, deletes the product, and updates 
--              ProductStats with a CASE statement for handling the last product deletion.
--              Uses GETDATE() for timestamps.
-- ===============================================
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

-- ===============================================
-- Statement 6: GetProductsByPriceRangeAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 235-257
-- Statement Type: SELECT with CTE, RANK and PERCENT_RANK Window Functions
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: Retrieves products within a price range with ranking information using
--              RANK() and PERCENT_RANK() window functions. Includes calculated price 
--              segment based on percentile.
-- ===============================================
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

-- ===============================================
-- Statement 7: GetLowStockProductsAsync
-- File: sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 270-291
-- Statement Type: SELECT with CTE and Multiple Window Functions (AVG, MIN, MAX)
-- Parameters: @Threshold (int)
-- Description: Retrieves low stock products using CTE with multiple window functions
--              (AVG, MIN, MAX OVER). Includes calculated stock status and percentage
--              of average stock. Filters by threshold.
-- ===============================================
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

-- ===============================================
-- END OF EXTRACTION CATALOG
-- Total Statements Extracted: 7
-- ===============================================
