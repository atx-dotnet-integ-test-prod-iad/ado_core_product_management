# ADO.NET Core PostgreSQL Data Management Application

**Migration Status: ✅ Code Migration Complete | ⚠️ Runtime Validation Pending**

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture. This application has been migrated from Microsoft SQL Server to PostgreSQL.

## Migration Overview

This application has been successfully migrated from SQL Server to PostgreSQL:
- ✅ All SQL statements converted (7 statements processed through DMS MCP tool)
- ✅ All ADO.NET classes migrated from Microsoft.Data.SqlClient to Npgsql
- ✅ Connection strings updated to PostgreSQL format with environment variable support
- ✅ Application compiles without errors
- ⚠️ **Runtime validation pending** - requires PostgreSQL database setup

**See [DEPLOYMENT_TESTING_GUIDE.md](DEPLOYMENT_TESTING_GUIDE.md) for complete setup and validation instructions.**

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- **PostgreSQL 12 or later**
- pgAdmin or psql command-line tool

## Quick Start

### 1. Install PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**macOS:**
```bash
brew install postgresql
brew services start postgresql
```

**Windows:**
Download installer from https://www.postgresql.org/download/windows/

### 2. Setup Database

```bash
# Connect to PostgreSQL
sudo -u postgres psql  # Linux/macOS
psql -U postgres       # Windows

# Create database
CREATE DATABASE "ProductManagement";
\c ProductManagement;
\q

# Run setup script
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### 3. Configure Environment (Optional)

For production, set environment variables:

```bash
# Linux/macOS
export PGUSER="postgres"
export PGPASSWORD="your_password"
export PGHOST="localhost"
export PGPORT="5432"
export PGDATABASE="ProductManagement"

# Windows PowerShell
$env:PGUSER="postgres"
$env:PGPASSWORD="your_password"
$env:PGHOST="localhost"
$env:PGPORT="5432"
$env:PGDATABASE="ProductManagement"
```

**Note:** If not set, application uses default development values (postgres/postgres on localhost).

### 4. Build and Run

```bash
# Navigate to project directory
cd sourceCode

# Build
dotnet build

# Run in interactive mode
dotnet run

# Or use CLI commands
dotnet run -- list
dotnet run -- add "Test Product" 29.99 5 "Description"
```

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs        # PostgreSQL data access using Npgsql
├── Models/
│   └── Product.cs                  # Domain model
├── Business/
│   └── ProductService.cs           # Business logic layer
├── CLI/
│   ├── CommandLineInterface.cs     # Command-line interface
│   └── InteractiveMenu.cs          # Interactive menu system
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql              # Original SQL Server script
│       └── 01_InitialSetup_PostgreSQL.sql   # PostgreSQL setup script
├── Program.cs                      # Application entry point
├── AdoCore.csproj
├── appsettings.json
├── migration_final_report.md       # Detailed migration report
├── sql_equivalency_validation_report.json
└── DEPLOYMENT_TESTING_GUIDE.md     # Runtime validation guide
```

## Application Features

### Interactive Mode

Run without arguments for menu-driven interface:

```bash
dotnet run
```

Menu options:
1. List all products
2. Get product by ID
3. Create new product
4. Update product
5. Delete product
6. Get products by price range
7. Get low stock products
Q. Quit

### Command-Line Interface

```bash
# Show help
dotnet run -- --help

# List all products
dotnet run -- list

# Get product by ID
dotnet run -- get 1

# Add new product
dotnet run -- add "Gaming Mouse" 49.99 10 "High-performance gaming mouse"

# Update product
dotnet run -- update 1 "Gaming Mouse Pro" 59.99 15 "Updated gaming mouse"

# Delete product
dotnet run -- delete 1

# Update stock quantity
dotnet run -- stock 1 20
```

## Key Features

- **Modern Async Patterns**: All database operations use async/await
- **PostgreSQL Native**: Uses Npgsql for optimal PostgreSQL integration
- **Advanced SQL**: CTEs, window functions (LAG, RANK, PERCENT_RANK), and complex queries
- **Transaction Support**: Atomic operations with rollback capability
- **Environment Variables**: Secure credential management
- **Parameterized Queries**: SQL injection protection
- **Connection Pooling**: Efficient connection management
- **Error Handling**: Comprehensive error handling and logging

## Testing the Application

After database setup, test the migration:

```bash
# Verify connectivity
dotnet run -- list
# Should display all 18 sample products

# Test insert with RETURNING clause (PostgreSQL-specific)
dotnet run -- add "Migration Test" 99.99 10 "Testing PostgreSQL features"

# Test update with CTE
dotnet run -- update <product_id> "Updated Name" 129.99 15 "Updated Description"

# Test delete with history tracking
dotnet run -- delete <product_id>
```

Verify in database:
```sql
-- Check products
SELECT COUNT(*) FROM products;

-- Check history tracking
SELECT * FROM product_history ORDER BY action_date DESC LIMIT 5;

-- Check statistics
SELECT * FROM product_stats;
```

## SQL Statements Migrated

All 7 SQL statements have been successfully converted:

1. **GetAllProductsAsync**: SELECT with CTEs and window functions (AVG OVER, COUNT OVER)
2. **GetProductByIdAsync**: SELECT with LAG window function
3. **InsertProductAsync**: Multi-statement transaction with RETURNING clause
4. **UpdateProductAsync**: Multi-statement transaction with CTE-based old value capture
5. **DeleteProductAsync**: Multi-statement transaction with CTE-based old value capture
6. **GetProductsByPriceRangeAsync**: SELECT with RANK and PERCENT_RANK window functions
7. **GetLowStockProductsAsync**: Complex JOIN query

See `migration_final_report.md` for detailed conversion documentation.

## Troubleshooting

### Connection Issues

```
Error: 57P03: the database system is starting up
```
**Solution:** Wait a few seconds for PostgreSQL to finish starting.

```
Error: 28P01: password authentication failed
```
**Solution:** 
- Check PGPASSWORD environment variable
- Verify password in pg_hba.conf
- Try: `psql -U postgres` to test credentials

### Database Not Found

```
Error: 3D000: database "ProductManagement" does not exist
```
**Solution:**
```bash
sudo -u postgres psql -c 'CREATE DATABASE "ProductManagement";'
```

### Permission Denied

```
Error: 42501: permission denied
```
**Solution:**
```sql
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
```

## NuGet Packages

- **Npgsql 8.0.5**: PostgreSQL data provider for .NET
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Best Practices

- ✅ All queries use parameterization (SQL injection protection)
- ✅ Connection strings support environment variables
- ✅ No hardcoded credentials in source code
- ✅ Proper resource disposal with IAsyncDisposable
- ✅ Transaction isolation for data integrity
- ⚠️ **Production**: Use SSL/TLS connections (add `SslMode=Require` to connection string)
- ⚠️ **Production**: Use dedicated database user with minimum required privileges
- ⚠️ **Production**: Enable PostgreSQL audit logging

## Performance Considerations

- Connection pooling enabled by default in Npgsql
- Indexes on foreign keys and frequently queried columns
- Efficient window functions for analytics
- CTEs for complex queries (better readability and potential optimization)

## Migration Documentation

- **migration_final_report.md**: Comprehensive migration report
- **sql_equivalency_validation_report.json**: Equivalency validation results
- **extracted_statements.sql**: Original SQL Server statements
- **converted_statements.sql**: PostgreSQL statements
- **dms_conversion_issues.log**: DMS tool outputs and manual conversions
- **DEPLOYMENT_TESTING_GUIDE.md**: Step-by-step runtime validation guide

## Runtime Validation (Pending)

To complete the migration validation:

1. Follow [DEPLOYMENT_TESTING_GUIDE.md](DEPLOYMENT_TESTING_GUIDE.md)
2. Test all database operations (Exit Criterion 13)
3. Verify transaction atomicity (Exit Criterion 14)
4. Run integration tests (Exit Criterion 15)

## Next Steps

1. ✅ Review migration artifacts (reports, converted statements)
2. ⚠️ Set up PostgreSQL database environment
3. ⚠️ Run runtime validation tests
4. ⏳ Deploy to staging environment
5. ⏳ Perform load testing
6. ⏳ Deploy to production

## Support and Documentation

- PostgreSQL Docs: https://www.postgresql.org/docs/
- Npgsql Docs: https://www.npgsql.org/doc/
- .NET Data Access: https://docs.microsoft.com/en-us/dotnet/standard/data/

## License

[Your License Here]
