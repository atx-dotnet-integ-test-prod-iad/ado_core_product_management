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
                    FROM public.""Products""
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
                FROM public.""Products"" p
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
                    FROM public.""Products""
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
                FROM public.""Products"" p
                LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
                WHERE p.ProductId = $1";

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
            await using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Insert the new product and retrieve the new ID
                const string insertProductSql = @"
                    INSERT INTO public.""Products"" (""Name"", ""Description"", ""Price"", ""StockQuantity"")
                    VALUES ($1, $2, $3, $4)
                    RETURNING ""ProductId""";

                int newProductId;
                using (var insertCmd = new NpgsqlCommand(insertProductSql, connection, (NpgsqlTransaction)transaction))
                {
                    insertCmd.Parameters.AddWithValue("@Name", product.Name);
                    insertCmd.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    insertCmd.Parameters.AddWithValue("@Price", product.Price);
                    insertCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    newProductId = Convert.ToInt32(await insertCmd.ExecuteScalarAsync());
                }

                // Log the insertion
                const string insertHistorySql = @"
                    INSERT INTO public.""ProductHistory"" (""ProductId"", ""Action"", ""OldPrice"", ""NewPrice"", ""OldStock"", ""NewStock"", ""ActionDate"")
                    VALUES ($1, 'INSERT', NULL, $2, NULL, $3, NOW())";

                using (var historyCmd = new NpgsqlCommand(insertHistorySql, connection, (NpgsqlTransaction)transaction))
                {
                    historyCmd.Parameters.AddWithValue("@NewProductId", newProductId);
                    historyCmd.Parameters.AddWithValue("@Price", product.Price);
                    historyCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    await historyCmd.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE public.""ProductStats""
                    SET 
                        ""TotalProducts"" = ""TotalProducts"" + 1,
                        ""AveragePrice"" = (""AveragePrice"" * ""TotalProducts"" + $1) / (""TotalProducts"" + 1),
                        ""LastUpdated"" = NOW()
                    WHERE ""StatId"" = 1";

                using (var statsCmd = new NpgsqlCommand(updateStatsSql, connection, (NpgsqlTransaction)transaction))
                {
                    statsCmd.Parameters.AddWithValue("@Price", product.Price);
                    await statsCmd.ExecuteNonQueryAsync();
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

            // Fetch old values first
            decimal oldPrice;
            int oldStock;
            const string selectOldValuesSql = @"
                SELECT ""Price"", ""StockQuantity""
                FROM public.""Products""
                WHERE ""ProductId"" = $1";

            using (var selectCmd = new NpgsqlCommand(selectOldValuesSql, connection))
            {
                selectCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                using var selectReader = await selectCmd.ExecuteReaderAsync();
                if (!await selectReader.ReadAsync())
                    throw new InvalidOperationException($"Product with ID {product.ProductId} not found.");
                oldPrice = Convert.ToDecimal(selectReader["Price"]);
                oldStock = Convert.ToInt32(selectReader["StockQuantity"]);
            }

            await using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Update the product
                const string updateProductSql = @"
                    UPDATE public.""Products""
                    SET 
                        ""Name"" = $1,
                        ""Description"" = $2,
                        ""Price"" = $3,
                        ""StockQuantity"" = $4,
                        ""ModifiedDate"" = NOW()
                    WHERE ""ProductId"" = $5";

                using (var updateCmd = new NpgsqlCommand(updateProductSql, connection, (NpgsqlTransaction)transaction))
                {
                    updateCmd.Parameters.AddWithValue("@Name", product.Name);
                    updateCmd.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    updateCmd.Parameters.AddWithValue("@Price", product.Price);
                    updateCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    updateCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                    await updateCmd.ExecuteNonQueryAsync();
                }

                // Log the changes
                const string insertHistorySql = @"
                    INSERT INTO public.""ProductHistory"" (""ProductId"", ""Action"", ""OldPrice"", ""NewPrice"", ""OldStock"", ""NewStock"", ""ActionDate"")
                    VALUES ($1, 'UPDATE', $2, $3, $4, $5, NOW())";

                using (var historyCmd = new NpgsqlCommand(insertHistorySql, connection, (NpgsqlTransaction)transaction))
                {
                    historyCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                    historyCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                    historyCmd.Parameters.AddWithValue("@Price", product.Price);
                    historyCmd.Parameters.AddWithValue("@OldStock", oldStock);
                    historyCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    await historyCmd.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE public.""ProductStats""
                    SET 
                        ""AveragePrice"" = (""AveragePrice"" * ""TotalProducts"" - $1 + $2) / ""TotalProducts"",
                        ""LastUpdated"" = NOW()
                    WHERE ""StatId"" = 1";

                using (var statsCmd = new NpgsqlCommand(updateStatsSql, connection, (NpgsqlTransaction)transaction))
                {
                    statsCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                    statsCmd.Parameters.AddWithValue("@Price", product.Price);
                    await statsCmd.ExecuteNonQueryAsync();
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

            // Fetch old values first
            decimal oldPrice;
            int oldStock;
            const string selectOldValuesSql = @"
                SELECT ""Price"", ""StockQuantity""
                FROM public.""Products""
                WHERE ""ProductId"" = $1";

            using (var selectCmd = new NpgsqlCommand(selectOldValuesSql, connection))
            {
                selectCmd.Parameters.AddWithValue("@ProductId", productId);
                using var selectReader = await selectCmd.ExecuteReaderAsync();
                if (!await selectReader.ReadAsync())
                    throw new InvalidOperationException($"Product with ID {productId} not found.");
                oldPrice = Convert.ToDecimal(selectReader["Price"]);
                oldStock = Convert.ToInt32(selectReader["StockQuantity"]);
            }

            await using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Log the deletion
                const string insertHistorySql = @"
                    INSERT INTO public.""ProductHistory"" (""ProductId"", ""Action"", ""OldPrice"", ""NewPrice"", ""OldStock"", ""NewStock"", ""ActionDate"")
                    VALUES ($1, 'DELETE', $2, NULL, $3, NULL, NOW())";

                using (var historyCmd = new NpgsqlCommand(insertHistorySql, connection, (NpgsqlTransaction)transaction))
                {
                    historyCmd.Parameters.AddWithValue("@ProductId", productId);
                    historyCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                    historyCmd.Parameters.AddWithValue("@OldStock", oldStock);
                    await historyCmd.ExecuteNonQueryAsync();
                }

                // Delete the product
                const string deleteProductSql = @"
                    DELETE FROM public.""Products"" 
                    WHERE ""ProductId"" = $1";

                using (var deleteCmd = new NpgsqlCommand(deleteProductSql, connection, (NpgsqlTransaction)transaction))
                {
                    deleteCmd.Parameters.AddWithValue("@ProductId", productId);
                    await deleteCmd.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE public.""ProductStats""
                    SET 
                        ""TotalProducts"" = ""TotalProducts"" - 1,
                        ""AveragePrice"" = CASE 
                            WHEN ""TotalProducts"" > 1 
                            THEN (""AveragePrice"" * ""TotalProducts"" - $1) / (""TotalProducts"" - 1)
                            ELSE 0
                        END,
                        ""LastUpdated"" = NOW()
                    WHERE ""StatId"" = 1";

                using (var statsCmd = new NpgsqlCommand(updateStatsSql, connection, (NpgsqlTransaction)transaction))
                {
                    statsCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                    await statsCmd.ExecuteNonQueryAsync();
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
                    FROM public.""Products"" p
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
                    FROM public.""Products"" p
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
