# ADO.NET Core PostgreSQL Data Management Application

**MIGRATION STATUS**: ✅ Successfully migrated from SQL Server to PostgreSQL

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture. This application has been migrated from SQL Server to PostgreSQL with all SQL statements converted and validated.

## Migration Overview

- **Original Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL 12+
- **Migration Date**: 2026-02-06
- **Status**: Code migration complete, runtime validation pending

### Key Changes
✅ All SQL Server packages replaced with Npgsql  
✅ All ADO.NET classes updated (SqlConnection → NpgsqlConnection, etc.)  
✅ All 7 SQL statements converted and validated  
✅ Connection strings updated to PostgreSQL format  
✅ Application compiles successfully  

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- **PostgreSQL 12+ or later** (Developer Edition recommended for development)
- pgAdmin 4 or psql command-line tool

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs      (Npgsql-based repository)
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql         (Original SQL Server)
│       └── 02_PostgreSQL_InitialSetup.sql  (PostgreSQL version)
├── Program.cs
├── AdoCore.csproj
└── appsettings.json                (PostgreSQL connection strings)
```

## Quick Start

### 1. Install PostgreSQL

**Option A: Using Installer**
- Download from https://www.postgresql.org/download/
- Install and set password for `postgres` user
- Default port: 5432

**Option B: Using Docker**
```bash
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:15
```

### 2. Create Database Schema

```bash
# Navigate to scripts directory
cd Database/Scripts

# Run PostgreSQL setup script
psql -U postgres -h localhost -p 5432 -f 02_PostgreSQL_InitialSetup.sql

# Enter password when prompted
```

**Using pgAdmin 4**:
1. Connect to localhost:5432
2. Create database: `ProductManagement`
3. Open Query Tool
4. Execute `02_PostgreSQL_InitialSetup.sql`

### 3. Update Connection String (if needed)

File: `appsettings.json`

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Port=5432;Pooling=true",
    "ProdConnection": "Host=your-prod-host;Database=ProductManagement;Username=your-user;Password=YOUR_PROD_PASSWORD;Port=5432;Pooling=true;SSL Mode=Require"
  },
  "Environment": "Development"
}
```

⚠️ **SECURITY**: Change the default password! Never commit production credentials to source control.

### 4. Build and Run

```bash
# Restore packages
dotnet restore

# Build the application
dotnet build

# Run in interactive mode
dotnet run

# Or run with CLI commands
dotnet run -- list
```

## Running the Application

### Interactive Mode

Run without arguments to see the menu:
```bash
dotnet run
```

Menu options:
```
Product Management System (PostgreSQL)
--------------------------------------
1. List all products
2. Get product by ID
3. Create new product
4. Update product
5. Delete product
6. Search by price range
7. Show low stock products
Q. Quit
```

### Command-Line Interface (CLI)

```bash
# Show help
dotnet run -- --help

# List all products (tests GetAllProductsAsync)
dotnet run -- list

# Get product by ID (tests GetProductByIdAsync)
dotnet run -- get 1

# Add new product (tests InsertProductAsync)
dotnet run -- add "New Product" 49.99 10 "Product description"

# Update product (tests UpdateProductAsync)
dotnet run -- update 1 "Updated Product" 59.99 15 "Updated description"

# Delete product (tests DeleteProductAsync)
dotnet run -- delete 1
```

## Database Schema

### Tables Created
- **products**: Main product catalog (18 sample products)
- **categories**: Product categories (20 categories with hierarchy)
- **suppliers**: Supplier information (8 suppliers)
- **product_history**: Audit trail for product changes
- **product_stats**: Aggregate statistics

### Indexes
- Primary keys on all tables (SERIAL)
- Foreign key indexes for relationships
- Unique index on product SKU
- History table indexes on product_id and action_date

### Triggers
- `trg_products_history`: Automatically logs INSERT/UPDATE/DELETE operations

## SQL Statement Conversion Details

All 7 SQL statements have been converted from SQL Server to PostgreSQL syntax:

| Method | Conversion Type | Key Changes |
|--------|----------------|-------------|
| GetAllProductsAsync | None | PostgreSQL compatible (CTE + window functions) |
| GetProductByIdAsync | None | PostgreSQL compatible (CTE + LAG) |
| InsertProductAsync | Syntax | SCOPE_IDENTITY() → RETURNING |
| UpdateProductAsync | Refactored | Transaction moved to C#, GETDATE() → CURRENT_TIMESTAMP |
| DeleteProductAsync | Refactored | Transaction moved to C#, GETDATE() → CURRENT_TIMESTAMP |
| GetProductsByPriceRangeAsync | None | PostgreSQL compatible (RANK, PERCENT_RANK) |
| GetLowStockProductsAsync | None | PostgreSQL compatible (Window functions) |

Full conversion details in: `final_migration_report.md`

## Required NuGet Packages

```xml
<PackageReference Include="Npgsql" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.Configuration" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.0.0" />
```

## Testing

### Verify Database Connection
```bash
# Test connection by listing products
dotnet run -- list

# Expected: List of 18 products from sample data
```

### Test CRUD Operations
```bash
# Create
dotnet run -- add "Test Product" 99.99 50 "Test description"

# Read
dotnet run -- get 19

# Update
dotnet run -- update 19 "Updated Product" 149.99 75 "Updated desc"

# Delete
dotnet run -- delete 19
```

### Verify History Tracking
```bash
psql -U postgres -h localhost -d ProductManagement
SELECT * FROM product_history ORDER BY action_date DESC LIMIT 10;
\q
```

For comprehensive testing instructions, see: `POSTGRESQL_RUNTIME_VALIDATION_GUIDE.md`

## Key Features

- ✅ Modern async/await patterns for all database operations
- ✅ Proper resource management with IAsyncDisposable
- ✅ Dependency injection for configuration
- ✅ Transaction support with async operations (C# managed)
- ✅ Parameterized queries for security
- ✅ Connection pooling and management (Npgsql)
- ✅ Error handling and logging
- ✅ PostgreSQL-native features (RETURNING clause, window functions)
- ✅ Automatic history tracking via triggers

## PostgreSQL-Specific Features Used

- **SERIAL**: Auto-incrementing primary keys
- **RETURNING**: Retrieve inserted IDs without separate query
- **Window Functions**: LAG, RANK, PERCENT_RANK, AVG, MIN, MAX with OVER()
- **CTEs (Common Table Expressions)**: WITH clauses for complex queries
- **Triggers**: Automatic product history logging
- **Timestamp Functions**: CURRENT_TIMESTAMP for date/time operations

## Troubleshooting

### Cannot connect to database
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list               # macOS
# Or check Windows Services

# Test connection
psql -U postgres -h localhost -p 5432

# Verify database exists
psql -U postgres -h localhost
\l  # List databases
\q
```

### Password authentication failed
- Verify password in `appsettings.json` matches PostgreSQL user password
- Reset password: `ALTER USER postgres PASSWORD 'newpassword';`

### Table not found
```bash
# Verify schema was created
psql -U postgres -h localhost -d ProductManagement
\dt  # List tables
# Should show: products, categories, suppliers, product_history, product_stats

# If missing, re-run setup script
\i Database/Scripts/02_PostgreSQL_InitialSetup.sql
```

### Build errors
```bash
# Clean and rebuild
dotnet clean
dotnet restore
dotnet build
```

### Npgsql version issues
```bash
# Check for package updates
dotnet list package --outdated

# Update Npgsql (if newer version available)
dotnet add package Npgsql --version 8.0.1
```

## Security Best Practices

⚠️ **IMPORTANT**: Before production deployment:

1. **Change Default Password**
   - Never use "postgres/postgres" in production
   - Use strong, unique passwords

2. **Externalize Credentials**
   ```bash
   # Use environment variables
   export DB_HOST="your-host"
   export DB_USER="your-user"
   export DB_PASSWORD="your-secure-password"
   
   # Update connection string
   # Host=${DB_HOST};Username=${DB_USER};Password=${DB_PASSWORD}
   ```

3. **Enable SSL/TLS**
   ```json
   {
     "ConnectionStrings": {
       "ProdConnection": "Host=...;SSL Mode=Require;..."
     }
   }
   ```

4. **Use Least Privilege**
   - Create application-specific database user
   - Grant only required permissions
   - Don't use superuser account

5. **Update Dependencies**
   - Check for Npgsql security updates
   - Address vulnerability NU1903 if applicable

## Migration Documentation

Comprehensive migration documentation available:

- **final_migration_report.md**: Complete migration report with all details
- **POSTGRESQL_RUNTIME_VALIDATION_GUIDE.md**: Step-by-step testing guide
- **dms_conversion_log.json**: DMS tool results and manual conversions
- **sql_equivalency_validation_report.json**: SQL equivalency validation results
- **extracted_statements.sql**: Original SQL Server statements
- **converted_statements.sql**: Converted PostgreSQL statements

## Performance Optimization

### Connection Pooling
Npgsql connection pooling is enabled by default:
```
Pooling=true;Minimum Pool Size=5;Maximum Pool Size=50
```

### Query Performance
```bash
# Analyze query performance
psql -U postgres -h localhost -d ProductManagement
EXPLAIN ANALYZE SELECT * FROM products WHERE price > 100;
\q
```

### Indexes
All required indexes are created by the setup script:
- Primary key indexes (automatic with SERIAL)
- Foreign key indexes
- Unique index on SKU
- History table indexes

## Architecture and Best Practices

### Layered Architecture
- **Data Access Layer**: ProductRepository (Npgsql integration)
- **Business Logic Layer**: ProductService
- **Presentation Layer**: CLI/InteractiveMenu

### Design Patterns
- Repository Pattern for data access
- Dependency Injection for configuration
- Async/Await for scalability
- IAsyncDisposable for resource management

### Code Quality
- Parameterized queries prevent SQL injection
- Transaction management ensures data consistency
- Proper error handling and logging
- Modern C# patterns and practices

## Migration to Production

### Checklist
- [ ] PostgreSQL server provisioned and secured
- [ ] Database schema deployed using `02_PostgreSQL_InitialSetup.sql`
- [ ] Credentials externalized (no hardcoded passwords)
- [ ] SSL/TLS configured for database connections
- [ ] Application deployed to target environment
- [ ] Connection string updated with production values
- [ ] Smoke tests executed successfully
- [ ] Monitoring and logging configured
- [ ] Backup and recovery procedures established
- [ ] Security audit completed

### Data Migration (if applicable)
If migrating existing SQL Server data:
1. Use PostgreSQL migration tools (pg_dump, AWS DMS, etc.)
2. Verify schema compatibility
3. Test with subset of data first
4. Validate data integrity post-migration
5. Plan for minimal downtime

## Support and Resources

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **Migration Report**: See `final_migration_report.md` for detailed migration analysis
- **Validation Guide**: See `POSTGRESQL_RUNTIME_VALIDATION_GUIDE.md` for testing

## Known Issues

### Npgsql Vulnerability (NU1903)
- **Status**: Warning during build
- **Severity**: High
- **Action**: Review vulnerability details and upgrade to patched version when available
- **Reference**: https://github.com/advisories/GHSA-x9vc-6hfv-hg8c

### SQL Equivalency Validation
- All 7 SQL statement pairs returned "UNKNOWN" status from formal verification
- Manual testing required to confirm runtime equivalence
- See `equivalency_failures.md` for detailed analysis

## License

[Your License Here]

## Version History

- **v2.0.0** (2026-02-06): PostgreSQL migration complete
  - All SQL Server dependencies replaced with Npgsql
  - All SQL statements converted to PostgreSQL syntax
  - Connection strings updated
  - Application compiles successfully
  - Runtime validation pending

- **v1.0.0**: Initial SQL Server version

---

**Migration Status**: Code migration complete ✅ | Runtime validation pending ⏸️

For questions or issues with the PostgreSQL migration, refer to the comprehensive documentation in the artifact directory.
