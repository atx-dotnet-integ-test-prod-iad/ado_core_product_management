# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**MIGRATION STATUS**: This application has been successfully migrated from Microsoft SQL Server to PostgreSQL.

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- PostgreSQL 12 or later
- pgAdmin or psql command-line tool

## Important Documentation

Before setting up and running this application, please review:

1. **[DATABASE_SETUP_AND_TESTING.md](DATABASE_SETUP_AND_TESTING.md)** - Complete guide for:
   - PostgreSQL database and schema setup
   - Table creation scripts
   - Test data insertion
   - Verification procedures for all exit criteria
   - Troubleshooting common issues

2. **[SECURITY_CONFIGURATION.md](SECURITY_CONFIGURATION.md)** - Security best practices:
   - Secure credential management
   - Environment variable configuration
   - Cloud secret management (Azure Key Vault, AWS Secrets Manager)
   - SSL/TLS configuration
   - Security monitoring and auditing

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs      # PostgreSQL data access using Npgsql
├── Models/
│   └── Product.cs                # Product domain model
├── Business/
│   └── ProductService.cs         # Business logic layer
├── CLI/
│   ├── CommandLineInterface.cs   # CLI commands
│   └── InteractiveMenu.cs        # Interactive menu
├── Program.cs                     # Application entry point
├── AdoCore.csproj                # Project configuration with Npgsql 8.0.5
├── appsettings.json              # Configuration (see security notes)
├── DATABASE_SETUP_AND_TESTING.md # Database setup guide
└── SECURITY_CONFIGURATION.md     # Security configuration guide
```

## Migration Summary

This application has been migrated from SQL Server to PostgreSQL with the following changes:

### Package Changes
- **Removed**: Microsoft.Data.SqlClient
- **Added**: Npgsql 8.0.5 (latest secure version)

### Code Changes
- All `SqlConnection` → `NpgsqlConnection`
- All `SqlCommand` → `NpgsqlCommand`
- All `SqlDataReader` → `NpgsqlDataReader`
- All `SqlTransaction` → `NpgsqlTransaction`

### SQL Statement Conversions
All 7 SQL statements have been converted to PostgreSQL syntax:
1. GetAllProductsAsync - CTE with window functions (LAG, RANK, DENSE_RANK)
2. GetProductByIdAsync - Window function (LAG)
3. InsertProductAsync - RETURNING clause, CURRENT_TIMESTAMP
4. UpdateProductAsync - Multi-statement transaction
5. DeleteProductAsync - CASCADE delete with CASE
6. GetProductsByPriceRangeAsync - RANK and PERCENT_RANK window functions
7. GetLowStockProductsAsync - Aggregate window functions (AVG, SUM)

### Schema Changes
Database schema migrated to PostgreSQL with lowercase identifiers:
- Schema: `productmanagement_dbo`
- Tables: `products`, `producthistory`, `productstats`

## Quick Start

### Step 1: Database Setup

**IMPORTANT**: Before running the application, you MUST set up the PostgreSQL database. 

See **[DATABASE_SETUP_AND_TESTING.md](DATABASE_SETUP_AND_TESTING.md)** for complete instructions, including:
- Database creation
- Schema creation
- Table creation with correct structure
- Test data insertion

### Step 2: Configure Connection

The default connection string in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;SSL Mode=Prefer"
  }
}
```

**For production**: See **[SECURITY_CONFIGURATION.md](SECURITY_CONFIGURATION.md)** for secure credential management.

### Step 3: Build and Run

```bash
# Navigate to project directory
cd sourceCode

# Restore NuGet packages (includes Npgsql 8.0.5)
dotnet restore

# Build the project
dotnet build

# Run in interactive mode
dotnet run

# Or run with CLI commands
dotnet run -- list
```

## Running the Application

The application supports two modes: Interactive (menu-driven) and Command-Line Interface (CLI).

### Interactive Mode

Run without arguments to see the menu:
```bash
dotnet run
```

Menu options:
```
Product Management System
------------------------
1. List all products
2. Get product by ID
3. Create new product
4. Update product
5. Delete product
6. Get products by price range
7. Get low stock products
Q. Quit
```

### Command-Line Interface (CLI)

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

- **Modern Async/Await**: All database operations use async patterns
- **PostgreSQL Native**: Uses Npgsql for optimal PostgreSQL performance
- **Advanced SQL**: Window functions, CTEs, RETURNING clause
- **Transaction Support**: Atomic operations with proper rollback
- **Parameterized Queries**: Protection against SQL injection
- **Connection Pooling**: Efficient database connection management
- **Error Handling**: Comprehensive exception handling and logging
- **Security**: Following PostgreSQL and .NET security best practices

## Testing

For comprehensive testing instructions, see **[DATABASE_SETUP_AND_TESTING.md](DATABASE_SETUP_AND_TESTING.md)**, which includes:

- Database connectivity testing (Exit Criterion 12)
- All database operations testing (Exit Criterion 13)
- Transaction atomicity verification (Exit Criterion 14)
- Performance testing
- Troubleshooting guides

Quick test after setup:
```bash
# Test database connection and list products
dotnet run -- list

# Test insert with RETURNING clause
dotnet run -- add "Test Product" 29.99 5 "Test Description"

# Test retrieval
dotnet run -- get 1
```

## Troubleshooting

### Connection Issues
1. Verify PostgreSQL is running:
   ```bash
   # Linux
   systemctl status postgresql
   
   # Windows - check Services app
   ```

2. Check connection string in `appsettings.json`
3. Verify PostgreSQL accepts connections on port 5432
4. Check `pg_hba.conf` for authentication settings

### Database Issues
1. Ensure database `ProductManagement` exists
2. Verify schema `productmanagement_dbo` is created
3. Check tables exist with correct lowercase names
4. Verify your user has appropriate permissions

### Build Issues
1. Ensure .NET 9.0 SDK is installed:
   ```bash
   dotnet --version
   ```
2. Restore packages:
   ```bash
   dotnet restore
   ```

For more troubleshooting, see **[DATABASE_SETUP_AND_TESTING.md](DATABASE_SETUP_AND_TESTING.md)**.

## Required NuGet Packages

- **Npgsql** (8.0.5) - PostgreSQL data provider
- **Microsoft.Extensions.Configuration** (8.0.0)
- **Microsoft.Extensions.Configuration.Json** (8.0.0)
- **Microsoft.Extensions.DependencyInjection** (8.0.0)

## Security Considerations

**CRITICAL**: The default `appsettings.json` contains placeholder credentials for development only.

For production deployments:
1. **Never use hardcoded credentials**
2. Use environment variables or secret management
3. Enable SSL/TLS (SSL Mode=Require)
4. Follow principle of least privilege
5. Regularly rotate credentials

See **[SECURITY_CONFIGURATION.md](SECURITY_CONFIGURATION.md)** for complete security guidance.

## Best Practices Implemented

- Modern async/await patterns for all I/O operations
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Parameterized queries for SQL injection prevention
- Connection pooling for performance
- Error handling with detailed logging
- Configuration management using .NET Core's IConfiguration
- Security best practices following OWASP guidelines
- Dependency injection for loose coupling
- Separation of concerns (layered architecture)

## Migration Artifacts

The following files document the migration process:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.txt` - DMS tool conversion log
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `final_migration_report.md` - Complete migration report

## Performance Considerations

PostgreSQL-specific optimizations:
1. Connection pooling (built into Npgsql)
2. Prepared statements for repeated queries
3. Appropriate indexes on frequently queried columns
4. Window functions for analytics without subqueries
5. RETURNING clause to eliminate round-trips

## Known Limitations

1. **Exit Criteria 12-14**: Runtime testing requires a live PostgreSQL database
2. **Exit Criteria 15**: No unit tests exist in the codebase
3. **SQL Equivalency**: All statements marked as ERROR due to equivalency tool limitations (cannot prove/disprove equivalency)

## Next Steps

1. **Immediate**: Set up PostgreSQL database using DATABASE_SETUP_AND_TESTING.md
2. **Before Production**: Implement secure credential management using SECURITY_CONFIGURATION.md
3. **Recommended**: Create unit and integration tests
4. **Performance**: Analyze and optimize indexes based on query patterns
5. **Monitoring**: Implement application performance monitoring (APM)
6. **Backup**: Establish database backup and recovery procedures

## Support and Documentation

- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [.NET Data Access Documentation](https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/)
- [PostgreSQL Window Functions](https://www.postgresql.org/docs/current/tutorial-window.html)

## Version History

- **v2.0** - PostgreSQL Migration (Current)
  - Migrated from SQL Server to PostgreSQL
  - Upgraded to Npgsql 8.0.5
  - Added comprehensive security documentation
  - Added database setup and testing documentation
  
- **v1.0** - Original SQL Server Version
  - ADO.NET with Microsoft.Data.SqlClient
  - SQL Server specific features
