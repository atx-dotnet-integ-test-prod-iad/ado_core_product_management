-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source Application: AdoCore (.NET ADO.NET Application)
-- Source Database: Microsoft SQL Server
-- Target Database: PostgreSQL
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync()
-- Description: CTE with ProductStats, window functions (AVG OVER, COUNT OVER),
--              CASE expressions, ROUND, INNER JOIN, ORDER BY with CASE
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
                    p.Name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync(int productId)
-- Description: CTE with ProductHistory, LAG window function, CASE expression,
--              LEFT JOIN, parameterized WHERE clause
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
                WHERE p.ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync(Product product)
-- Description: Transaction block with DECLARE, INSERT INTO Products,
--              SCOPE_IDENTITY(), INSERT INTO ProductHistory,
--              UPDATE ProductStats, GETDATE()
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
-- STATEMENT 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync(Product product)
-- Description: Transaction block with DECLARE, SELECT INTO variables,
--              UPDATE Products with GETDATE(), INSERT INTO ProductHistory,
--              UPDATE ProductStats
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
-- STATEMENT 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync(int productId)
-- Description: Transaction block with DECLARE, SELECT INTO variables,
--              INSERT INTO ProductHistory, DELETE FROM Products,
--              UPDATE ProductStats with CASE
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
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Description: CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN,
--              CASE expression
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
                ORDER BY rp.PriceRank;

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync(int threshold)
-- Description: CTE with AVG/MIN/MAX window functions, CASE expression,
--              ROUND, parameterized WHERE
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
                ORDER BY StockQuantity;

-- ============================================================================
-- REFERENCE: DDL Statements from Scripts/01_InitialSetup.sql
-- These are database setup scripts, not application SQL statements
-- ============================================================================
-- Contains: CREATE DATABASE, CREATE TABLE Products, stored procedures
-- (sp_GetAllProducts, sp_GetProductById, sp_InsertProduct, sp_UpdateProduct, sp_DeleteProduct)
-- and sample data inserts

-- ============================================================================
-- REFERENCE: DDL Statements from Database/Scripts/01_InitialSetup.sql
-- These are database setup scripts, not application SQL statements
-- ============================================================================
-- Contains: CREATE DATABASE, CREATE TABLE (Categories, Suppliers, Products, ProductHistory, ProductStats)
-- CREATE INDEX, sample data inserts, CREATE TRIGGER trg_Products_History
-- Stored procedures: sp_GetAllProducts, sp_GetProductById, sp_InsertProduct, sp_UpdateProduct, sp_DeleteProduct
