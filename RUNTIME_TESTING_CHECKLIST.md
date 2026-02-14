# Runtime Testing Checklist for PostgreSQL Migration

## Status: PENDING - Requires PostgreSQL Database Instance

This document outlines the runtime testing required to complete exit criteria 12-15 of the transformation definition.

## Prerequisites

Before running these tests, ensure:
- [ ] PostgreSQL server is installed and running
- [ ] Database schema has been deployed using `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
- [ ] Connection string in `appsettings.json` points to the PostgreSQL instance
- [ ] Application compiles successfully (`dotnet build`)

## Exit Criterion 12: Database Connection Testing

**Objective**: Verify the application successfully connects to PostgreSQL database

### Manual Test Steps:

1. **Verify PostgreSQL is Running**:
   ```bash
   pg_isready -h localhost -p 5432
   ```

2. **Test Connection with psql**:
   ```bash
   psql -U postgres -h localhost -d product_management -c "SELECT version();"
   ```

3. **Update Connection String** (if needed):
   Edit `appsettings.json` with actual database credentials:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=product_management;Username=postgres;Password=your_password"
     }
   }
   ```

4. **Test Application Connection**:
   Run the application and verify it connects without errors:
   ```bash
   dotnet run
   ```

**Expected Result**: Application starts without connection errors

**Status**: ⏳ PENDING - Requires live PostgreSQL instance

---

## Exit Criterion 13: Database Operations Testing

**Objective**: Verify all database operations (SELECT, INSERT, UPDATE, DELETE) execute successfully

### Test Case 1: GetAllProductsAsync
```bash
# Manual Test via Application CLI
dotnet run -- list-all
```
**Expected**: Returns list of products with rankings and previous prices
**Validates**: SELECT with CTEs, window functions (ROW_NUMBER, LAG)

### Test Case 2: GetProductByIdAsync
```bash
# Test with product ID 1
dotnet run -- get-product 1
```
**Expected**: Returns single product with price comparison to previous product
**Validates**: Parameterized SELECT with LAG window function

### Test Case 3: InsertProductAsync
```bash
# Insert new product
dotnet run -- add-product "Test Product" "Test Description" 99.99 50
```
**Expected**: Returns new ProductId, product appears in database
**Validates**: 
- INSERT with RETURNING clause
- Transaction: INSERT product + INSERT history + UPDATE stats
- CURRENT_TIMESTAMP function

**Database Verification**:
```sql
SELECT * FROM products WHERE name = 'Test Product';
SELECT * FROM product_history WHERE action = 'INSERT' ORDER BY action_date DESC LIMIT 1;
SELECT * FROM product_stats;
```

### Test Case 4: UpdateProductAsync
```bash
# Update existing product
dotnet run -- update-product 1 "Updated Product" "Updated Description" 149.99 25
```
**Expected**: Product updated successfully, old values stored in history
**Validates**:
- Transaction with multiple statements
- UPDATE with CURRENT_TIMESTAMP
- SELECT to capture old values
- INSERT into history
- UPDATE stats

**Database Verification**:
```sql
SELECT * FROM products WHERE product_id = 1;
SELECT * FROM product_history WHERE product_id = 1 AND action = 'UPDATE' ORDER BY action_date DESC LIMIT 1;
SELECT * FROM product_stats;
```

### Test Case 5: DeleteProductAsync
```bash
# Delete product
dotnet run -- delete-product 19
```
**Expected**: Product deleted, history record created
**Validates**:
- Transaction: SELECT + INSERT history + DELETE + UPDATE stats
- Proper transaction atomicity

**Database Verification**:
```sql
SELECT * FROM products WHERE product_id = 19;  -- Should return no rows
SELECT * FROM product_history WHERE product_id = 19 AND action = 'DELETE';
SELECT * FROM product_stats;
```

### Test Case 6: GetProductsByPriceRangeAsync
```bash
# Get products in price range
dotnet run -- price-range 100 500
```
**Expected**: Returns products with RANK and PERCENT_RANK values
**Validates**: Window functions with partitioning

### Test Case 7: GetLowStockProductsAsync
```bash
# Get low stock products
dotnet run -- low-stock
```
**Expected**: Returns products where stock <= reorder level
**Validates**: Window functions with WHERE clause filter

**Status**: ⏳ PENDING - Requires live PostgreSQL instance

---

## Exit Criterion 14: Transaction Atomicity Testing

**Objective**: Verify transaction blocks maintain ACID properties

### Test Case 1: InsertProductAsync Rollback Test

**Objective**: Verify transaction rolls back if any statement fails

**Test Steps**:
1. Modify code temporarily to force error after INSERT (e.g., invalid history insert)
2. Attempt to insert product
3. Verify product NOT in database (transaction rolled back)
4. Restore original code

**Expected**: Transaction rolls back completely, no partial data inserted

### Test Case 2: UpdateProductAsync Atomicity Test

**Objective**: Verify all or nothing update

**Test Steps**:
1. Note current product data, history count, stats
2. Update product
3. Verify all changes committed together:
   - Product updated
   - History record created
   - Stats updated
4. Attempt update with invalid data
5. Verify nothing changed (rollback)

**Expected**: Either all changes committed or all rolled back

### Test Case 3: DeleteProductAsync Atomicity Test

**Objective**: Verify delete transaction atomicity

**Test Steps**:
1. Select a product to delete
2. Delete product
3. Verify:
   - History record created BEFORE delete
   - Product deleted
   - Stats updated
4. All happen atomically

**Expected**: Complete transaction or complete rollback

### Test Case 4: Concurrent Transaction Test

**Test Steps**:
1. Open two database connections
2. Start transaction in both
3. Update same product from both
4. Commit both
5. Verify data consistency

**Expected**: PostgreSQL handles concurrency properly, no data corruption

**Status**: ⏳ PENDING - Requires live PostgreSQL instance

---

## Exit Criterion 15: Test Suite Execution

**Objective**: Execute all unit and integration tests with PostgreSQL

### Current Status
```bash
# Search for test files
find . -name "*Test*.cs" -o -name "*test*.cs"
```

**Finding**: No test files exist in the project

**Required Actions**:
1. **If tests exist elsewhere**: Locate and configure to use PostgreSQL connection
2. **If no tests exist**: This criterion cannot be validated

**Recommendation**: Create integration tests for the repository methods:
- Test file: `Tests/ProductRepositoryTests.cs`
- Test framework: xUnit or NUnit
- Database: Test PostgreSQL instance with test data

### Sample Test Structure (if creating tests)

```csharp
public class ProductRepositoryIntegrationTests : IDisposable
{
    private readonly IConfiguration _configuration;
    private readonly ProductRepository _repository;
    
    public ProductRepositoryIntegrationTests()
    {
        // Setup test configuration with PostgreSQL connection
        _configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.test.json")
            .Build();
        _repository = new ProductRepository(_configuration);
    }
    
    [Fact]
    public async Task GetAllProductsAsync_ReturnsProducts()
    {
        // Arrange
        // Act
        var products = await _repository.GetAllProductsAsync();
        // Assert
        Assert.NotNull(products);
        Assert.True(products.Any());
    }
    
    [Fact]
    public async Task InsertProductAsync_ReturnsNewProductId()
    {
        // Arrange
        var product = new Product { Name = "Test", ... };
        // Act
        var id = await _repository.InsertProductAsync(product);
        // Assert
        Assert.True(id > 0);
    }
    
    // Additional tests...
}
```

**Status**: ⏳ PENDING - No test files exist in project

---

## Summary of Testing Status

| Criterion | Description | Status | Blocker |
|-----------|-------------|--------|---------|
| 12 | Database Connection | PENDING | No PostgreSQL instance |
| 13 | Database Operations | PENDING | No PostgreSQL instance |
| 14 | Transaction Atomicity | PENDING | No PostgreSQL instance |
| 15 | Test Suite Execution | PENDING | No test files exist |

## Next Steps

To complete validation:

1. **Deploy PostgreSQL Database**:
   - Install PostgreSQL 12+ or use Docker
   - Run deployment script: `01_InitialSetup_PostgreSQL.sql`
   - Verify schema and sample data

2. **Configure Application**:
   - Update `appsettings.json` with actual connection string
   - Verify application builds: `dotnet build`

3. **Execute Manual Tests**:
   - Follow test cases in this document
   - Document results for each test case
   - Verify all operations succeed

4. **Address Test Suite** (Criterion 15):
   - Confirm no tests exist in project
   - OR locate and execute existing tests
   - OR create integration tests (recommended)

5. **Update Validation Summary**:
   - Document test results
   - Update exit criteria status
   - Generate final report

## Test Results Template

```markdown
## Test Execution Results

**Date**: [Date]
**Tester**: [Name]
**Environment**: PostgreSQL [Version] on [OS]

### Criterion 12: Connection Testing
- [ ] PostgreSQL Running: YES/NO
- [ ] Schema Deployed: YES/NO  
- [ ] Application Connects: YES/NO
- **Status**: PASS/FAIL
- **Notes**: 

### Criterion 13: Operations Testing
- [ ] GetAllProductsAsync: PASS/FAIL
- [ ] GetProductByIdAsync: PASS/FAIL
- [ ] InsertProductAsync: PASS/FAIL
- [ ] UpdateProductAsync: PASS/FAIL
- [ ] DeleteProductAsync: PASS/FAIL
- [ ] GetProductsByPriceRangeAsync: PASS/FAIL
- [ ] GetLowStockProductsAsync: PASS/FAIL
- **Status**: PASS/FAIL
- **Notes**:

### Criterion 14: Transaction Testing
- [ ] Insert Transaction Atomicity: PASS/FAIL
- [ ] Update Transaction Atomicity: PASS/FAIL
- [ ] Delete Transaction Atomicity: PASS/FAIL
- [ ] Rollback Testing: PASS/FAIL
- **Status**: PASS/FAIL
- **Notes**:

### Criterion 15: Test Suite
- [ ] Tests Located: YES/NO
- [ ] Tests Configured for PostgreSQL: YES/NO
- [ ] All Tests Pass: YES/NO
- **Status**: PASS/FAIL/NOT_APPLICABLE
- **Notes**:
```

---

**Document Status**: READY FOR TESTING
**Last Updated**: 2026-02-14
**Next Action**: Deploy PostgreSQL database instance and execute test cases
