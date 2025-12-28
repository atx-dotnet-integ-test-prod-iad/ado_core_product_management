-- ============================================================================
-- SQL STATEMENT EXTRACTION CATALOG
-- Purpose: Complete inventory of all SQL statements from ADO.NET application
-- Source Repository: AdoCore
-- Extraction Date: 2024
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1 of 7
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Line Numbers: Approximately 37-67
-- Statement Type: Complex CTE with Window Functions and CASE expressions
-- Parameterized: No
-- Transaction Block: No
-- Tables Referenced: Products
-- Window Functions: AVG() OVER(), COUNT() OVER()
-- Special Features: Common Table Expression (CTE), INNER JOIN, CASE expressions
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 2 of 7
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Line Numbers: Approximately 82-106
-- Statement Type: CTE with LAG Window Function and LEFT JOIN
-- Parameterized: Yes (@ProductId)
-- Transaction Block: No
-- Tables Referenced: Products
-- Window Functions: LAG() OVER (ORDER BY ModifiedDate)
-- Special Features: Common Table Expression (CTE), LEFT JOIN, CASE expression
-- Parameters: @ProductId (int)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 3 of 7
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Line Numbers: Approximately 121-145
-- Statement Type: Multi-statement Transaction with INSERT, SET, SCOPE_IDENTITY(), UPDATE
-- Parameterized: Yes (@Name, @Description, @Price, @StockQuantity)
-- Transaction Block: Yes (BEGIN TRANSACTION/COMMIT)
-- Tables Referenced: Products, ProductHistory, ProductStats
-- Special Features: Transaction block, SCOPE_IDENTITY(), GETDATE(), variable declaration
-- Parameters: @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 4 of 7
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Line Numbers: Approximately 157-185
-- Statement Type: Multi-statement Transaction with DECLARE, SELECT into variables, UPDATE, INSERT
-- Parameterized: Yes (@ProductId, @Name, @Description, @Price, @StockQuantity)
-- Transaction Block: Yes (BEGIN TRANSACTION/COMMIT)
-- Tables Referenced: Products, ProductHistory, ProductStats
-- Special Features: Transaction block, variable declaration, SELECT into variables, GETDATE()
-- Parameters: @ProductId (int), @Name (string), @Description (string, nullable), @Price (decimal), @StockQuantity (int)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 5 of 7
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Line Numbers: Approximately 194-222
-- Statement Type: Multi-statement Transaction with DECLARE, SELECT into variables, INSERT, DELETE, UPDATE with CASE
-- Parameterized: Yes (@ProductId)
-- Transaction Block: Yes (BEGIN TRANSACTION/COMMIT)
-- Tables Referenced: Products, ProductHistory, ProductStats
-- Special Features: Transaction block, variable declaration, SELECT into variables, GETDATE(), CASE expression
-- Parameters: @ProductId (int)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 6 of 7
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: Approximately 227-250
-- Statement Type: CTE with RANK() and PERCENT_RANK() Window Functions
-- Parameterized: Yes (@MinPrice, @MaxPrice)
-- Transaction Block: No
-- Tables Referenced: Products
-- Window Functions: RANK() OVER (ORDER BY), PERCENT_RANK() OVER (ORDER BY)
-- Special Features: Common Table Expression (CTE), CASE expression, BETWEEN clause
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 7 of 7
-- ============================================================================
-- Source File: /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: Approximately 255-280
-- Statement Type: CTE with Multiple Window Functions (AVG, MIN, MAX) and CASE
-- Parameterized: Yes (@Threshold)
-- Transaction Block: No
-- Tables Referenced: Products
-- Window Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
-- Special Features: Common Table Expression (CTE), CASE expression, multiple window functions
-- Parameters: @Threshold (int)
-- ============================================================================

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

-- ============================================================================
-- END OF EXTRACTION CATALOG
-- ============================================================================
-- Summary Statistics:
-- Total Statements Extracted: 7
-- Statements with Parameters: 5 (Statements 2, 3, 4, 5, 6, 7)
-- Statements without Parameters: 2 (Statement 1)
-- Transaction Blocks: 3 (Statements 3, 4, 5)
-- CTE Statements: 5 (Statements 1, 2, 6, 7)
-- Window Functions Used: AVG OVER, COUNT OVER, LAG OVER, RANK OVER, PERCENT_RANK OVER, MIN OVER, MAX OVER
-- Tables Referenced: Products (all), ProductHistory (3, 4, 5), ProductStats (3, 4, 5)
-- ============================================================================
