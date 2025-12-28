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
                        COUNT(*) OVER() as Totalproducts
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
                    END as PriceCategory,
                    ROUND((p.price / ps.avgprice) * 100, 2) as PricePercentageOfAverage
                FROM productmanagement_dbo.products p
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
                    FROM productmanagement_dbo.products
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
                    ph.previousprice,
                    ph.previousstock,
                    CASE 
                        WHEN ph.previousprice IS NOT NULL THEN 
                            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
                        ELSE NULL
                    END as PriceChangePercentage
                FROM productmanagement_dbo.products p
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
                // Insert the new product and get the ID
                const string insertSql = @"
                    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                    VALUES (@name, @description, @price, @stockquantity)
                    RETURNING productid";

                int newProductId;
                using (var insertCommand = new NpgsqlCommand(insertSql, connection, transaction))
                {
                    insertCommand.Parameters.AddWithValue("@name", product.Name);
                    insertCommand.Parameters.AddWithValue("@description", (object)product.Description ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@price", product.Price);
                    insertCommand.Parameters.AddWithValue("@stockquantity", product.StockQuantity);
                    
                    newProductId = Convert.ToInt32(await insertCommand.ExecuteScalarAsync());
                }
                
                // Log the insertion
                const string historySql = @"
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@productid, 'INSERT', NULL, @price, NULL, @stockquantity, NOW())";
                
                using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
                {
                    historyCommand.Parameters.AddWithValue("@productid", newProductId);
                    historyCommand.Parameters.AddWithValue("@price", product.Price);
                    historyCommand.Parameters.AddWithValue("@stockquantity", product.StockQuantity);
                    
                    await historyCommand.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @price) / (totalproducts + 1),
                        lastupdated = NOW()
                    WHERE statid = 1";
                
                using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@price", product.Price);
                    
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
                    FROM productmanagement_dbo.products
                    WHERE productid = @productid";
                
                decimal oldPrice;
                int oldStock;
                
                using (var selectCommand = new NpgsqlCommand(selectSql, connection, transaction))
                {
                    selectCommand.Parameters.AddWithValue("@productid", product.ProductId);
                    
                    using var reader = await selectCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {product.ProductId} not found.");
                    }
                }
                
                // Update the product
                const string updateSql = @"
                    UPDATE productmanagement_dbo.products
                    SET 
                        name = @name,
                        description = @description,
                        price = @price,
                        stockquantity = @stockquantity,
                        modifieddate = NOW()
                    WHERE productid = @productid";
                
                using (var updateCommand = new NpgsqlCommand(updateSql, connection, transaction))
                {
                    updateCommand.Parameters.AddWithValue("@productid", product.ProductId);
                    updateCommand.Parameters.AddWithValue("@name", product.Name);
                    updateCommand.Parameters.AddWithValue("@description", (object)product.Description ?? DBNull.Value);
                    updateCommand.Parameters.AddWithValue("@price", product.Price);
                    updateCommand.Parameters.AddWithValue("@stockquantity", product.StockQuantity);
                    
                    await updateCommand.ExecuteNonQueryAsync();
                }
                
                // Log the changes
                const string historySql = @"
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@productid, 'UPDATE', @oldprice, @newprice, @oldstock, @newstock, NOW())";
                
                using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
                {
                    historyCommand.Parameters.AddWithValue("@productid", product.ProductId);
                    historyCommand.Parameters.AddWithValue("@oldprice", oldPrice);
                    historyCommand.Parameters.AddWithValue("@newprice", product.Price);
                    historyCommand.Parameters.AddWithValue("@oldstock", oldStock);
                    historyCommand.Parameters.AddWithValue("@newstock", product.StockQuantity);
                    
                    await historyCommand.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        averageprice = (averageprice * totalproducts - @oldprice + @newprice) / totalproducts,
                        lastupdated = NOW()
                    WHERE statid = 1";
                
                using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@oldprice", oldPrice);
                    statsCommand.Parameters.AddWithValue("@newprice", product.Price);
                    
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
                    FROM productmanagement_dbo.products
                    WHERE productid = @productid";
                
                decimal oldPrice;
                int oldStock;
                
                using (var selectCommand = new NpgsqlCommand(selectSql, connection, transaction))
                {
                    selectCommand.Parameters.AddWithValue("@productid", productId);
                    
                    using var reader = await selectCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                    else
                    {
                        throw new InvalidOperationException($"Product with ID {productId} not found.");
                    }
                }
                
                // Log the deletion
                const string historySql = @"
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@productid, 'DELETE', @oldprice, NULL, @oldstock, NULL, NOW())";
                
                using (var historyCommand = new NpgsqlCommand(historySql, connection, transaction))
                {
                    historyCommand.Parameters.AddWithValue("@productid", productId);
                    historyCommand.Parameters.AddWithValue("@oldprice", oldPrice);
                    historyCommand.Parameters.AddWithValue("@oldstock", oldStock);
                    
                    await historyCommand.ExecuteNonQueryAsync();
                }
                
                // Delete the product
                const string deleteSql = @"
                    DELETE FROM productmanagement_dbo.products 
                    WHERE productid = @productid";
                
                using (var deleteCommand = new NpgsqlCommand(deleteSql, connection, transaction))
                {
                    deleteCommand.Parameters.AddWithValue("@productid", productId);
                    
                    await deleteCommand.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - @oldprice) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = NOW()
                    WHERE statid = 1";
                
                using (var statsCommand = new NpgsqlCommand(statsSql, connection, transaction))
                {
                    statsCommand.Parameters.AddWithValue("@oldprice", oldPrice);
                    
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
                WITH Rankedproducts AS (
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
                    END as PriceSegment
                FROM Rankedproducts rp
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
                WITH StockAnalysis AS (
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
                    END as StockStatus,
                    ROUND((stockquantity / avgstock) * 100, 2) as StockPercentageOfAverage
                FROM StockAnalysis sa
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
