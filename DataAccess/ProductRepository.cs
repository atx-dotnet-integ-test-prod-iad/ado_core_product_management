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
                        product_id,
                        AVG(price) OVER() as AvgPrice,
                        COUNT(*) OVER() as TotalProducts
                    FROM public.products
                )
                SELECT 
                    p.product_id,
                    p.name,
                    p.description,
                    p.price,
                    p.stock_quantity,
                    p.created_date,
                    p.modified_date,
                    CASE 
                        WHEN p.price > ps.AvgPrice THEN 'Above Average'
                        WHEN p.price < ps.AvgPrice THEN 'Below Average'
                        ELSE 'Average'
                    END as PriceCategory,
                    ROUND((p.price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
                FROM public.products p
                INNER JOIN ProductStats ps ON p.product_id = ps.product_id
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.AvgPrice THEN 1
                        ELSE 2
                    END,
                    p.name;";

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
                        product_id,
                        LAG(price) OVER (ORDER BY modified_date) as PreviousPrice,
                        LAG(stock_quantity) OVER (ORDER BY modified_date) as PreviousStock
                    FROM public.products
                    WHERE product_id = @ProductId
                )
                SELECT 
                    p.product_id,
                    p.name,
                    p.description,
                    p.price,
                    p.stock_quantity,
                    p.created_date,
                    p.modified_date,
                    ph.PreviousPrice,
                    ph.PreviousStock,
                    CASE 
                        WHEN ph.PreviousPrice IS NOT NULL THEN 
                            ROUND(((p.price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
                        ELSE NULL
                    END as PriceChangePercentage
                FROM public.products p
                LEFT JOIN ProductHistory ph ON p.product_id = ph.product_id
                WHERE p.product_id = @ProductId;";

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

            const string sql = @"
                WITH inserted_product AS (
                    INSERT INTO public.products (name, description, price, stock_quantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING product_id, price, stock_quantity
                ),
                history_insert AS (
                    INSERT INTO public.product_history (product_id, action, old_price, new_price, old_stock, new_stock, action_date)
                    SELECT product_id, 'INSERT', NULL, price, NULL, stock_quantity, CURRENT_TIMESTAMP
                    FROM inserted_product
                    RETURNING product_id
                ),
                stats_update AS (
                    UPDATE public.product_stats
                    SET 
                        total_products = total_products + 1,
                        average_price = (average_price * total_products + (SELECT price FROM inserted_product)) / (total_products + 1),
                        last_updated = CURRENT_TIMESTAMP
                    WHERE stat_id = 1
                    RETURNING stat_id
                )
                SELECT product_id FROM inserted_product;";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            return Convert.ToInt32(await command.ExecuteScalarAsync());
        }

        public async Task UpdateProductAsync(Product product)
        {
            var connection = await GetConnectionAsync();

            const string sql = @"
                WITH old_values AS (
                    SELECT price as OldPrice, stock_quantity as OldStock
                    FROM public.products
                    WHERE product_id = @ProductId
                ),
                product_update AS (
                    UPDATE public.products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stock_quantity = @StockQuantity,
                        modified_date = CURRENT_TIMESTAMP
                    WHERE product_id = @ProductId
                    RETURNING product_id, price, stock_quantity
                ),
                history_insert AS (
                    INSERT INTO public.product_history (product_id, action, old_price, new_price, old_stock, new_stock, action_date)
                    SELECT @ProductId, 'UPDATE', ov.OldPrice, pu.price, ov.OldStock, pu.stock_quantity, CURRENT_TIMESTAMP
                    FROM product_update pu, old_values ov
                    RETURNING product_id
                ),
                stats_update AS (
                    UPDATE public.product_stats
                    SET 
                        average_price = (average_price * total_products - (SELECT OldPrice FROM old_values) + @Price) / total_products,
                        last_updated = CURRENT_TIMESTAMP
                    WHERE stat_id = 1
                    RETURNING stat_id
                )
                SELECT 1;";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            await command.ExecuteNonQueryAsync();
        }

        public async Task DeleteProductAsync(int productId)
        {
            var connection = await GetConnectionAsync();

            const string sql = @"
                WITH old_values AS (
                    SELECT price as OldPrice, stock_quantity as OldStock
                    FROM public.products
                    WHERE product_id = @ProductId
                ),
                history_insert AS (
                    INSERT INTO public.product_history (product_id, action, old_price, new_price, old_stock, new_stock, action_date)
                    SELECT @ProductId, 'DELETE', OldPrice, NULL, OldStock, NULL, CURRENT_TIMESTAMP
                    FROM old_values
                    RETURNING product_id
                ),
                product_delete AS (
                    DELETE FROM public.products 
                    WHERE product_id = @ProductId
                    RETURNING product_id
                ),
                stats_update AS (
                    UPDATE public.product_stats
                    SET 
                        total_products = total_products - 1,
                        average_price = CASE 
                            WHEN total_products > 1 
                            THEN (average_price * total_products - (SELECT OldPrice FROM old_values)) / (total_products - 1)
                            ELSE 0
                        END,
                        last_updated = CURRENT_TIMESTAMP
                    WHERE stat_id = 1
                    RETURNING stat_id
                )
                SELECT 1;";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@ProductId", productId);

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
                        RANK() OVER (ORDER BY p.price) as PriceRank,
                        PERCENT_RANK() OVER (ORDER BY p.price) as PricePercentile
                    FROM public.products p
                    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
                )
                SELECT 
                    rp.*,
                    CASE 
                        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
                        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
                        ELSE 'Premium'
                    END as PriceSegment
                FROM RankedProducts rp
                ORDER BY rp.PriceRank;";

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
                        AVG(stock_quantity) OVER() as AvgStock,
                        MIN(stock_quantity) OVER() as MinStock,
                        MAX(stock_quantity) OVER() as MaxStock
                    FROM public.products p
                )
                SELECT 
                    sa.*,
                    CASE 
                        WHEN stock_quantity <= @Threshold THEN 'Critical'
                        WHEN stock_quantity <= AvgStock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END as StockStatus,
                    ROUND((stock_quantity / AvgStock) * 100, 2) as StockPercentageOfAverage
                FROM StockAnalysis sa
                WHERE stock_quantity <= @Threshold
                ORDER BY stock_quantity;";

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
                ProductId = Convert.ToInt32(reader["product_id"]),
                Name = reader["name"].ToString(),
                Description = reader["description"] == DBNull.Value ? null : reader["description"].ToString(),
                Price = Convert.ToDecimal(reader["price"]),
                StockQuantity = Convert.ToInt32(reader["stock_quantity"]),
                CreatedDate = Convert.ToDateTime(reader["created_date"]),
                ModifiedDate = reader["modified_date"] == DBNull.Value ? null : (DateTime?)Convert.ToDateTime(reader["modified_date"])
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
