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
                WITH productstats_cte AS (
                    SELECT 
                        productid,
                        AVG(price) OVER() as avgprice,
                        COUNT(*) OVER() as totalproducts
                    FROM productmanagement_dbo.products
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
                FROM productmanagement_dbo.products p
                INNER JOIN productstats_cte ps ON p.productid = ps.productid
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
                WITH producthistory_cte AS (
                    SELECT 
                        productid,
                        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
                        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
                    FROM productmanagement_dbo.products
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
                FROM productmanagement_dbo.products p
                LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
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

            const string insertSql = @"
                INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid";

            const string historySql = @"
                INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";

            const string statsSql = @"
                UPDATE productmanagement_dbo.productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                    lastupdated = CURRENT_TIMESTAMP
                WHERE statid = 1";

            var transaction = (NpgsqlTransaction)await connection.BeginTransactionAsync();
            try
            {
                // Insert the new product and get the new ID
                using var insertCommand = new NpgsqlCommand(insertSql, connection, transaction);
                insertCommand.Parameters.AddWithValue("@Name", product.Name);
                insertCommand.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                insertCommand.Parameters.AddWithValue("@Price", product.Price);
                insertCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                var newProductId = Convert.ToInt32(await insertCommand.ExecuteScalarAsync());

                // Log the insertion
                using var historyCommand = new NpgsqlCommand(historySql, connection, transaction);
                historyCommand.Parameters.AddWithValue("@NewProductId", newProductId);
                historyCommand.Parameters.AddWithValue("@Price", product.Price);
                historyCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                await historyCommand.ExecuteNonQueryAsync();

                // Update product statistics
                using var statsCommand = new NpgsqlCommand(statsSql, connection, transaction);
                statsCommand.Parameters.AddWithValue("@Price", product.Price);
                await statsCommand.ExecuteNonQueryAsync();

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

            const string getOldValuesSql = @"
                SELECT price, stockquantity
                FROM productmanagement_dbo.products
                WHERE productid = @ProductId";

            const string updateSql = @"
                UPDATE productmanagement_dbo.products
                SET 
                    name = @Name,
                    description = @Description,
                    price = @Price,
                    stockquantity = @StockQuantity,
                    modifieddate = CURRENT_TIMESTAMP
                WHERE productid = @ProductId";

            const string historySql = @"
                INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP)";

            const string statsSql = @"
                UPDATE productmanagement_dbo.productstats
                SET 
                    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
                    lastupdated = CURRENT_TIMESTAMP
                WHERE statid = 1";

            var transaction = (NpgsqlTransaction)await connection.BeginTransactionAsync();
            try
            {
                // Get old values for history
                decimal oldPrice;
                int oldStock;
                using (var getOldCommand = new NpgsqlCommand(getOldValuesSql, connection, transaction))
                {
                    getOldCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    using var reader = await getOldCommand.ExecuteReaderAsync();
                    await reader.ReadAsync();
                    oldPrice = Convert.ToDecimal(reader["price"]);
                    oldStock = Convert.ToInt32(reader["stockquantity"]);
                }

                // Update the product
                using var updateCommand = new NpgsqlCommand(updateSql, connection, transaction);
                updateCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                updateCommand.Parameters.AddWithValue("@Name", product.Name);
                updateCommand.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                updateCommand.Parameters.AddWithValue("@Price", product.Price);
                updateCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                await updateCommand.ExecuteNonQueryAsync();

                // Log the changes
                using var historyCommand = new NpgsqlCommand(historySql, connection, transaction);
                historyCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                historyCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                historyCommand.Parameters.AddWithValue("@Price", product.Price);
                historyCommand.Parameters.AddWithValue("@OldStock", oldStock);
                historyCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                await historyCommand.ExecuteNonQueryAsync();

                // Update product statistics
                using var statsCommand = new NpgsqlCommand(statsSql, connection, transaction);
                statsCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                statsCommand.Parameters.AddWithValue("@Price", product.Price);
                await statsCommand.ExecuteNonQueryAsync();

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

            const string getOldValuesSql = @"
                SELECT price, stockquantity
                FROM productmanagement_dbo.products
                WHERE productid = @ProductId";

            const string historySql = @"
                INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP)";

            const string deleteSql = @"
                DELETE FROM productmanagement_dbo.products 
                WHERE productid = @ProductId";

            const string statsSql = @"
                UPDATE productmanagement_dbo.productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = CURRENT_TIMESTAMP
                WHERE statid = 1";

            var transaction = (NpgsqlTransaction)await connection.BeginTransactionAsync();
            try
            {
                // Get old values for history
                decimal oldPrice;
                int oldStock;
                using (var getOldCommand = new NpgsqlCommand(getOldValuesSql, connection, transaction))
                {
                    getOldCommand.Parameters.AddWithValue("@ProductId", productId);
                    using var reader = await getOldCommand.ExecuteReaderAsync();
                    await reader.ReadAsync();
                    oldPrice = Convert.ToDecimal(reader["price"]);
                    oldStock = Convert.ToInt32(reader["stockquantity"]);
                }

                // Log the deletion
                using var historyCommand = new NpgsqlCommand(historySql, connection, transaction);
                historyCommand.Parameters.AddWithValue("@ProductId", productId);
                historyCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                historyCommand.Parameters.AddWithValue("@OldStock", oldStock);
                await historyCommand.ExecuteNonQueryAsync();

                // Delete the product
                using var deleteCommand = new NpgsqlCommand(deleteSql, connection, transaction);
                deleteCommand.Parameters.AddWithValue("@ProductId", productId);
                await deleteCommand.ExecuteNonQueryAsync();

                // Update product statistics
                using var statsCommand = new NpgsqlCommand(statsSql, connection, transaction);
                statsCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                await statsCommand.ExecuteNonQueryAsync();

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
                    FROM productmanagement_dbo.products p
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
                    FROM productmanagement_dbo.products p
                )
                SELECT 
                    sa.*,
                    CASE 
                        WHEN stockquantity <= @Threshold THEN 'Critical'
                        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END as stockstatus,
                    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
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
