# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL using Npgsql, following best practices for data access and application architecture.

**Migration Status:** ✅ Successfully migrated from SQL Server to PostgreSQL

## Prerequisites

- Visual Studio 2022 or later (or any .NET-compatible IDE)
- .NET 9.0 SDK or later
- PostgreSQL 14 or later (or Docker with PostgreSQL image)
- pgAdmin or psql for database management

## Migration Information

This application was migrated from Microsoft SQL Server to PostgreSQL. Key changes include:
- **Package:** Microsoft.Data.SqlClient → Npgsql 8.0.5
- **ADO.NET Classes:** SqlConnection → NpgsqlConnection, SqlCommand → NpgsqlCommand, etc.
- **SQL Syntax:** All statements converted to PostgreSQL-compatible syntax
- **Transaction Handling:** Moved from SQL-level to application-level management

For detailed migration information, see:
- `sql_equivalency_validation_report.json` - SQL statement equivalency validation
- `final_migration_report.json` - Complete migration report
- `POSTGRESQL_TESTING_GUIDE.md` - Comprehensive testing guide

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs          # PostgreSQL data access using Npgsql
├── Models/
│   └── Product.cs                     # Domain models
├── Business/
│   └── ProductService.cs              # Business logic layer
├── CLI/
│   ├── CommandLineInterface.cs        # CLI interface
│   └── InteractiveMenu.cs             # Interactive menu
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql                # Original SQL Server script
│       └── 01_PostgreSQL_InitialSetup.sql     # PostgreSQL schema script
├── Program.cs                          # Application entry point
├── AdoCore.csproj                      # Project file with Npgsql
├── appsettings.json                    # PostgreSQL connection strings
└── POSTGRESQL_TESTING_GUIDE.md         # Testing instructions
```

## Quick Start

### Option 1: Using Docker (Recommended for Testing)

1. **Start PostgreSQL with Docker:**
   ```bash
   docker run --name postgres-adocore \
     -e POSTGRES_PASSWORD=postgres \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_DB=ProductManagement \
     -p 5432:5432 \
     -d postgres:15
   ```

2. **Setup Database Schema:**
   ```bash
   docker cp Database/Scripts/01_PostgreSQL_InitialSetup.sql postgres-adocore:/tmp/
   docker exec -i postgres-adocore psql -U postgres -d ProductManagement -f /tmp/01_PostgreSQL_InitialSetup.sql
   ```

3. **Run the Application:**
   ```bash
   dotnet restore
   dotnet build
   dotnet run -- list
   ```

### Option 2: Using Native PostgreSQL

1. **Install PostgreSQL:**
   - Download from https://www.postgresql.org/download/
   - Install with default settings
   - Note the password you set for the postgres user

2. **Create Database and Schema:**
   ```bash
   # Connect with psql
   psql -U postgres -h localhost
   
   # Run setup script
   \i Database/Scripts/01_PostgreSQL_InitialSetup.sql
   \q
   ```

3. **Update Connection String (if needed):**
   Edit `appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
     },
     "Environment": "Development"
   }
   ```

4. **Run the Application:**
   ```bash
   dotnet restore
   dotnet build
   dotnet run
   ```

## Running the Application

### Interactive Mode

Run without arguments to enter interactive mode:
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

### Database Operations
- **GetAllProductsAsync:** Complex query with window functions (AVG, COUNT OVER)
- **GetProductByIdAsync:** Query with LAG window function for historical analysis
- **InsertProductAsync:** Multi-table transaction with RETURNING clause
- **UpdateProductAsync:** Update with history tracking
- **DeleteProductAsync:** Cascading operation with history and stats updates
- **GetProductsByPriceRangeAsync:** Advanced ranking with RANK() and PERCENT_RANK()
- **GetLowStockProductsAsync:** Stock analysis with window functions

### Technical Features
- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Application-level transaction management
- Parameterized queries for SQL injection prevention
- Connection pooling with Npgsql
- Comprehensive error handling and logging

## Testing

For comprehensive testing instructions, see `POSTGRESQL_TESTING_GUIDE.md`.

Quick test:
```bash
# Verify database connection
dotnet run -- list

# Test CRUD operations
dotnet run -- add "Test Product" 29.99 5 "Test Description"
dotnet run -- get 19  # Use the returned ID
dotnet run -- update 19 "Updated Test" 39.99 10 "Updated"
dotnet run -- delete 19
```

## Troubleshooting

### Connection Issues

**Error: "Npgsql.NpgsqlException: 57P03: the database system is starting up"**
- Solution: Wait 10-30 seconds for PostgreSQL to fully start

**Error: "Npgsql.NpgsqlException: 28P01: password authentication failed"**
- Solution: Update password in `appsettings.json` or reset PostgreSQL password

**Error: "Npgsql.NpgsqlException: 3D000: database 'ProductManagement' does not exist"**
- Solution: Run the schema setup script: `Database/Scripts/01_PostgreSQL_InitialSetup.sql`

**Error: "Npgsql.NpgsqlException: 42P01: relation 'products' does not exist"**
- Solution: Verify schema script executed successfully without errors

### Verify PostgreSQL is Running

```bash
# Docker
docker ps | grep postgres-adocore

# Native (Linux)
sudo systemctl status postgresql

# Windows - Check Services
# Look for "postgresql-x64-15" or similar

# Test connection
psql -U postgres -h localhost -d ProductManagement
```

### Check Connection String

Verify in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true"
  }
}
```

## NuGet Packages

- **Npgsql** 8.0.5 - PostgreSQL data provider for .NET
- **Microsoft.Extensions.Configuration** 8.0.0 - Configuration abstraction
- **Microsoft.Extensions.Configuration.Json** 8.0.0 - JSON configuration provider
- **Microsoft.Extensions.DependencyInjection** 8.0.0 - Dependency injection

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings stored in configuration (not hardcoded)
- Proper error handling prevents information disclosure
- All database resources disposed using async patterns
- Connection pooling managed securely by Npgsql
- Password should be stored in environment variables for production

## Best Practices Implemented

- Modern async/await patterns throughout
- Proper resource disposal with IAsyncDisposable
- Application-level transaction management (BeginTransactionAsync)
- Comprehensive error handling with try-catch-finally
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries, no SQL injection)
- Dependency injection for loose coupling
- Separation of concerns (Data/Business/CLI layers)
- PostgreSQL-specific optimizations (RETURNING clause, NOW() function)

## Production Deployment

### Connection String Configuration

For production, use environment variables:
```bash
export ConnectionStrings__DevConnection="Host=prod-server;Port=5432;Database=ProductManagement;Username=app_user;Password=STRONG_PASSWORD;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100"
```

Or use AWS Secrets Manager, Azure Key Vault, etc.

### Database Migration

1. Export from SQL Server (if applicable)
2. Transform data using PostgreSQL COPY or INSERT statements
3. Verify data integrity
4. Test all application functionality
5. Update production connection strings
6. Deploy application

### Monitoring

Monitor PostgreSQL connections:
```sql
SELECT count(*), state 
FROM pg_stat_activity 
WHERE datname = 'ProductManagement' 
GROUP BY state;
```

## Development Tips

### Enable SQL Logging

Add to `appsettings.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Npgsql": "Debug"
    }
  }
}
```

### Connection String Options

Common Npgsql connection string parameters:
- `Host` - Server hostname or IP
- `Port` - Port number (default: 5432)
- `Database` - Database name
- `Username` - Database user
- `Password` - User password
- `Pooling` - Enable connection pooling (default: true)
- `Minimum Pool Size` - Min connections in pool (default: 1)
- `Maximum Pool Size` - Max connections in pool (default: 100)
- `Connection Lifetime` - Max connection age in seconds
- `Timeout` - Connection timeout in seconds (default: 15)

## Resources

- **Npgsql Documentation:** https://www.npgsql.org/doc/
- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **Migration Reports:**
  - `sql_equivalency_validation_report.json` - SQL equivalency validation
  - `final_migration_report.json` - Complete migration report
  - `dms_conversion_log.txt` - DMS tool conversion log
- **Testing Guide:** `POSTGRESQL_TESTING_GUIDE.md`

## License

[Your License Information]

## Support

For issues related to:
- **Application:** Check migration reports and testing guide
- **PostgreSQL:** Visit https://www.postgresql.org/support/
- **Npgsql:** Visit https://github.com/npgsql/npgsql/issues
