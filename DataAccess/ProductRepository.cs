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
                    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
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
                FROM public.products p
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
            await using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Step 1: Insert the new product and retrieve its generated ID via RETURNING
                const string insertProductSql = @"
                    INSERT INTO public.products (Name, Description, Price, StockQuantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING ""ProductId""";

                int newProductId;
                await using (var insertCmd = new NpgsqlCommand(insertProductSql, connection, (NpgsqlTransaction)transaction))
                {
                    insertCmd.Parameters.AddWithValue("@Name", product.Name);
                    insertCmd.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    insertCmd.Parameters.AddWithValue("@Price", product.Price);
                    insertCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    newProductId = Convert.ToInt32(await insertCmd.ExecuteScalarAsync());
                }

                // Step 2: Log the insertion in product history
                const string insertHistorySql = @"
                    INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW())";

                await using (var historyCmd = new NpgsqlCommand(insertHistorySql, connection, (NpgsqlTransaction)transaction))
                {
                    historyCmd.Parameters.AddWithValue("@ProductId", newProductId);
                    historyCmd.Parameters.AddWithValue("@Price", product.Price);
                    historyCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    await historyCmd.ExecuteNonQueryAsync();
                }

                // Step 3: Update product statistics
                const string updateStatsSql = @"
                    UPDATE public.productstats
                    SET 
                        TotalProducts = TotalProducts + 1,
                        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                        LastUpdated = NOW()
                    WHERE StatId = 1";

                await using (var statsCmd = new NpgsqlCommand(updateStatsSql, connection, (NpgsqlTransaction)transaction))
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
            await using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Step 1: Fetch current price and stock to record in history
                const string selectOldValuesSql = @"
                    SELECT Price, StockQuantity
                    FROM public.products
                    WHERE ProductId = @ProductId";

                decimal oldPrice;
                int oldStock;
                await using (var selectCmd = new NpgsqlCommand(selectOldValuesSql, connection, (NpgsqlTransaction)transaction))
                {
                    selectCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                    await using var reader = (NpgsqlDataReader)await selectCmd.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                    {
                        throw new InvalidOperationException($"Product with ID {product.ProductId} was not found.");
                    }
                    oldPrice = Convert.ToDecimal(reader["Price"]);
                    oldStock = Convert.ToInt32(reader["StockQuantity"]);
                }

                // Step 2: Update the product record
                const string updateProductSql = @"
                    UPDATE public.products
                    SET 
                        Name = @Name,
                        Description = @Description,
                        Price = @Price,
                        StockQuantity = @StockQuantity,
                        ModifiedDate = NOW()
                    WHERE ProductId = @ProductId";

                await using (var updateCmd = new NpgsqlCommand(updateProductSql, connection, (NpgsqlTransaction)transaction))
                {
                    updateCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                    updateCmd.Parameters.AddWithValue("@Name", product.Name);
                    updateCmd.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    updateCmd.Parameters.AddWithValue("@Price", product.Price);
                    updateCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    await updateCmd.ExecuteNonQueryAsync();
                }

                // Step 3: Log the changes in product history
                const string insertHistorySql = @"
                    INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @NewPrice, @OldStock, @NewStock, NOW())";

                await using (var historyCmd = new NpgsqlCommand(insertHistorySql, connection, (NpgsqlTransaction)transaction))
                {
                    historyCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
                    historyCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                    historyCmd.Parameters.AddWithValue("@NewPrice", product.Price);
                    historyCmd.Parameters.AddWithValue("@OldStock", oldStock);
                    historyCmd.Parameters.AddWithValue("@NewStock", product.StockQuantity);
                    await historyCmd.ExecuteNonQueryAsync();
                }

                // Step 4: Update product statistics
                const string updateStatsSql = @"
                    UPDATE public.productstats
                    SET 
                        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @NewPrice) / TotalProducts,
                        LastUpdated = NOW()
                    WHERE StatId = 1";

                await using (var statsCmd = new NpgsqlCommand(updateStatsSql, connection, (NpgsqlTransaction)transaction))
                {
                    statsCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                    statsCmd.Parameters.AddWithValue("@NewPrice", product.Price);
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
            await using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Step 1: Fetch current price and stock before deleting
                const string selectOldValuesSql = @"
                    SELECT Price, StockQuantity
                    FROM public.products
                    WHERE ProductId = @ProductId";

                decimal oldPrice;
                int oldStock;
                await using (var selectCmd = new NpgsqlCommand(selectOldValuesSql, connection, (NpgsqlTransaction)transaction))
                {
                    selectCmd.Parameters.AddWithValue("@ProductId", productId);
                    await using var reader = (NpgsqlDataReader)await selectCmd.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                    {
                        throw new InvalidOperationException($"Product with ID {productId} was not found.");
                    }
                    oldPrice = Convert.ToDecimal(reader["Price"]);
                    oldStock = Convert.ToInt32(reader["StockQuantity"]);
                }

                // Step 2: Log the deletion in product history
                const string insertHistorySql = @"
                    INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW())";

                await using (var historyCmd = new NpgsqlCommand(insertHistorySql, connection, (NpgsqlTransaction)transaction))
                {
                    historyCmd.Parameters.AddWithValue("@ProductId", productId);
                    historyCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
                    historyCmd.Parameters.AddWithValue("@OldStock", oldStock);
                    await historyCmd.ExecuteNonQueryAsync();
                }

                // Step 3: Delete the product record
                const string deleteProductSql = @"
                    DELETE FROM public.products
                    WHERE ProductId = @ProductId";

                await using (var deleteCmd = new NpgsqlCommand(deleteProductSql, connection, (NpgsqlTransaction)transaction))
                {
                    deleteCmd.Parameters.AddWithValue("@ProductId", productId);
                    await deleteCmd.ExecuteNonQueryAsync();
                }

                // Step 4: Update product statistics
                const string updateStatsSql = @"
                    UPDATE public.productstats
                    SET 
                        TotalProducts = TotalProducts - 1,
                        AveragePrice = CASE 
                            WHEN TotalProducts > 1 
                            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
                            ELSE 0
                        END,
                        LastUpdated = NOW()
                    WHERE StatId = 1";

                await using (var statsCmd = new NpgsqlCommand(updateStatsSql, connection, (NpgsqlTransaction)transaction))
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
                    FROM public.products p
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
                    FROM public.products p
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
