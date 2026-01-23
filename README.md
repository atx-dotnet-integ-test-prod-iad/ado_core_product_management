# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

## Migration Notice

**This application has been migrated from Microsoft SQL Server to PostgreSQL.** All database access code has been updated to use Npgsql (the PostgreSQL .NET driver) and all SQL statements have been converted to PostgreSQL syntax.

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- PostgreSQL 13 or later (recommended for development)
- pgAdmin or any PostgreSQL client tool

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Program.cs
├── AdoCore.csproj
└── appsettings.json
```

## Setup Instructions

### Option 1: Using Visual Studio

1. **Open the Project**:
   - Open Visual Studio 2022
   - Select "Open a project or solution"
   - Navigate to the project folder and select `AdoCore.csproj`

2. **Restore NuGet Packages**:
   - Right-click on the solution in Solution Explorer
   - Select "Restore NuGet Packages"

3. **Database Setup**:
   - Open pgAdmin or your PostgreSQL client
   - Connect to your local PostgreSQL instance
   - Create the database and schema:
   ```sql
   CREATE DATABASE productmanagement;
   CREATE SCHEMA productmanagement_dbo;
   ```
   - Open and run the PostgreSQL schema migration script: `Database/Scripts/01_PostgreSQL_InitialSetup.sql`

4. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - Update the connection string if needed:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=your_password;Port=5432",
       "ProdConnection": "your-production-connection-string"
     },
     "Environment": "Development"
   }
   ```

5. **Run the Application**:
   - Press F5 to run in debug mode
   - Or press Ctrl+F5 to run without debugging
   - The application will start in interactive mode

### Option 2: Using Command Line

1. **Prerequisites Check**:
   ```bash
   # Verify .NET 9.0 SDK is installed
   dotnet --version
   # Should show 9.0.x
   
   # Verify PostgreSQL is installed and running
   psql --version
   ```

2. **Database Setup**:
   ```bash
   # Connect to PostgreSQL
   psql -U postgres
   
   # Create database and schema
   CREATE DATABASE productmanagement;
   \c productmanagement
   CREATE SCHEMA productmanagement_dbo;
   
   # Run the schema migration script
   \i Database/Scripts/01_PostgreSQL_InitialSetup.sql
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd /path/to/AdoCore
   
   # Restore NuGet packages
   dotnet restore
   
   # Update connection string in appsettings.json if needed
   # Current connection string format:
   # "Host=localhost;Database=productmanagement;Username=postgres;Password=your_password;Port=5432"
   ```

4. **Build and Run**:
   ```bash
   # Build the project
   dotnet build
   
   # Run in interactive mode
   dotnet run
   
   # Or run with CLI commands
   dotnet run -- list
   ```

## Running the Application

The application can be run in two modes: Interactive (menu-driven) and Command-Line Interface (CLI).

### Interactive Mode

1. Run the application without any arguments:
   ```bash
   dotnet run
   ```
2. You'll see the main menu with these options:
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

The application supports the following commands:

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

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations
- Parameterized queries for security (PostgreSQL parameterization)
- Connection pooling and management (Npgsql connection pooling)
- Error handling and logging
- PostgreSQL-specific features (RETURNING clause, NOW() function, etc.)

## Testing the Application

1. Try listing products:
   ```bash
   dotnet run -- list
   ```

2. Add a new product:
   ```bash
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   ```

3. View the product details:
   ```bash
   dotnet run -- get 1
   ```

## Troubleshooting

If you encounter errors:
1. Verify PostgreSQL is running:
   ```bash
   # On Linux/Mac
   sudo systemctl status postgresql
   
   # On Windows (check Services application)
   # Or use: pg_ctl status
   ```
2. Confirm your connection string matches your PostgreSQL configuration
3. Ensure the `productmanagement` database and `productmanagement_dbo` schema were created successfully
4. Check you have appropriate permissions to access the database
5. Verify the username and password in the connection string are correct
6. Make sure all required NuGet packages are restored:
   ```bash
   dotnet restore
   ```
7. Check PostgreSQL logs for connection errors:
   ```bash
   # Typical location on Linux
   tail -f /var/log/postgresql/postgresql-*.log
   ```

## Required NuGet Packages

- **Npgsql** (v10.0.1 or later) - PostgreSQL .NET Data Provider
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Migration from SQL Server

This application was migrated from SQL Server to PostgreSQL. Key changes include:

### Database Access Code
- `Microsoft.Data.SqlClient` → `Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlParameter` → `NpgsqlParameter`
- `SqlTransaction` → `NpgsqlTransaction`

### SQL Syntax Changes
- `GETDATE()` → `NOW()`
- `SCOPE_IDENTITY()` → `RETURNING` clause
- Schema prefixing: `dbo.Products` → `productmanagement_dbo.products`
- Case sensitivity: PostgreSQL uses lowercase for unquoted identifiers
- `NULLS FIRST` clauses added to `ORDER BY` for consistent sorting

### Connection Strings
- Old format: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;...`
- New format: `Host=localhost;Database=productmanagement;Username=postgres;Password=...;Port=5432`

### Transaction Handling
- Transactions moved from SQL-level (`BEGIN TRANSACTION`/`COMMIT`) to ADO.NET level
- All transactional operations use `BeginTransactionAsync()`, `CommitAsync()`, `RollbackAsync()`

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings should be stored securely (use environment variables or secure configuration)
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- SSL/TLS encryption can be enabled via connection string parameters

## Best Practices Implemented

- Modern async/await patterns throughout
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries, secure credential handling)
- Dependency injection
- Separation of concerns (layered architecture)
- PostgreSQL best practices (lowercase identifiers, schema organization)

## Deployment Considerations

### PostgreSQL Database Setup
1. Install PostgreSQL on your target environment (AWS RDS, Azure Database, or self-hosted)
2. Create the `productmanagement` database and `productmanagement_dbo` schema
3. Run the schema migration scripts to create tables
4. Configure appropriate user permissions
5. Set up connection pooling and performance tuning as needed

### Application Deployment
1. Update the production connection string in `appsettings.json` or use environment variables
2. Ensure network connectivity between application and PostgreSQL server
3. Configure firewall rules to allow PostgreSQL connections (default port 5432)
4. Deploy the application using Visual Studio's Publish feature or CI/CD pipeline
5. Monitor application logs and PostgreSQL logs for any issues

## Known Limitations and Manual Testing Requirements

**IMPORTANT:** All SQL statements in this application have been converted to PostgreSQL syntax and validated for structural correctness. However, formal equivalency verification using automated tools was inconclusive for the following complex SQL statements due to limitations in formal methods solvers:

1. **GetAllProductsAsync** - CTE with window functions (AVG, COUNT OVER)
2. **GetProductByIdAsync** - CTE with LAG window function
3. **InsertProductAsync** - Transaction with RETURNING clause
4. **UpdateProductAsync** - Multi-statement transaction
5. **DeleteProductAsync** - Multi-statement transaction
6. **GetProductsByPriceRangeAsync** - CTE with RANK and PERCENT_RANK functions
7. **GetLowStockProductsAsync** - CTE with multiple window functions

**Manual Testing Recommended:** Before production deployment, it is strongly recommended to:
- Test all CRUD operations with sample data
- Verify transaction atomicity with deliberate rollback scenarios
- Compare results from SQL Server and PostgreSQL for identical datasets
- Perform load and performance testing

See `sql_equivalency_validation_report.json` for detailed information about the automated validation attempts.

## Support and Documentation

For issues or questions:
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- .NET Data Access: https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/

## Migration Documentation

Complete migration documentation including:
- SQL statement extraction log: `extraction_log.json`
- DMS conversion log: `conversion_log.json`
- SQL equivalency validation report: `sql_equivalency_validation_report.json`
- Final migration report: `final_migration_report.json`

These files contain detailed information about every SQL statement that was converted and validated during the migration process.
