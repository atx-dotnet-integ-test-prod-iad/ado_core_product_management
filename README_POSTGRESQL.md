# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**⚠️ MIGRATION NOTICE**: This application has been successfully migrated from Microsoft SQL Server to PostgreSQL.

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- **PostgreSQL 12 or later** (instead of SQL Server)
- pgAdmin or psql command-line tool (instead of SSMS)
- **For detailed PostgreSQL setup instructions, see `Database/POSTGRESQL_SETUP_GUIDE.md`**

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs (migrated to PostgreSQL)
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   ├── Scripts/
│   │   ├── 01_InitialSetup.sql (SQL Server - legacy)
│   │   └── 01_PostgreSQL_InitialSetup.sql (PostgreSQL - use this)
│   └── POSTGRESQL_SETUP_GUIDE.md
├── Program.cs
├── AdoCore.csproj (now uses Npgsql)
└── appsettings.json (PostgreSQL connection strings)
```

## Quick Start

### Step 1: Set up PostgreSQL Database

**Option A: Using Docker (Recommended for Development)**
```bash
docker run --name postgres-productmgmt \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15
```

**Option B: Native Installation**
See `Database/POSTGRESQL_SETUP_GUIDE.md` for detailed instructions.

### Step 2: Initialize Database Schema

```bash
# Using psql
psql -U postgres -h localhost -p 5432 -d ProductManagement \
  -f Database/Scripts/01_PostgreSQL_InitialSetup.sql

# Or using pgAdmin: Open Query Tool and execute the script
```

### Step 3: Update Connection String

Edit `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
  },
  "Environment": "Development"
}
```

### Step 4: Build and Run

```bash
# Restore packages
dotnet restore

# Build the project
dotnet build

# Run the application
dotnet run
```

## Running the Application

### Interactive Mode

Run without arguments to access the menu:
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
6. Update product stock
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

## Migration from SQL Server

This application has been migrated from SQL Server to PostgreSQL with the following changes:

### Database Changes
- **Identity columns**: `IDENTITY(1,1)` → `SERIAL`
- **Data types**: `NVARCHAR` → `VARCHAR`, `BIT` → `BOOLEAN`
- **Functions**: `GETDATE()` → `CURRENT_TIMESTAMP`, `SCOPE_IDENTITY()` → `RETURNING` clause
- **Stored Procedures**: Converted to PostgreSQL functions
- **Triggers**: Converted to PostgreSQL trigger functions

### Code Changes
- **Package**: `Microsoft.Data.SqlClient` → `Npgsql 8.0.5`
- **Classes**: `SqlConnection` → `NpgsqlConnection`, `SqlCommand` → `NpgsqlCommand`, etc.
- **Connection Strings**: Updated to PostgreSQL format
- **Transaction Handling**: Updated to use PostgreSQL-specific patterns

### Migration Artifacts

All migration artifacts are available in the project root:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - PostgreSQL converted statements
- `dms_conversion_log.txt` - Conversion process log
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `migration_report.md` - Comprehensive migration report

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- **PostgreSQL-specific transaction support** with async operations
- Parameterized queries for security
- **PostgreSQL connection pooling** and management
- Error handling and logging
- **RETURNING clause** support for efficient INSERT/UPDATE/DELETE operations

## Testing the Application

### Verify Database Connection

```bash
# Test connection by listing products
dotnet run -- list
```

Expected output: List of 18 sample products from the database

### Test CRUD Operations

```bash
# Create a product
dotnet run -- add "Test Product" 99.99 10 "Test Description"
# Note the returned product ID

# Get product by ID
dotnet run -- get 19

# Update product
dotnet run -- update 19 "Updated Product" 89.99 15 "Updated Description"

# Delete product
dotnet run -- delete 19
```

### Test Transaction Integrity

All INSERT, UPDATE, and DELETE operations use transactions with proper rollback handling. If an error occurs, changes will be automatically rolled back.

## Troubleshooting

### Connection Failed

**Error**: "could not connect to server: Connection refused"

**Solutions**:
1. Verify PostgreSQL is running:
   ```bash
   # Docker
   docker ps | grep postgres-productmgmt
   
   # Native Linux
   sudo systemctl status postgresql
   
   # Native macOS
   brew services list | grep postgresql
   ```

2. Check port 5432 is accessible
3. Verify connection string in `appsettings.json`

### Authentication Failed

**Error**: "password authentication failed for user 'postgres'"

**Solutions**:
1. Verify password in connection string
2. Reset postgres password (see POSTGRESQL_SETUP_GUIDE.md)

### Build Errors

**Error**: "The type or namespace name 'SqlConnection' could not be found"

**Solutions**:
1. Ensure you're using the migrated version
2. Run `dotnet restore`
3. Verify `Npgsql` package is installed (check AdoCore.csproj)

### No Sample Data

**Error**: "No products found"

**Solutions**:
1. Verify database setup script was run successfully
2. Re-run the PostgreSQL setup script
3. Check for errors in PostgreSQL logs

## Required NuGet Packages

- **Npgsql 8.0.5** (PostgreSQL driver)
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings should use environment variables in production (not hardcoded passwords)
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- **SSL Mode should be enabled for production** (`SSL Mode=Require`)
- Connection pooling is configured for optimal performance

## Best Practices Implemented

- Modern async/await patterns
- Proper resource disposal with IAsyncDisposable
- **PostgreSQL-specific transaction management** with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices
- Dependency injection
- Separation of concerns (layered architecture)
- **Use of PostgreSQL RETURNING clause** for efficient operations

## Performance Optimization

The application uses PostgreSQL-specific optimizations:

1. **Connection Pooling**: Configured in connection string
   ```
   Pooling=true;Minimum Pool Size=5;Maximum Pool Size=20
   ```

2. **RETURNING Clause**: Eliminates extra round trips for INSERT/UPDATE/DELETE operations

3. **Efficient Window Functions**: CTEs and window functions for complex queries

4. **Proper Indexing**: Indexes created on foreign keys and frequently queried columns

## Deployment Options

### AWS RDS PostgreSQL
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-instance.region.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=admin;Password=YOUR_PASSWORD;SSL Mode=Require"
  }
}
```

### Azure Database for PostgreSQL
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-server.postgres.database.azure.com;Port=5432;Database=ProductManagement;Username=admin@your-server;Password=YOUR_PASSWORD;SSL Mode=Require"
  }
}
```

### Docker Compose (Development)
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ProductManagement
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
volumes:
  postgres_data:
```

## Additional Documentation

- **Database Setup**: See `Database/POSTGRESQL_SETUP_GUIDE.md` for comprehensive PostgreSQL setup instructions
- **Migration Report**: See `migration_report.md` for detailed migration documentation
- **SQL Conversions**: See `converted_statements.sql` for all converted SQL statements
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/

## Support and Resources

- **PostgreSQL**: https://www.postgresql.org/
- **Npgsql**: https://www.npgsql.org/
- **.NET Data Access**: https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/

## Next Steps

1. ✅ Install PostgreSQL
2. ✅ Run PostgreSQL setup script
3. ✅ Update connection string with your credentials
4. ✅ Test application connectivity
5. ✅ Verify all CRUD operations
6. ✅ Set up monitoring and backups
7. ✅ Configure production security settings

For production deployment, refer to `Database/POSTGRESQL_SETUP_GUIDE.md` for security best practices, backup procedures, and performance tuning.
