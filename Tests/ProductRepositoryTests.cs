using System;
using System.Threading.Tasks;
using Xunit;
using Moq;
using Microsoft.Extensions.Configuration;
using AdoCore.DataAccess;

namespace AdoCore.Tests
{
    public class ProductRepositoryTests
    {
        private readonly Mock<IConfiguration> _mockConfiguration;
        private readonly Mock<IConfigurationSection> _mockConnectionSection;

        public ProductRepositoryTests()
        {
            _mockConfiguration = new Mock<IConfiguration>();
            _mockConnectionSection = new Mock<IConfigurationSection>();
        }

        [Fact]
        public void ProductRepository_Constructor_InitializesWithConfiguration()
        {
            // Arrange
            _mockConfiguration.Setup(c => c["Environment"]).Returns("Development");
            _mockConnectionSection.Setup(s => s.Value).Returns("Host=localhost;Port=5432;Database=testdb;Username=test;Password=test");
            _mockConfiguration.Setup(c => c.GetSection("ConnectionStrings:DevConnection")).Returns(_mockConnectionSection.Object);

            // Act & Assert - Should not throw
            var repository = new ProductRepository(_mockConfiguration.Object);
            Assert.NotNull(repository);
        }

        [Fact]
        public void ProductRepository_Constructor_UsesDevConnectionForDevelopment()
        {
            // Arrange
            var devConnection = "Host=localhost;Port=5432;Database=devdb;Username=dev;Password=dev";
            _mockConfiguration.Setup(c => c["Environment"]).Returns("Development");
            _mockConfiguration.Setup(c => c.GetConnectionString("DevConnection")).Returns(devConnection);

            // Act
            var repository = new ProductRepository(_mockConfiguration.Object);

            // Assert
            Assert.NotNull(repository);
            _mockConfiguration.Verify(c => c.GetConnectionString("DevConnection"), Times.Once);
        }

        [Fact]
        public void ProductRepository_Constructor_UsesProdConnectionForProduction()
        {
            // Arrange
            var prodConnection = "Host=prodserver;Port=5432;Database=proddb;Username=prod;Password=prod";
            _mockConfiguration.Setup(c => c["Environment"]).Returns("Production");
            _mockConfiguration.Setup(c => c.GetConnectionString("ProdConnection")).Returns(prodConnection);

            // Act
            var repository = new ProductRepository(_mockConfiguration.Object);

            // Assert
            Assert.NotNull(repository);
            _mockConfiguration.Verify(c => c.GetConnectionString("ProdConnection"), Times.Once);
        }

        [Fact]
        public void ProductRepository_Implements_IAsyncDisposable()
        {
            // Arrange
            _mockConfiguration.Setup(c => c["Environment"]).Returns("Development");
            _mockConfiguration.Setup(c => c.GetConnectionString("DevConnection")).Returns("Host=localhost;Database=test");

            // Act
            var repository = new ProductRepository(_mockConfiguration.Object);

            // Assert
            Assert.IsAssignableFrom<IAsyncDisposable>(repository);
        }
    }
}
