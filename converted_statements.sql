-- ===================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Migration from SQL Server to PostgreSQL
-- Total Statements: 7
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE (DMS tool encountered errors)
-- ===================================================================

-- ===================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Location: ProductRepository.cs, Lines 38-68
-- Description: CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE expressions
-- Parameters: None
-- Conversion Notes: 
-- - Window functions compatible with PostgreSQL
-- - ROUND function syntax identical
-- - String literals use single quotes (compatible)
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
-- Location: ProductRepository.cs, Lines 82-110
-- Description: CTE with LAG window function, LEFT JOIN, parameterized query
-- Parameters: @ProductId → $1 (PostgreSQL positional parameter)
-- Conversion Notes:
-- - LAG window function compatible with PostgreSQL
-- - Changed @ProductId to $1 for PostgreSQL parameter syntax
-- - ROUND function syntax identical
-- ===================================================================
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

-- ===================================================================
-- STATEMENT 3: InsertProductAsync
-- Location: ProductRepository.cs, Lines 124-150
-- Description: Multi-statement transaction block with INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE()
-- Parameters: @Name → $1, @Description → $2, @Price → $3, @StockQuantity → $4
-- Conversion Notes:
-- - Removed DECLARE statement (PostgreSQL uses DO blocks or functions for variables)
-- - Changed SCOPE_IDENTITY() to RETURNING clause in INSERT
-- - Changed GETDATE() to CURRENT_TIMESTAMP
-- - Converted to DO block with variable support
-- - Parameters changed from @Name style to $1, $2, $3, $4 style
-- ===================================================================
DO $$
DECLARE v_NewProductId INT;
BEGIN
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES ($1, $2, $3, $4)
    RETURNING ProductId INTO v_NewProductId;
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (v_NewProductId, 'INSERT', NULL, $3, NULL, $4, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + $3) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- Return the new product ID (handled separately in application code via RETURNING clause)

-- ===================================================================
-- STATEMENT 4: UpdateProductAsync
-- Location: ProductRepository.cs, Lines 161-195
-- Description: Multi-statement transaction with DECLARE variables, SELECT INTO, UPDATE, INSERT
-- Parameters: @ProductId → $1, @Name → $2, @Description → $3, @Price → $4, @StockQuantity → $5
-- Conversion Notes:
-- - Converted to DO block for variable declarations
-- - Changed SELECT variable assignment to SELECT INTO
-- - Changed GETDATE() to CURRENT_TIMESTAMP
-- - Changed DECIMAL(18,2) to NUMERIC(18,2) (PostgreSQL standard)
-- ===================================================================
DO $$
DECLARE 
    v_OldPrice NUMERIC(18,2);
    v_OldStock INT;
BEGIN
    -- Store old values for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = $1;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = $2,
        Description = $3,
        Price = $4,
        StockQuantity = $5,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = $1;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'UPDATE', v_OldPrice, $4, v_OldStock, $5, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - v_OldPrice + $4) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ===================================================================
-- STATEMENT 5: DeleteProductAsync
-- Location: ProductRepository.cs, Lines 206-236
-- Description: Multi-statement transaction with DECLARE, SELECT INTO, INSERT, DELETE, UPDATE with CASE
-- Parameters: @ProductId → $1
-- Conversion Notes:
-- - Converted to DO block for variable declarations
-- - Changed SELECT variable assignment to SELECT INTO
-- - Changed GETDATE() to CURRENT_TIMESTAMP
-- - CASE expression syntax identical in PostgreSQL
-- ===================================================================
DO $$
DECLARE 
    v_OldPrice NUMERIC(18,2);
    v_OldStock INT;
BEGIN
    -- Store product info for history
    SELECT Price, StockQuantity INTO v_OldPrice, v_OldStock
    FROM Products
    WHERE ProductId = $1;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES ($1, 'DELETE', v_OldPrice, NULL, v_OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = $1;
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - v_OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
END $$;

-- ===================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Location: ProductRepository.cs, Lines 245-271
-- Description: CTE with RANK() and PERCENT_RANK() window functions, parameterized BETWEEN
-- Parameters: @MinPrice → $1, @MaxPrice → $2
-- Conversion Notes:
-- - RANK() and PERCENT_RANK() window functions compatible with PostgreSQL
-- - Changed parameters from @MinPrice, @MaxPrice to $1, $2
-- - All other syntax identical
-- ===================================================================
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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
-- Location: ProductRepository.cs, Lines 285-313
-- Description: CTE with AVG/MIN/MAX OVER window functions, CASE expressions
-- Parameters: @Threshold → $1
-- Conversion Notes:
-- - AVG/MIN/MAX OVER window functions compatible with PostgreSQL
-- - Changed @Threshold to $1
-- - All other syntax identical
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

-- ===================================================================
-- END OF CONVERTED SQL STATEMENTS
-- ===================================================================
