# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**MIGRATION NOTE**: This application has been migrated from Microsoft SQL Server to PostgreSQL. All SQL statements, database connections, and dependencies have been updated to work with PostgreSQL.

## Prerequisites

- .NET 9.0 SDK or later
- PostgreSQL 12 or later (installed and running)
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

### 1. PostgreSQL Database Setup

1. **Install PostgreSQL** (if not already installed):
   - Download from https://www.postgresql.org/download/
   - Install PostgreSQL server and pgAdmin

2. **Create the Database**:
   - Open pgAdmin or connect to PostgreSQL using psql
   - Run the database setup scripts located in `Database/Scripts/`
   - Create the `ProductManagement` database and required tables

### 2. Environment Variable Configuration

**IMPORTANT**: This application uses environment variables for database credentials to enhance security. You MUST set these environment variables before running the application.

#### Required Environment Variable:
- `PGPASSWORD` - PostgreSQL password (REQUIRED)

#### Optional Environment Variables (with defaults):
- `PGHOST` - PostgreSQL host (default: localhost)
- `PGDATABASE` - Database name (default: ProductManagement)
- `PGUSER` - PostgreSQL username (default: postgres)
- `PGPORT` - PostgreSQL port (default: 5432)

#### Setting Environment Variables:

**Linux/macOS:**
```bash
export PGPASSWORD='your_password_here'
export PGHOST='localhost'
export PGDATABASE='ProductManagement'
export PGUSER='postgres'
export PGPORT='5432'
```

**Windows (Command Prompt):**
```cmd
set PGPASSWORD=your_password_here
set PGHOST=localhost
set PGDATABASE=ProductManagement
set PGUSER=postgres
set PGPORT=5432
```

**Windows (PowerShell):**
```powershell
$env:PGPASSWORD = 'your_password_here'
$env:PGHOST = 'localhost'
$env:PGDATABASE = 'ProductManagement'
$env:PGUSER = 'postgres'
$env:PGPORT = '5432'
```

**For Persistent Configuration:**
- Linux/macOS: Add export commands to `~/.bashrc` or `~/.zshrc`
- Windows: Set system environment variables through System Properties > Environment Variables

### 3. Build and Run

```bash
# Navigate to project directory
cd /path/to/AdoCore

# Restore NuGet packages
dotnet restore

# Build the project
dotnet build

# Run in interactive mode (after setting PGPASSWORD)
dotnet run

# Or run with CLI commands
dotnet run -- list
```

## Security Improvements

**CRITICAL SECURITY UPDATE**: Hardcoded passwords have been removed from configuration files.

- ✅ Connection credentials now use environment variables
- ✅ No sensitive data stored in appsettings.json
- ✅ Proper error message if PGPASSWORD is not set
- ✅ Follows 12-factor app configuration principles

## Running the Application

The application can be run in two modes: Interactive (menu-driven) and Command-Line Interface (CLI).

### Interactive Mode

1. Set the required environment variable `PGPASSWORD`
2. Run the application without any arguments:
   ```bash
   dotnet run
   ```
3. You'll see the main menu with these options:
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

# Update stock quantity
dotnet run -- stock 1 20

# Get products by price range
dotnet run -- pricerange 10 100

# Get low stock products (below threshold)
dotnet run -- lowstock 15
```

## Migration from SQL Server to PostgreSQL

This application was migrated from SQL Server using the following process:

1. **Package Updates**: Replaced `Microsoft.Data.SqlClient` with `Npgsql`
2. **ADO.NET Classes**: Updated all SQL Server types to Npgsql equivalents
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlParameter` → `NpgsqlParameter`
3. **SQL Statements**: Converted 7 SQL statements from T-SQL to PostgreSQL syntax
4. **Transaction Handling**: Updated to use PostgreSQL transaction patterns
5. **Connection Strings**: Converted to PostgreSQL format with environment variable support

### Migration Artifacts

See the following files for detailed migration information:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `final_migration_report.json` - Complete migration report
- `sql_equivalency_validation_report.json` - Statement equivalency validation

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations
- Parameterized queries for security
- Connection pooling and management
- Error handling and logging
- **Secure credential management via environment variables**
- Complex queries with CTEs and window functions

## Testing the Application

1. **Set environment variable**:
   ```bash
   export PGPASSWORD='your_actual_password'
   ```

2. Try listing products:
   ```bash
   dotnet run -- list
   ```

3. Add a new product:
   ```bash
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   ```

4. View the product details:
   ```bash
   dotnet run -- get 1
   ```

## Troubleshooting

If you encounter errors:

1. **"PostgreSQL password not configured" error**:
   - Ensure you've set the `PGPASSWORD` environment variable
   - Check spelling and case sensitivity
   - Verify the variable is set in the current shell session

2. **Connection errors**:
   - Verify PostgreSQL is running: `systemctl status postgresql` (Linux) or check Services (Windows)
   - Confirm your environment variables match your PostgreSQL configuration
   - Test connection manually: `psql -h localhost -U postgres -d ProductManagement`

3. **Database does not exist**:
   - Ensure the `ProductManagement` database was created
   - Run the database setup scripts from `Database/Scripts/`

4. **Permission errors**:
   - Check PostgreSQL user permissions
   - Ensure the user has appropriate access to the database

5. **Build errors**:
   ```bash
   dotnet restore
   dotnet clean
   dotnet build
   ```

## Required NuGet Packages

- Npgsql (Version 8.0.5)
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- ✅ All database queries use parameterization to prevent SQL injection
- ✅ **Connection credentials stored in environment variables, not configuration files**
- ✅ No hardcoded passwords in source code
- ✅ Proper error handling and logging is implemented
- ✅ All database resources are properly disposed using async patterns
- ✅ Follows security best practices for credential management

## Best Practices Implemented

- Modern async/await patterns
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- **Secure credential management using environment variables**
- Security best practices (parameterized queries, no SQL injection vulnerabilities)
- Dependency injection
- Separation of concerns (layered architecture)

## Production Deployment

For production deployment:

1. **Set production environment variables** on the target system
2. **Use secrets management** (AWS Secrets Manager, Azure Key Vault, etc.) for credentials
3. **Update Environment setting** in appsettings.json to "Production"
4. **Configure SSL/TLS** for PostgreSQL connections
5. **Review connection pooling** settings for your workload
6. **Set up monitoring and logging**
7. **Never commit** credentials or sensitive data to version control

## Known Limitations

The following exit criteria require a live PostgreSQL database for validation:
- **Runtime connectivity testing** - Cannot be validated without a running PostgreSQL instance
- **Database operation execution** - Requires runtime testing with actual database
- **Transaction atomicity** - Requires runtime verification
- **Integration tests** - No test suite exists in the original application

These items should be validated during deployment and integration testing phases.
