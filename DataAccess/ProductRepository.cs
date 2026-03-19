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
                WHERE p.ProductId = @ProductId";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@ProductId", productId);

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

            // Step 1: Insert the product and return the new ID via RETURNING clause.
            const string insertSql = @"
                INSERT INTO Products (Name, Description, Price, StockQuantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING ProductId";

            // Step 2: Log the insertion into ProductHistory.
            const string historySql = @"
                INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW())";

            // Step 3: Update running product statistics.
            const string statsSql = @"
                UPDATE ProductStats
                SET 
                    TotalProducts = TotalProducts + 1,
                    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                    LastUpdated = NOW()
                WHERE StatId = 1";

            int newProductId;

            using (var insertCmd = new NpgsqlCommand(insertSql, connection))
            {
                insertCmd.Parameters.AddWithValue("@Name", product.Name);
                insertCmd.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                insertCmd.Parameters.AddWithValue("@Price", product.Price);
                insertCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                newProductId = Convert.ToInt32(await insertCmd.ExecuteScalarAsync());
            }

            using (var historyCmd = new NpgsqlCommand(historySql, connection))
            {
                historyCmd.Parameters.AddWithValue("@ProductId", newProductId);
                historyCmd.Parameters.AddWithValue("@Price", product.Price);
                historyCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                await historyCmd.ExecuteNonQueryAsync();
            }

            using (var statsCmd = new NpgsqlCommand(statsSql, connection))
            {
                statsCmd.Parameters.AddWithValue("@Price", product.Price);
                await statsCmd.ExecuteNonQueryAsync();
            }

            return newProductId;
        }

        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();

            // Step 1: Update the product row.
            const string updateSql = @"
                UPDATE Products
                SET 
                    Name = @Name,
                    Description = @Description,
                    Price = @Price,
                    StockQuantity = @StockQuantity,
                    ModifiedDate = NOW()
                WHERE ProductId = @ProductId";

            // Step 2: Log the changes to ProductHistory.
            const string historySql = @"
                INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW())";

            // Step 3: Refresh product statistics.
            const string statsSql = @"
                UPDATE ProductStats
                SET 
                    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
                    LastUpdated = NOW()
                WHERE StatId = 1";

            // Read old values before issuing the UPDATE so they can be passed to history/stats.
            decimal oldPrice;
            int oldStock;

            const string selectOldSql = @"
                SELECT Price, StockQuantity
                FROM Products
                WHERE ProductId = @ProductId";

            using (var selectCmd = new NpgsqlCommand(selectOldSql, connection))
            {
                selectCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                using var oldReader = await selectCmd.ExecuteReaderAsync();
                if (!await oldReader.ReadAsync())
                    return; // product not found – nothing to update
                oldPrice = Convert.ToDecimal(oldReader["Price"]);
                oldStock = Convert.ToInt32(oldReader["StockQuantity"]);
            }

            using (var updateCmd = new NpgsqlCommand(updateSql, connection))
            {
                updateCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                updateCmd.Parameters.AddWithValue("@Name", product.Name);
                updateCmd.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                updateCmd.Parameters.AddWithValue("@Price", product.Price);
                updateCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                await updateCmd.ExecuteNonQueryAsync();
            }

            using (var historyCmd = new NpgsqlCommand(historySql, connection))
            {
                historyCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                historyCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                historyCmd.Parameters.AddWithValue("@Price", product.Price);
                historyCmd.Parameters.AddWithValue("@OldStock", oldStock);
                historyCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                await historyCmd.ExecuteNonQueryAsync();
            }

            using (var statsCmd = new NpgsqlCommand(statsSql, connection))
            {
                statsCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                statsCmd.Parameters.AddWithValue("@Price", product.Price);
                await statsCmd.ExecuteNonQueryAsync();
            }
        }

        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();

            // Step 1: Use a data-modifying CTE to delete the product and capture its
            // old values in a single atomic statement, then write the history record.
            const string deleteAndHistorySql = @"
                WITH deleted AS (
                    DELETE FROM Products
                    WHERE ProductId = @ProductId
                    RETURNING ProductId, Price AS OldPrice, StockQuantity AS OldStock
                )
                INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                SELECT ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, NOW()
                FROM deleted";

            // Step 2: Refresh product statistics.
            const string statsSql = @"
                UPDATE ProductStats
                SET 
                    TotalProducts = TotalProducts - 1,
                    AveragePrice = CASE 
                        WHEN TotalProducts > 1 
                        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
                        ELSE 0
                    END,
                    LastUpdated = NOW()
                WHERE StatId = 1";

            // Read old price before deletion so we can update statistics.
            decimal oldPrice;

            const string selectOldSql = @"
                SELECT Price
                FROM Products
                WHERE ProductId = @ProductId";

            using (var selectCmd = new NpgsqlCommand(selectOldSql, connection))
            {
                selectCmd.Parameters.AddWithValue("@ProductId", productId);
                var result = await selectCmd.ExecuteScalarAsync();
                if (result == null || result == DBNull.Value)
                    return; // product not found – nothing to delete
                oldPrice = Convert.ToDecimal(result);
            }

            using (var deleteCmd = new NpgsqlCommand(deleteAndHistorySql, connection))
            {
                deleteCmd.Parameters.AddWithValue("@ProductId", productId);
                await deleteCmd.ExecuteNonQueryAsync();
            }

            using (var statsCmd = new NpgsqlCommand(statsSql, connection))
            {
                statsCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                await statsCmd.ExecuteNonQueryAsync();
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
                ORDER BY rp.PriceRank";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@MinPrice", minPrice);
            command.Parameters.AddWithValue("@MaxPrice", maxPrice);

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
                        WHEN StockQuantity <= @Threshold THEN 'Critical'
                        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END as StockStatus,
                    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
                FROM StockAnalysis sa
                WHERE StockQuantity <= @Threshold
                ORDER BY StockQuantity";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@Threshold", threshold);

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
