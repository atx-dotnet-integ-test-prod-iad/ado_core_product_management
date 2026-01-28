using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Npgsql;
using Microsoft.Extensions.Configuration;
using AdoCore.Models;

namespace AdoCore.DataAccess
{
    public class ProductRepository : IAsyncDisposable
    {
        private readonly string _connectionString;
        private NpgsqlConnection _connection;
        private readonly IConfiguration _configuration;

        public ProductRepository(IConfiguration configuration)
        {
            _configuration = configuration;
            var environment = _configuration["Environment"];
            var connectionName = environment == "Production" ? "ProdConnection" : "DevConnection";
            
            // Check for environment variables first, then fall back to configuration
            var host = Environment.GetEnvironmentVariable("DB_HOST") ?? _configuration["PostgreSQL:Host"];
            var port = Environment.GetEnvironmentVariable("DB_PORT") ?? _configuration["PostgreSQL:Port"];
            var database = Environment.GetEnvironmentVariable("DB_NAME") ?? _configuration["PostgreSQL:Database"];
            var username = Environment.GetEnvironmentVariable("DB_USER") ?? _configuration["PostgreSQL:Username"];
            var password = Environment.GetEnvironmentVariable("DB_PASSWORD");
            
            // Build connection string from environment variables if password is provided
            if (!string.IsNullOrEmpty(password))
            {
                _connectionString = $"Host={host};Port={port};Database={database};Username={username};Password={password}";
            }
            else
            {
                // Fall back to connection string from appsettings.json
                _connectionString = _configuration.GetConnectionString(connectionName);
                
                // Warn if using default/placeholder credentials
                if (_connectionString.Contains("CHANGEME") || _connectionString.Contains("postgres;Password=postgres"))
                {
                    Console.WriteLine("WARNING: Using default or placeholder credentials. Set DB_PASSWORD environment variable for secure operation.");
                }
            }
        }

        private async Task<NpgsqlConnection> GetConnectionAsync()
        {
            if (_connection == null)
            {
                _connection = new NpgsqlConnection(_connectionString);
            }
            if (_connection.State != ConnectionState.Open)
            {
                await _connection.OpenAsync();
            }
            return _connection;
        }

        public async Task<List<Product>> GetAllProductsAsync()
        {
            var products = new List<Product>();
            var connection = await GetConnectionAsync();

            const string sql = @"
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
                    p.Name";

            using var command = new NpgsqlCommand(sql, connection);
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                products.Add(MapProductFromReader(reader));
            }

            return products;
        }

        public async Task<Product> GetProductByIdAsync(int productId)
        {
            var connection = await GetConnectionAsync();

            const string sql = @"
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
                WHERE p.ProductId = $1";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue(productId);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return MapProductFromReader(reader);
            }

            return null;
        }

        public async Task<int> InsertProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Insert the new product and get the ID using RETURNING
                const string insertSql = @"
                    INSERT INTO Products (Name, Description, Price, StockQuantity)
                    VALUES ($1, $2, $3, $4)
                    RETURNING ProductId";

                int newProductId;
                using (var command = new NpgsqlCommand(insertSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.Name);
                    command.Parameters.AddWithValue((object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue(product.Price);
                    command.Parameters.AddWithValue(product.StockQuantity);
                    
                    newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());
                }

                // Log the insertion
                const string historySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP)";

                using (var command = new NpgsqlCommand(historySql, connection, transaction))
                {
                    command.Parameters.AddWithValue(newProductId);
                    command.Parameters.AddWithValue(product.Price);
                    command.Parameters.AddWithValue(product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string statsSql = @"
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts + 1,
                        AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1";

                using (var command = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.Price);
                    
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
        }

        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();

            try
            {
                // Store old values for history
                decimal oldPrice;
                int oldStock;
                
                const string selectSql = @"
                    SELECT Price, StockQuantity
                    FROM Products
                    WHERE ProductId = $1";

                using (var command = new NpgsqlCommand(selectSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.ProductId);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {product.ProductId} not found");
                    }
                }

                // Update the product
                const string updateSql = @"
                    UPDATE Products
                    SET 
                        Name = $1,
                        Description = $2,
                        Price = $3,
                        StockQuantity = $4,
                        ModifiedDate = CURRENT_TIMESTAMP
                    WHERE ProductId = $5";

                using (var command = new NpgsqlCommand(updateSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.Name);
                    command.Parameters.AddWithValue((object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue(product.Price);
                    command.Parameters.AddWithValue(product.StockQuantity);
                    command.Parameters.AddWithValue(product.ProductId);
                    
                    await command.ExecuteNonQueryAsync();
                }

                // Log the changes
                const string historySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES ($1, 'UPDATE', $2, $3, $4, $5, CURRENT_TIMESTAMP)";

                using (var command = new NpgsqlCommand(historySql, connection, transaction))
                {
                    command.Parameters.AddWithValue(product.ProductId);
                    command.Parameters.AddWithValue(oldPrice);
                    command.Parameters.AddWithValue(product.Price);
                    command.Parameters.AddWithValue(oldStock);
                    command.Parameters.AddWithValue(product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string statsSql = @"
                    UPDATE ProductStats
                    SET 
                        AveragePrice = (AveragePrice * TotalProducts - $1 + $2) / TotalProducts,
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1";

                using (var command = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(oldPrice);
                    command.Parameters.AddWithValue(product.Price);
                    
                    await command.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();

            try
            {
                // Store product info for history
                decimal oldPrice;
                int oldStock;
                
                const string selectSql = @"
                    SELECT Price, StockQuantity
                    FROM Products
                    WHERE ProductId = $1";

                using (var command = new NpgsqlCommand(selectSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(productId);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {productId} not found");
                    }
                }

                // Log the deletion
                const string historySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP)";

                using (var command = new NpgsqlCommand(historySql, connection, transaction))
                {
                    command.Parameters.AddWithValue(productId);
                    command.Parameters.AddWithValue(oldPrice);
                    command.Parameters.AddWithValue(oldStock);
                    
                    await command.ExecuteNonQueryAsync();
                }

                // Delete the product
                const string deleteSql = @"
                    DELETE FROM Products 
                    WHERE ProductId = $1";

                using (var command = new NpgsqlCommand(deleteSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(productId);
                    
                    await command.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string statsSql = @"
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts - 1,
                        AveragePrice = CASE 
                            WHEN TotalProducts > 1 
                            THEN (AveragePrice * TotalProducts - $1) / (TotalProducts - 1)
                            ELSE 0
                        END,
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1";

                using (var command = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    command.Parameters.AddWithValue(oldPrice);
                    
                    await command.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<List<Product>> GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
        {
            var products = new List<Product>();
            var connection = await GetConnectionAsync();

            const string sql = @"
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
                ORDER BY rp.PriceRank";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue(minPrice);
            command.Parameters.AddWithValue(maxPrice);

            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                products.Add(MapProductFromReader(reader));
            }

            return products;
        }

        public async Task<List<Product>> GetLowStockProductsAsync(int threshold)
        {
            var products = new List<Product>();
            var connection = await GetConnectionAsync();

            const string sql = @"
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
                ORDER BY StockQuantity";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue(threshold);

            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                products.Add(MapProductFromReader(reader));
            }

            return products;
        }

        public async Task ExecuteInTransactionAsync(Func<Task> action)
        {
            var connection = await GetConnectionAsync();
            using var transaction = await connection.BeginTransactionAsync();
            try
            {
                await action();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        private static Product MapProductFromReader(NpgsqlDataReader reader)
        {
            return new Product
            {
                ProductId = Convert.ToInt32(reader["ProductId"]),
                Name = reader["Name"].ToString(),
                Description = reader["Description"] == DBNull.Value ? null : reader["Description"].ToString(),
                Price = Convert.ToDecimal(reader["Price"]),
                StockQuantity = Convert.ToInt32(reader["StockQuantity"]),
                CreatedDate = Convert.ToDateTime(reader["CreatedDate"]),
                ModifiedDate = reader["ModifiedDate"] == DBNull.Value ? null : (DateTime?)Convert.ToDateTime(reader["ModifiedDate"])
            };
        }

        public async ValueTask DisposeAsync()
        {
            if (_connection != null)
            {
                if (_connection.State == ConnectionState.Open)
                {
                    await _connection.CloseAsync();
                }
                await _connection.DisposeAsync();
                _connection = null;
            }
        }
    }
}
