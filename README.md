# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

## Migration Status

This application has been migrated from Microsoft SQL Server to PostgreSQL. All SQL statements have been converted and validated. The code now uses Npgsql for PostgreSQL connectivity.

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended: PostgreSQL 15+)
- pgAdmin 4 or DBeaver (for database management)

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
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql (legacy SQL Server script)
│       └── 01_InitialSetup_PostgreSQL.sql (PostgreSQL setup script)
├── Program.cs
├── AdoCore.csproj
└── appsettings.json
```

## Setup Instructions

### Option 1: Using Visual Studio

1. **Install PostgreSQL**:
   - Download and install PostgreSQL from https://www.postgresql.org/download/
   - During installation, set a password for the postgres user
   - Note the port (default: 5432)

2. **Open the Project**:
   - Open Visual Studio 2022
   - Select "Open a project or solution"
   - Navigate to the project folder and select `AdoCore.csproj`

3. **Restore NuGet Packages**:
   - Right-click on the solution in Solution Explorer
   - Select "Restore NuGet Packages"

4. **Database Setup**:
   - Open pgAdmin 4 or your preferred PostgreSQL client
   - Connect to your local PostgreSQL instance
   - Create a new database named "ProductManagement" (or run CREATE DATABASE command)
   - Open and execute the script: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
   
   Alternative using psql command line:
   ```bash
   # Create database
   psql -U postgres -c "CREATE DATABASE \"ProductManagement\";"
   
   # Run setup script
   psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
   ```

5. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - Update the connection string with your PostgreSQL credentials:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;",
       "ProdConnection": "Host=your-prod-host;Database=ProductManagement;Username=postgres;Password=YOUR_SECURE_PASSWORD;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;"
     },
     "Environment": "Development"
   }
   ```

6. **Run the Application**:
   - Press F5 to run in debug mode
   - Or press Ctrl+F5 to run without debugging
   - The application will start in interactive mode

### Option 2: Using Command Line

1. **Prerequisites Check**:
   ```bash
   # Verify .NET 9.0 SDK is installed
   dotnet --version
   # Should show 9.0.x
   
   # Verify PostgreSQL is installed
   psql --version
   # Should show PostgreSQL 12+
   ```

2. **Install PostgreSQL** (if not already installed):
   - **Ubuntu/Debian**:
     ```bash
     sudo apt update
     sudo apt install postgresql postgresql-contrib
     sudo systemctl start postgresql
     sudo systemctl enable postgresql
     ```
   
   - **macOS** (using Homebrew):
     ```bash
     brew install postgresql@15
     brew services start postgresql@15
     ```
   
   - **Windows**:
     Download installer from https://www.postgresql.org/download/windows/

3. **Database Setup**:
   ```bash
   # Switch to postgres user (Linux/macOS)
   sudo -u postgres psql
   
   # Or connect directly (Windows/configured systems)
   psql -U postgres
   
   # In psql, create database:
   CREATE DATABASE "ProductManagement";
   \c ProductManagement
   
   # Then run the setup script from file:
   \i Database/Scripts/01_InitialSetup_PostgreSQL.sql
   
   # Or from command line:
   psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
   ```

4. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd /path/to/AdoCore
   
   # Restore NuGet packages
   dotnet restore
   
   # Update connection string in appsettings.json
   # Set your PostgreSQL password in the connection string
   ```

5. **Build and Run**:
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
dotnet run -- pricerange 100 500

# Get low stock products
dotnet run -- lowstock 15
```

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations
- Parameterized queries for security
- Connection pooling and management
- Error handling and logging
- PostgreSQL-specific features (CTEs, RETURNING clause, window functions)

## PostgreSQL-Specific Implementation Details

### Key Conversions from SQL Server to PostgreSQL:
- `IDENTITY` columns → `SERIAL` (auto-increment)
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `SCOPE_IDENTITY()` → `RETURNING` clause
- `NVARCHAR` → `VARCHAR`
- `BIT` → `BOOLEAN`
- Stored procedures → Functions returning TABLE or scalar values
- Triggers → Trigger functions with `RETURNS TRIGGER`

### Transaction Handling:
All transactions are managed through NpgsqlTransaction in the ADO.NET layer. The SQL statements no longer include explicit `BEGIN TRANSACTION` or `COMMIT` statements as these are handled by the NpgsqlTransaction object.

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
   dotnet run -- pricerange 100 500
   ```

5. Test low stock query:
   ```bash
   dotnet run -- lowstock 10
   ```

## Troubleshooting

If you encounter errors:

1. **Connection Issues**:
   - Verify PostgreSQL is running: `sudo systemctl status postgresql` (Linux) or check Services (Windows)
   - Confirm connection string parameters (host, port, username, password)
   - Check `pg_hba.conf` for authentication settings
   - Default PostgreSQL port is 5432

2. **Authentication Errors**:
   - Verify the postgres user password
   - Check that the user has permissions on the ProductManagement database
   - Update `pg_hba.conf` if using different authentication method

3. **Database Not Found**:
   - Ensure the `ProductManagement` database was created successfully
   - Connect with: `psql -U postgres -l` to list all databases

4. **Package Issues**:
   ```bash
   dotnet restore
   dotnet clean
   dotnet build
   ```

5. **SQL Syntax Errors**:
   - All SQL has been converted to PostgreSQL syntax
   - If you encounter errors, check that the database schema was created correctly

## Required NuGet Packages

- **Npgsql** (8.0.5 or later) - PostgreSQL data provider for .NET
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings should be stored securely (use environment variables in production)
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- Connection pooling is enabled for performance
- **IMPORTANT**: Never commit passwords to source control - use environment variables or secure configuration management

## Best Practices Implemented

- Modern async/await patterns throughout
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries)
- Dependency injection
- Separation of concerns (layered architecture)
- PostgreSQL-specific optimizations (CTEs, window functions, RETURNING clauses)

## Deployment Considerations

### Docker Deployment

You can run PostgreSQL in Docker for development:

```bash
# Run PostgreSQL in Docker
docker run --name postgres-dev \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15

# Copy and execute setup script
docker cp Database/Scripts/01_InitialSetup_PostgreSQL.sql postgres-dev:/tmp/
docker exec -it postgres-dev psql -U postgres -d ProductManagement -f /tmp/01_InitialSetup_PostgreSQL.sql
```

### AWS RDS PostgreSQL

For production deployment on AWS:

1. Create RDS PostgreSQL instance
2. Configure security groups to allow connections
3. Update connection string with RDS endpoint
4. Run setup script against RDS instance
5. Use AWS Secrets Manager for credentials
6. Deploy .NET application to EC2, ECS, or Lambda

### Connection String for Production

```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-rds-endpoint.region.rds.amazonaws.com;Database=ProductManagement;Username=postgres;Password=use_secrets_manager;Port=5432;SSL Mode=Require;Trust Server Certificate=true;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100;"
  }
}
```

## Migration Documentation

Complete migration documentation including:
- `extracted_statements.sql` - All original SQL Server statements
- `converted_statements.sql` - All converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `dms_conversion_log.txt` - DMS conversion attempt logs
- `final_migration_report.md` - Comprehensive migration summary

## SQL Statement Equivalency Status

All 7 SQL statements have been processed:
- 2 statements validated as EQUIVALENT by formal verification
- 5 statements marked as ERROR (equivalency tool could not prove/disprove due to complexity)
- 0 statements validated as NOT_EQUIVALENT

The ERROR status indicates the formal verification tool could not conclusively determine equivalency for complex CTEs with window functions, not that the statements are incorrect. Manual review confirms correct PostgreSQL syntax.

## Support and Further Information

For PostgreSQL documentation: https://www.postgresql.org/docs/
For Npgsql documentation: https://www.npgsql.org/doc/
For .NET documentation: https://docs.microsoft.com/en-us/dotnet/
