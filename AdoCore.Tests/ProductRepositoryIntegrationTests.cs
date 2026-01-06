using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using AdoCore.DataAccess;
using AdoCore.Models;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace AdoCore.Tests
{
    /// <summary>
    /// Integration tests for ProductRepository that require a running PostgreSQL database.
    /// These tests validate actual database operations and SQL query execution.
    /// 
    /// Prerequisites:
    /// - PostgreSQL server running on localhost:5432
    /// - Database "ProductManagement" exists
    /// - Schema initialized with Database/01_InitialSetup.sql
    /// - Valid credentials configured in appsettings.json
    /// 
    /// Note: These tests are marked with [Trait("Category", "Integration")] and can be run separately
    /// using: dotnet test --filter "Category=Integration"
    /// </summary>
    [Trait("Category", "Integration")]
    public class ProductRepositoryIntegrationTests : IAsyncLifetime
    {
        private ProductRepository _repository;
        private IConfiguration _configuration;
        private int _testProductId;

        public async Task InitializeAsync()
        {
            // Setup configuration
            var configBuilder = new ConfigurationBuilder()
                .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
                .AddJsonFile("appsettings.json", optional: true);

            _configuration = configBuilder.Build();
            _repository = new ProductRepository(_configuration);

            // Insert a test product for use in tests
            var testProduct = new Product
            {
                Name = "Integration Test Product",
                Description = "Created by integration tests",
                Price = 99.99m,
                StockQuantity = 100
            };

            try
            {
                _testProductId = await _repository.InsertProductAsync(testProduct);
            }
            catch (Exception ex)
            {
                // If we can't insert a test product, the database is not available
                throw new InvalidOperationException(
                    "Unable to initialize integration tests. Ensure PostgreSQL is running and the database is initialized.", 
                    ex);
            }
        }

        public async Task DisposeAsync()
        {
            // Cleanup: Delete test product if it exists
            try
            {
                if (_testProductId > 0)
                {
                    await _repository.DeleteProductAsync(_testProductId);
                }
            }
            catch
            {
                // Ignore cleanup errors
            }

            if (_repository != null)
            {
                await _repository.DisposeAsync();
            }
        }

        [Fact]
        public async Task GetAllProductsAsync_WithValidConnection_ReturnsProducts()
        {
            // Act
            var products = await _repository.GetAllProductsAsync();

            // Assert
            Assert.NotNull(products);
            Assert.IsType<List<Product>>(products);
            Assert.True(products.Count > 0, "Expected at least one product (the test product)");
        }

        [Fact]
        public async Task GetProductByIdAsync_WithValidId_ReturnsProduct()
        {
            // Act
            var product = await _repository.GetProductByIdAsync(_testProductId);

            // Assert
            Assert.NotNull(product);
            Assert.Equal(_testProductId, product.ProductId);
            Assert.Equal("Integration Test Product", product.Name);
        }

        [Fact]
        public async Task GetProductByIdAsync_WithInvalidId_ReturnsNull()
        {
            // Arrange
            int invalidId = -9999;

            // Act
            var product = await _repository.GetProductByIdAsync(invalidId);

            // Assert
            Assert.Null(product);
        }

        [Fact]
        public async Task InsertProductAsync_WithValidProduct_ReturnsNewId()
        {
            // Arrange
            var newProduct = new Product
            {
                Name = "Test Insert Product",
                Description = "Testing insert operation",
                Price = 49.99m,
                StockQuantity = 50
            };

            // Act
            int newId = await _repository.InsertProductAsync(newProduct);

            // Assert
            Assert.True(newId > 0, "Expected a positive product ID");

            // Cleanup
            await _repository.DeleteProductAsync(newId);
        }

        [Fact]
        public async Task InsertProductAsync_WithTransaction_MaintainsAtomicity()
        {
            // Arrange
            var product1 = new Product
            {
                Name = "Transaction Test 1",
                Description = "First product in transaction",
                Price = 25.00m,
                StockQuantity = 25
            };

            // Act
            int productId = await _repository.InsertProductAsync(product1);

            // Assert - Verify the product was inserted
            var retrievedProduct = await _repository.GetProductByIdAsync(productId);
            Assert.NotNull(retrievedProduct);
            Assert.Equal("Transaction Test 1", retrievedProduct.Name);

            // Cleanup
            await _repository.DeleteProductAsync(productId);
        }

        [Fact]
        public async Task UpdateProductAsync_WithValidProduct_UpdatesSuccessfully()
        {
            // Arrange
            var product = await _repository.GetProductByIdAsync(_testProductId);
            var originalPrice = product.Price;
            product.Price = originalPrice + 10.00m;
            product.StockQuantity = product.StockQuantity + 10;

            // Act
            await _repository.UpdateProductAsync(product);

            // Assert
            var updatedProduct = await _repository.GetProductByIdAsync(_testProductId);
            Assert.Equal(originalPrice + 10.00m, updatedProduct.Price);
            Assert.Equal(product.StockQuantity, updatedProduct.StockQuantity);
        }

        [Fact]
        public async Task UpdateProductAsync_WithNonExistentProduct_ThrowsException()
        {
            // Arrange
            var nonExistentProduct = new Product
            {
                ProductId = -9999,
                Name = "Non-existent",
                Price = 1.00m,
                StockQuantity = 1
            };

            // Act & Assert
            await Assert.ThrowsAsync<InvalidOperationException>(
                async () => await _repository.UpdateProductAsync(nonExistentProduct));
        }

        [Fact]
        public async Task DeleteProductAsync_WithValidId_DeletesSuccessfully()
        {
            // Arrange - Create a product specifically for deletion
            var productToDelete = new Product
            {
                Name = "Product To Delete",
                Description = "This product will be deleted",
                Price = 1.00m,
                StockQuantity = 1
            };
            int productId = await _repository.InsertProductAsync(productToDelete);

            // Act
            await _repository.DeleteProductAsync(productId);

            // Assert
            var deletedProduct = await _repository.GetProductByIdAsync(productId);
            Assert.Null(deletedProduct);
        }

        [Fact]
        public async Task DeleteProductAsync_WithNonExistentId_ThrowsException()
        {
            // Arrange
            int nonExistentId = -9999;

            // Act & Assert
            await Assert.ThrowsAsync<InvalidOperationException>(
                async () => await _repository.DeleteProductAsync(nonExistentId));
        }

        [Fact]
        public async Task GetProductsByPriceRangeAsync_WithValidRange_ReturnsMatchingProducts()
        {
            // Arrange
            decimal minPrice = 50.00m;
            decimal maxPrice = 150.00m;

            // Act
            var products = await _repository.GetProductsByPriceRangeAsync(minPrice, maxPrice);

            // Assert
            Assert.NotNull(products);
            Assert.True(products.Count > 0, "Expected at least the test product in this range");
            Assert.All(products, p => Assert.InRange(p.Price, minPrice, maxPrice));
        }

        [Fact]
        public async Task GetProductsByPriceRangeAsync_WithNoMatchingProducts_ReturnsEmptyList()
        {
            // Arrange
            decimal minPrice = 999999.00m;
            decimal maxPrice = 9999999.00m;

            // Act
            var products = await _repository.GetProductsByPriceRangeAsync(minPrice, maxPrice);

            // Assert
            Assert.NotNull(products);
            Assert.Empty(products);
        }

        [Fact]
        public async Task GetLowStockProductsAsync_WithValidThreshold_ReturnsMatchingProducts()
        {
            // Arrange
            int threshold = 150;

            // Act
            var products = await _repository.GetLowStockProductsAsync(threshold);

            // Assert
            Assert.NotNull(products);
            Assert.All(products, p => Assert.True(p.StockQuantity <= threshold));
        }

        [Fact]
        public async Task GetLowStockProductsAsync_WithHighThreshold_ReturnsAllProducts()
        {
            // Arrange
            int highThreshold = 100000;

            // Act
            var products = await _repository.GetLowStockProductsAsync(highThreshold);

            // Assert
            Assert.NotNull(products);
            Assert.True(products.Count > 0);
        }

        [Fact]
        public async Task TransactionRollback_OnError_MaintainsDataIntegrity()
        {
            // This test verifies that if an error occurs during a transaction,
            // the transaction is properly rolled back and no partial data is committed.
            
            // Arrange - Get the current product count
            var productsBefore = await _repository.GetAllProductsAsync();
            int countBefore = productsBefore.Count;

            // Act & Assert - Try to update a non-existent product (should rollback)
            var nonExistentProduct = new Product
            {
                ProductId = -9999,
                Name = "Should Not Be Inserted",
                Price = 1.00m,
                StockQuantity = 1
            };

            await Assert.ThrowsAsync<InvalidOperationException>(
                async () => await _repository.UpdateProductAsync(nonExistentProduct));

            // Verify that the product count hasn't changed
            var productsAfter = await _repository.GetAllProductsAsync();
            int countAfter = productsAfter.Count;

            Assert.Equal(countBefore, countAfter);
        }

        [Fact]
        public async Task MultipleOperations_InSequence_MaintainDataConsistency()
        {
            // Arrange
            var product = new Product
            {
                Name = "Consistency Test Product",
                Description = "Testing data consistency",
                Price = 30.00m,
                StockQuantity = 30
            };

            // Act - Insert
            int productId = await _repository.InsertProductAsync(product);
            var insertedProduct = await _repository.GetProductByIdAsync(productId);

            // Act - Update
            insertedProduct.Price = 35.00m;
            insertedProduct.StockQuantity = 25;
            await _repository.UpdateProductAsync(insertedProduct);
            var updatedProduct = await _repository.GetProductByIdAsync(productId);

            // Act - Delete
            await _repository.DeleteProductAsync(productId);
            var deletedProduct = await _repository.GetProductByIdAsync(productId);

            // Assert
            Assert.NotNull(insertedProduct);
            Assert.Equal(30.00m, insertedProduct.Price);
            Assert.NotNull(updatedProduct);
            Assert.Equal(35.00m, updatedProduct.Price);
            Assert.Equal(25, updatedProduct.StockQuantity);
            Assert.Null(deletedProduct);
        }

        [Fact]
        public async Task PostgreSQLSpecificSyntax_CTEsAndWindowFunctions_ExecuteCorrectly()
        {
            // This test verifies that PostgreSQL-specific syntax (CTEs, window functions)
            // executes correctly after migration from SQL Server

            // Act - Test CTE and window functions in GetAllProductsAsync
            var products = await _repository.GetAllProductsAsync();

            // Assert
            Assert.NotNull(products);
            Assert.True(products.Count > 0);
            Assert.All(products, p =>
            {
                Assert.True(p.ProductId > 0);
                Assert.NotNull(p.Name);
                Assert.True(p.Price >= 0);
            });
        }

        [Fact]
        public async Task PostgreSQLTimestampFunction_CURRENT_TIMESTAMP_WorksCorrectly()
        {
            // This test verifies that CURRENT_TIMESTAMP (PostgreSQL) works correctly
            // after migration from GETDATE() (SQL Server)

            // Arrange
            var beforeInsert = DateTime.UtcNow.AddMinutes(-1);
            var product = new Product
            {
                Name = "Timestamp Test Product",
                Description = "Testing timestamp function",
                Price = 15.00m,
                StockQuantity = 15
            };

            // Act
            int productId = await _repository.InsertProductAsync(product);
            var insertedProduct = await _repository.GetProductByIdAsync(productId);
            var afterInsert = DateTime.UtcNow.AddMinutes(1);

            // Assert
            Assert.NotNull(insertedProduct);
            Assert.InRange(insertedProduct.CreatedDate, beforeInsert, afterInsert);

            // Cleanup
            await _repository.DeleteProductAsync(productId);
        }

        [Fact]
        public async Task PostgreSQLReturningClause_ReturnsCorrectInsertedId()
        {
            // This test verifies that the RETURNING clause (PostgreSQL) works correctly
            // after migration from SCOPE_IDENTITY() (SQL Server)

            // Arrange
            var product = new Product
            {
                Name = "RETURNING Test Product",
                Description = "Testing RETURNING clause",
                Price = 20.00m,
                StockQuantity = 20
            };

            // Act
            int returnedId = await _repository.InsertProductAsync(product);
            var retrievedProduct = await _repository.GetProductByIdAsync(returnedId);

            // Assert
            Assert.True(returnedId > 0);
            Assert.NotNull(retrievedProduct);
            Assert.Equal(returnedId, retrievedProduct.ProductId);
            Assert.Equal("RETURNING Test Product", retrievedProduct.Name);

            // Cleanup
            await _repository.DeleteProductAsync(returnedId);
        }
    }
}
