/*******************************************************************************
 * SQL STATEMENT EXTRACTION CATALOG
 * Microsoft SQL Server to PostgreSQL Migration
 * 
 * This file contains all SQL statements extracted from the .NET ADO application
 * for systematic conversion to PostgreSQL using the DMS MCP tool.
 * 
 * Total Statement Groups: 7
 * Source File: DataAccess/ProductRepository.cs
 * Date: 2026-01-30
 *******************************************************************************/

/*******************************************************************************
 * STATEMENT GROUP 1: GetAllProductsAsync
 * Source File: DataAccess/ProductRepository.cs
 * Line Numbers: 38-67
 * Method: GetAllProductsAsync()
 * Description: Complex query with CTE, AVG OVER window function, COUNT OVER, 
 *              CASE expressions, and computed columns
 * Construction Pattern: Direct string constant (const string sql)
 * Parameters: None
 *******************************************************************************/
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

/*******************************************************************************
 * STATEMENT GROUP 2: GetProductByIdAsync
 * Source File: DataAccess/ProductRepository.cs
 * Line Numbers: 81-109
 * Method: GetProductByIdAsync(int productId)
 * Description: Complex query with CTE, LAG OVER window function, LEFT JOIN,
 *              and computed price change percentage
 * Construction Pattern: Direct string constant (const string sql)
 * Parameters: @ProductId (int)
 *******************************************************************************/
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

/*******************************************************************************
 * STATEMENT GROUP 3: InsertProductAsync
 * Source File: DataAccess/ProductRepository.cs
 * Line Numbers: 123-150
 * Method: InsertProductAsync(Product product)
 * Description: Multi-statement transaction block with INSERT, SCOPE_IDENTITY(),
 *              history logging, and statistics update
 * Construction Pattern: Direct string constant (const string sql)
 * Parameters: @Name (string), @Description (string/null), @Price (decimal), 
 *             @StockQuantity (int)
 * Special Considerations: SCOPE_IDENTITY() requires conversion to PostgreSQL
 *                        RETURNING clause pattern
 *******************************************************************************/
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

/*******************************************************************************
 * STATEMENT GROUP 4: UpdateProductAsync
 * Source File: DataAccess/ProductRepository.cs
 * Line Numbers: 165-196
 * Method: UpdateProductAsync(Product product)
 * Description: Multi-statement transaction block with variable declarations,
 *              SELECT to store old values, UPDATE, INSERT for history logging,
 *              and statistics update
 * Construction Pattern: Direct string constant (const string sql)
 * Parameters: @ProductId (int), @Name (string), @Description (string/null), 
 *             @Price (decimal), @StockQuantity (int)
 * Special Considerations: GETDATE() requires conversion to PostgreSQL NOW() or
 *                        CURRENT_TIMESTAMP
 *******************************************************************************/
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

/*******************************************************************************
 * STATEMENT GROUP 5: DeleteProductAsync
 * Source File: DataAccess/ProductRepository.cs
 * Line Numbers: 210-243
 * Method: DeleteProductAsync(int productId)
 * Description: Multi-statement transaction block with variable declarations,
 *              SELECT to store values, INSERT for history, DELETE, and
 *              UPDATE with conditional CASE expression
 * Construction Pattern: Direct string constant (const string sql)
 * Parameters: @ProductId (int)
 * Special Considerations: GETDATE() requires conversion, conditional CASE
 *                        expression in UPDATE
 *******************************************************************************/
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

/*******************************************************************************
 * STATEMENT GROUP 6: GetProductsByPriceRangeAsync
 * Source File: DataAccess/ProductRepository.cs
 * Line Numbers: 257-284
 * Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
 * Description: Complex query with CTE, RANK() window function, PERCENT_RANK()
 *              window function, and CASE expression for segmentation
 * Construction Pattern: Direct string constant (const string sql)
 * Parameters: @MinPrice (decimal), @MaxPrice (decimal)
 *******************************************************************************/
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

/*******************************************************************************
 * STATEMENT GROUP 7: GetLowStockProductsAsync
 * Source File: DataAccess/ProductRepository.cs
 * Line Numbers: 298-327
 * Method: GetLowStockProductsAsync(int threshold)
 * Description: Complex query with CTE, multiple aggregate window functions
 *              (AVG OVER, MIN OVER, MAX OVER), CASE expression for status
 *              determination, and computed columns
 * Construction Pattern: Direct string constant (const string sql)
 * Parameters: @Threshold (int)
 *******************************************************************************/
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

/*******************************************************************************
 * END OF SQL STATEMENT EXTRACTION CATALOG
 * 
 * Summary:
 * - Total Statement Groups: 7
 * - Statements with CTEs: 5 (Groups 1, 2, 6, 7, and implicit in 3, 4, 5)
 * - Statements with Window Functions: 4 (Groups 1, 2, 6, 7)
 * - Transaction Blocks: 3 (Groups 3, 4, 5)
 * - Parameterized Statements: 5 (Groups 2, 3, 4, 5, 6, 7)
 * 
 * Key Conversion Considerations:
 * - SCOPE_IDENTITY() → PostgreSQL RETURNING clause pattern
 * - GETDATE() → PostgreSQL NOW() or CURRENT_TIMESTAMP
 * - BEGIN TRANSACTION/COMMIT → PostgreSQL BEGIN/COMMIT
 * - Window functions should translate but verify syntax
 * - DECLARE statements → PostgreSQL variable syntax
 * - Parameter syntax (@param) should remain compatible with Npgsql
 *******************************************************************************/
