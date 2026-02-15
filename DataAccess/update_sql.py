#!/usr/bin/env python3
import re

# Read the file
with open('ProductRepository.cs', 'r') as f:
    content = f.read()

# Statement 3: InsertProductAsync - Replace SCOPE_IDENTITY with RETURNING
old_insert = r'DECLARE @NewProductId INT;\r\n                \r\n                BEGIN TRANSACTION;\r\n                    -- Insert the new product\r\n                    INSERT INTO Products \(Name, Description, Price, StockQuantity\)\r\n                    VALUES \(@Name, @Description, @Price, @StockQuantity\);\r\n                    \r\n                    SET @NewProductId = SCOPE_IDENTITY\(\);\r\n                    \r\n                    -- Log the insertion\r\n                    INSERT INTO ProductHistory \(ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate\)\r\n                    VALUES \(@NewProductId, \'INSERT\', NULL, @Price, NULL, @StockQuantity, GETDATE\(\)\);\r\n                    \r\n                    -- Update product statistics\r\n                    UPDATE ProductStats\r\n                    SET \r\n                        TotalProducts = TotalProducts \+ 1,\r\n                        AveragePrice = \(AveragePrice \* TotalProducts \+ @Price\) / \(TotalProducts \+ 1\),\r\n                        LastUpdated = GETDATE\(\)\r\n                    WHERE StatId = 1;\r\n                COMMIT;\r\n                \r\n                SELECT @NewProductId;'

new_insert = r'''WITH inserted_product AS (\r
                    INSERT INTO Products (Name, Description, Price, StockQuantity)\r
                    VALUES (@Name, @Description, @Price, @StockQuantity)\r
                    RETURNING ProductId\r
                ),\r
                logged_history AS (\r
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)\r
                    SELECT ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP\r
                    FROM inserted_product\r
                    RETURNING ProductId\r
                ),\r
                updated_stats AS (\r
                    UPDATE ProductStats\r
                    SET \r
                        TotalProducts = TotalProducts + 1,\r
                        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),\r
                        LastUpdated = CURRENT_TIMESTAMP\r
                    WHERE StatId = 1\r
                    RETURNING StatId\r
                )\r
                SELECT ProductId FROM inserted_product;'''

content = re.sub(old_insert, new_insert, content)

# Statement 4: UpdateProductAsync - Replace BEGIN TRANSACTION with WITH clauses
old_update = r'BEGIN TRANSACTION;\r\n                    -- Store old values for history\r\n                    DECLARE @OldPrice DECIMAL\(18,2\);\r\n                    DECLARE @OldStock INT;\r\n                    \r\n                    SELECT @OldPrice = Price, @OldStock = StockQuantity\r\n                    FROM Products\r\n                    WHERE ProductId = @ProductId;\r\n                    \r\n                    -- Update the product\r\n                    UPDATE Products\r\n                    SET \r\n                        Name = @Name,\r\n                        Description = @Description,\r\n                        Price = @Price,\r\n                        StockQuantity = @StockQuantity,\r\n                        ModifiedDate = GETDATE\(\)\r\n                    WHERE ProductId = @ProductId;\r\n                    \r\n                    -- Log the changes\r\n                    INSERT INTO ProductHistory \(ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate\)\r\n                    VALUES \(@ProductId, \'UPDATE\', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE\(\)\);\r\n                    \r\n                    -- Update product statistics\r\n                    UPDATE ProductStats\r\n                    SET \r\n                        AveragePrice = \(AveragePrice \* TotalProducts - @OldPrice \+ @Price\) / TotalProducts,\r\n                        LastUpdated = GETDATE\(\)\r\n                    WHERE StatId = 1;\r\n                COMMIT;'

new_update = r'''WITH old_values AS (\r
                    SELECT Price as OldPrice, StockQuantity as OldStock\r
                    FROM Products\r
                    WHERE ProductId = @ProductId\r
                ),\r
                updated_product AS (\r
                    UPDATE Products\r
                    SET \r
                        Name = @Name,\r
                        Description = @Description,\r
                        Price = @Price,\r
                        StockQuantity = @StockQuantity,\r
                        ModifiedDate = CURRENT_TIMESTAMP\r
                    WHERE ProductId = @ProductId\r
                    RETURNING ProductId\r
                ),\r
                logged_history AS (\r
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)\r
                    SELECT @ProductId, 'UPDATE', ov.OldPrice, @Price, ov.OldStock, @StockQuantity, CURRENT_TIMESTAMP\r
                    FROM old_values ov\r
                    RETURNING ProductId\r
                )\r
                UPDATE ProductStats\r
                SET \r
                    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values) + @Price) / TotalProducts,\r
                    LastUpdated = CURRENT_TIMESTAMP\r
                WHERE StatId = 1;'''

content = re.sub(old_update, new_update, content)

# Statement 5: DeleteProductAsync - Replace BEGIN TRANSACTION with WITH clauses
old_delete = r'BEGIN TRANSACTION;\r\n                    -- Store product info for history\r\n                    DECLARE @OldPrice DECIMAL\(18,2\);\r\n                    DECLARE @OldStock INT;\r\n                    \r\n                    SELECT @OldPrice = Price, @OldStock = StockQuantity\r\n                    FROM Products\r\n                    WHERE ProductId = @ProductId;\r\n                    \r\n                    -- Log the deletion\r\n                    INSERT INTO ProductHistory \(ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate\)\r\n                    VALUES \(@ProductId, \'DELETE\', @OldPrice, NULL, @OldStock, NULL, GETDATE\(\)\);\r\n                    \r\n                    -- Delete the product\r\n                    DELETE FROM Products \r\n                    WHERE ProductId = @ProductId;\r\n                    \r\n                    -- Update product statistics\r\n                    UPDATE ProductStats\r\n                    SET \r\n                        TotalProducts = TotalProducts - 1,\r\n                        AveragePrice = CASE \r\n                            WHEN TotalProducts > 1 \r\n                            THEN \(AveragePrice \* TotalProducts - @OldPrice\) / \(TotalProducts - 1\)\r\n                            ELSE 0\r\n                        END,\r\n                        LastUpdated = GETDATE\(\)\r\n                    WHERE StatId = 1;\r\n                COMMIT;'

new_delete = r'''WITH old_values AS (\r
                    SELECT Price as OldPrice, StockQuantity as OldStock\r
                    FROM Products\r
                    WHERE ProductId = @ProductId\r
                ),\r
                logged_history AS (\r
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)\r
                    SELECT @ProductId, 'DELETE', ov.OldPrice, NULL, ov.OldStock, NULL, CURRENT_TIMESTAMP\r
                    FROM old_values ov\r
                    RETURNING ProductId\r
                ),\r
                deleted_product AS (\r
                    DELETE FROM Products \r
                    WHERE ProductId = @ProductId\r
                    RETURNING ProductId\r
                )\r
                UPDATE ProductStats\r
                SET \r
                    TotalProducts = TotalProducts - 1,\r
                    AveragePrice = CASE \r
                        WHEN TotalProducts > 1 \r
                        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM old_values)) / (TotalProducts - 1)\r
                        ELSE 0\r
                    END,\r
                    LastUpdated = CURRENT_TIMESTAMP\r
                WHERE StatId = 1;'''

content = re.sub(old_delete, new_delete, content)

# Write the updated file
with open('ProductRepository.cs', 'w') as f:
    f.write(content)

print("SQL statements updated successfully")
