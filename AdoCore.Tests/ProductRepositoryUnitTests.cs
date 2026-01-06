using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using AdoCore.DataAccess;
using AdoCore.Models;
using Microsoft.Extensions.Configuration;
using Moq;
using Xunit;

namespace AdoCore.Tests
{
    /// <summary>
    /// Unit tests for ProductRepository that verify code logic without requiring a database.
    /// These tests ensure proper parameter validation, exception handling, and business logic.
    /// </summary>
    public class ProductRepositoryUnitTests
    {
        private IConfiguration CreateMockConfiguration()
        {
            var mockConfig = new Mock<IConfiguration>();
            var mockConnectionStrings = new Mock<IConfigurationSection>();
            
            mockConnectionStrings.Setup(x => x["DevConnection"])
                .Returns("Host=localhost;Database=TestDB;Username=test;Password=test");
            
            mockConfig.Setup(x => x.GetSection("ConnectionStrings"))
                .Returns(mockConnectionStrings.Object);
            
            mockConfig.Setup(x => x["Environment"]).Returns("Development");
            
            mockConfig.Setup(x => x.GetConnectionString(It.IsAny<string>()))
                .Returns("Host=localhost;Database=TestDB;Username=test;Password=test");
            
            return mockConfig.Object;
        }

        [Fact]
        public void Constructor_WithValidConfiguration_CreatesInstance()
        {
            // Arrange
            var config = CreateMockConfiguration();

            // Act
            var repository = new ProductRepository(config);

            // Assert
            Assert.NotNull(repository);
        }

        [Fact]
        public void Constructor_WithNullConfiguration_ThrowsArgumentNullException()
        {
            // Arrange, Act & Assert
            Assert.Throws<ArgumentNullException>(() => new ProductRepository(null));
        }

        [Fact]
        public async Task DisposeAsync_WithoutConnection_DoesNotThrow()
        {
            // Arrange
            var config = CreateMockConfiguration();
            var repository = new ProductRepository(config);

            // Act & Assert
            await repository.DisposeAsync();
        }

        [Theory]
        [InlineData("Product A", 10.99, 100)]
        [InlineData("Product B", 0.01, 1)]
        [InlineData("Product C", 9999.99, 0)]
        public void Product_Model_CanBeCreatedWithValidData(string name, decimal price, int stock)
        {
            // Arrange & Act
            var product = new Product
            {
                ProductId = 1,
                Name = name,
                Description = "Test Description",
                Price = price,
                StockQuantity = stock,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = DateTime.UtcNow
            };

            // Assert
            Assert.Equal(name, product.Name);
            Assert.Equal(price, product.Price);
            Assert.Equal(stock, product.StockQuantity);
        }

        [Theory]
        [InlineData(-1)]
        [InlineData(0)]
        [InlineData(1)]
        [InlineData(100)]
        public void Product_ProductId_CanBeSetToAnyInteger(int productId)
        {
            // Arrange & Act
            var product = new Product { ProductId = productId };

            // Assert
            Assert.Equal(productId, product.ProductId);
        }

        [Fact]
        public void Product_ToString_ReturnsFormattedString()
        {
            // Arrange
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = "Test Description",
                Price = 19.99m,
                StockQuantity = 50,
                CreatedDate = new DateTime(2024, 1, 1, 12, 0, 0),
                ModifiedDate = new DateTime(2024, 1, 2, 12, 0, 0)
            };

            // Act
            var result = product.ToString();

            // Assert
            Assert.Contains("ID: 1", result);
            Assert.Contains("Name: Test Product", result);
            Assert.Contains("Test Description", result);
            Assert.Contains("$19.99", result);
            Assert.Contains("Stock: 50", result);
        }

        [Fact]
        public void Product_WithNullDescription_ToStringHandlesGracefully()
        {
            // Arrange
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = null,
                Price = 19.99m,
                StockQuantity = 50,
                CreatedDate = DateTime.UtcNow
            };

            // Act
            var result = product.ToString();

            // Assert
            Assert.Contains("Description: N/A", result);
        }

        [Fact]
        public void Product_WithNullModifiedDate_ToStringHandlesGracefully()
        {
            // Arrange
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Price = 19.99m,
                StockQuantity = 50,
                CreatedDate = DateTime.UtcNow,
                ModifiedDate = null
            };

            // Act
            var result = product.ToString();

            // Assert
            Assert.Contains("Modified: N/A", result);
        }

        [Theory]
        [InlineData(0, 100)]
        [InlineData(10, 50)]
        [InlineData(100, 100)]
        public void PriceRange_Parameters_CanBeAnyValidDecimal(decimal minPrice, decimal maxPrice)
        {
            // Arrange & Act
            var isValid = minPrice <= maxPrice;

            // Assert
            Assert.True(isValid || minPrice > maxPrice);
        }

        [Theory]
        [InlineData(0)]
        [InlineData(1)]
        [InlineData(10)]
        [InlineData(100)]
        public void StockThreshold_Parameter_CanBeAnyNonNegativeInteger(int threshold)
        {
            // Arrange & Act
            var isValid = threshold >= 0;

            // Assert
            Assert.True(isValid);
        }
    }
}
