# AdoCore.Tests

Comprehensive test suite for the AdoCore application after migration from SQL Server to PostgreSQL.

## Test Categories

### 1. Unit Tests (`ProductRepositoryUnitTests.cs`)
Tests that verify code logic without requiring a database connection.

**Tests Include:**
- Constructor validation
- Parameter validation
- Product model validation
- Business logic validation
- Error handling

**Run unit tests:**
```bash
dotnet test --filter "FullyQualifiedName~ProductRepositoryUnitTests"
```

### 2. Integration Tests (`ProductRepositoryIntegrationTests.cs`)
Tests that require a running PostgreSQL database and validate actual database operations.

**Prerequisites:**
- PostgreSQL server running on localhost:5432
- Database "ProductManagement" created
- Schema initialized using `Database/01_InitialSetup.sql`
- Valid credentials configured in `appsettings.json`

**Tests Include:**
- Database connectivity
- CRUD operations (Create, Read, Update, Delete)
- Transaction atomicity and rollback
- PostgreSQL-specific syntax validation (CTEs, window functions)
- CURRENT_TIMESTAMP function validation
- RETURNING clause validation
- Complex queries with multiple operations

**Run integration tests:**
```bash
dotnet test --filter "Category=Integration"
```

### 3. SQL Migration Validation Tests (`SqlMigrationValidationTests.cs`)
Tests that validate the SQL migration artifacts and transformation completeness.

**Tests Include:**
- Verification of all migration artifact files
- DMS conversion log completeness
- SQL Equivalency report validation
- Confirmation all 7 SQL statements were processed
- PostgreSQL syntax validation
- SQL Server syntax removal validation
- Package migration validation
- Connection string format validation

**Run migration validation tests:**
```bash
dotnet test --filter "FullyQualifiedName~SqlMigrationValidationTests"
```

## Running All Tests

To run all tests:
```bash
dotnet test
```

To run with detailed output:
```bash
dotnet test --logger "console;verbosity=detailed"
```

To run only unit tests (no database required):
```bash
dotnet test --filter "FullyQualifiedName!~IntegrationTests"
```

## Test Coverage

The test suite covers:
- **7 repository methods** with comprehensive integration tests
- **10 unit tests** for code logic validation
- **16 migration validation tests** for transformation completeness
- **Transaction atomicity** across all multi-statement operations
- **PostgreSQL-specific features** including CTEs, window functions, RETURNING clause, CURRENT_TIMESTAMP

## Expected Results

### Without PostgreSQL Database
- Unit tests: **All pass** (10/10)
- Migration validation tests: **All pass** (16/16)
- Integration tests: **Skipped or fail with connection error**

### With PostgreSQL Database
- Unit tests: **All pass** (10/10)
- Migration validation tests: **All pass** (16/16)
- Integration tests: **All pass** (20/20) - if database is properly configured

## Setting Up PostgreSQL for Integration Tests

1. **Install PostgreSQL** (if not already installed)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql postgresql-contrib
   
   # macOS
   brew install postgresql
   
   # Windows
   # Download installer from https://www.postgresql.org/download/
   ```

2. **Create the database**
   ```bash
   psql -U postgres -c "CREATE DATABASE ProductManagement;"
   ```

3. **Initialize the schema**
   ```bash
   psql -U postgres -d ProductManagement -f Database/01_InitialSetup.sql
   ```

4. **Update connection string** in `appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Port=5432;Pooling=true"
     },
     "Environment": "Development"
   }
   ```

5. **Run integration tests**
   ```bash
   dotnet test --filter "Category=Integration"
   ```

## Continuous Integration

For CI/CD pipelines, consider:

1. **Running unit tests always** (no database required)
   ```yaml
   - name: Run Unit Tests
     run: dotnet test --filter "FullyQualifiedName!~IntegrationTests"
   ```

2. **Running integration tests with PostgreSQL service**
   ```yaml
   services:
     postgres:
       image: postgres:15
       env:
         POSTGRES_DB: ProductManagement
         POSTGRES_USER: postgres
         POSTGRES_PASSWORD: postgres
       ports:
         - 5432:5432
   
   - name: Run Integration Tests
     run: dotnet test --filter "Category=Integration"
   ```

## Test Maintenance

When adding new repository methods:
1. Add unit tests to `ProductRepositoryUnitTests.cs`
2. Add integration tests to `ProductRepositoryIntegrationTests.cs`
3. Update expected method count in `SqlMigrationValidationTests.cs`
4. Document SQL conversions in migration artifacts

## Exit Criteria Validation

These tests help validate the following migration exit criteria:
- **Criterion 11**: Application compiles without errors (verified by test build)
- **Criterion 12**: Application connects to PostgreSQL (verified by integration tests)
- **Criterion 13**: All database operations execute successfully (verified by integration tests)
- **Criterion 14**: Transaction atomicity maintained (verified by integration tests)
- **Criterion 15**: Application passes all tests (this test suite)

## Support

For issues or questions:
- Check migration artifacts in the root directory
- Review `final_migration_report.md` for migration details
- Verify `sql_equivalency_validation_report.json` for SQL conversion status
- Check `DEBUGGER_COMPLETION_REPORT.md` for known issues and resolutions
