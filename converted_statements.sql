-- ============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL
-- Source File: ProductRepository.cs
-- Total Statements: 7
-- Conversion Date: Microsoft SQL Server to PostgreSQL Migration
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - CONVERTED
-- Original Method: GetAllProductsAsync()
-- Conversion: Manual (DMS Tool Failed)
-- Changes Applied:
--   - Table names converted to lowercase: Products -> products
--   - Column names converted to lowercase
--   - Window functions (AVG OVER, COUNT OVER) are PostgreSQL compatible
--   - CASE expressions are PostgreSQL compatible
--   - ROUND function is PostgreSQL compatible
-- ============================================================================
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CONVERTED
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion: Manual (DMS Tool Failed)
-- Changes Applied:
--   - Table names converted to lowercase: Products -> products
--   - Column names converted to lowercase
--   - LAG window function is PostgreSQL compatible
--   - Parameter syntax @ProductId remains same in PostgreSQL
--   - CASE and ROUND functions are PostgreSQL compatible
-- ============================================================================
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - CONVERTED
-- Original Method: InsertProductAsync(Product product)
-- Conversion: Manual (DMS Tool Failed)
-- Changes Applied:
--   - Table names converted to lowercase: Products -> products
--   - Column names converted to lowercase
--   - Replaced DECLARE @NewProductId INT with PostgreSQL variable syntax
--   - Removed BEGIN TRANSACTION/COMMIT (will be handled at ADO.NET level)
--   - Replaced SCOPE_IDENTITY() with RETURNING clause on INSERT
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Combined into DO block for transaction handling
-- PostgreSQL Note: This will be refactored to use RETURNING in INSERT
-- ============================================================================
DO $$
DECLARE 
    v_newproductid INTEGER;
BEGIN
    -- Insert the new product
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product id
    PERFORM v_newproductid;
END $$;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - CONVERTED
-- Original Method: UpdateProductAsync(Product product)
-- Conversion: Manual (DMS Tool Failed)
-- Changes Applied:
--   - Table names converted to lowercase: Products -> products
--   - Column names converted to lowercase
--   - Removed BEGIN TRANSACTION/COMMIT (handled at ADO.NET level)
--   - Replaced DECLARE syntax with PostgreSQL variable syntax
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - Combined into DO block for transaction handling
-- ============================================================================
DO $$
DECLARE 
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity
    INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - CONVERTED
-- Original Method: DeleteProductAsync(int productId)
-- Conversion: Manual (DMS Tool Failed)
-- Changes Applied:
--   - Table names converted to lowercase: Products -> products
--   - Column names converted to lowercase
--   - Removed BEGIN TRANSACTION/COMMIT (handled at ADO.NET level)
--   - Replaced DECLARE syntax with PostgreSQL variable syntax
--   - Replaced GETDATE() with CURRENT_TIMESTAMP
--   - CASE expression is PostgreSQL compatible
--   - Combined into DO block for transaction handling
-- ============================================================================
DO $$
DECLARE 
    v_oldprice NUMERIC(18,2);
    v_oldstock INTEGER;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity
    INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CONVERTED
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: Manual (DMS Tool Failed)
-- Changes Applied:
--   - Table names converted to lowercase: Products -> products
--   - Column names converted to lowercase
--   - RANK() and PERCENT_RANK() window functions are PostgreSQL compatible
--   - CASE expression is PostgreSQL compatible
--   - Parameter syntax @MinPrice, @MaxPrice remains same in PostgreSQL
-- ============================================================================
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CONVERTED
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion: Manual (DMS Tool Failed)
-- Changes Applied:
--   - Table names converted to lowercase: Products -> products
--   - Column names converted to lowercase
--   - Window functions (AVG OVER, MIN OVER, MAX OVER) are PostgreSQL compatible
--   - CASE expression is PostgreSQL compatible
--   - ROUND function is PostgreSQL compatible
--   - Parameter syntax @Threshold remains same in PostgreSQL
-- ============================================================================
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- ============================================================================
