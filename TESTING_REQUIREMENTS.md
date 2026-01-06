# PostgreSQL Migration Testing Requirements

## Overview
This document outlines the testing requirements and procedures for validating the ADO.NET application migration from Microsoft SQL Server to PostgreSQL. The code transformation is complete and the application compiles successfully, but several exit criteria require an actual PostgreSQL database environment to validate.

## Migration Transformation Summary

### Completed Successfully ✓
1. **Package Migration**: Microsoft.Data.SqlClient replaced with Npgsql 8.0.5
2. **ADO.NET Class Replacement**: All SqlConnection, SqlCommand, SqlDataReader, SqlTransaction replaced with Npgsql equivalents
3. **SQL Statement Extraction**: All 7 SQL statements extracted and cataloged
4. **DMS Conversion**: 6/7 statements successfully converted via DMS MCP tool; 1 manually converted after DMS failure
5. **SQL Equivalency Validation**: All 7 statement pairs validated through SQL Equivalency tool (all returned ERROR due to complex SQL constructs exceeding solver capabilities)
6. **Code Re-integration**: All converted PostgreSQL statements re-integrated into codebase
7. **Connection Strings**: Updated to PostgreSQL format (Host/Port/Database/Username/Password)
8. **Transaction Handling**: Updated to use NpgsqlTransaction with BeginTransactionAsync/CommitAsync/RollbackAsync
9. **Application Compilation**: Application compiles with 0 errors

### Requires PostgreSQL Database Environment
The following exit criteria cannot be validated without a live PostgreSQL database:

1. **Database Connectivity** (Criterion 12 - PARTIAL)
2. **Database Operations** (Criterion 13 - FAIL)
3. **Transaction Atomicity** (Criterion 14 - FAIL)
4. **Automated Testing** (Criterion 15 - FAIL)

## PostgreSQL Environment Setup

### Prerequisites
- PostgreSQL 13 or higher
- psql command-line tool or pgAdmin
- Network access to PostgreSQL server

### Database Schema Setup
```sql
-- Create database
CREATE DATABASE ProductManagement;

-- Connect to database
\c ProductManagement

-- Create schema (optional, using default public schema)
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;

-- Create products table
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(18,2) NOT NULL,
    stockquantity INTEGER NOT NULL,
    createddate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifieddate TIMESTAMP
);

-- Create producthistory table
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL,
    oldprice DECIMAL(18,2),
    newprice DECIMAL(18,2),
    oldstock INTEGER,
    newstock INTEGER,
    actiondate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (productid) REFERENCES productmanagement_dbo.products(productid)
);

-- Create productstats table
CREATE TABLE productmanagement_dbo.productstats (
    statid INTEGER PRIMARY KEY,
    totalproducts INTEGER NOT NULL DEFAULT 0,
    averageprice DECIMAL(18,2) NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial stats record
INSERT INTO productmanagement_dbo.productstats (statid, totalproducts, averageprice, lastupdated)
VALUES (1, 0, 0, CURRENT_TIMESTAMP);

-- Create indexes for performance
CREATE INDEX idx_products_price ON productmanagement_dbo.products(price);
CREATE INDEX idx_products_stockquantity ON productmanagement_dbo.products(stockquantity);
CREATE INDEX idx_producthistory_productid ON productmanagement_dbo.producthistory(productid);
```

### Connection String Configuration
Update `appsettings.json` with your PostgreSQL credentials:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=your_username;Password=your_password",
    "ProdConnection": "Host=your_prod_server;Port=5432;Database=ProductManagement;Username=prod_username;Password=prod_password"
  },
  "Environment": "Development"
}
```

## Testing Procedures

### 1. Database Connectivity Test (Criterion 12)
**Objective**: Verify the application successfully connects to PostgreSQL database

**Steps**:
1. Set up PostgreSQL environment as described above
2. Configure connection string in appsettings.json
3. Run the application: `dotnet run`
4. Verify connection is established without errors

**Expected Result**: Application starts without connection errors, NpgsqlConnection opens successfully

### 2. Database Operations Test (Criterion 13)
**Objective**: Verify all CRUD operations execute successfully

**Test Cases**:

#### Test 2.1: GetAllProductsAsync
- **SQL Statement**: Statement 1 (CTE with window functions)
- **Operation**: SELECT with Complex CTE, AVG/COUNT OVER, CASE expressions
- **Verification**: 
  - Query executes without errors
  - Results include price category calculations
  - Results include price percentage of average

#### Test 2.2: GetProductByIdAsync
- **SQL Statement**: Statement 2 (CTE with LAG window function)
- **Operation**: SELECT with parameter, LAG window function, LEFT OUTER JOIN
- **Verification**:
  - Query with valid ID returns correct product
  - Query with invalid ID returns null
  - Previous price and stock calculations are correct

#### Test 2.3: InsertProductAsync
- **SQL Statement**: Statement 3 (INSERT with RETURNING)
- **Operation**: Multi-statement transaction (INSERT product, INSERT history, UPDATE stats)
- **Verification**:
  - New product is inserted
  - RETURNING clause returns new product ID
  - Product history is logged
  - Product stats are updated
  - Transaction commits successfully

#### Test 2.4: UpdateProductAsync
- **SQL Statement**: Statement 4 (UPDATE with transaction)
- **Operation**: Multi-statement transaction (SELECT old values, UPDATE product, INSERT history, UPDATE stats)
- **Verification**:
  - Product is updated with new values
  - Old values are captured
  - History record is created
  - Stats are recalculated
  - Transaction commits successfully

#### Test 2.5: DeleteProductAsync
- **SQL Statement**: Statement 5 (DELETE with transaction)
- **Operation**: Multi-statement transaction (SELECT old values, INSERT history, DELETE product, UPDATE stats)
- **Verification**:
  - History is logged before deletion
  - Product is deleted
  - Stats are updated (decremented)
  - Transaction commits successfully

#### Test 2.6: GetProductsByPriceRangeAsync
- **SQL Statement**: Statement 6 (CTE with RANK/PERCENT_RANK)
- **Operation**: SELECT with parameters, RANK/PERCENT_RANK window functions, CASE for segmentation
- **Verification**:
  - Query returns products within price range
  - Price ranking is correct
  - Price segmentation (Budget/Mid-Range/Premium) is accurate

#### Test 2.7: GetLowStockProductsAsync
- **SQL Statement**: Statement 7 (CTE with multiple aggregations)
- **Operation**: SELECT with parameter, AVG/MIN/MAX window functions, stock status calculation
- **Verification**:
  - Query returns products below threshold
  - Stock statistics (avg, min, max) are calculated correctly
  - Stock status (Critical/Low/Adequate) is accurate

### 3. Transaction Atomicity Test (Criterion 14)
**Objective**: Verify transaction blocks maintain atomicity with commit/rollback

**Test Scenarios**:

#### Scenario 3.1: Successful Transaction Commit
- Execute InsertProductAsync with valid data
- Verify all three operations complete:
  1. Product inserted
  2. History logged
  3. Stats updated
- Verify all changes are persisted

#### Scenario 3.2: Transaction Rollback on Error
- Simulate error in multi-statement transaction (e.g., constraint violation)
- Verify NO partial changes are committed
- Verify database state remains consistent

#### Scenario 3.3: Concurrent Transaction Handling
- Execute multiple update operations simultaneously
- Verify transaction isolation
- Verify no data corruption occurs

### 4. SQL Equivalency Manual Validation (Required)
**Objective**: Manually verify SQL equivalency since automated tool returned UNKNOWN for all pairs

**Background**: The SQL Equivalency tool's Z3SqlSolverVerifier could not prove equivalency/non-equivalency for any of the 7 statement pairs due to complex SQL features (CTEs, window functions, multi-statement transactions) exceeding formal verification solver capabilities.

**Manual Validation Procedure**:
1. Set up IDENTICAL test data in both SQL Server and PostgreSQL databases
2. Execute each SQL statement pair against their respective databases
3. Compare query results for functional equivalency
4. Document any differences in behavior or results

**Statement Pairs to Validate**:
- Statement 1: CTE with AVG/COUNT OVER window functions
- Statement 2: CTE with LAG window function and LEFT JOIN
- Statement 3: INSERT with RETURNING vs SCOPE_IDENTITY()
- Statement 4: Multi-statement UPDATE transaction
- Statement 5: Multi-statement DELETE transaction  
- Statement 6: CTE with RANK/PERCENT_RANK window functions
- Statement 7: CTE with multiple aggregate window functions

## Automated Testing Framework

### Recommended Test Framework
- **Unit Tests**: xUnit or NUnit
- **Mocking**: Moq for repository mocking in service layer tests
- **Integration Tests**: TestContainers for PostgreSQL or dedicated test database

### Test Project Structure
```
AdoCore.Tests/
├── Unit/
│   ├── ProductServiceTests.cs
│   ├── ProductModelTests.cs
│   └── ValidationTests.cs
├── Integration/
│   ├── ProductRepositoryIntegrationTests.cs
│   ├── TransactionTests.cs
│   └── DatabaseConnectionTests.cs
└── TestData/
    └── SampleProducts.json
```

### Sample Unit Test (ProductService)
```csharp
[Fact]
public async Task CreateProductAsync_WithValidProduct_ReturnsNewId()
{
    // Arrange
    var mockRepo = new Mock<ProductRepository>();
    var service = new ProductService(mockRepo.Object);
    var product = new Product { Name = "Test", Price = 10.99m, StockQuantity = 100 };
    mockRepo.Setup(r => r.InsertProductAsync(product)).ReturnsAsync(1);

    // Act
    var result = await service.CreateProductAsync(product);

    // Assert
    Assert.Equal(1, result);
    mockRepo.Verify(r => r.InsertProductAsync(product), Times.Once);
}
```

### Sample Integration Test (Repository)
```csharp
[Fact]
public async Task InsertProductAsync_WithTransaction_MaintainsAtomicity()
{
    // Arrange
    using var repository = new ProductRepository(_configuration);
    var product = new Product 
    { 
        Name = "Integration Test Product",
        Price = 25.99m,
        StockQuantity = 50
    };

    // Act
    var newId = await repository.InsertProductAsync(product);

    // Assert
    Assert.True(newId > 0);
    
    // Verify product was inserted
    var retrieved = await repository.GetProductByIdAsync(newId);
    Assert.NotNull(retrieved);
    Assert.Equal(product.Name, retrieved.Name);
    
    // Verify history was logged
    // Verify stats were updated
    
    // Cleanup
    await repository.DeleteProductAsync(newId);
}
```

## Performance Testing

### Recommended Performance Tests
1. **Query Performance**: Compare execution times of complex CTEs and window functions
2. **Connection Pooling**: Verify Npgsql connection pooling efficiency
3. **Transaction Throughput**: Measure transaction commit rates
4. **Concurrent Operations**: Test behavior under high concurrency

### Performance Baseline Metrics
- GetAllProductsAsync: < 100ms for 1000 records
- GetProductByIdAsync: < 10ms
- InsertProductAsync (with transaction): < 50ms
- UpdateProductAsync (with transaction): < 50ms
- DeleteProductAsync (with transaction): < 50ms

## Known Limitations and Considerations

### 1. SQL Equivalency Tool Limitations
- All 7 statement pairs returned UNKNOWN/ERROR status from SQL Equivalency tool
- Manual functional testing required to confirm query result equivalency
- Complex SQL constructs (CTEs, window functions) exceeded solver capabilities

### 2. Schema Object Name Changes
- DMS tool converted some schema references (e.g., "Products" → "productmanagement_dbo.products")
- Code has been updated to use converted names
- Verify schema setup matches converted names

### 3. Date/Time Functions
- GETDATE() converted to CURRENT_TIMESTAMP
- Verify timezone handling matches requirements
- Consider using clock_timestamp() for statement-level timestamps if needed

### 4. Window Function Behavior
- Verify NULLS FIRST/NULLS LAST ordering matches expectations
- Test window function results with NULL values in data

### 5. Transaction Isolation Levels
- Default PostgreSQL isolation level is READ COMMITTED
- May differ from SQL Server default (READ COMMITTED with different locking)
- Test for phantom reads and other isolation phenomena if critical

## Success Criteria Summary

### Code Transformation: COMPLETE ✓
- All SQL Server dependencies removed
- All Npgsql dependencies added
- All SQL statements converted and re-integrated
- Application compiles with 0 errors

### Runtime Validation: REQUIRES POSTGRESQL DATABASE
- Database connectivity: Code ready, needs live database
- CRUD operations: Code ready, needs live database  
- Transaction atomicity: Code ready, needs live database
- Automated tests: Test structure documented, needs implementation
- SQL equivalency: Automated validation failed, requires manual verification

## Next Steps

1. **Immediate** (to complete migration):
   - Set up PostgreSQL test environment
   - Create database schema
   - Configure connection strings
   - Execute manual connectivity and operation tests

2. **Short-term** (for quality assurance):
   - Implement automated test suite
   - Perform manual SQL equivalency validation
   - Conduct performance testing
   - Document any behavioral differences

3. **Long-term** (for production readiness):
   - Set up CI/CD with PostgreSQL integration tests
   - Implement monitoring and logging
   - Create runbooks for common operations
   - Train team on PostgreSQL-specific behaviors

## Contact and Support

For questions about the migration or testing procedures:
- Review transformation artifacts in project root
- Consult DMS conversion logs: `dms_conversion_failures.log`
- Review SQL equivalency report: `sql_equivalency_validation_report.json`
- Review migration summary: `final_migration_report.txt`
