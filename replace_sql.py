import re

# Read the file
with open('/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs', 'r') as f:
    content = f.read()

# Statement 1: GetAllProductsAsync - just add semicolon
content = content.replace(
    '                    p.Name";',
    '                    p.Name;";'
)

# Statement 2: GetProductByIdAsync - just add semicolon
content = content.replace(
    '                WHERE p.ProductId = @ProductId";',
    '                WHERE p.ProductId = @ProductId;";'
)

# Statement 3: InsertProductAsync - complete replacement
old_insert = '''DECLARE @NewProductId INT;
                
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
                
                SELECT @NewProductId;'''

new_insert = '''WITH inserted_product AS (
                    INSERT INTO Products (Name, Description, Price, StockQuantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING ProductId, Price, StockQuantity
                ),
                history_insert AS (
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    SELECT ProductId, 'INSERT', NULL, Price, NULL, StockQuantity, CURRENT_TIMESTAMP
                    FROM inserted_product
                    RETURNING ProductId
                ),
                stats_update AS (
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts + 1,
                        AveragePrice = (AveragePrice * TotalProducts + (SELECT Price FROM inserted_product)) / (TotalProducts + 1),
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1
                    RETURNING StatId
                )
                SELECT ProductId FROM inserted_product;'''

content = content.replace(old_insert, new_insert)

# Statement 4: UpdateProductAsync - complete replacement
old_update = '''BEGIN TRANSACTION;
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
                COMMIT;'''

new_update = '''WITH old_values AS (
                    SELECT Price as OldPrice, StockQuantity as OldStock
                    FROM Products
                    WHERE ProductId = @ProductId
                ),
                product_update AS (
                    UPDATE Products
                    SET 
                        Name = @Name,
                        Description = @Description,
                        Price = @Price,
                        StockQuantity = @StockQuantity,
                        ModifiedDate = CURRENT_TIMESTAMP
                    WHERE ProductId = @ProductId
                    RETURNING ProductId, Price, StockQuantity
                ),
                history_insert AS (
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    SELECT @ProductId, 'UPDATE', ov.OldPrice, pu.Price, ov.OldStock, pu.StockQuantity, CURRENT_TIMESTAMP
                    FROM product_update pu, old_values ov
                    RETURNING ProductId
                ),
                stats_update AS (
                    UPDATE ProductStats
                    SET 
                        AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1
                    RETURNING StatId
                )
                SELECT 1;'''

content = content.replace(old_update, new_update)

# Statement 5: DeleteProductAsync - complete replacement
old_delete = '''BEGIN TRANSACTION;
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
                COMMIT;'''

new_delete = '''WITH old_values AS (
                    SELECT Price as OldPrice, StockQuantity as OldStock
                    FROM Products
                    WHERE ProductId = @ProductId
                ),
                history_insert AS (
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
                    FROM old_values
                    RETURNING ProductId
                ),
                product_delete AS (
                    DELETE FROM Products 
                    WHERE ProductId = @ProductId
                    RETURNING ProductId
                ),
                stats_update AS (
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts - 1,
                        AveragePrice = CASE 
                            WHEN TotalProducts > 1 
                            THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)
                            ELSE 0
                        END,
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1
                    RETURNING StatId
                )
                SELECT 1;'''

content = content.replace(old_delete, new_delete)

# Statement 6: GetProductsByPriceRangeAsync - just add semicolon
content = content.replace(
    '                ORDER BY rp.PriceRank";',
    '                ORDER BY rp.PriceRank;";'
)

# Statement 7: GetLowStockProductsAsync - just add semicolon  
content = content.replace(
    '                ORDER BY StockQuantity";',
    '                ORDER BY StockQuantity;";'
)

# Write back
with open('/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs', 'w') as f:
    f.write(content)

print("Successfully replaced all 7 SQL statements with PostgreSQL versions")
