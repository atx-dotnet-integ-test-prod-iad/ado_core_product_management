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
            _connectionString = _configuration.GetConnectionString(connectionName);
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
            command.Parameters.AddWithValue("$1", productId);

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
            int newProductId;

            // Use transaction to ensure atomicity across multiple statements
            using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Statement 1: Insert product and get the new ID using RETURNING clause
                const string insertSql = @"
                    INSERT INTO Products (Name, Description, Price, StockQuantity)
                    VALUES ($1, $2, $3, $4)
                    RETURNING ProductId;";

                using (var insertCommand = new NpgsqlCommand(insertSql, connection, transaction))
                {
                    insertCommand.Parameters.AddWithValue("$1", product.Name);
                    insertCommand.Parameters.AddWithValue("$2", (object)product.Description ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("$3", product.Price);
                    insertCommand.Parameters.AddWithValue("$4", product.StockQuantity);

                    newProductId = Convert.ToInt32(await insertCommand.ExecuteScalarAsync());
                }

                // Statement 2: Log the insertion
                const string historySql = @"
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP);";

                using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
                {
                    historyCommand.Parameters.AddWithValue("$1", newProductId);
                    historyCommand.Parameters.AddWithValue("$2", product.Price);
                    historyCommand.Parameters.AddWithValue("$3", product.StockQuantity);

                    await historyCommand.ExecuteNonQueryAsync();
                }

                // Statement 3: Update product statistics
                const string statsSql = @"
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts + 1,
                        AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
                        LastUpdated = CURRENT_TIMESTAMP
                    WHERE StatId = 1;";

                using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("$1", product.Price);

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
        }

        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();

            // Use CTE pattern for PostgreSQL - captures old values, updates product, logs history, and updates stats
            const string sql = @"
                WITH OldValues AS (
                    SELECT Price as OldPrice, StockQuantity as OldStock
                    FROM Products
                    WHERE ProductId = $1
                ),
                UpdatedProduct AS (
                    UPDATE Products
                    SET 
                        Name = $2,
                        Description = $3,
                        Price = $4,
                        StockQuantity = $5,
                        ModifiedDate = CURRENT_TIMESTAMP
                    WHERE ProductId = $1
                    RETURNING ProductId
                ),
                InsertHistory AS (
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    SELECT $1, 'UPDATE', OldValues.OldPrice, $4, OldValues.OldStock, $5, CURRENT_TIMESTAMP
                    FROM OldValues
                    RETURNING ProductId
                )
                UPDATE ProductStats
                SET 
                    AveragePrice = (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues) + $4) / TotalProducts,
                    LastUpdated = CURRENT_TIMESTAMP
                WHERE StatId = 1;";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("$1", product.ProductId);
            command.Parameters.AddWithValue("$2", product.Name);
            command.Parameters.AddWithValue("$3", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("$4", product.Price);
            command.Parameters.AddWithValue("$5", product.StockQuantity);

            await command.ExecuteNonQueryAsync();
        }

        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();

            // Use CTE pattern for PostgreSQL - captures old values, logs history, deletes product, and updates stats
            const string sql = @"
                WITH OldValues AS (
                    SELECT Price as OldPrice, StockQuantity as OldStock
                    FROM Products
                    WHERE ProductId = $1
                ),
                InsertHistory AS (
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    SELECT $1, 'DELETE', OldValues.OldPrice, NULL, OldValues.OldStock, NULL, CURRENT_TIMESTAMP
                    FROM OldValues
                    RETURNING ProductId
                ),
                DeletedProduct AS (
                    DELETE FROM Products 
                    WHERE ProductId = $1
                    RETURNING ProductId
                )
                UPDATE ProductStats
                SET 
                    TotalProducts = TotalProducts - 1,
                    AveragePrice = CASE 
                        WHEN TotalProducts > 1 
                        THEN (AveragePrice * TotalProducts - (SELECT OldPrice FROM OldValues)) / (TotalProducts - 1)
                        ELSE 0
                    END,
                    LastUpdated = CURRENT_TIMESTAMP
                WHERE StatId = 1;";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("$1", productId);

            await command.ExecuteNonQueryAsync();
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
            command.Parameters.AddWithValue("$1", minPrice);
            command.Parameters.AddWithValue("$2", maxPrice);

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
            command.Parameters.AddWithValue("$1", threshold);

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
