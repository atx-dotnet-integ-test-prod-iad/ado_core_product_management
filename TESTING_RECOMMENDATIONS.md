# Testing Recommendations for PostgreSQL Migration

## Overview
This document provides recommendations for implementing comprehensive testing for the AdoCore application after migration from SQL Server to PostgreSQL. Since no unit tests or integration tests existed in the original application, this represents a critical gap that should be addressed post-migration.

## Current State
- **Unit Tests:** None exist in the codebase
- **Integration Tests:** None exist in the codebase
- **Manual Testing:** Required for validation
- **Code Status:** Compiles successfully with 0 errors, 10 pre-existing nullable reference warnings

## Testing Strategy

### Phase 1: Database Infrastructure Setup

Before any testing can begin, set up the PostgreSQL database:

1. **Install PostgreSQL Server**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql postgresql-contrib
   
   # macOS
   brew install postgresql
   
   # Docker (Recommended for testing)
   docker run --name postgres-adocore -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16
   ```

2. **Create Database and Schema**
   ```sql
   -- Connect to PostgreSQL
   psql -U postgres
   
   -- Create database
   CREATE DATABASE ProductManagement;
   
   -- Connect to the database
   \c ProductManagement
   
   -- Create tables (example schema based on application code)
   CREATE TABLE Products (
       ProductId SERIAL PRIMARY KEY,
       Name VARCHAR(200) NOT NULL,
       Description TEXT,
       Price DECIMAL(18,2) NOT NULL,
       StockQuantity INTEGER NOT NULL DEFAULT 0,
       CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       ModifiedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
   );
   
   CREATE TABLE ProductHistory (
       HistoryId SERIAL PRIMARY KEY,
       ProductId INTEGER NOT NULL,
       Action VARCHAR(50) NOT NULL,
       OldPrice DECIMAL(18,2),
       NewPrice DECIMAL(18,2),
       OldStock INTEGER,
       NewStock INTEGER,
       ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE
   );
   
   CREATE TABLE ProductStats (
       StatId INTEGER PRIMARY KEY,
       TotalProducts INTEGER NOT NULL DEFAULT 0,
       AveragePrice DECIMAL(18,2) NOT NULL DEFAULT 0,
       LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
   );
   
   -- Initialize ProductStats
   INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, LastUpdated)
   VALUES (1, 0, 0, CURRENT_TIMESTAMP);
   
   -- Create indexes for performance
   CREATE INDEX idx_products_price ON Products(Price);
   CREATE INDEX idx_products_stock ON Products(StockQuantity);
   CREATE INDEX idx_producthistory_productid ON ProductHistory(ProductId);
   CREATE INDEX idx_producthistory_actiondate ON ProductHistory(ActionDate);
   ```

### Phase 2: Manual Integration Testing

Execute each repository method manually to verify functionality:

#### Test 1: Connection Test
```csharp
// Verify the application can connect to PostgreSQL
var repository = new ProductRepository(configuration);
await repository.TestConnectionAsync(); // Implement if not exists
```
**Expected Result:** Successful connection without exceptions

#### Test 2: Insert Product (InsertProductAsync)
```csharp
var product = new Product
{
    Name = "Test Product",
    Description = "This is a test product",
    Price = 99.99M,
    StockQuantity = 50
};

int newProductId = await repository.InsertProductAsync(product);
```
**Expected Results:**
- Returns valid ProductId > 0
- Product exists in Products table
- ProductHistory record created with Action='INSERT'
- ProductStats.TotalProducts incremented by 1
- ProductStats.AveragePrice updated correctly

#### Test 3: Get All Products (GetAllProductsAsync)
```csharp
var products = await repository.GetAllProductsAsync();
```
**Expected Results:**
- Returns list of products
- Each product has PriceCategory calculated correctly
- PricePercentageOfAverage calculated correctly
- Products sorted by price category and name

#### Test 4: Get Product By ID (GetProductByIdAsync)
```csharp
var product = await repository.GetProductByIdAsync(newProductId);
```
**Expected Results:**
- Returns correct product
- PriceChangePercentage calculated if previous price exists
- Returns null for non-existent IDs

#### Test 5: Update Product (UpdateProductAsync)
```csharp
product.Name = "Updated Test Product";
product.Price = 149.99M;
product.StockQuantity = 75;

await repository.UpdateProductAsync(product);
```
**Expected Results:**
- Product updated in database
- ModifiedDate updated to current timestamp
- ProductHistory record created with Action='UPDATE'
- Old and new prices/stock recorded in history
- ProductStats.AveragePrice updated correctly

#### Test 6: Get Products By Price Range (GetProductsByPriceRangeAsync)
```csharp
var products = await repository.GetProductsByPriceRangeAsync(50M, 200M);
```
**Expected Results:**
- Returns only products in price range
- PriceRank calculated correctly
- PricePercentile calculated correctly
- PriceSegment assigned correctly (Budget/Mid-Range/Premium)
- Sorted by PriceRank

#### Test 7: Get Low Stock Products (GetLowStockProductsAsync)
```csharp
var lowStockProducts = await repository.GetLowStockProductsAsync(threshold: 10);
```
**Expected Results:**
- Returns only products with StockQuantity <= threshold
- StockStatus calculated correctly (Critical/Low/Adequate)
- StockPercentageOfAverage calculated correctly
- Sorted by StockQuantity ascending

#### Test 8: Delete Product (DeleteProductAsync)
```csharp
await repository.DeleteProductAsync(newProductId);
```
**Expected Results:**
- Product removed from Products table
- ProductHistory record created with Action='DELETE'
- Old price/stock recorded in history
- ProductStats.TotalProducts decremented by 1
- ProductStats.AveragePrice updated correctly

#### Test 9: Transaction Rollback Test
```csharp
// Test that failed transactions rollback properly
// Attempt an insert with invalid data or force an error
```
**Expected Results:**
- No partial data committed
- Database remains in consistent state
- Appropriate exception thrown

### Phase 3: Implement Automated Integration Tests

Create an integration test project:

```bash
cd /path/to/AdoCore
dotnet new xunit -n AdoCore.IntegrationTests
cd AdoCore.IntegrationTests
dotnet add reference ../AdoCore.csproj
dotnet add package Npgsql
dotnet add package Microsoft.Extensions.Configuration
dotnet add package Microsoft.Extensions.Configuration.Json
```

**Sample Integration Test:**
```csharp
using Xunit;
using AdoCore.DataAccess;
using AdoCore.Models;
using Microsoft.Extensions.Configuration;

namespace AdoCore.IntegrationTests
{
    [Collection("Database")]
    public class ProductRepositoryIntegrationTests : IAsyncLifetime
    {
        private readonly ProductRepository _repository;
        private readonly IConfiguration _configuration;
        
        public ProductRepositoryIntegrationTests()
        {
            _configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.test.json")
                .Build();
                
            _repository = new ProductRepository(_configuration);
        }
        
        public async Task InitializeAsync()
        {
            // Setup: Clean database before each test
            await CleanDatabaseAsync();
        }
        
        public Task DisposeAsync()
        {
            return Task.CompletedTask;
        }
        
        [Fact]
        public async Task InsertProductAsync_ShouldCreateProductAndHistory()
        {
            // Arrange
            var product = new Product
            {
                Name = "Integration Test Product",
                Description = "Test Description",
                Price = 99.99M,
                StockQuantity = 100
            };
            
            // Act
            int productId = await _repository.InsertProductAsync(product);
            
            // Assert
            Assert.True(productId > 0, "Product ID should be greater than 0");
            
            var retrievedProduct = await _repository.GetProductByIdAsync(productId);
            Assert.NotNull(retrievedProduct);
            Assert.Equal(product.Name, retrievedProduct.Name);
            Assert.Equal(product.Price, retrievedProduct.Price);
            Assert.Equal(product.StockQuantity, retrievedProduct.StockQuantity);
        }
        
        [Fact]
        public async Task GetAllProductsAsync_ShouldReturnProductsWithCalculations()
        {
            // Arrange
            await SeedTestDataAsync();
            
            // Act
            var products = await _repository.GetAllProductsAsync();
            
            // Assert
            Assert.NotNull(products);
            Assert.True(products.Count > 0, "Should return at least one product");
            
            foreach (var product in products)
            {
                Assert.NotNull(product.PriceCategory);
                Assert.True(product.PricePercentageOfAverage > 0, 
                    "PricePercentageOfAverage should be calculated");
            }
        }
        
        [Fact]
        public async Task UpdateProductAsync_ShouldUpdateAndCreateHistory()
        {
            // Arrange
            int productId = await CreateTestProductAsync();
            var product = await _repository.GetProductByIdAsync(productId);
            decimal oldPrice = product.Price;
            int oldStock = product.StockQuantity;
            
            // Act
            product.Name = "Updated Name";
            product.Price = 199.99M;
            product.StockQuantity = 50;
            await _repository.UpdateProductAsync(product);
            
            // Assert
            var updatedProduct = await _repository.GetProductByIdAsync(productId);
            Assert.Equal("Updated Name", updatedProduct.Name);
            Assert.Equal(199.99M, updatedProduct.Price);
            Assert.Equal(50, updatedProduct.StockQuantity);
            Assert.True(updatedProduct.ModifiedDate > product.CreatedDate);
        }
        
        [Fact]
        public async Task DeleteProductAsync_ShouldRemoveProductAndUpdateStats()
        {
            // Arrange
            int productId = await CreateTestProductAsync();
            
            // Act
            await _repository.DeleteProductAsync(productId);
            
            // Assert
            var deletedProduct = await _repository.GetProductByIdAsync(productId);
            Assert.Null(deletedProduct);
        }
        
        [Fact]
        public async Task GetProductsByPriceRangeAsync_ShouldReturnOnlyProductsInRange()
        {
            // Arrange
            await SeedTestDataWithVariedPricesAsync();
            
            // Act
            var products = await _repository.GetProductsByPriceRangeAsync(50M, 150M);
            
            // Assert
            Assert.All(products, p => 
            {
                Assert.True(p.Price >= 50M && p.Price <= 150M);
                Assert.NotNull(p.PriceSegment);
                Assert.True(p.PriceRank > 0);
            });
        }
        
        [Fact]
        public async Task GetLowStockProductsAsync_ShouldReturnOnlyLowStockItems()
        {
            // Arrange
            await SeedTestDataWithVariedStockAsync();
            int threshold = 20;
            
            // Act
            var products = await _repository.GetLowStockProductsAsync(threshold);
            
            // Assert
            Assert.All(products, p => 
            {
                Assert.True(p.StockQuantity <= threshold);
                Assert.NotNull(p.StockStatus);
            });
        }
        
        [Fact]
        public async Task Transaction_ShouldRollbackOnFailure()
        {
            // Arrange
            int initialCount = (await _repository.GetAllProductsAsync()).Count;
            
            // Act & Assert
            await Assert.ThrowsAsync<Exception>(async () =>
            {
                // Attempt operation that should fail and rollback
                // Implementation depends on your transaction handling
            });
            
            int finalCount = (await _repository.GetAllProductsAsync()).Count;
            Assert.Equal(initialCount, finalCount);
        }
        
        // Helper methods
        private async Task CleanDatabaseAsync()
        {
            // Delete all test data
            // Implementation depends on your cleanup strategy
        }
        
        private async Task<int> CreateTestProductAsync()
        {
            var product = new Product
            {
                Name = "Test Product",
                Description = "Test",
                Price = 99.99M,
                StockQuantity = 100
            };
            return await _repository.InsertProductAsync(product);
        }
        
        private async Task SeedTestDataAsync()
        {
            // Create multiple test products
        }
        
        private async Task SeedTestDataWithVariedPricesAsync()
        {
            // Create products with different prices
        }
        
        private async Task SeedTestDataWithVariedStockAsync()
        {
            // Create products with different stock levels
        }
    }
}
```

### Phase 4: Performance Testing

Test query performance and connection pooling:

1. **Connection Pool Test**
   - Execute multiple concurrent operations
   - Monitor connection pool metrics
   - Verify proper connection reuse

2. **Query Performance Test**
   - Test with varying data volumes (100, 1000, 10000 records)
   - Measure response times for complex queries (CTEs with window functions)
   - Compare with SQL Server baseline if available

3. **Load Testing**
   - Use tools like Apache JMeter or k6
   - Simulate concurrent users
   - Monitor database CPU and memory usage

### Phase 5: Data Validation Testing

Ensure data integrity and calculation accuracy:

1. **Window Function Validation**
   - Verify AVG(), COUNT(), LAG(), RANK(), PERCENT_RANK() produce expected results
   - Compare results with SQL Server if test data is available

2. **Numeric Precision Validation**
   - Test ROUND() function with various decimal values
   - Verify no precision loss in price calculations

3. **Date/Time Validation**
   - Verify CURRENT_TIMESTAMP produces correct timestamps
   - Test timezone handling if applicable

4. **NULL Handling**
   - Test queries with NULL values
   - Verify CASE expressions handle NULLs correctly

### Phase 6: Edge Case Testing

1. **Empty Database**: Test all queries with no data
2. **Single Record**: Test with exactly one product
3. **Boundary Values**: Test with MIN/MAX prices, stock quantities
4. **Concurrent Modifications**: Test simultaneous updates
5. **Large Datasets**: Test with 100,000+ records
6. **Special Characters**: Test product names with Unicode, quotes, etc.

## Test Environment Setup

### appsettings.test.json
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement_Test;Username=postgres;Password=postgres;Pooling=true"
  }
}
```

### Test Database Isolation
- Use separate test database (ProductManagement_Test)
- Clean database before each test run
- Consider using transactions that rollback after tests

## Continuous Integration

Integrate tests into CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
    - uses: actions/checkout@v2
    - name: Setup .NET
      uses: actions/setup-dotnet@v1
      with:
        dotnet-version: 9.0.x
    - name: Setup Test Database
      run: |
        psql -h localhost -U postgres -c "CREATE DATABASE ProductManagement_Test;"
        # Run schema creation scripts
    - name: Run Integration Tests
      run: dotnet test
```

## Success Criteria

Migration testing is complete when:
- [ ] PostgreSQL database set up with proper schema
- [ ] All 7 repository methods tested manually successfully
- [ ] Integration test project created
- [ ] All integration tests passing (minimum 80% code coverage)
- [ ] Performance benchmarks meet requirements
- [ ] Edge cases tested and handled
- [ ] CI/CD pipeline includes automated tests
- [ ] Test documentation complete

## Known Limitations

1. **No Unit Tests in Original Application**: This represents a gap in the original application design, not a migration failure. It is recommended to implement tests post-migration.

2. **Runtime Validation Requires Infrastructure**: Cannot validate actual database operations without PostgreSQL instance running.

3. **Complex Queries**: The SQL equivalency tool couldn't formally verify complex CTE and window function queries. Manual testing and integration tests are critical to ensure correctness.

## Recommendations

1. **Prioritize Integration Tests**: Given the complexity of the SQL queries (CTEs, window functions, transactions), integration tests are more valuable than unit tests for this application.

2. **Implement Tests Incrementally**: Start with core CRUD operations, then add tests for complex query features.

3. **Monitor in Production**: Even with comprehensive testing, monitor query performance and error rates in production.

4. **Consider Test Data Generators**: Use tools like Bogus or custom generators to create realistic test data at scale.

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-29  
**Migration Phase:** Post-Migration Testing Strategy
