#!/usr/bin/env python3
"""
Fix ProductRepository.cs to use proper PostgreSQL syntax with code-level transaction management.
Replaces SQL Server specific syntax (DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), etc.)
with PostgreSQL-compatible code.
"""

import re

def fix_insert_method(content):
    """Fix InsertProductAsync method to use RETURNING clause and code-level transactions"""
    
    insert_pattern = r'(        public async Task<int> InsertProductAsync\(Product product\)\r?\n        \{\r?\n            var connection = await GetConnectionAsync\(\);\r?\n\r?\n            const string sql = @")\r?\n                DECLARE @NewProductId INT;\r?\n                \r?\n                BEGIN TRANSACTION;[\s\S]*?SELECT @NewProductId;";(\r?\n\r?\n            using var command = new NpgsqlCommand\(sql, connection\);[\s\S]*?return Convert\.ToInt32\(await command\.ExecuteScalarAsync\(\)\);\r?\n        \})'
    
    insert_replacement = r'''        public async Task<int> InsertProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Insert the new product and get the ID using RETURNING clause
                const string insertSql = @"
                    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid;";

                int newProductId;
                using (var insertCommand = new NpgsqlCommand(insertSql, connection, transaction))
                {
                    insertCommand.Parameters.AddWithValue("@Name", product.Name);
                    insertCommand.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@Price", product.Price);
                    insertCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    newProductId = Convert.ToInt32(await insertCommand.ExecuteScalarAsync());
                }

                // Log the insertion
                const string logSql = @"
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);";

                using (var logCommand = new NpgsqlCommand(logSql, connection, transaction))
                {
                    logCommand.Parameters.AddWithValue("@NewProductId", newProductId);
                    logCommand.Parameters.AddWithValue("@Price", product.Price);
                    logCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await logCommand.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1;";

                using (var statsCommand = new NpgsqlCommand(updateStatsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@Price", product.Price);
                    
                    await statsCommand.ExecuteNonQueryAsync();
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
    
    content = re.sub(insert_pattern, insert_replacement, content, flags=re.MULTILINE | re.DOTALL)
    return content

def fix_update_method(content):
    """Fix UpdateProductAsync method to use code-level transactions"""
    
    update_pattern = r'(        public async Task UpdateProductAsync\(Product product\)\r?\n        \{\r?\n            var connection = await GetConnectionAsync\(\);\r?\n\r?\n            const string sql = @")\r?\n                BEGIN TRANSACTION;[\s\S]*?COMMIT;";(\r?\n\r?\n            using var command = new NpgsqlCommand\(sql, connection\);[\s\S]*?await command\.ExecuteNonQueryAsync\(\);\r?\n        \})'
    
    update_replacement = r'''        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Get old values for history
                const string getOldValuesSql = @"
                    SELECT price, stockquantity
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId;";

                decimal oldPrice;
                int oldStock;
                using (var getValuesCommand = new NpgsqlCommand(getOldValuesSql, connection, transaction))
                {
                    getValuesCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    
                    using var reader = await getValuesCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {product.ProductId} not found.");
                    }
                }

                // Update the product
                const string updateSql = @"
                    UPDATE productmanagement_dbo.products
                    SET name = @Name, 
                        description = @Description, 
                        price = @Price, 
                        stockquantity = @StockQuantity, 
                        modifieddate = CURRENT_TIMESTAMP
                    WHERE productid = @ProductId;";

                using (var updateCommand = new NpgsqlCommand(updateSql, connection, transaction))
                {
                    updateCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    updateCommand.Parameters.AddWithValue("@Name", product.Name);
                    updateCommand.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    updateCommand.Parameters.AddWithValue("@Price", product.Price);
                    updateCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await updateCommand.ExecuteNonQueryAsync();
                }

                // Log the changes
                const string logSql = @"
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);";

                using (var logCommand = new NpgsqlCommand(logSql, connection, transaction))
                {
                    logCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    logCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    logCommand.Parameters.AddWithValue("@Price", product.Price);
                    logCommand.Parameters.AddWithValue("@OldStock", oldStock);
                    logCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await logCommand.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE productmanagement_dbo.productstats
                    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, 
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1;";

                using (var statsCommand = new NpgsqlCommand(updateStatsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    statsCommand.Parameters.AddWithValue("@Price", product.Price);
                    
                    await statsCommand.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }'''
    
    content = re.sub(update_pattern, update_replacement, content, flags=re.MULTILINE | re.DOTALL)
    return content

def fix_delete_method(content):
    """Fix DeleteProductAsync method to use code-level transactions"""
    
    delete_pattern = r'(        public async Task DeleteProductAsync\(int productId\)\r?\n        \{\r?\n            var connection = await GetConnectionAsync\(\);\r?\n\r?\n            const string sql = @")\r?\n                BEGIN TRANSACTION;[\s\S]*?COMMIT;";(\r?\n\r?\n            using var command = new NpgsqlCommand\(sql, connection\);[\s\S]*?await command\.ExecuteNonQueryAsync\(\);\r?\n        \})'
    
    delete_replacement = r'''        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Get old values for history
                const string getOldValuesSql = @"
                    SELECT price, stockquantity
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId;";

                decimal oldPrice;
                int oldStock;
                using (var getValuesCommand = new NpgsqlCommand(getOldValuesSql, connection, transaction))
                {
                    getValuesCommand.Parameters.AddWithValue("@ProductId", productId);
                    
                    using var reader = await getValuesCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {productId} not found.");
                    }
                }

                // Log the deletion
                const string logSql = @"
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);";

                using (var logCommand = new NpgsqlCommand(logSql, connection, transaction))
                {
                    logCommand.Parameters.AddWithValue("@ProductId", productId);
                    logCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    logCommand.Parameters.AddWithValue("@OldStock", oldStock);
                    
                    await logCommand.ExecuteNonQueryAsync();
                }

                // Delete the product
                const string deleteSql = @"
                    DELETE FROM productmanagement_dbo.products
                    WHERE productid = @ProductId;";

                using (var deleteCommand = new NpgsqlCommand(deleteSql, connection, transaction))
                {
                    deleteCommand.Parameters.AddWithValue("@ProductId", productId);
                    
                    await deleteCommand.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE productmanagement_dbo.productstats
                    SET totalproducts = totalproducts - 1, 
                        averageprice = CASE
                            WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                            ELSE 0
                        END, 
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1;";

                using (var statsCommand = new NpgsqlCommand(updateStatsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    
                    await statsCommand.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }'''
    
    content = re.sub(delete_pattern, delete_replacement, content, flags=re.MULTILINE | re.DOTALL)
    return content

def main():
    # Read the original file
    with open('ProductRepository.cs', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Apply fixes
    print("Fixing InsertProductAsync...")
    content = fix_insert_method(content)
    
    print("Fixing UpdateProductAsync...")
    content = fix_update_method(content)
    
    print("Fixing DeleteProductAsync...")
    content = fix_delete_method(content)
    
    # Write the fixed content
    with open('ProductRepository.cs', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("ProductRepository.cs has been updated with PostgreSQL-compatible code.")

if __name__ == '__main__':
    main()
