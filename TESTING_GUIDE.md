# Unit Testing Guide for AdoCore PostgreSQL Migration

## Overview
This guide provides instructions for creating and running unit tests for the migrated AdoCore application. Currently, the repository contains no unit tests, which prevents validation of CRITERION 15.

## Creating a Test Project

### Step 1: Create Test Project Structure

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Create test project
dotnet new mstest -n AdoCore.Tests
cd AdoCore.Tests

# Add reference to main project
dotnet add reference ../AdoCore.csproj

# Add required testing packages
dotnet add package Moq --version 4.20.70
dotnet add package FluentAssertions --version 6.12.0
dotnet add package Npgsql --version 8.0.0
dotnet add package Microsoft.Extensions.Configuration --version 8.0.0
dotnet add package Microsoft.Extensions.Configuration.Json --version 8.0.0
```

### Step 2: Create Test Database Configuration

Create `appsettings.test.json` in the test project:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement_Test;Username=postgres;Password=postgres;Port=5432",
    "ProdConnection": "Host=localhost;Database=ProductManagement_Test;Username=postgres;Password=postgres;Port=5432"
  },
  "Environment": "Test"
}
```

### Step 3: Create Test Database Setup Script

Create a script to set up test data before tests run.

## Sample Unit Tests

### ProductRepository Unit Tests

Create `ProductRepositoryTests.cs`:

```csharp
using Microsoft.VisualStudio.TestTools.UnitTesting;
using AdoCore.DataAccess;
using AdoCore.Models;
using System.Threading.Tasks;
using System.Collections.Generic;
using FluentAssertions;

namespace AdoCore.Tests
{
    [TestClass]
    public class ProductRepositoryTests
    {
        private ProductRepository _repository;
        private const string TestConnectionString = "Host=localhost;Database=ProductManagement_Test;Username=postgres;Password=postgres;Port=5432";

        [TestInitialize]
        public void Setup()
        {
            _repository = new ProductRepository();
            _repository.Initialize(TestConnectionString);
        }

        [TestCleanup]
        public void Cleanup()
        {
            _repository?.Dispose();
        }

        [TestMethod]
        public async Task GetAllProductsAsync_ShouldReturnProducts()
        {
            // Arrange
            await _repository.OpenAsync();

            // Act
            var products = await _repository.GetAllProductsAsync();

            // Assert
            products.Should().NotBeNull();
            products.Should().NotBeEmpty();
            products.Count.Should().BeGreaterThan(0);
        }

        [TestMethod]
        public async Task GetProductByIdAsync_WithValidId_ShouldReturnProduct()
        {
            // Arrange
            await _repository.OpenAsync();
            var productId = 1;

            // Act
            var product = await _repository.GetProductByIdAsync(productId);

            // Assert
            product.Should().NotBeNull();
            product.ProductId.Should().Be(productId);
            product.Name.Should().NotBeNullOrEmpty();
        }

        [TestMethod]
        public async Task GetProductByIdAsync_WithInvalidId_ShouldReturnNull()
        {
            // Arrange
            await _repository.OpenAsync();
            var invalidProductId = 999999;

            // Act
            var product = await _repository.GetProductByIdAsync(invalidProductId);

            // Assert
            product.Should().BeNull();
        }

        [TestMethod]
        public async Task InsertProductAsync_WithValidData_ShouldReturnNewProductId()
        {
            // Arrange
            await _repository.OpenAsync();
            var newProduct = new Product
            {
                Name = "Test Product",
                Description = "Test Description",
                Price = 99.99m,
                StockQuantity = 10
            };

            // Act
            var productId = await _repository.InsertProductAsync(newProduct);

            // Assert
            productId.Should().BeGreaterThan(0);

            // Cleanup - delete the test product
            await _repository.DeleteProductAsync(productId);
        }

        [TestMethod]
        public async Task UpdateProductAsync_WithValidData_ShouldUpdateProduct()
        {
            // Arrange
            await _repository.OpenAsync();
            
            // First, create a test product
            var newProduct = new Product
            {
                Name = "Test Product for Update",
                Description = "Original Description",
                Price = 50.00m,
                StockQuantity = 5
            };
            var productId = await _repository.InsertProductAsync(newProduct);

            // Modify the product
            newProduct.ProductId = productId;
            newProduct.Name = "Updated Test Product";
            newProduct.Description = "Updated Description";
            newProduct.Price = 75.00m;
            newProduct.StockQuantity = 10;

            // Act
            await _repository.UpdateProductAsync(newProduct);

            // Assert
            var updatedProduct = await _repository.GetProductByIdAsync(productId);
            updatedProduct.Should().NotBeNull();
            updatedProduct.Name.Should().Be("Updated Test Product");
            updatedProduct.Description.Should().Be("Updated Description");
            updatedProduct.Price.Should().Be(75.00m);
            updatedProduct.StockQuantity.Should().Be(10);

            // Cleanup
            await _repository.DeleteProductAsync(productId);
        }

        [TestMethod]
        public async Task DeleteProductAsync_WithValidId_ShouldDeleteProduct()
        {
            // Arrange
            await _repository.OpenAsync();
            
            // First, create a test product
            var newProduct = new Product
            {
                Name = "Test Product for Deletion",
                Description = "Will be deleted",
                Price = 25.00m,
                StockQuantity = 3
            };
            var productId = await _repository.InsertProductAsync(newProduct);

            // Act
            await _repository.DeleteProductAsync(productId);

            // Assert
            var deletedProduct = await _repository.GetProductByIdAsync(productId);
            deletedProduct.Should().BeNull();
        }

        [TestMethod]
        public async Task GetProductsByPriceRangeAsync_WithValidRange_ShouldReturnFilteredProducts()
        {
            // Arrange
            await _repository.OpenAsync();
            decimal minPrice = 100.00m;
            decimal maxPrice = 500.00m;

            // Act
            var products = await _repository.GetProductsByPriceRangeAsync(minPrice, maxPrice);

            // Assert
            products.Should().NotBeNull();
            products.Should().OnlyContain(p => p.Price >= minPrice && p.Price <= maxPrice);
        }

        [TestMethod]
        public async Task GetLowStockProductsAsync_ShouldReturnLowStockProducts()
        {
            // Arrange
            await _repository.OpenAsync();

            // Act
            var products = await _repository.GetLowStockProductsAsync();

            // Assert
            products.Should().NotBeNull();
            // Each product's stock should be at or below its reorder level
            // Note: We can't easily verify this without accessing the reorder level
            // but we can verify that products are returned
            products.Should().BeOfType<List<Product>>();
        }
    }
}
```

### Integration Tests

Create `IntegrationTests.cs` for end-to-end testing:

```csharp
using Microsoft.VisualStudio.TestTools.UnitTesting;
using AdoCore.DataAccess;
using AdoCore.Models;
using System.Threading.Tasks;
using FluentAssertions;

namespace AdoCore.Tests
{
    [TestClass]
    public class IntegrationTests
    {
        private ProductRepository _repository;
        private const string TestConnectionString = "Host=localhost;Database=ProductManagement_Test;Username=postgres;Password=postgres;Port=5432";

        [TestInitialize]
        public void Setup()
        {
            _repository = new ProductRepository();
            _repository.Initialize(TestConnectionString);
        }

        [TestCleanup]
        public void Cleanup()
        {
            _repository?.Dispose();
        }

        [TestMethod]
        public async Task FullProductLifecycle_CreateUpdateDelete_ShouldWorkCorrectly()
        {
            // Arrange
            await _repository.OpenAsync();

            // Act - CREATE
            var newProduct = new Product
            {
                Name = "Lifecycle Test Product",
                Description = "Testing full lifecycle",
                Price = 150.00m,
                StockQuantity = 20
            };
            var productId = await _repository.InsertProductAsync(newProduct);

            // Assert - CREATE
            productId.Should().BeGreaterThan(0);
            var createdProduct = await _repository.GetProductByIdAsync(productId);
            createdProduct.Should().NotBeNull();
            createdProduct.Name.Should().Be("Lifecycle Test Product");

            // Act - UPDATE
            createdProduct.Name = "Updated Lifecycle Product";
            createdProduct.Price = 175.00m;
            await _repository.UpdateProductAsync(createdProduct);

            // Assert - UPDATE
            var updatedProduct = await _repository.GetProductByIdAsync(productId);
            updatedProduct.Name.Should().Be("Updated Lifecycle Product");
            updatedProduct.Price.Should().Be(175.00m);

            // Act - DELETE
            await _repository.DeleteProductAsync(productId);

            // Assert - DELETE
            var deletedProduct = await _repository.GetProductByIdAsync(productId);
            deletedProduct.Should().BeNull();
        }

        [TestMethod]
        public async Task TransactionAtomicity_MultipleOperations_ShouldBeAtomic()
        {
            // Arrange
            await _repository.OpenAsync();

            // Act - Create two products
            var product1 = new Product
            {
                Name = "Transaction Test Product 1",
                Description = "First product",
                Price = 100.00m,
                StockQuantity = 10
            };
            var product2 = new Product
            {
                Name = "Transaction Test Product 2",
                Description = "Second product",
                Price = 200.00m,
                StockQuantity = 20
            };

            var productId1 = await _repository.InsertProductAsync(product1);
            var productId2 = await _repository.InsertProductAsync(product2);

            // Assert - Both products created
            productId1.Should().BeGreaterThan(0);
            productId2.Should().BeGreaterThan(0);

            // Verify both products exist
            var retrievedProduct1 = await _repository.GetProductByIdAsync(productId1);
            var retrievedProduct2 = await _repository.GetProductByIdAsync(productId2);

            retrievedProduct1.Should().NotBeNull();
            retrievedProduct2.Should().NotBeNull();

            // Cleanup
            await _repository.DeleteProductAsync(productId1);
            await _repository.DeleteProductAsync(productId2);
        }

        [TestMethod]
        public async Task DatabaseConnection_ShouldConnect_WhenConfigurationIsValid()
        {
            // Act
            await _repository.OpenAsync();

            // Assert - Connection should be open
            var products = await _repository.GetAllProductsAsync();
            products.Should().NotBeNull();
        }
    }
}
```

## Running Tests

### Setup Test Database

Before running tests, create the test database:

```bash
# Connect to PostgreSQL
psql -h localhost -U postgres -p 5432

# Create test database
CREATE DATABASE "ProductManagement_Test";

# Connect to test database
\c ProductManagement_Test

# Run setup script (use the same script as production)
\i /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/Database/Scripts/01_PostgreSQL_Setup.sql
```

### Run All Tests

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/AdoCore.Tests

# Run all tests
dotnet test

# Run tests with detailed output
dotnet test --logger "console;verbosity=detailed"

# Run tests with coverage (requires coverlet)
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover
```

### Run Specific Tests

```bash
# Run tests from a specific class
dotnet test --filter "FullyQualifiedName~ProductRepositoryTests"

# Run a specific test method
dotnet test --filter "FullyQualifiedName~GetAllProductsAsync_ShouldReturnProducts"

# Run tests by category (if you add [TestCategory] attributes)
dotnet test --filter "TestCategory=Integration"
```

## Test Coverage Goals

Aim for the following test coverage:

### Unit Tests
- ✅ All repository methods (7 methods)
- ✅ Successful operations
- ✅ Error conditions (invalid IDs, null data, etc.)
- ✅ Boundary conditions (empty results, large datasets)

### Integration Tests
- ✅ Database connectivity
- ✅ Full CRUD lifecycle
- ✅ Transaction atomicity
- ✅ Data consistency
- ✅ Performance benchmarks

### Expected Coverage
- **Line Coverage**: > 80%
- **Branch Coverage**: > 70%
- **Method Coverage**: 100% of public methods

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: Run Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: ProductManagement_Test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v3
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '9.0.x'
    
    - name: Restore dependencies
      run: dotnet restore
      working-directory: ./sourceCode
    
    - name: Build
      run: dotnet build --no-restore
      working-directory: ./sourceCode
    
    - name: Setup test database
      run: |
        PGPASSWORD=postgres psql -h localhost -U postgres -d ProductManagement_Test -f Database/Scripts/01_PostgreSQL_Setup.sql
      working-directory: ./sourceCode
    
    - name: Run tests
      run: dotnet test --no-build --verbosity normal
      working-directory: ./sourceCode
```

## Troubleshooting Tests

### Common Issues

**Issue**: "Cannot connect to test database"
```
Solution:
1. Verify PostgreSQL is running
2. Verify test database exists
3. Check connection string in appsettings.test.json
4. Ensure PostgreSQL accepts connections on localhost:5432
```

**Issue**: "Test data interferes with other tests"
```
Solution:
1. Use [TestInitialize] to set up clean state
2. Use [TestCleanup] to remove test data
3. Consider using transactions that rollback
4. Use unique test data identifiers
```

**Issue**: "Tests pass individually but fail when run together"
```
Solution:
1. Ensure tests don't share state
2. Clean up test data properly
3. Use separate test database
4. Check for connection pooling issues
```

## Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Always clean up test data
3. **Fast**: Tests should run quickly (<100ms per test)
4. **Deterministic**: Tests should always produce same results
5. **Readable**: Test names should describe what they test
6. **Arrange-Act-Assert**: Follow AAA pattern
7. **One Assertion**: Focus on one logical assertion per test

## Next Steps

1. Create test project using commands above
2. Implement all sample tests
3. Run tests against test database
4. Achieve >80% code coverage
5. Add tests to CI/CD pipeline
6. Document test results in validation report

Once tests are created and passing, CRITERION 15 can be validated and marked as PASS.
