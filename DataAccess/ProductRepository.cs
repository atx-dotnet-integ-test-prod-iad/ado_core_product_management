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
                WITH productstats AS (
                    SELECT 
                        productid,
                        AVG(price) OVER() as avgprice,
                        COUNT(*) OVER() as totalproducts
                    FROM products
                )
                SELECT 
                    p.productid,
                    p.name,
                    p.description,
                    p.price,
                    p.stockquantity,
                    p.createddate,
                    p.modifieddate,
                    CASE 
                        WHEN p.price > ps.avgprice THEN 'Above Average'
                        WHEN p.price < ps.avgprice THEN 'Below Average'
                        ELSE 'Average'
                    END as pricecategory,
                    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
                FROM products p
                INNER JOIN productstats ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END,
                    p.name";

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
                WITH producthistory AS (
                    SELECT 
                        productid,
                        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
                        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
                    FROM products
                    WHERE productid = @ProductId
                )
                SELECT 
                    p.productid,
                    p.name,
                    p.description,
                    p.price,
                    p.stockquantity,
                    p.createddate,
                    p.modifieddate,
                    ph.previousprice,
                    ph.previousstock,
                    CASE 
                        WHEN ph.previousprice IS NOT NULL THEN 
                            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
                        ELSE NULL
                    END as pricechangepercentage
                FROM products p
                LEFT JOIN producthistory ph ON p.productid = ph.productid
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
            using var transaction = await connection.BeginTransactionAsync();
            try
            {
                // Insert the new product and get the new ID via RETURNING
                const string insertProductSql = @"
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid";

                int newProductId;
                using (var cmd1 = new NpgsqlCommand(insertProductSql, connection))
                {
                    cmd1.Transaction = (NpgsqlTransaction)transaction;
                    cmd1.Parameters.AddWithValue("@Name", product.Name);
                    cmd1.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    cmd1.Parameters.AddWithValue("@Price", product.Price);
                    cmd1.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    newProductId = Convert.ToInt32(await cmd1.ExecuteScalarAsync());
                }

                // Log the insertion
                const string insertHistorySql = @"
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW())";

                using (var cmd2 = new NpgsqlCommand(insertHistorySql, connection))
                {
                    cmd2.Transaction = (NpgsqlTransaction)transaction;
                    cmd2.Parameters.AddWithValue("@ProductId", newProductId);
                    cmd2.Parameters.AddWithValue("@Price", product.Price);
                    cmd2.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    await cmd2.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = NOW()
                    WHERE statid = 1";

                using (var cmd3 = new NpgsqlCommand(updateStatsSql, connection))
                {
                    cmd3.Transaction = (NpgsqlTransaction)transaction;
                    cmd3.Parameters.AddWithValue("@Price", product.Price);
                    await cmd3.ExecuteNonQueryAsync();
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
                const string selectOldValuesSql = @"
                    SELECT price, stockquantity
                    FROM products
                    WHERE productid = @ProductId";

                decimal oldPrice;
                int oldStock;
                using (var cmd1 = new NpgsqlCommand(selectOldValuesSql, connection))
                {
                    cmd1.Transaction = (NpgsqlTransaction)transaction;
                    cmd1.Parameters.AddWithValue("@ProductId", product.ProductId);
                    using var reader = await cmd1.ExecuteReaderAsync();
                    await reader.ReadAsync();
                    oldPrice = Convert.ToDecimal(reader["price"]);
                    oldStock = Convert.ToInt32(reader["stockquantity"]);
                }

                // Update the product
                const string updateProductSql = @"
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = NOW()
                    WHERE productid = @ProductId";

                using (var cmd2 = new NpgsqlCommand(updateProductSql, connection))
                {
                    cmd2.Transaction = (NpgsqlTransaction)transaction;
                    cmd2.Parameters.AddWithValue("@ProductId", product.ProductId);
                    cmd2.Parameters.AddWithValue("@Name", product.Name);
                    cmd2.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    cmd2.Parameters.AddWithValue("@Price", product.Price);
                    cmd2.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    await cmd2.ExecuteNonQueryAsync();
                }

                // Log the changes
                const string insertHistorySql = @"
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW())";

                using (var cmd3 = new NpgsqlCommand(insertHistorySql, connection))
                {
                    cmd3.Transaction = (NpgsqlTransaction)transaction;
                    cmd3.Parameters.AddWithValue("@ProductId", product.ProductId);
                    cmd3.Parameters.AddWithValue("@OldPrice", oldPrice);
                    cmd3.Parameters.AddWithValue("@Price", product.Price);
                    cmd3.Parameters.AddWithValue("@OldStock", oldStock);
                    cmd3.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    await cmd3.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
                        lastupdated = NOW()
                    WHERE statid = 1";

                using (var cmd4 = new NpgsqlCommand(updateStatsSql, connection))
                {
                    cmd4.Transaction = (NpgsqlTransaction)transaction;
                    cmd4.Parameters.AddWithValue("@OldPrice", oldPrice);
                    cmd4.Parameters.AddWithValue("@Price", product.Price);
                    await cmd4.ExecuteNonQueryAsync();
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
                const string selectOldValuesSql = @"
                    SELECT price, stockquantity
                    FROM products
                    WHERE productid = @ProductId";

                decimal oldPrice;
                int oldStock;
                using (var cmd1 = new NpgsqlCommand(selectOldValuesSql, connection))
                {
                    cmd1.Transaction = (NpgsqlTransaction)transaction;
                    cmd1.Parameters.AddWithValue("@ProductId", productId);
                    using var reader = await cmd1.ExecuteReaderAsync();
                    await reader.ReadAsync();
                    oldPrice = Convert.ToDecimal(reader["price"]);
                    oldStock = Convert.ToInt32(reader["stockquantity"]);
                }

                // Log the deletion
                const string insertHistorySql = @"
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW())";

                using (var cmd2 = new NpgsqlCommand(insertHistorySql, connection))
                {
                    cmd2.Transaction = (NpgsqlTransaction)transaction;
                    cmd2.Parameters.AddWithValue("@ProductId", productId);
                    cmd2.Parameters.AddWithValue("@OldPrice", oldPrice);
                    cmd2.Parameters.AddWithValue("@OldStock", oldStock);
                    await cmd2.ExecuteNonQueryAsync();
                }

                // Delete the product
                const string deleteProductSql = @"
                    DELETE FROM products 
                    WHERE productid = @ProductId";

                using (var cmd3 = new NpgsqlCommand(deleteProductSql, connection))
                {
                    cmd3.Transaction = (NpgsqlTransaction)transaction;
                    cmd3.Parameters.AddWithValue("@ProductId", productId);
                    await cmd3.ExecuteNonQueryAsync();
                }

                // Update product statistics
                const string updateStatsSql = @"
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = NOW()
                    WHERE statid = 1";

                using (var cmd4 = new NpgsqlCommand(updateStatsSql, connection))
                {
                    cmd4.Transaction = (NpgsqlTransaction)transaction;
                    cmd4.Parameters.AddWithValue("@OldPrice", oldPrice);
                    await cmd4.ExecuteNonQueryAsync();
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
                WITH rankedproducts AS (
                    SELECT 
                        p.*,
                        RANK() OVER (ORDER BY p.price) as pricerank,
                        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
                    FROM products p
                    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
                )
                SELECT 
                    rp.*,
                    CASE 
                        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
                        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
                        ELSE 'Premium'
                    END as pricesegment
                FROM rankedproducts rp
                ORDER BY rp.pricerank";

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
                WITH stockanalysis AS (
                    SELECT 
                        p.*,
                        AVG(stockquantity) OVER() as avgstock,
                        MIN(stockquantity) OVER() as minstock,
                        MAX(stockquantity) OVER() as maxstock
                    FROM products p
                )
                SELECT 
                    sa.*,
                    CASE 
                        WHEN stockquantity <= @Threshold THEN 'Critical'
                        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END as stockstatus,
                    ROUND(CAST(stockquantity AS NUMERIC) / avgstock * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity";

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
                ProductId = Convert.ToInt32(reader["productid"]),
                Name = reader["name"].ToString(),
                Description = reader["description"] == DBNull.Value ? null : reader["description"].ToString(),
                Price = Convert.ToDecimal(reader["price"]),
                StockQuantity = Convert.ToInt32(reader["stockquantity"]),
                CreatedDate = Convert.ToDateTime(reader["createddate"]),
                ModifiedDate = reader["modifieddate"] == DBNull.Value ? null : (DateTime?)Convert.ToDateTime(reader["modifieddate"])
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
