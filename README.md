# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**⚠️ Migration Notice**: This application has been migrated from Microsoft SQL Server to PostgreSQL. See the [SQL Server to PostgreSQL Migration](#migration-from-sql-server-to-postgresql) section for details.

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (PostgreSQL 15+ recommended for best performance)
- pgAdmin 4, DBeaver, or any PostgreSQL database management tool

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs     # PostgreSQL data access using Npgsql
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Program.cs
├── AdoCore.csproj
├── appsettings.json             # Configuration template (no real passwords)
└── appsettings.Development.json.template  # Local config template
```

## Setup Instructions

### 1. Database Setup

**Create PostgreSQL Database**:

```sql
-- Connect to PostgreSQL using psql, pgAdmin, or DBeaver
-- Run these commands:

CREATE DATABASE "ProductManagement";

\c ProductManagement

-- Create Products table
CREATE TABLE "Products" (
    "ProductId" SERIAL PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL,
    "Price" DECIMAL(10, 2) NOT NULL,
    "StockQuantity" INTEGER NOT NULL,
    "Description" TEXT,
    "CreatedDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Optional: Create ProductHistory table for audit trail
CREATE TABLE "ProductHistory" (
    "HistoryId" SERIAL PRIMARY KEY,
    "ProductId" INTEGER NOT NULL,
    "ChangeDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "ChangeType" VARCHAR(50),
    "OldValue" TEXT,
    "NewValue" TEXT
);

-- Optional: Create ProductStats table
CREATE TABLE "ProductStats" (
    "StatId" SERIAL PRIMARY KEY,
    "ProductId" INTEGER NOT NULL,
    "ViewCount" INTEGER DEFAULT 0,
    "LastViewed" TIMESTAMP
);

-- Insert sample data
INSERT INTO "Products" ("Name", "Price", "StockQuantity", "Description") VALUES
('Gaming Mouse', 49.99, 10, 'High-performance gaming mouse'),
('Mechanical Keyboard', 89.99, 15, 'RGB mechanical keyboard'),
('USB-C Cable', 12.99, 50, '6ft USB-C charging cable');
```

### 2. Application Configuration

**Create Local Configuration File**:

```bash
# Copy the template to create your local config
cp appsettings.Development.json.template appsettings.Development.json

# Edit appsettings.Development.json and set your PostgreSQL password
# This file is in .gitignore and won't be committed
```

**appsettings.Development.json example**:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_REAL_PASSWORD;Port=5432;Pooling=true;Timeout=30"
  },
  "Environment": "Development"
}
```

**Alternative: Use Environment Variables** (recommended for production):

```bash
# Linux/Mac
export CONNECTIONSTRINGS__DEVCONNECTION="Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Port=5432;Pooling=true;Timeout=30"

# Windows PowerShell
$env:CONNECTIONSTRINGS__DEVCONNECTION="Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Port=5432;Pooling=true;Timeout=30"

# Windows Command Prompt
set CONNECTIONSTRINGS__DEVCONNECTION=Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Port=5432;Pooling=true;Timeout=30
```

### 3. Build and Run

```bash
# Navigate to project directory
cd sourceCode

# Restore NuGet packages
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

Run without arguments to access the interactive menu:

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

Execute specific commands directly:

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

### PostgreSQL-Specific Enhancements
- **Npgsql provider** for optimal PostgreSQL performance
- **Connection pooling** for efficient resource management
- **Async operations** throughout for better scalability
- **Parameterized queries** to prevent SQL injection
- **PostgreSQL native types** support (arrays, JSON, etc.)

### Application Features
- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations
- Error handling and logging
- Layered architecture (separation of concerns)

## Testing the Application

### Quick Test Sequence

```bash
# 1. List all products (should show sample data)
dotnet run -- list

# 2. Add a new product
dotnet run -- add "Test Product" 29.99 5 "Test Description"

# 3. Get the new product (note the ProductId from previous command)
dotnet run -- get <ProductId>

# 4. Update stock quantity
dotnet run -- stock <ProductId> 20

# 5. Delete the test product
dotnet run -- delete <ProductId>
```

## Troubleshooting

### Connection Issues

**Error: "Connection refused" or "Could not connect"**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list | grep postgresql  # Mac
# Windows: Check Services app for PostgreSQL service

# Verify PostgreSQL is listening on port 5432
netstat -an | grep 5432
```

**Error: "password authentication failed"**
- Verify your password in appsettings.Development.json
- Check PostgreSQL pg_hba.conf for authentication settings
- Ensure the postgres user exists and has correct permissions

**Error: "database does not exist"**
```bash
# List databases to verify ProductManagement exists
psql -U postgres -c "\l"

# Create if missing
psql -U postgres -c "CREATE DATABASE \"ProductManagement\";"
```

### Build Issues

**Error: "Package Npgsql could not be found"**
```bash
# Restore packages
dotnet restore

# If issues persist, clear cache and restore
dotnet nuget locals all --clear
dotnet restore
```

**Compilation errors after migration**
```bash
# Verify .NET 9.0 SDK is installed
dotnet --version

# Clean and rebuild
dotnet clean
dotnet build
```

## Required NuGet Packages

- **Npgsql** (10.0.1) - PostgreSQL data provider for .NET
- **Microsoft.Extensions.Configuration** (8.0.0) - Configuration framework
- **Microsoft.Extensions.Configuration.Json** (8.0.0) - JSON configuration provider
- **Microsoft.Extensions.DependencyInjection** (8.0.0) - Dependency injection

## Security Considerations

### Implemented Security Measures
- ✅ **Parameterized queries** prevent SQL injection attacks
- ✅ **No hardcoded passwords** in source control (template only)
- ✅ **Environment variable support** for production secrets
- ✅ **Connection pooling** with timeout limits
- ✅ **Proper resource disposal** using async patterns
- ✅ **.gitignore protection** for appsettings.Development.json

### Production Security Checklist
- [ ] Use environment variables or secrets manager (AWS Secrets Manager, Azure Key Vault)
- [ ] Enable SSL/TLS for database connections (add `SslMode=Require` to connection string)
- [ ] Use least-privilege database accounts (not postgres superuser)
- [ ] Implement connection string encryption at rest
- [ ] Regular security updates for Npgsql and dependencies
- [ ] Enable PostgreSQL audit logging
- [ ] Use strong passwords (min 16 characters, complex)

## Migration from SQL Server to PostgreSQL

This application was migrated from Microsoft SQL Server to PostgreSQL. Key changes:

### Code Changes
- Replaced `Microsoft.Data.SqlClient` with `Npgsql`
- Updated all ADO.NET classes:
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`
  - `SqlParameter` → `NpgsqlParameter`

### SQL Syntax Changes
- `SCOPE_IDENTITY()` → `RETURNING` clause
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `BEGIN TRANSACTION/COMMIT` → Simplified to single statements or application-level transactions
- Square brackets `[TableName]` → Double quotes `"TableName"` (optional in PostgreSQL)

### Connection String Changes
```
Before (SQL Server):
Server=localhost;Database=ProductManagement;Trusted_Connection=True;...

After (PostgreSQL):
Host=localhost;Database=ProductManagement;Username=postgres;Password=...;Port=5432;...
```

### Migration Artifacts
The following files document the complete migration process:
- `extracted_statements.sql` - All original SQL Server statements
- `converted_statements.sql` - SQL Server to PostgreSQL conversion mapping
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `dms_conversion_issues.log` - DMS tool processing log
- `TRANSFORMATION_VALIDATION_REPORT.md` - Complete validation report

## Best Practices Implemented

- ✅ Modern async/await patterns throughout
- ✅ Proper resource disposal with IAsyncDisposable
- ✅ Transaction management with async support
- ✅ Error handling and graceful degradation
- ✅ Configuration management using .NET Core's IConfiguration
- ✅ Security best practices (parameterized queries, no hardcoded secrets)
- ✅ Dependency injection
- ✅ Separation of concerns (layered architecture)
- ✅ Connection pooling for performance
- ✅ Comprehensive documentation

## Performance Considerations

### PostgreSQL Optimizations
- Connection pooling enabled (`Pooling=true`)
- Appropriate timeout settings (`Timeout=30`)
- Efficient use of async operations
- Proper index usage (ensure indexes on frequently queried columns)

### Recommended PostgreSQL Tuning
```sql
-- Add indexes for frequently queried columns
CREATE INDEX idx_products_name ON "Products"("Name");
CREATE INDEX idx_products_price ON "Products"("Price");

-- Analyze tables for query optimization
ANALYZE "Products";
```

## Deployment

### Local Development
1. Install PostgreSQL locally
2. Create `appsettings.Development.json` with local credentials
3. Run `dotnet build && dotnet run`

### Production Deployment (AWS/Azure/GCP)

**AWS RDS PostgreSQL**:
```bash
# Set environment variables
export CONNECTIONSTRINGS__PRODCONNECTION="Host=your-rds-endpoint.amazonaws.com;Database=ProductManagement;Username=dbuser;Password=$DB_PASSWORD;Port=5432;SslMode=Require"
export ENVIRONMENT=Production

# Deploy and run
dotnet publish -c Release
dotnet AdoCore.dll
```

**Docker Container**:
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY bin/Release/net9.0/publish/ .
ENTRYPOINT ["dotnet", "AdoCore.dll"]
```

## Support and Documentation

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **.NET Documentation**: https://docs.microsoft.com/dotnet/

## License

[Add your license information here]
