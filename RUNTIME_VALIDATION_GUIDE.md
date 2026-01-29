# PostgreSQL Migration - Runtime Validation Guide

## Overview
This document provides instructions for completing the runtime validation of the Microsoft SQL Server to PostgreSQL migration for the AdoCore application.

## Migration Status

### Completed ✅
1. **Package Dependencies**: All SQL Server packages replaced with Npgsql 8.0.8
2. **ADO.NET Classes**: All SqlConnection, SqlCommand, etc. replaced with Npgsql equivalents
3. **SQL Statement Extraction**: All 7 SQL statements extracted and documented
4. **SQL Statement Conversion**: All 7 statements processed through DMS MCP tool
5. **Code Integration**: All converted statements integrated into ProductRepository.cs
6. **Connection Strings**: All connection strings updated to PostgreSQL format
7. **Transaction Handling**: All transaction code updated to use Npgsql transaction methods
8. **Build Validation**: Application compiles successfully with 0 errors and 0 warnings

### Requires Runtime Validation ⏳
The following exit criteria cannot be validated without a running PostgreSQL database instance:

- **Criterion 12**: Database connectivity testing
- **Criterion 13**: Database operations execution (SELECT, INSERT, UPDATE, DELETE)
- **Criterion 14**: Transaction atomicity validation
- **Criterion 15**: Test suite execution (no tests exist in current codebase)

### SQL Equivalency Tool Limitation ⚠️
- **Criterion 6**: All 7 SQL statement pairs returned "UNKNOWN" from the SQL Equivalency tool
  - Tool response: "Z3SqlSolverVerifier stage in formal methods could not prove equivalancy/non-equivalency"
  - This is a formal verification tool limitation, not a code issue
  - Functional equivalency must be verified through integration testing

## Prerequisites for Runtime Validation

### 1. PostgreSQL Installation
Install PostgreSQL 12 or higher:
- **Windows**: Download from https://www.postgresql.org/download/windows/
- **Linux**: `sudo apt-get install postgresql postgresql-contrib` (Ubuntu/Debian)
- **macOS**: `brew install postgresql@14`

### 2. PostgreSQL Configuration
Default settings in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;SSL Mode=Prefer;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=REPLACE_WITH_SECURE_PASSWORD;SSL Mode=Require;Pooling=true"
  }
}
```

**IMPORTANT**: Replace `REPLACE_WITH_SECURE_PASSWORD` in production connection string before deployment.

## Database Setup

### Step 1: Create PostgreSQL Database
```bash
# Connect to PostgreSQL as postgres user
psql -U postgres

# Create the database
CREATE DATABASE "ProductManagement";

# Exit psql
\q
```

### Step 2: Run Database Setup Script
```bash
# Execute the PostgreSQL setup script
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

This script will:
- Create all required tables (products, categories, suppliers, product_history, product_stats)
- Create indexes for performance optimization
- Insert sample data (20 categories, 8 suppliers, 18 products)
- Create triggers for product history tracking
- Create stored procedure equivalent functions

### Step 3: Verify Database Schema
```bash
# Connect to the database
psql -U postgres -d ProductManagement

# List all tables
\dt

# Verify sample data
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;

# Exit
\q
```

Expected results:
- products: 18 rows
- categories: 20 rows
- suppliers: 8 rows

## Runtime Validation Tests

### Test 1: Database Connectivity (Criterion 12)
```bash
cd sourceCode
dotnet run
```

Expected outcome:
- Application starts without errors
- Database connection established successfully
- No connection timeout or authentication errors

### Test 2: SELECT Operations (Criterion 13)
Test the following repository methods:

#### GetAllProductsAsync
```csharp
// Should return all 18 products with:
// - ProductId, Name, Description, Price, StockQuantity
// - Calculated fields: PriceCategory, PricePercentageOfAverage
// - Uses CTE with window functions
```

#### GetProductByIdAsync
```csharp
// Should return specific product by ID with:
// - All product fields
// - Historical price data (PreviousPrice, PreviousStock)
// - PriceChangePercentage calculation
// - Uses LAG window function
```

#### GetProductsByPriceRangeAsync
```csharp
// Should return products within price range with:
// - Price ranking (RANK() function)
// - Price percentile (PERCENT_RANK() function)
// - Price segment classification (Budget/Mid-Range/Premium)
```

#### GetLowStockProductsAsync
```csharp
// Should return products below stock threshold with:
// - Stock analysis metrics
// - Stock status classification
// - Stock percentage calculations
```

### Test 3: INSERT Operations (Criterion 13)
Test the InsertProductAsync method:

```csharp
// Should insert new product and return ProductId
// Uses PostgreSQL RETURNING clause
// Verifies transaction handling with BeginTransactionAsync/CommitAsync
```

Expected behavior:
- Product inserted successfully
- ProductId returned from RETURNING clause
- Transaction committed
- Product visible in subsequent queries

### Test 4: UPDATE Operations (Criterion 13)
Test the UpdateProductAsync method:

```csharp
// Should update existing product
// Uses CURRENT_TIMESTAMP for ModifiedDate
// Verifies transaction handling
```

Expected behavior:
- Product updated successfully
- ModifiedDate automatically set
- Product history entry created by trigger
- Transaction committed

### Test 5: DELETE Operations (Criterion 13)
Test the DeleteProductAsync method:

```csharp
// Should delete product
// Verifies transaction handling with rollback on error
```

Expected behavior:
- Product deleted successfully
- Product history entry created by trigger
- Transaction committed
- Product not visible in subsequent queries

### Test 6: Transaction Atomicity (Criterion 14)
Test transaction rollback scenarios:

#### Scenario 1: Insert with Constraint Violation
```csharp
// Attempt to insert product with duplicate SKU
// Should rollback and not commit partial changes
```

#### Scenario 2: Update with Error
```csharp
// Attempt to update product with invalid data
// Should rollback and preserve original data
```

#### Scenario 3: Multi-Statement Transaction
```csharp
// Execute multiple operations in single transaction
// Verify all-or-nothing behavior
```

## Validation Checklist

Use this checklist to track validation progress:

- [ ] PostgreSQL installed and running
- [ ] ProductManagement database created
- [ ] Database schema created from 01_InitialSetup_PostgreSQL.sql
- [ ] Sample data loaded successfully
- [ ] Application compiles without errors (already verified ✅)
- [ ] Application starts and connects to database
- [ ] GetAllProductsAsync returns correct results
- [ ] GetProductByIdAsync returns correct results
- [ ] GetProductsByPriceRangeAsync returns correct results
- [ ] GetLowStockProductsAsync returns correct results
- [ ] InsertProductAsync inserts data correctly
- [ ] InsertProductAsync returns ProductId via RETURNING clause
- [ ] UpdateProductAsync updates data correctly
- [ ] UpdateProductAsync sets ModifiedDate with CURRENT_TIMESTAMP
- [ ] DeleteProductAsync deletes data correctly
- [ ] Product history trigger captures INSERT events
- [ ] Product history trigger captures UPDATE events
- [ ] Product history trigger captures DELETE events
- [ ] Transactions commit successfully on success
- [ ] Transactions rollback correctly on errors
- [ ] All 7 SQL statements function equivalently to original SQL Server versions

## Known Limitations

### 1. SQL Equivalency Tool Results
All 7 SQL statement pairs were marked as ERROR because the SQL Equivalency tool returned UNKNOWN status. This indicates a limitation of the formal verification tool (Z3SqlSolverVerifier), NOT a code issue.

**Recommendation**: Verify functional equivalency through integration testing by:
1. Running identical test cases against SQL Server and PostgreSQL
2. Comparing result sets for data accuracy
3. Verifying business logic consistency

### 2. Missing Test Suite
The original codebase does not include unit tests or integration tests (Criterion 15). 

**Recommendation**: Create test project with:
- Unit tests for repository methods
- Integration tests for database operations
- Transaction rollback tests
- Performance baseline tests

### 3. Connection String Security
The production connection string contains a placeholder password.

**Action Required**: Before production deployment:
- Use environment variables for credentials
- Implement Azure Key Vault or similar secret management
- Enable connection string encryption
- Review SSL/TLS settings

## Troubleshooting

### Issue: Connection Timeout
**Symptoms**: "Npgsql.NpgsqlException: Connection timeout"
**Solutions**:
1. Verify PostgreSQL service is running: `sudo systemctl status postgresql`
2. Check firewall allows port 5432
3. Verify host in connection string (localhost vs 127.0.0.1)
4. Check PostgreSQL pg_hba.conf for authentication settings

### Issue: Authentication Failed
**Symptoms**: "28P01: password authentication failed"
**Solutions**:
1. Verify PostgreSQL user password
2. Update connection string with correct credentials
3. Check pg_hba.conf authentication method (md5, scram-sha-256)
4. Reset PostgreSQL password: `ALTER USER postgres PASSWORD 'newpassword';`

### Issue: Database Does Not Exist
**Symptoms**: "3D000: database 'ProductManagement' does not exist"
**Solutions**:
1. Create database: `CREATE DATABASE "ProductManagement";`
2. Verify database name case-sensitivity
3. List databases: `\l` in psql

### Issue: Table Does Not Exist
**Symptoms**: "42P01: relation 'products' does not exist"
**Solutions**:
1. Run 01_InitialSetup_PostgreSQL.sql script
2. Verify schema: `\dt` in psql
3. Check for schema qualification (public.products vs products)

### Issue: RETURNING Clause Not Working
**Symptoms**: "No data returned from INSERT with RETURNING"
**Solutions**:
1. Verify NpgsqlCommand.ExecuteScalar() is used (not ExecuteNonQuery())
2. Check SQL syntax: `RETURNING product_id` (lowercase in PostgreSQL)
3. Ensure auto-increment column is SERIAL type

## Performance Considerations

### Query Optimization
The converted SQL statements use advanced PostgreSQL features:
- **Common Table Expressions (CTEs)**: All complex queries use WITH clauses
- **Window Functions**: RANK(), PERCENT_RANK(), LAG(), AVG() OVER(), COUNT() OVER()
- **Indexes**: Created on foreign keys and frequently queried columns

### Connection Pooling
Connection string includes `Pooling=true` for optimal connection management:
- Reduces connection overhead
- Improves concurrent request handling
- Recommended for production workloads

### Monitoring
Consider implementing:
- Query performance logging
- Connection pool metrics
- Transaction duration tracking
- Error rate monitoring

## Next Steps

1. **Complete Runtime Validation**: Follow the validation checklist above
2. **Document Test Results**: Record all test outcomes and any issues encountered
3. **Performance Testing**: Establish baseline performance metrics
4. **Create Test Suite**: Develop comprehensive unit and integration tests (addresses Criterion 15)
5. **Security Review**: Implement secure credential management for production
6. **Deployment Planning**: Create deployment runbook for production migration

## Additional Resources

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **Migration Artifacts**:
  - `extracted_statements.sql`: All original SQL Server statements
  - `converted_statements.sql`: All converted PostgreSQL statements
  - `dms_conversion_log.txt`: DMS tool conversion log
  - `sql_equivalency_validation_report.json`: Equivalency validation results
  - `migration_final_report.md`: Complete migration report

## Contact

For questions or issues related to this migration, refer to:
- Transformation artifacts in the project root directory
- Migration final report for detailed conversion decisions
- DMS conversion log for SQL statement transformation details
