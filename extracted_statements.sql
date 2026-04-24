-- =====================================================
-- Extracted SQL Statements Catalog
-- Source: AdoCore .NET Application
-- Purpose: Comprehensive catalog of all SQL statements
--          for MS SQL Server to PostgreSQL migration
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Lines: ~46-71 (within const string sql)
-- Type: SELECT with CTE, window functions (AVG OVER, COUNT OVER),
--       INNER JOIN, CASE, ROUND, ORDER BY with CASE
-- Parameters: None
-- =====================================================

-- [MSSQL_STATEMENT_1]
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
-- [END_MSSQL_STATEMENT_1]

-- =====================================================
-- Statement 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Lines: ~82-103 (within const string sql)
-- Type: SELECT with CTE, LAG() window function,
--       LEFT JOIN, CASE with NULL handling, ROUND
-- Parameters: @ProductId (int)
-- =====================================================

-- [MSSQL_STATEMENT_2]
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
-- [END_MSSQL_STATEMENT_2]

-- =====================================================
-- Statement 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Lines: ~114-135 (within const string sql)
-- Type: Transaction block with DECLARE, INSERT,
--       SCOPE_IDENTITY(), GETDATE(), UPDATE with arithmetic
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- =====================================================

-- [MSSQL_STATEMENT_3]
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
-- [END_MSSQL_STATEMENT_3]

-- =====================================================
-- Statement 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Lines: ~146-174 (within const string sql)
-- Type: Transaction block with DECLARE variables,
--       SELECT INTO variables, UPDATE, INSERT history,
--       GETDATE()
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- =====================================================

-- [MSSQL_STATEMENT_4]
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
-- [END_MSSQL_STATEMENT_4]

-- =====================================================
-- Statement 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Lines: ~185-215 (within const string sql)
-- Type: Transaction block with DECLARE variables,
--       SELECT INTO variables, INSERT history, DELETE,
--       UPDATE with CASE, GETDATE()
-- Parameters: @ProductId
-- =====================================================

-- [MSSQL_STATEMENT_5]
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
-- [END_MSSQL_STATEMENT_5]

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Lines: ~257-275 (within const string sql)
-- Type: SELECT with CTE, RANK(), PERCENT_RANK() window functions,
--       BETWEEN, CASE, ORDER BY
-- Parameters: @MinPrice, @MaxPrice
-- =====================================================

-- [MSSQL_STATEMENT_6]
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
-- [END_MSSQL_STATEMENT_6]

-- =====================================================
-- Statement 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Lines: ~297-316 (within const string sql)
-- Type: SELECT with CTE, AVG(), MIN(), MAX() window functions
--       (OVER()), CASE, ROUND, WHERE, ORDER BY
-- Parameters: @Threshold
-- =====================================================

-- [MSSQL_STATEMENT_7]
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
-- [END_MSSQL_STATEMENT_7]

-- =====================================================
-- Additional SQL Files Identified
-- =====================================================
-- File: Scripts/01_InitialSetup.sql
--   Contains: Database creation, table DDL (Products, Categories,
--             Suppliers, ProductHistory, ProductStats), stored procedures
--             (sp_GetAllProducts, sp_GetProductById, sp_InsertProduct,
--             sp_UpdateProduct, sp_DeleteProduct), triggers
--             (trg_Products_History), indexes, sample data inserts
--
-- File: Database/Scripts/01_InitialSetup.sql
--   Contains: Extended version of setup script with additional tables
--             (Categories, Suppliers), more stored procedures, triggers,
--             and comprehensive sample data
-- =====================================================
