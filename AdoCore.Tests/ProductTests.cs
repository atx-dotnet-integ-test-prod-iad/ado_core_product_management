using System;
using Xunit;
using AdoCore.Models;

namespace AdoCore.Tests
{
    /// <summary>
    /// Unit tests for the Product model class.
    /// Tests validate property access, initialization, and string representation.
    /// </summary>
    public class ProductTests
    {
        [Fact]
        public void Product_DefaultConstructor_SetsPropertiesToDefault()
        {
            // Arrange & Act
            var product = new Product();

            // Assert
            Assert.Equal(0, product.ProductId);
            Assert.Null(product.Name);
            Assert.Null(product.Description);
            Assert.Equal(0, product.Price);
            Assert.Equal(0, product.StockQuantity);
            Assert.Equal(DateTime.MinValue, product.CreatedDate);
            Assert.Null(product.ModifiedDate);
        }

        [Fact]
        public void Product_PropertySetters_SetValuesCorrectly()
        {
            // Arrange
            var product = new Product();
            var now = DateTime.Now;

            // Act
            product.ProductId = 1;
            product.Name = "Test Product";
            product.Description = "Test Description";
            product.Price = 99.99m;
            product.StockQuantity = 50;
            product.CreatedDate = now;
            product.ModifiedDate = now.AddDays(1);

            // Assert
            Assert.Equal(1, product.ProductId);
            Assert.Equal("Test Product", product.Name);
            Assert.Equal("Test Description", product.Description);
            Assert.Equal(99.99m, product.Price);
            Assert.Equal(50, product.StockQuantity);
            Assert.Equal(now, product.CreatedDate);
            Assert.Equal(now.AddDays(1), product.ModifiedDate);
        }

        [Fact]
        public void Product_ToString_WithAllProperties_ReturnsFormattedString()
        {
            // Arrange
            var createdDate = new DateTime(2024, 1, 1, 10, 0, 0);
            var modifiedDate = new DateTime(2024, 1, 2, 10, 0, 0);
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = "Test Description",
                Price = 99.99m,
                StockQuantity = 50,
                CreatedDate = createdDate,
                ModifiedDate = modifiedDate
            };

            // Act
            var result = product.ToString();

            // Assert
            Assert.Contains("ID: 1", result);
            Assert.Contains("Name: Test Product", result);
            Assert.Contains("Description: Test Description", result);
            Assert.Contains("Price: $99.99", result);
            Assert.Contains("Stock: 50", result);
            Assert.Contains("Created:", result);
            Assert.Contains("Modified:", result);
        }

        [Fact]
        public void Product_ToString_WithNullDescription_ShowsNA()
        {
            // Arrange
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Description = null,
                Price = 99.99m,
                StockQuantity = 50,
                CreatedDate = DateTime.Now
            };

            // Act
            var result = product.ToString();

            // Assert
            Assert.Contains("Description: N/A", result);
        }

        [Fact]
        public void Product_ToString_WithNullModifiedDate_ShowsNA()
        {
            // Arrange
            var product = new Product
            {
                ProductId = 1,
                Name = "Test Product",
                Price = 99.99m,
                StockQuantity = 50,
                CreatedDate = DateTime.Now,
                ModifiedDate = null
            };

            // Act
            var result = product.ToString();

            // Assert
            Assert.Contains("Modified: N/A", result);
        }

        [Theory]
        [InlineData(0)]
        [InlineData(1)]
        [InlineData(999)]
        [InlineData(int.MaxValue)]
        public void Product_ProductId_AcceptsValidValues(int productId)
        {
            // Arrange
            var product = new Product();

            // Act
            product.ProductId = productId;

            // Assert
            Assert.Equal(productId, product.ProductId);
        }

        [Theory]
        [InlineData(0)]
        [InlineData(0.01)]
        [InlineData(99.99)]
        [InlineData(9999.99)]
        public void Product_Price_AcceptsValidDecimalValues(double priceValue)
        {
            // Arrange
            var product = new Product();
            var price = (decimal)priceValue;

            // Act
            product.Price = price;

            // Assert
            Assert.Equal(price, product.Price);
        }

        [Theory]
        [InlineData(0)]
        [InlineData(1)]
        [InlineData(100)]
        [InlineData(int.MaxValue)]
        public void Product_StockQuantity_AcceptsValidValues(int stock)
        {
            // Arrange
            var product = new Product();

            // Act
            product.StockQuantity = stock;

            // Assert
            Assert.Equal(stock, product.StockQuantity);
        }

        [Fact]
        public void Product_Name_AcceptsEmptyString()
        {
            // Arrange
            var product = new Product();

            // Act
            product.Name = string.Empty;

            // Assert
            Assert.Equal(string.Empty, product.Name);
        }

        [Fact]
        public void Product_Description_AcceptsNullValue()
        {
            // Arrange
            var product = new Product { Description = "Initial" };

            // Act
            product.Description = null;

            // Assert
            Assert.Null(product.Description);
        }
    }
}
