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
                    FROM public.products
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
                    ROUND(CAST((p.Price / ps.AvgPrice) * 100 AS numeric), 2) as PricePercentageOfAverage
                FROM public.products p
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
                    FROM public.products
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
                FROM public.products p
                LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
                WHERE p.ProductId = $1";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("ProductId", productId);

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

            const string sqlInsertProduct = @"
                INSERT INTO public.products (Name, Description, Price, StockQuantity)
                VALUES ($1, $2, $3, $4)
                RETURNING ProductId";

            const string sqlInsertHistory = @"
                INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                VALUES ($1, 'INSERT', NULL, $2, NULL, $3, NOW())";

            const string sqlUpdateStats = @"
                UPDATE public.productstats
                SET 
                    TotalProducts = TotalProducts + 1,
                    AveragePrice = (AveragePrice * TotalProducts + $1) / (TotalProducts + 1),
                    LastUpdated = NOW()
                WHERE StatId = 1";

            await using var transaction = await connection.BeginTransactionAsync();
            try
            {
                int newProductId;

                using (var cmdInsert = new NpgsqlCommand(sqlInsertProduct, connection))
                {
                    cmdInsert.Transaction = (NpgsqlTransaction)transaction;
                    cmdInsert.Parameters.AddWithValue("Name", product.Name);
                    cmdInsert.Parameters.AddWithValue("Description", (object)product.Description ?? DBNull.Value);
                    cmdInsert.Parameters.AddWithValue("Price", product.Price);
                    cmdInsert.Parameters.AddWithValue("StockQuantity", product.StockQuantity);
                    newProductId = Convert.ToInt32(await cmdInsert.ExecuteScalarAsync());
                }

                using (var cmdHistory = new NpgsqlCommand(sqlInsertHistory, connection))
                {
                    cmdHistory.Transaction = (NpgsqlTransaction)transaction;
                    cmdHistory.Parameters.AddWithValue("ProductId", newProductId);
                    cmdHistory.Parameters.AddWithValue("NewPrice", product.Price);
                    cmdHistory.Parameters.AddWithValue("NewStock", product.StockQuantity);
                    await cmdHistory.ExecuteNonQueryAsync();
                }

                using (var cmdStats = new NpgsqlCommand(sqlUpdateStats, connection))
                {
                    cmdStats.Transaction = (NpgsqlTransaction)transaction;
                    cmdStats.Parameters.AddWithValue("Price", product.Price);
                    await cmdStats.ExecuteNonQueryAsync();
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

            const string sqlSelectOld = @"
                SELECT Price, StockQuantity
                FROM public.products
                WHERE ProductId = $1";

            const string sqlUpdate = @"
                UPDATE public.products
                SET 
                    Name = $1,
                    Description = $2,
                    Price = $3,
                    StockQuantity = $4,
                    ModifiedDate = NOW()
                WHERE ProductId = $5";

            const string sqlInsertHistory = @"
                INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                VALUES ($1, 'UPDATE', $2, $3, $4, $5, NOW())";

            const string sqlUpdateStats = @"
                UPDATE public.productstats
                SET 
                    AveragePrice = (AveragePrice * TotalProducts - $1 + $2) / TotalProducts,
                    LastUpdated = NOW()
                WHERE StatId = 1";

            await using var transaction = await connection.BeginTransactionAsync();
            try
            {
                decimal oldPrice;
                int oldStock;

                using (var cmdSelect = new NpgsqlCommand(sqlSelectOld, connection))
                {
                    cmdSelect.Transaction = (NpgsqlTransaction)transaction;
                    cmdSelect.Parameters.AddWithValue("ProductId", product.ProductId);
                    using var reader = await cmdSelect.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                        throw new InvalidOperationException($"Product {product.ProductId} not found.");
                    oldPrice = Convert.ToDecimal(reader["Price"]);
                    oldStock = Convert.ToInt32(reader["StockQuantity"]);
                }

                using (var cmdUpdate = new NpgsqlCommand(sqlUpdate, connection))
                {
                    cmdUpdate.Transaction = (NpgsqlTransaction)transaction;
                    cmdUpdate.Parameters.AddWithValue("Name", product.Name);
                    cmdUpdate.Parameters.AddWithValue("Description", (object)product.Description ?? DBNull.Value);
                    cmdUpdate.Parameters.AddWithValue("Price", product.Price);
                    cmdUpdate.Parameters.AddWithValue("StockQuantity", product.StockQuantity);
                    cmdUpdate.Parameters.AddWithValue("ProductId", product.ProductId);
                    await cmdUpdate.ExecuteNonQueryAsync();
                }

                using (var cmdHistory = new NpgsqlCommand(sqlInsertHistory, connection))
                {
                    cmdHistory.Transaction = (NpgsqlTransaction)transaction;
                    cmdHistory.Parameters.AddWithValue("ProductId", product.ProductId);
                    cmdHistory.Parameters.AddWithValue("OldPrice", oldPrice);
                    cmdHistory.Parameters.AddWithValue("NewPrice", product.Price);
                    cmdHistory.Parameters.AddWithValue("OldStock", oldStock);
                    cmdHistory.Parameters.AddWithValue("NewStock", product.StockQuantity);
                    await cmdHistory.ExecuteNonQueryAsync();
                }

                using (var cmdStats = new NpgsqlCommand(sqlUpdateStats, connection))
                {
                    cmdStats.Transaction = (NpgsqlTransaction)transaction;
                    cmdStats.Parameters.AddWithValue("OldPrice", oldPrice);
                    cmdStats.Parameters.AddWithValue("NewPrice", product.Price);
                    await cmdStats.ExecuteNonQueryAsync();
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

            const string sqlSelectOld = @"
                SELECT Price, StockQuantity
                FROM public.products
                WHERE ProductId = $1";

            const string sqlInsertHistory = @"
                INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                VALUES ($1, 'DELETE', $2, NULL, $3, NULL, NOW())";

            const string sqlDelete = @"
                DELETE FROM public.products
                WHERE ProductId = $1";

            const string sqlUpdateStats = @"
                UPDATE public.productstats
                SET 
                    TotalProducts = TotalProducts - 1,
                    AveragePrice = CASE 
                        WHEN TotalProducts > 1 
                        THEN (AveragePrice * TotalProducts - $1) / (TotalProducts - 1)
                        ELSE 0
                    END,
                    LastUpdated = NOW()
                WHERE StatId = 1";

            await using var transaction = await connection.BeginTransactionAsync();
            try
            {
                decimal oldPrice;
                int oldStock;

                using (var cmdSelect = new NpgsqlCommand(sqlSelectOld, connection))
                {
                    cmdSelect.Transaction = (NpgsqlTransaction)transaction;
                    cmdSelect.Parameters.AddWithValue("ProductId", productId);
                    using var reader = await cmdSelect.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                        throw new InvalidOperationException($"Product {productId} not found.");
                    oldPrice = Convert.ToDecimal(reader["Price"]);
                    oldStock = Convert.ToInt32(reader["StockQuantity"]);
                }

                using (var cmdHistory = new NpgsqlCommand(sqlInsertHistory, connection))
                {
                    cmdHistory.Transaction = (NpgsqlTransaction)transaction;
                    cmdHistory.Parameters.AddWithValue("ProductId", productId);
                    cmdHistory.Parameters.AddWithValue("OldPrice", oldPrice);
                    cmdHistory.Parameters.AddWithValue("OldStock", oldStock);
                    await cmdHistory.ExecuteNonQueryAsync();
                }

                using (var cmdDelete = new NpgsqlCommand(sqlDelete, connection))
                {
                    cmdDelete.Transaction = (NpgsqlTransaction)transaction;
                    cmdDelete.Parameters.AddWithValue("ProductId", productId);
                    await cmdDelete.ExecuteNonQueryAsync();
                }

                using (var cmdStats = new NpgsqlCommand(sqlUpdateStats, connection))
                {
                    cmdStats.Transaction = (NpgsqlTransaction)transaction;
                    cmdStats.Parameters.AddWithValue("OldPrice", oldPrice);
                    await cmdStats.ExecuteNonQueryAsync();
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
                    FROM public.products p
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
            command.Parameters.AddWithValue("MinPrice", minPrice);
            command.Parameters.AddWithValue("MaxPrice", maxPrice);

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
                    FROM public.products p
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
            command.Parameters.AddWithValue("Threshold", threshold);

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
