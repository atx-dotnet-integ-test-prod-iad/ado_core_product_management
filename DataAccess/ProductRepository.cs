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
                    FROM productmanagement_dbo.products
                )
                SELECT 
                    p.productid AS ProductId,
                    p.name AS Name,
                    p.description AS Description,
                    p.price AS Price,
                    p.stockquantity AS StockQuantity,
                    p.createddate AS CreatedDate,
                    p.modifieddate AS ModifiedDate,
                    CASE 
                        WHEN p.price > ps.avgprice THEN 'Above Average'
                        WHEN p.price < ps.avgprice THEN 'Below Average'
                        ELSE 'Average'
                    END as PriceCategory,
                    ROUND((p.price / ps.avgprice) * 100, 2) as PricePercentageOfAverage
                FROM productmanagement_dbo.products AS p
                INNER JOIN productstats AS ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END NULLS FIRST,
                    p.name NULLS FIRST";

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
                    WHERE productid = @ProductId
                )
                SELECT 
                    p.productid AS ProductId,
                    p.name AS Name,
                    p.description AS Description,
                    p.price AS Price,
                    p.stockquantity AS StockQuantity,
                    p.createddate AS CreatedDate,
                    p.modifieddate AS ModifiedDate,
                    ph.previousprice AS PreviousPrice,
                    ph.previousstock AS PreviousStock,
                    CASE 
                        WHEN ph.previousprice IS NOT NULL THEN 
                            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
                        ELSE NULL
                    END as PriceChangePercentage
                FROM productmanagement_dbo.products AS p
                LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid
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
            var transaction = (NpgsqlTransaction)await connection.BeginTransactionAsync();
            
            try
            {
                // Insert the new product and get the ID using RETURNING
                const string insertSql = @"
                    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid";
                
                int newProductId;
                using (var command = new NpgsqlCommand(insertSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@Name", product.Name);
                    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());
                }
                
                // Log the insertion
                const string logSql = @"
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";
                
                using (var command = new NpgsqlCommand(logSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@NewProductId", newProductId);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productmanagement_dbo.productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1";
                
                using (var command = new NpgsqlCommand(statsSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@Price", product.Price);
                    
                    await command.ExecuteNonQueryAsync();
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
            var transaction = (NpgsqlTransaction)await connection.BeginTransactionAsync();
            
            try
            {
                // Get old values for history
                decimal oldPrice = 0;
                int oldStock = 0;
                
                const string getOldSql = @"
                    SELECT price, stockquantity
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId";
                
                using (var command = new NpgsqlCommand(getOldSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@ProductId", product.ProductId);
                    
                    using var reader = await command.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        oldPrice = reader.GetDecimal(0);
                        oldStock = reader.GetInt32(1);
                    }
                }
                
                // Update the product
                const string updateSql = @"
                    UPDATE productmanagement_dbo.products
                    SET name = @Name, description = @Description, price = @Price, 
                        stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
                    WHERE productid = @ProductId";
                
                using (var command = new NpgsqlCommand(updateSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@ProductId", product.ProductId);
                    command.Parameters.AddWithValue("@Name", product.Name);
                    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Log the changes
                const string logSql = @"
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP)";
                
                using (var command = new NpgsqlCommand(logSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@ProductId", product.ProductId);
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    command.Parameters.AddWithValue("@OldStock", oldStock);
                    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
                const string statsSql = @"
                    UPDATE productmanagement_dbo.productstats
                    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, 
                        lastupdated = CURRENT_TIMESTAMP
                    WHERE statid = 1";
                
                using (var command = new NpgsqlCommand(statsSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    command.Parameters.AddWithValue("@Price", product.Price);
                    
                    await command.ExecuteNonQueryAsync();
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
            var transaction = (NpgsqlTransaction)await connection.BeginTransactionAsync();
            
            try
            {
                // Get old values before deletion
                decimal oldPrice = 0;
                const string getOldPriceSql = @"
                    SELECT price FROM productmanagement_dbo.products WHERE productid = @ProductId";
                
                using (var command = new NpgsqlCommand(getOldPriceSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@ProductId", productId);
                    
                    var result = await command.ExecuteScalarAsync();
                    if (result != null)
                        oldPrice = Convert.ToDecimal(result);
                }
                
                // Log the deletion (capture values before delete)
                const string logSql = @"
                    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, CURRENT_TIMESTAMP
                    FROM productmanagement_dbo.products
                    WHERE productid = @ProductId";
                
                using (var command = new NpgsqlCommand(logSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@ProductId", productId);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Delete the product
                const string deleteSql = @"
                    DELETE FROM productmanagement_dbo.products 
                    WHERE productid = @ProductId";
                
                using (var command = new NpgsqlCommand(deleteSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@ProductId", productId);
                    
                    await command.ExecuteNonQueryAsync();
                }
                
                // Update product statistics
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
                
                using (var command = new NpgsqlCommand(statsSql, connection))
                {
                    command.Transaction = transaction;
                    command.Parameters.AddWithValue("@OldPrice", oldPrice);
                    
                    await command.ExecuteNonQueryAsync();
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
                        p.productid AS ProductId, p.name AS Name, p.description AS Description, 
                        p.price AS Price, p.stockquantity AS StockQuantity, p.createddate AS CreatedDate, 
                        p.modifieddate AS ModifiedDate,
                        RANK() OVER (ORDER BY p.price) AS pricerank,
                        percent_rank() OVER (ORDER BY p.price) AS pricepercentile
                    FROM productmanagement_dbo.products AS p
                    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
                )
                SELECT 
                    rp.ProductId, rp.Name, rp.Description, rp.Price, rp.StockQuantity, 
                    rp.CreatedDate, rp.ModifiedDate,
                    CASE 
                        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
                        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
                        ELSE 'Premium'
                    END AS PriceSegment
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
                WITH stockanalysis AS (
                    SELECT 
                        p.productid AS ProductId, p.name AS Name, p.description AS Description, 
                        p.price AS Price, p.stockquantity AS StockQuantity, p.createddate AS CreatedDate, 
                        p.modifieddate AS ModifiedDate,
                        AVG(stockquantity) OVER () AS avgstock,
                        MIN(stockquantity) OVER () AS minstock,
                        MAX(stockquantity) OVER () AS maxstock
                    FROM productmanagement_dbo.products AS p
                )
                SELECT 
                    sa.ProductId, sa.Name, sa.Description, sa.Price, sa.StockQuantity, 
                    sa.CreatedDate, sa.ModifiedDate,
                    CASE 
                        WHEN sa.StockQuantity <= @Threshold THEN 'Critical'
                        WHEN sa.StockQuantity <= sa.avgstock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END AS StockStatus,
                    ROUND((sa.StockQuantity / sa.avgstock) * 100, 2) AS StockPercentageOfAverage
                FROM stockanalysis AS sa
                WHERE sa.StockQuantity <= @Threshold
                ORDER BY sa.StockQuantity NULLS FIRST";

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
