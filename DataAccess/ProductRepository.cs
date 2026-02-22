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
                        AVG(price) OVER() as Avgprice,
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
                        WHEN p.price > ps.Avgprice THEN 'Above Average'
                        WHEN p.price < ps.Avgprice THEN 'Below Average'
                        ELSE 'Average'
                    END as priceCategory,
                    ROUND((p.price / ps.Avgprice) * 100, 2) as pricePercentageOfAverage
                FROM products p
                INNER JOIN productstats ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.Avgprice THEN 1
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
                        LAG(price) OVER (ORDER BY modifieddate) as Previousprice,
                        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
                    FROM products
                    WHERE productid = @productid
                )
                SELECT 
                    p.productid,
                    p.name,
                    p.description,
                    p.price,
                    p.stockquantity,
                    p.createddate,
                    p.modifieddate,
                    ph.Previousprice,
                    ph.previousstock,
                    CASE 
                        WHEN ph.Previousprice IS NOT NULL THEN 
                            ROUND(((p.price - ph.Previousprice) / ph.Previousprice) * 100, 2)
                        ELSE NULL
                    END as priceChangePercentage
                FROM products p
                LEFT JOIN producthistory ph ON p.productid = ph.productid
                WHERE p.productid = @productid";

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
                // Insert the new product and get the new ID using RETURNING clause
                const string insertSql = @"
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid";

                int newProductId;
                using (var insertCommand = new NpgsqlCommand(insertSql, connection, transaction))
                {
                    insertCommand.Parameters.AddWithValue("@Name", product.Name);
                    insertCommand.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@Price", product.Price);
                    insertCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    newProductId = Convert.ToInt32(await insertCommand.ExecuteScalarAsync());
                }
                
                // Log the insertion
                const string historySql = @"
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";
                
                using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
                {
                    historyCommand.Parameters.AddWithValue("@ProductId", newProductId);
                    historyCommand.Parameters.AddWithValue("@Price", product.Price);
                    historyCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await historyCommand.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1";
                
                using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@Price", product.Price);
                    
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
            using var transaction = await connection.BeginTransactionAsync();
            
            try
            {
                // Store old values for history
                const string selectSql = @"
                    SELECT price, stockquantity
                    FROM products
                    WHERE productid = @ProductId";
                
                decimal oldPrice;
                int oldStock;
                
                using (var selectCommand = new NpgsqlCommand(selectSql, connection, transaction))
                {
                    selectCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    
                    using var reader = await selectCommand.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                    {
                        throw new InvalidOperationException($"Product with ID {product.ProductId} not found");
                    }
                    
                    oldPrice = reader.GetDecimal(0);
                    oldStock = reader.GetInt32(1);
                }
                
                // Update the product
                const string updateSql = @"
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = CURRENT_TIMESTAMP
                    WHERE productid = @ProductId";
                
                using (var updateCommand = new NpgsqlCommand(updateSql, connection, transaction))
                {
                    updateCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    updateCommand.Parameters.AddWithValue("@Name", product.Name);
                    updateCommand.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    updateCommand.Parameters.AddWithValue("@Price", product.Price);
                    updateCommand.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await updateCommand.ExecuteNonQueryAsync();
                }
                
                // Log the changes
                const string historySql = @"
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @NewPrice, @OldStock, @NewStock, CURRENT_TIMESTAMP)";
                
                using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
                {
                    historyCommand.Parameters.AddWithValue("@ProductId", product.ProductId);
                    historyCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    historyCommand.Parameters.AddWithValue("@NewPrice", product.Price);
                    historyCommand.Parameters.AddWithValue("@OldStock", oldStock);
                    historyCommand.Parameters.AddWithValue("@NewStock", product.StockQuantity);
                    
                    await historyCommand.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - @OldPrice + @NewPrice) / totalproducts,
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1";
                
                using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    statsCommand.Parameters.AddWithValue("@NewPrice", product.Price);
                    
                    await statsCommand.ExecuteNonQueryAsync();
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
                const string selectSql = @"
                    SELECT price, stockquantity
                    FROM products
                    WHERE productid = @ProductId";
                
                decimal oldPrice;
                int oldStock;
                
                using (var selectCommand = new NpgsqlCommand(selectSql, connection, transaction))
                {
                    selectCommand.Parameters.AddWithValue("@ProductId", productId);
                    
                    using var reader = await selectCommand.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                    {
                        throw new InvalidOperationException($"Product with ID {productId} not found");
                    }
                    
                    oldPrice = reader.GetDecimal(0);
                    oldStock = reader.GetInt32(1);
                }
                
                // Log the deletion
                const string historySql = @"
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP)";
                
                using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
                {
                    historyCommand.Parameters.AddWithValue("@ProductId", productId);
                    historyCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    historyCommand.Parameters.AddWithValue("@OldStock", oldStock);
                    
                    await historyCommand.ExecuteNonQueryAsync();
                }
                
                // Delete the product
                const string deleteSql = @"
                    DELETE FROM products 
                    WHERE productid = @ProductId";
                
                using (var deleteCommand = new NpgsqlCommand(deleteSql, connection, transaction))
                {
                    deleteCommand.Parameters.AddWithValue("@ProductId", productId);
                    
                    await deleteCommand.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1";
                
                using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@OldPrice", oldPrice);
                    
                    await statsCommand.ExecuteNonQueryAsync();
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
                        RANK() OVER (ORDER BY p.price) as priceRank,
                        PERCENT_RANK() OVER (ORDER BY p.price) as pricePercentile
                    FROM products p
                    WHERE p.price BETWEEN @Minprice AND @Maxprice
                )
                SELECT 
                    rp.*,
                    CASE 
                        WHEN rp.pricePercentile <= 0.25 THEN 'Budget'
                        WHEN rp.pricePercentile <= 0.75 THEN 'Mid-Range'
                        ELSE 'Premium'
                    END as priceSegment
                FROM rankedproducts rp
                ORDER BY rp.priceRank";

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
                    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
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
