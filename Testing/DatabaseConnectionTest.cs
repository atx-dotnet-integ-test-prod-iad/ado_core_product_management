using System;
using System.Threading.Tasks;
using Npgsql;
using Microsoft.Extensions.Configuration;

namespace AdoCore.Testing
{
    /// <summary>
    /// Database connection verification utility for PostgreSQL
    /// Tests connectivity and basic database operations
    /// </summary>
    public class DatabaseConnectionTest
    {
        private readonly IConfiguration _configuration;
        
        public DatabaseConnectionTest(IConfiguration configuration)
        {
            _configuration = configuration;
        }
        
        public async Task<bool> TestConnectionAsync()
        {
            Console.WriteLine("=== PostgreSQL Database Connection Test ===\n");
            
            var environment = _configuration["Environment"];
            var connectionName = environment == "Production" ? "ProdConnection" : "DevConnection";
            var connectionString = _configuration.GetConnectionString(connectionName);
            
            Console.WriteLine($"Environment: {environment}");
            Console.WriteLine($"Connection Name: {connectionName}");
            Console.WriteLine($"Connection String: {MaskPassword(connectionString)}\n");
            
            try
            {
                // Test 1: Basic Connection
                Console.WriteLine("Test 1: Testing basic connection...");
                using (var connection = new NpgsqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    Console.WriteLine($"✓ Connection successful! State: {connection.State}");
                    Console.WriteLine($"  PostgreSQL Version: {connection.PostgreSqlVersion}");
                    Console.WriteLine($"  Server: {connection.Host}:{connection.Port}");
                    Console.WriteLine($"  Database: {connection.Database}\n");
                }
                
                // Test 2: Query Execution
                Console.WriteLine("Test 2: Testing query execution...");
                using (var connection = new NpgsqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    
                    const string testQuery = "SELECT current_database(), current_user, version()";
                    using var command = new NpgsqlCommand(testQuery, connection);
                    using var reader = await command.ExecuteReaderAsync();
                    
                    if (await reader.ReadAsync())
                    {
                        Console.WriteLine($"✓ Query execution successful!");
                        Console.WriteLine($"  Current Database: {reader.GetString(0)}");
                        Console.WriteLine($"  Current User: {reader.GetString(1)}");
                        Console.WriteLine($"  Version: {reader.GetString(2).Split('\n')[0]}\n");
                    }
                }
                
                // Test 3: Check Required Tables
                Console.WriteLine("Test 3: Checking required tables...");
                using (var connection = new NpgsqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    
                    var requiredTables = new[] { "products", "producthistory", "productstats" };
                    foreach (var tableName in requiredTables)
                    {
                        const string checkTableQuery = @"
                            SELECT EXISTS (
                                SELECT FROM information_schema.tables 
                                WHERE table_schema = 'public' 
                                AND table_name = @tableName
                            )";
                        
                        using var command = new NpgsqlCommand(checkTableQuery, connection);
                        command.Parameters.AddWithValue("@tableName", tableName);
                        
                        var exists = (bool)await command.ExecuteScalarAsync();
                        var status = exists ? "✓" : "✗";
                        Console.WriteLine($"  {status} Table '{tableName}': {(exists ? "EXISTS" : "NOT FOUND")}");
                    }
                    Console.WriteLine();
                }
                
                // Test 4: Count Products
                Console.WriteLine("Test 4: Counting products...");
                using (var connection = new NpgsqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    
                    const string countQuery = "SELECT COUNT(*) FROM products";
                    using var command = new NpgsqlCommand(countQuery, connection);
                    
                    try
                    {
                        var count = Convert.ToInt32(await command.ExecuteScalarAsync());
                        Console.WriteLine($"✓ Products table accessible: {count} products found\n");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"✗ Failed to count products: {ex.Message}\n");
                        return false;
                    }
                }
                
                // Test 5: Transaction Test
                Console.WriteLine("Test 5: Testing transaction handling...");
                using (var connection = new NpgsqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    using var transaction = await connection.BeginTransactionAsync();
                    
                    try
                    {
                        const string testInsert = @"
                            INSERT INTO products (name, description, price, stockquantity)
                            VALUES (@Name, @Description, @Price, @StockQuantity)
                            RETURNING productid";
                        
                        using var command = new NpgsqlCommand(testInsert, connection, transaction);
                        command.Parameters.AddWithValue("@Name", "TEST_PRODUCT_DO_NOT_USE");
                        command.Parameters.AddWithValue("@Description", "Connection test product");
                        command.Parameters.AddWithValue("@Price", 0.01m);
                        command.Parameters.AddWithValue("@StockQuantity", 0);
                        
                        var testId = Convert.ToInt32(await command.ExecuteScalarAsync());
                        Console.WriteLine($"✓ Transaction test successful (test ID: {testId})");
                        Console.WriteLine($"  Rolling back transaction...");
                        
                        await transaction.RollbackAsync();
                        Console.WriteLine($"✓ Rollback successful (test data removed)\n");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"✗ Transaction test failed: {ex.Message}\n");
                        await transaction.RollbackAsync();
                        return false;
                    }
                }
                
                Console.WriteLine("=== All Tests Passed! ===\n");
                Console.WriteLine("Database connection is working correctly.");
                Console.WriteLine("The application is ready to use PostgreSQL.\n");
                
                return true;
            }
            catch (NpgsqlException ex)
            {
                Console.WriteLine($"✗ PostgreSQL Error: {ex.Message}");
                Console.WriteLine($"  Error Code: {ex.SqlState}");
                Console.WriteLine($"\nPossible issues:");
                Console.WriteLine("  - PostgreSQL server is not running");
                Console.WriteLine("  - Connection string is incorrect");
                Console.WriteLine("  - Database 'ProductManagement' does not exist");
                Console.WriteLine("  - User credentials are invalid");
                Console.WriteLine("  - Firewall is blocking the connection\n");
                return false;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"✗ Unexpected Error: {ex.Message}");
                Console.WriteLine($"  Type: {ex.GetType().Name}\n");
                return false;
            }
        }
        
        private static string MaskPassword(string connectionString)
        {
            if (string.IsNullOrEmpty(connectionString))
                return connectionString;
                
            var parts = connectionString.Split(';');
            var maskedParts = new string[parts.Length];
            
            for (int i = 0; i < parts.Length; i++)
            {
                var part = parts[i].Trim();
                if (part.StartsWith("Password=", StringComparison.OrdinalIgnoreCase))
                {
                    maskedParts[i] = "Password=********";
                }
                else
                {
                    maskedParts[i] = part;
                }
            }
            
            return string.Join("; ", maskedParts);
        }
    }
}
