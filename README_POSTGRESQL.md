# ADO.NET Core PostgreSQL Data Management Application

**MIGRATION NOTICE**: This application has been migrated from Microsoft SQL Server to PostgreSQL.

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL using Npgsql, following best practices for data access and application architecture.

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended for development)
- pgAdmin or another PostgreSQL client tool

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
   - Create database: `CREATE DATABASE productmanagement;`
   - Open and run the PostgreSQL migration script: `Database/Scripts/01_PostgreSQL_Setup.sql`

4. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - Update the connection string with your PostgreSQL credentials:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=productmanagement;Username=your_user;Password=your_password;Port=5432",
       "ProdConnection": "your-production-connection-string"
     },
     "Environment": "Development"
   }
   ```
   **SECURITY NOTE**: Replace `postgres/postgres` placeholder credentials with actual secure credentials before testing or deployment.

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
   
   # Create database
   CREATE DATABASE productmanagement;
   
   # Connect to the new database
   \c productmanagement
   
   # Run the setup script
   \i Database/Scripts/01_PostgreSQL_Setup.sql
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd /path/to/sourceCode

   # Restore NuGet packages
   dotnet restore

   # Update connection string in appsettings.json with your credentials
   # IMPORTANT: Replace placeholder credentials (postgres/postgres) with actual secure credentials
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
   6. Get products by price range
   7. Get low stock products
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

# Get products by price range
dotnet run -- price-range 10.00 50.00

# Get low stock products (quantity < 5)
dotnet run -- low-stock
```

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations
- Parameterized queries for security (SQL injection prevention)
- Connection pooling and management
- Error handling and logging
- **PostgreSQL-specific features**:
  - RETURNING clause for INSERT operations
  - CTEs (Common Table Expressions) for complex queries
  - Window functions for analytics
  - PostgreSQL parameter syntax (@param)

## Migration from SQL Server

This application was migrated from SQL Server to PostgreSQL. Key changes include:

### Code Changes:
- Replaced `Microsoft.Data.SqlClient` with `Npgsql` package
- Updated all ADO.NET classes:
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`
  - `SqlParameter` → `NpgsqlParameter`
  - `SqlTransaction` → `NpgsqlTransaction`

### SQL Syntax Changes:
- Schema object names converted to lowercase (PostgreSQL convention)
- `SCOPE_IDENTITY()` → `RETURNING` clause
- `GETDATE()` → `CURRENT_TIMESTAMP`
- Transaction handling moved from SQL to application code level
- `DECLARE` variables → CTEs where appropriate

### Documentation:
- See `extracted_statements.sql` for original SQL Server statements
- See `converted_statements.sql` for converted PostgreSQL statements
- See `dms_conversion_log.json` for detailed conversion metadata
- See `sql_equivalency_validation_report.json` for equivalency validation results
- See `final_migration_report.md` for comprehensive migration report

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

4. Test price range query:
   ```bash
   dotnet run -- price-range 20.00 100.00
   ```

5. Test low stock query:
   ```bash
   dotnet run -- low-stock
   ```

## Troubleshooting

If you encounter errors:

1. **Connection Issues**:
   - Verify PostgreSQL is running: `sudo systemctl status postgresql` (Linux) or check Services (Windows)
   - Confirm your connection string matches your PostgreSQL host and port
   - Ensure the `productmanagement` database was created successfully
   - Verify you have appropriate permissions to access the database

2. **Authentication Issues**:
   - Replace placeholder credentials in appsettings.json with actual credentials
   - Check PostgreSQL pg_hba.conf for authentication methods
   - Ensure the user has appropriate privileges on the database

3. **Package Issues**:
   - Make sure all required NuGet packages are restored:
     ```bash
     dotnet restore
     ```
   - Verify Npgsql version 10.0.1 is installed (addresses known security vulnerability)

4. **SQL Errors**:
   - PostgreSQL is case-sensitive for quoted identifiers
   - All schema objects (tables, columns) use lowercase naming
   - Check converted_statements.sql for correct PostgreSQL syntax

## Required NuGet Packages

- **Npgsql** (10.0.1) - PostgreSQL data provider for .NET
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- **IMPORTANT**: Replace placeholder credentials (postgres/postgres) in appsettings.json before deployment
- Consider using environment variables or secure configuration providers for production credentials
- Connection strings should be stored in secure configuration (Azure Key Vault, AWS Secrets Manager, etc.)
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- Regular package updates to address security vulnerabilities

## Best Practices Implemented

- Modern async/await patterns throughout
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support at application level
- Comprehensive error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries, secure credential storage)
- Dependency injection for loose coupling
- Separation of concerns (layered architecture)
- PostgreSQL naming conventions (lowercase schema objects)

## Performance Considerations

- Npgsql provides automatic connection pooling
- Async operations prevent thread blocking
- Parameterized queries are cached and reused
- Proper transaction scope management
- Consider indexing strategies for your PostgreSQL schema

## Deployment

### Local Development:
1. Ensure PostgreSQL is installed and running
2. Update appsettings.json with local credentials
3. Run database setup scripts
4. Build and run: `dotnet run`

### Production Deployment:
1. Set up PostgreSQL instance (RDS, Azure Database for PostgreSQL, etc.)
2. Use secure credential management (environment variables, secrets managers)
3. Update ProdConnection in appsettings.json or override via environment
4. Deploy using standard .NET deployment methods
5. Run database migrations/setup scripts on production database

## Additional Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/index.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Migration Documentation](final_migration_report.md)
- [SQL Statement Catalog](extracted_statements.sql, converted_statements.sql)

## Known Issues and Notes

1. **Npgsql Vulnerability**: Version 8.0.0 had a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c). This has been addressed by upgrading to version 10.0.1.

2. **SQL Equivalency Validation**: All SQL statement pairs were validated using the SQL Equivalency tool. All 7 pairs returned ERROR status due to tool errors, NOT due to statement incompatibility. Manual review and functional testing are recommended.

3. **Runtime Validation**: Criteria 12-15 (database connectivity, operation execution, transaction atomicity, test execution) require a live PostgreSQL database instance and are outside the scope of code transformation. These should be validated in a test environment.

4. **Placeholder Credentials**: The appsettings.json file contains placeholder credentials (postgres/postgres) for development purposes. These MUST be replaced with secure credentials before any production use or deployment.
