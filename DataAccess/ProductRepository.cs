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
                WITH productstats
                AS (SELECT
                    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
                    FROM productmanagement_dbo.products)
                SELECT
                    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
                    CASE
                        WHEN p.price > ps.avgprice THEN 'Above Average'
                        WHEN p.price < ps.avgprice THEN 'Below Average'
                        ELSE 'Average'
                    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
                    FROM productmanagement_dbo.products AS p
                    INNER JOIN productstats AS ps
                        ON p.productid = ps.productid
                    ORDER BY
                    CASE
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END NULLS FIRST, p.name NULLS FIRST";

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
                WITH producthistory
                AS (SELECT
                    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId)
                SELECT
                    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
                    CASE
                        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
                        ELSE NULL
                    END AS pricechangepercentage
                    FROM productmanagement_dbo.products AS p
                    LEFT OUTER JOIN producthistory AS ph
                        ON p.productid = ph.productid
                    WHERE p.productid = @ProductId";

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
                WITH new_product AS (
                    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid
                ),
                log_insertion AS (
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
                    FROM new_product
                ),
                update_stats AS (
                    UPDATE productmanagement_dbo.productstats
                    SET
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = clock_timestamp()
                    WHERE statid = 1
                )
                SELECT productid FROM new_product";

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
                    SELECT price AS oldprice, stockquantity AS oldstock
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId
                ),
                do_update AS (
                    UPDATE productmanagement_dbo.products
                    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
                    WHERE productid = @ProductId
                    RETURNING productid
                ),
                log_changes AS (
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, clock_timestamp()
                    FROM old_values ov
                )
                UPDATE productmanagement_dbo.productstats
                SET averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts, lastupdated = clock_timestamp()
                WHERE statid = 1";

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
                    SELECT price AS oldprice, stockquantity AS oldstock
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId
                ),
                log_deletion AS (
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, clock_timestamp()
                    FROM old_values ov
                ),
                do_delete AS (
                    DELETE FROM productmanagement_dbo.products
                    WHERE productid = @ProductId
                    RETURNING productid
                )
                UPDATE productmanagement_dbo.productstats
                SET totalproducts = totalproducts - 1, averageprice =
                CASE
                    WHEN totalproducts > 1 THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
                    ELSE 0
                END, lastupdated = clock_timestamp()
                WHERE statid = 1";

            using var command = new NpgsqlCommand(sql, connection);
            command.Parameters.AddWithValue("@ProductId", productId);

            await command.ExecuteNonQueryAsync();
        }

        public async Task<List<Product>> GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
        {
            var products = new List<Product>();
            var connection = await GetConnectionAsync();

            const string sql = @"
                WITH rankedproducts
                AS (SELECT
                    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
                    FROM productmanagement_dbo.products AS p
                    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
                SELECT
                    rp.*,
                    CASE
                        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
                        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
                        ELSE 'Premium'
                    END AS pricesegment
                    FROM rankedproducts AS rp
                    ORDER BY rp.pricerank NULLS FIRST";

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
                WITH stockanalysis
                AS (SELECT
                    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
                    FROM productmanagement_dbo.products AS p)
                SELECT
                    sa.*,
                    CASE
                        WHEN stockquantity <= @Threshold THEN 'Critical'
                        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
                    FROM stockanalysis AS sa
                    WHERE stockquantity <= @Threshold
                    ORDER BY stockquantity NULLS FIRST";

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
