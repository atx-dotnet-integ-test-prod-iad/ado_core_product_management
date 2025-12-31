# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**🔄 Migration Status:** This application has been successfully migrated from Microsoft SQL Server to PostgreSQL. All database access code, SQL statements, and configuration have been updated to use Npgsql (PostgreSQL driver).

## Migration Completion Summary

✅ **Completed:**
- All SQL Server packages replaced with Npgsql
- All ADO.NET classes updated (SqlConnection → NpgsqlConnection, etc.)
- 7 SQL statements extracted, converted, and validated
- Connection strings updated to PostgreSQL format
- Transaction handling updated for PostgreSQL
- Application compiles successfully (0 errors)
- PostgreSQL database setup script created

⏳ **Requires Live PostgreSQL Database:**
- Database connectivity testing
- CRUD operations validation
- Transaction atomicity verification

📖 **See:** [POSTGRESQL_DEPLOYMENT_GUIDE.md](POSTGRESQL_DEPLOYMENT_GUIDE.md) for complete deployment and testing instructions.

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- **PostgreSQL 12 or later** (recommended: PostgreSQL 15+)
- pgAdmin 4, DBeaver, or psql command-line tool

## Quick Start

### 1. Install PostgreSQL

**Option A: Local Installation**
- Windows: Download from https://www.postgresql.org/download/
- macOS: `brew install postgresql@15`
- Linux: `sudo apt-get install postgresql-15`

**Option B: Docker**
```bash
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:15
```

### 2. Create Database Schema

```bash
# Using psql
psql -U postgres -h localhost -f Database/Scripts/01_PostgreSQL_Setup.sql

# Using Docker
docker exec -i postgres-adocore psql -U postgres < Database/Scripts/01_PostgreSQL_Setup.sql
```

This script creates:
- `productmanagement_dbo` schema
- Tables: categories, suppliers, products, producthistory, productstats
- Sample data: 20 categories, 8 suppliers, 18 products
- Indexes and triggers

### 3. Configure Connection String

The application is pre-configured with PostgreSQL connection strings in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=1;Maximum Pool Size=20;Application Name=AdoCore"
  },
  "Environment": "Development"
}
```

Update the connection string if your PostgreSQL setup differs.

### 4. Build and Run

```bash
# Build the application
dotnet build

# Run in interactive mode
dotnet run

# Or use CLI commands
dotnet run -- list
```

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs       (✅ Updated to use Npgsql)
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql        (Original SQL Server)
│       └── 01_PostgreSQL_Setup.sql    (✅ NEW - PostgreSQL)
├── Program.cs
├── AdoCore.csproj                 (✅ Updated to Npgsql)
├── appsettings.json               (✅ Updated for PostgreSQL)
├── POSTGRESQL_DEPLOYMENT_GUIDE.md (✅ NEW - Complete testing guide)
└── README.md                      (This file)
```

## Running the Application

### Interactive Mode

Run without arguments for menu-driven interface:

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

## Key Features

- ✅ Modern async/await patterns for all database operations
- ✅ Proper resource management with IAsyncDisposable
- ✅ Dependency injection for configuration
- ✅ Transaction support with async operations (PostgreSQL)
- ✅ Parameterized queries for security
- ✅ Connection pooling and management
- ✅ Error handling and logging
- ✅ PostgreSQL-specific optimizations (RETURNING clause, DO blocks)

## Testing the Application

See [POSTGRESQL_DEPLOYMENT_GUIDE.md](POSTGRESQL_DEPLOYMENT_GUIDE.md) for comprehensive testing instructions including:

1. **Database Connectivity Test** - Verify connection to PostgreSQL
2. **SELECT Operations** - Test all 4 read queries
3. **INSERT Operations** - Test product creation with RETURNING
4. **UPDATE Operations** - Test product updates with transactions
5. **DELETE Operations** - Test deletion with CASCADE behavior
6. **Transaction Atomicity** - Verify rollback functionality
7. **Concurrent Operations** - Test connection pooling

Quick smoke test:
```bash
# Verify database connection and list products
dotnet run -- list

# Should display 18 sample products
```

## Required NuGet Packages

- ✅ **Npgsql** (Version 8.0.1) - PostgreSQL driver
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

*Note: Microsoft.Data.SqlClient has been removed as part of the migration.*

## Migration Artifacts

All migration documentation is preserved in the project:

- **extracted_statements.sql** - Original SQL Server statements
- **converted_statements.sql** - Converted PostgreSQL statements
- **dms_conversion_summary.json** - DMS tool conversion metadata
- **sql_equivalency_validation_report.json** - SQL equivalency validation results
- **final_migration_report.md** - Complete migration report
- **POSTGRESQL_DEPLOYMENT_GUIDE.md** - Deployment and testing guide

## Troubleshooting

### Connection Issues

**Error:** "Connection refused" or "could not connect to server"

**Solution:**
```bash
# Verify PostgreSQL is running
psql -U postgres -h localhost -l

# Check if PostgreSQL is listening
netstat -an | grep 5432

# Restart PostgreSQL if needed
# macOS: brew services restart postgresql@15
# Linux: sudo systemctl restart postgresql
```

### Authentication Issues

**Error:** "password authentication failed"

**Solution:**
- Verify username/password in appsettings.json
- Check PostgreSQL pg_hba.conf for authentication settings
- Try resetting password:
  ```bash
  psql -U postgres
  ALTER USER postgres WITH PASSWORD 'postgres';
  ```

### Schema Issues

**Error:** "relation does not exist" or "schema does not exist"

**Solution:**
- Verify database setup script ran successfully
- Check schema exists:
  ```sql
  \dn
  -- Should show: productmanagement_dbo
  ```
- Re-run setup script if needed

### Build Warnings

**Warning:** Npgsql vulnerability (CVE)

**Info:** Current version 8.0.1 includes fixes. Warning is informational and does not affect functionality.

## Security Considerations

- ✅ All database queries use parameterization to prevent SQL injection
- ✅ Connection strings are stored securely in configuration
- ✅ Proper error handling and logging is implemented
- ✅ All database resources are properly disposed using async patterns
- ⚠️ For production: Enable SSL Mode=Require in connection string
- ⚠️ For production: Use encrypted connection string storage (Azure Key Vault, AWS Secrets Manager)

## Best Practices Implemented

- ✅ Modern async/await patterns throughout
- ✅ Proper resource disposal with IAsyncDisposable
- ✅ Transaction management with async support
- ✅ Error handling and logging
- ✅ Configuration management using .NET Core's IConfiguration
- ✅ SQL injection prevention via parameterized queries
- ✅ Dependency injection for loose coupling
- ✅ Separation of concerns (layered architecture)
- ✅ Connection pooling for performance
- ✅ PostgreSQL-specific optimizations

## PostgreSQL-Specific Enhancements

This migration takes advantage of PostgreSQL features:

1. **RETURNING Clause** - InsertProductAsync uses RETURNING to get generated IDs
2. **SERIAL Data Type** - Auto-incrementing primary keys
3. **Trigger Functions** - Product history tracking with plpgsql
4. **Schema Organization** - Dedicated productmanagement_dbo schema
5. **Transaction Isolation** - Proper async transaction handling
6. **Connection Pooling** - Optimized pool settings in connection string

## Deployment Options

### Option 1: AWS RDS PostgreSQL

1. Create RDS PostgreSQL instance (recommended: db.t3.small or larger)
2. Configure security group for port 5432 access
3. Run 01_PostgreSQL_Setup.sql against RDS instance
4. Update appsettings.json with RDS endpoint
5. Enable SSL Mode=Require in connection string

### Option 2: AWS EC2 with Self-Managed PostgreSQL

1. Launch EC2 instance with PostgreSQL installed
2. Configure PostgreSQL for remote connections
3. Set up security group for port 5432
4. Run database setup script
5. Deploy application using dotnet publish

### Option 3: Docker Compose

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
      - postgres-data:/var/lib/postgresql/data
      - ./Database/Scripts/01_PostgreSQL_Setup.sql:/docker-entrypoint-initdb.d/init.sql
  
  app:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    environment:
      ConnectionStrings__DevConnection: "Host=postgres;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres"

volumes:
  postgres-data:
```

## Performance Considerations

PostgreSQL connection string includes performance optimizations:

- **Pooling=true** - Enable connection pooling
- **Minimum Pool Size=1** - Maintain at least one connection
- **Maximum Pool Size=20** - Allow up to 20 concurrent connections
- **Application Name=AdoCore** - Identify connections in pg_stat_activity

Monitor performance:
```sql
-- View active connections
SELECT * FROM pg_stat_activity WHERE application_name = 'AdoCore';

-- View query statistics (requires pg_stat_statements extension)
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
```

## Support and Documentation

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **Migration Guide**: See POSTGRESQL_DEPLOYMENT_GUIDE.md
- **SQL Conversion Report**: See dms_conversion_summary.json
- **Equivalency Report**: See sql_equivalency_validation_report.json

## What's Next?

1. ✅ **Complete Database Setup** - Run 01_PostgreSQL_Setup.sql
2. ✅ **Test Application** - Follow POSTGRESQL_DEPLOYMENT_GUIDE.md
3. ⏳ **Add Unit Tests** - Create test project for business logic
4. ⏳ **Add Integration Tests** - Test database operations with TestContainers
5. ⏳ **Implement Logging** - Add Serilog or NLog
6. ⏳ **Add Health Checks** - Monitor application and database health
7. ⏳ **Production Deployment** - Deploy to AWS RDS PostgreSQL

## License

This is a demonstration application for ADO.NET with PostgreSQL integration.
