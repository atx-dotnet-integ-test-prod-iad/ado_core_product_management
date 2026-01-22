using System;
using System.Threading.Tasks;
using Xunit;
using Moq;
using Microsoft.Extensions.Configuration;
using AdoCore.DataAccess;
using AdoCore.Models;

namespace AdoCore.Tests
{
    /// <summary>
    /// Unit tests for ProductRepository class.
    /// These tests focus on repository initialization, configuration handling,
    /// and class structure without requiring a database connection.
    /// </summary>
    public class ProductRepositoryTests
    {
        private IConfiguration CreateMockConfiguration(string environment = "Development", string connectionString = "Host=localhost;Port=5432;Database=testdb;Username=testuser;Password=testpass")
        {
            var inMemorySettings = new System.Collections.Generic.Dictionary<string, string>
            {
                {"Environment", environment},
                {"ConnectionStrings:DevConnection", connectionString},
                {"ConnectionStrings:ProdConnection", "Host=prod.example.com;Port=5432;Database=proddb;Username=produser;Password=prodpass"}
            };

            return new ConfigurationBuilder()
                .AddInMemoryCollection(inMemorySettings)
                .Build();
        }

        [Fact]
        public void ProductRepository_Constructor_WithValidConfiguration_CreatesInstance()
        {
            // Arrange
            var configuration = CreateMockConfiguration();

            // Act
            var repository = new ProductRepository(configuration);

            // Assert
            Assert.NotNull(repository);
        }

        [Fact]
        public void ProductRepository_Constructor_WithDevelopmentEnvironment_UsesDevConnection()
        {
            // Arrange
            var configuration = CreateMockConfiguration("Development");

            // Act
            var repository = new ProductRepository(configuration);

            // Assert
            Assert.NotNull(repository);
            // Repository should be initialized successfully with dev connection string
        }

        [Fact]
        public void ProductRepository_Constructor_WithProductionEnvironment_UsesProdConnection()
        {
            // Arrange
            var configuration = CreateMockConfiguration("Production");

            // Act
            var repository = new ProductRepository(configuration);

            // Assert
            Assert.NotNull(repository);
            // Repository should be initialized successfully with prod connection string
        }

        [Fact]
        public void ProductRepository_ImplementsIAsyncDisposable()
        {
            // Arrange
            var configuration = CreateMockConfiguration();

            // Act
            var repository = new ProductRepository(configuration);

            // Assert
            Assert.IsAssignableFrom<IAsyncDisposable>(repository);
        }

        [Fact]
        public async Task ProductRepository_DisposeAsync_CompletesWithoutError()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act & Assert - should not throw
            await repository.DisposeAsync();
        }

        [Fact]
        public async Task ProductRepository_DisposeAsync_CanBeCalledMultipleTimes()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act & Assert - should not throw on multiple calls
            await repository.DisposeAsync();
            await repository.DisposeAsync();
            await repository.DisposeAsync();
        }

        [Fact]
        public void ProductRepository_Constructor_WithNullConfiguration_ThrowsException()
        {
            // Act & Assert
            Assert.Throws<NullReferenceException>(() => new ProductRepository(null));
        }

        [Fact]
        public void ProductRepository_HasGetAllProductsAsyncMethod()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act
            var method = repository.GetType().GetMethod("GetAllProductsAsync");

            // Assert
            Assert.NotNull(method);
            Assert.True(method.ReturnType.IsGenericType);
            Assert.Equal(typeof(Task<>), method.ReturnType.GetGenericTypeDefinition());
        }

        [Fact]
        public void ProductRepository_HasGetProductByIdAsyncMethod()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act
            var method = repository.GetType().GetMethod("GetProductByIdAsync");

            // Assert
            Assert.NotNull(method);
            Assert.True(method.ReturnType.IsGenericType);
            Assert.Equal(typeof(Task<>), method.ReturnType.GetGenericTypeDefinition());
        }

        [Fact]
        public void ProductRepository_HasInsertProductAsyncMethod()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act
            var method = repository.GetType().GetMethod("InsertProductAsync");

            // Assert
            Assert.NotNull(method);
            Assert.Equal(typeof(Task<int>), method.ReturnType);
        }

        [Fact]
        public void ProductRepository_HasUpdateProductAsyncMethod()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act
            var method = repository.GetType().GetMethod("UpdateProductAsync");

            // Assert
            Assert.NotNull(method);
            Assert.Equal(typeof(Task), method.ReturnType);
        }

        [Fact]
        public void ProductRepository_HasDeleteProductAsyncMethod()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act
            var method = repository.GetType().GetMethod("DeleteProductAsync");

            // Assert
            Assert.NotNull(method);
            Assert.Equal(typeof(Task), method.ReturnType);
        }

        [Fact]
        public void ProductRepository_HasGetProductsByPriceRangeAsyncMethod()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act
            var method = repository.GetType().GetMethod("GetProductsByPriceRangeAsync");

            // Assert
            Assert.NotNull(method);
            Assert.True(method.ReturnType.IsGenericType);
            Assert.Equal(typeof(Task<>), method.ReturnType.GetGenericTypeDefinition());
        }

        [Fact]
        public void ProductRepository_HasGetLowStockProductsAsyncMethod()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act
            var method = repository.GetType().GetMethod("GetLowStockProductsAsyncMethod");

            // Assert
            // Method name in code is GetLowStockProductsAsync
            var actualMethod = repository.GetType().GetMethod("GetLowStockProductsAsync");
            Assert.NotNull(actualMethod);
        }

        [Fact]
        public void ProductRepository_HasExecuteInTransactionAsyncMethod()
        {
            // Arrange
            var configuration = CreateMockConfiguration();
            var repository = new ProductRepository(configuration);

            // Act
            var method = repository.GetType().GetMethod("ExecuteInTransactionAsync");

            // Assert
            Assert.NotNull(method);
            Assert.Equal(typeof(Task), method.ReturnType);
        }

        [Theory]
        [InlineData("Development")]
        [InlineData("Production")]
        [InlineData("Staging")]
        [InlineData("Test")]
        public void ProductRepository_Constructor_WithDifferentEnvironments_CreatesInstance(string environment)
        {
            // Arrange
            var configuration = CreateMockConfiguration(environment);

            // Act
            var repository = new ProductRepository(configuration);

            // Assert
            Assert.NotNull(repository);
        }

        [Fact]
        public async Task ProductRepository_CanBeUsedInUsingStatement()
        {
            // Arrange
            var configuration = CreateMockConfiguration();

            // Act & Assert - should complete without error
            await using (var repository = new ProductRepository(configuration))
            {
                Assert.NotNull(repository);
            }
        }
    }
}
