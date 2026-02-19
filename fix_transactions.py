#!/usr/bin/env python3
"""
Script to fix SQL Server transaction syntax in ProductRepository.cs
Replaces SQL Server-specific syntax with PostgreSQL-compatible code
"""

def fix_repository():
    file_path = '/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs'
    
    # Read the file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Fix InsertProductAsync
    old_insert = '''        public async Task<int> InsertProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();

            const string sql = @"
                DECLARE @NewProductId INT;
                
                BEGIN TRANSACTION;
                    -- Insert the new product
                    INSERT INTO Products (Name, Description, Price, StockQuantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity);
                    
                    SET @NewProductId = SCOPE_IDENTITY();
                    
                    -- Log the insertion
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
                    
                    -- Update product statistics
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts + 1,
                        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1;
                COMMIT;
                
                SELECT @NewProductId;";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            return Convert.ToInt32(await command.ExecuteScalarAsync());
        }'''
    
    new_insert = '''        public async Task<int> InsertProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Insert the new product and get the ID using RETURNING clause
                const string insertSql = @"
                    INSERT INTO Products (Name, Description, Price, StockQuantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING ProductId";

                int newProductId;
                using (var command = new NpgsqlCommand(insertSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@Name", product.Name);
                    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());
                }
                
                // Log the insertion
                const string historySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";
                
                using (var command = new NpgsqlCommand(historySql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@NewProductId", newProductId);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts + 1,
                        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1";
                
                using (var command = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@Price", product.Price);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                await transaction.CommitAsync();
                return newProductId;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }'''
    
    # Fix UpdateProductAsync
    old_update = '''        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();

            const string sql = @"
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
                        ModifiedDate = CURRENT_TIMESTAMP
                    WHERE ProductId = @ProductId;
                    
                    -- Log the changes
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);
                    
                    -- Update product statistics
                    UPDATE ProductStats
                    SET 
                        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1;
                COMMIT;";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            await command.ExecuteNonQueryAsync();
        }'''
    
    new_update = '''        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Get old values for history
                const string getOldValuesSql = @"
                    SELECT Price, StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId";
                
                decimal oldPrice;
                int oldStock;
                using (var command = new NpgsqlCommand(getOldValuesSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", product.ProductId);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                    {
                        throw new InvalidOperationException($"Product with ID {product.ProductId} not found");
                    }
                    
                    oldPrice = reader.GetDecimal(0);
                    oldStock = reader.GetInt32(1);
                }
                
                // Update the product
                const string updateSql = @"
                    UPDATE Products
                    SET 
                        Name = @Name,
                        Description = @Description,
                        Price = @Price,
                        StockQuantity = @StockQuantity,
                        ModifiedDate = CURRENT_TIMESTAMP
                    WHERE ProductId = @ProductId";
                
                using (var command = new NpgsqlCommand(updateSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", product.ProductId);
                    command.Parameters.AddWithValue("@Name", product.Name);
                    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Log the changes
                const string historySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP)";
                
                using (var command = new NpgsqlCommand(historySql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", product.ProductId);
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@OldStock", oldStock);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE ProductStats
                    SET 
                        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1";
                
                using (var command = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }'''
    
    # Fix DeleteProductAsync
    old_delete = '''        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();

            const string sql = @"
                BEGIN TRANSACTION;
                    -- Store product info for history
                    DECLARE @OldPrice DECIMAL(18,2);
                    DECLARE @OldStock INT;
                    
                    SELECT @OldPrice = Price, @OldStock = StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId;
                    
                    -- Log the deletion
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);
                    
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
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1;
                COMMIT;";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@ProductId", productId);

            await command.ExecuteNonQueryAsync();
        }'''
    
    new_delete = '''        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Get product info for history
                const string getOldValuesSql = @"
                    SELECT Price, StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId";
                
                decimal oldPrice;
                int oldStock;
                using (var command = new NpgsqlCommand(getOldValuesSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", productId);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                    {
                        throw new InvalidOperationException($"Product with ID {productId} not found");
                    }
                    
                    oldPrice = reader.GetDecimal(0);
                    oldStock = reader.GetInt32(1);
                }
                
                // Log the deletion
                const string historySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP)";
                
                using (var command = new NpgsqlCommand(historySql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", productId);
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    command.Parameters.AddWithValue("@OldStock", oldStock);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Delete the product
                const string deleteSql = @"
                    DELETE FROM Products 
                    WHERE ProductId = @ProductId";
                
                using (var command = new NpgsqlCommand(deleteSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@ProductId", productId);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts - 1,
                        AveragePrice = CASE 
                            WHEN TotalProducts > 1 
                            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
                            ELSE 0
                        END,
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1";
                
                using (var command = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }'''
    
    # Replace all three methods
    content = content.replace(old_insert, new_insert)
    content = content.replace(old_update, new_update)
    content = content.replace(old_delete, new_delete)
    
    # Write back to file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("Successfully updated ProductRepository.cs with PostgreSQL-compatible transaction handling")
    return True

if __name__ == '__main__':
    try:
        fix_repository()
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
