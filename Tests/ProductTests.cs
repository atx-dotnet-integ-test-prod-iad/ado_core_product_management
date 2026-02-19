using System;
using Xunit;
using AdoCore.Models;

namespace AdoCore.Tests
{
    public class ProductTests
    {
        [Fact]
        public void Product_Creation_SetsPropertiesCorrectly()
        {
            // Arrange & Act
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = "Test Description",
                Price = 19.99m,
                StockQuantity = 100,
                CreatedDate = DateTime.Now,
                ModifiedDate = DateTime.Now
            };

            // Assert
            Assert.Equal(1, product.ProductId);
            Assert.Equal("Test Product", product.Name);
            Assert.Equal("Test Description", product.Description);
            Assert.Equal(19.99m, product.Price);
            Assert.Equal(100, product.StockQuantity);
            Assert.NotNull(product.CreatedDate);
            Assert.NotNull(product.ModifiedDate);
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
                StockQuantity = 100,
                CreatedDate = new DateTime(2024, 1, 1),
                ModifiedDate = new DateTime(2024, 1, 2)
            };

            // Act
            var result = product.ToString();

            // Assert
            Assert.Contains("ID: 1", result);
            Assert.Contains("Name: Test Product", result);
            Assert.Contains("Description: Test Description", result);
            Assert.Contains("Price: $19.99", result);
            Assert.Contains("Stock: 100", result);
        }

        [Fact]
        public void Product_WithNullDescription_ToString_ShowsNA()
        {
            // Arrange
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = null,
                Price = 19.99m,
                StockQuantity = 100,
                CreatedDate = new DateTime(2024, 1, 1)
            };

            // Act
            var result = product.ToString();

            // Assert
            Assert.Contains("Description: N/A", result);
        }

        [Fact]
        public void Product_WithNullModifiedDate_ToString_ShowsNA()
        {
            // Arrange
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = "Test",
                Price = 19.99m,
                StockQuantity = 100,
                CreatedDate = new DateTime(2024, 1, 1),
                ModifiedDate = null
            };

            // Act
            var result = product.ToString();

            // Assert
            Assert.Contains("Modified: N/A", result);
        }

        [Theory]
        [InlineData(0)]
        [InlineData(10)]
        [InlineData(1000)]
        public void Product_StockQuantity_AcceptsValidValues(int stockQuantity)
        {
            // Arrange & Act
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Price = 19.99m,
                StockQuantity = stockQuantity,
                CreatedDate = DateTime.Now
            };

            // Assert
            Assert.Equal(stockQuantity, product.StockQuantity);
        }

        [Theory]
        [InlineData(0.01)]
        [InlineData(10.50)]
        [InlineData(999.99)]
        public void Product_Price_AcceptsValidValues(decimal price)
        {
            // Arrange & Act
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Price = price,
                StockQuantity = 100,
                CreatedDate = DateTime.Now
            };

            // Assert
            Assert.Equal(price, product.Price);
        }
    }
}
