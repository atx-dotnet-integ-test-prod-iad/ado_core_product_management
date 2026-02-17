# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL using Npgsql, following best practices for data access and application architecture.

**MIGRATION NOTE:** This application has been migrated from Microsoft SQL Server to PostgreSQL. All SQL statements, ADO.NET classes, and connection strings have been updated to support PostgreSQL.

## Prerequisites

- Visual Studio 2022 or later (optional)
- .NET 9.0 SDK or later
- PostgreSQL 12 or later (recommended: PostgreSQL 14+)
- pgAdmin 4 or any PostgreSQL client tool

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs  (Updated to use Npgsql)
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Scripts/
│   ├── 01_InitialSetup.sql              (Original SQL Server script)
│   └── 01_InitialSetup_PostgreSQL.sql   (PostgreSQL setup script)
├── Program.cs
├── AdoCore.csproj
└── appsettings.json
```

## Migration Changes

The following changes were made during the SQL Server to PostgreSQL migration:

1. **Package References:**
   - Replaced `Microsoft.Data.SqlClient` with `Npgsql` (v8.0.5)

2. **ADO.NET Classes:**
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlParameter` → `NpgsqlParameter`

3. **Connection Strings:**
   - Changed from SQL Server format to PostgreSQL format
   - Example: `Host=localhost;Database=postgres;Username=postgres;Password=postgres`

4. **SQL Syntax:**
   - All SQL statements converted to PostgreSQL syntax
   - Window functions, CTEs, and complex queries updated
   - Transaction handling updated to use Npgsql patterns

## Setup Instructions

### Option 1: Using PostgreSQL with Command Line

1. **Prerequisites Check:**
   ```bash
   # Verify .NET 9.0 SDK is installed
   dotnet --version
   # Should show 9.0.x

   # Verify PostgreSQL is installed and running
   psql --version
   ```

2. **PostgreSQL Database Setup:**
   ```bash
   # Connect to PostgreSQL as superuser
   psql -U postgres

   # Create the database (optional, depending on your setup)
   CREATE DATABASE productmanagement;

   # Connect to the database
   \c productmanagement

   # Run the setup script
   \i /path/to/Scripts/01_InitialSetup_PostgreSQL.sql

   # Or from outside psql:
   psql -U postgres -d productmanagement -f Scripts/01_InitialSetup_PostgreSQL.sql
   ```

3. **Update Connection String:**
   Edit `appsettings.json` to match your PostgreSQL configuration:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=your_password",
       "ProdConnection": "Host=your_prod_host;Database=productmanagement;Username=your_user;Password=your_password"
     },
     "Environment": "Development"
   }
   ```

4. **Project Setup:**
   ```bash
   # Navigate to project directory
   cd /path/to/sourceCode

   # Restore NuGet packages
   dotnet restore

   # Build the project
   dotnet build
   ```

5. **Run the Application:**
   ```bash
   # Run in interactive mode
   dotnet run

   # Or run with CLI commands
   dotnet run -- list
   ```

### Option 2: Using Docker for PostgreSQL (Recommended for Testing)

1. **Start PostgreSQL with Docker:**
   ```bash
   # Run PostgreSQL in Docker
   docker run --name postgres-adocore \
     -e POSTGRES_PASSWORD=postgres \
     -e POSTGRES_DB=productmanagement \
     -p 5432:5432 \
     -d postgres:14

   # Wait for PostgreSQL to start (about 10 seconds)
   sleep 10

   # Copy the setup script into the container
   docker cp Scripts/01_InitialSetup_PostgreSQL.sql postgres-adocore:/tmp/

   # Execute the setup script
   docker exec -i postgres-adocore psql -U postgres -d productmanagement < Scripts/01_InitialSetup_PostgreSQL.sql
   ```

2. **Update Connection String:**
   Use this connection string in `appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=postgres"
     },
     "Environment": "Development"
   }
   ```

3. **Run the Application:**
   ```bash
   dotnet restore
   dotnet build
   dotnet run
   ```

4. **Stop PostgreSQL Docker Container (when done):**
   ```bash
   docker stop postgres-adocore
   docker rm postgres-adocore
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
- Transaction support with async operations using Npgsql
- Parameterized queries for security
- Connection pooling and management
- Error handling and logging
- PostgreSQL-specific features (Window functions, CTEs, RETURNING clause)

## Testing the Application

1. **Verify Database Connection:**
   ```bash
   # Try listing products (should show 18 sample products)
   dotnet run -- list
   ```

2. **Test Insert Operation:**
   ```bash
   # Add a new product
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   ```

3. **Test Query Operation:**
   ```bash
   # View the product details
   dotnet run -- get 1
   ```

4. **Test Update Operation:**
   ```bash
   # Update a product
   dotnet run -- update 1 "Updated Product" 39.99 10 "Updated Description"
   ```

5. **Test Delete Operation:**
   ```bash
   # Delete a product
   dotnet run -- delete 1
   ```

## Troubleshooting

### Database Connection Issues

1. **Verify PostgreSQL is running:**
   ```bash
   # On Linux/Mac
   sudo systemctl status postgresql
   
   # On Windows (check Services)
   # Or for Docker:
   docker ps | grep postgres
   ```

2. **Test connection with psql:**
   ```bash
   psql -U postgres -d productmanagement -c "SELECT version();"
   ```

3. **Check connection string:**
   - Verify hostname, port (default: 5432), database name, username, and password
   - Ensure no firewall blocking the connection

4. **Check PostgreSQL logs:**
   ```bash
   # Docker
   docker logs postgres-adocore
   
   # Linux
   sudo tail -f /var/log/postgresql/postgresql-14-main.log
   ```

### Application Errors

1. **Ensure all NuGet packages are restored:**
   ```bash
   dotnet restore
   ```

2. **Rebuild the application:**
   ```bash
   dotnet clean
   dotnet build
   ```

3. **Check for SQL syntax errors:**
   - Review the converted_statements.sql file in the parent directory
   - Compare with the equivalency validation report

## Required NuGet Packages

- **Npgsql** (v8.0.5) - PostgreSQL data provider for .NET
- **Microsoft.Extensions.Configuration** (v8.0.0)
- **Microsoft.Extensions.Configuration.Json** (v8.0.0)
- **Microsoft.Extensions.DependencyInjection** (v8.0.0)

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings are stored in configuration files (use environment variables in production)
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- Use SSL/TLS for production PostgreSQL connections

## PostgreSQL-Specific Features Used

- **Window Functions:** RANK(), PERCENT_RANK(), AVG() OVER(), COUNT() OVER()
- **Common Table Expressions (CTEs):** WITH clauses for complex queries
- **RETURNING Clause:** For retrieving auto-generated IDs after INSERT
- **Transactions:** Using Npgsql's BeginTransactionAsync, CommitAsync, RollbackAsync
- **SERIAL Type:** For auto-incrementing primary keys

## Best Practices Implemented

- Modern async/await patterns throughout
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries)
- Dependency injection
- Separation of concerns (layered architecture)
- PostgreSQL connection pooling (handled by Npgsql)

## Deployment Considerations

### Deploying to AWS

1. **Using AWS RDS for PostgreSQL:**
   - Create an RDS PostgreSQL instance
   - Run the setup script against the RDS instance
   - Update connection string with RDS endpoint
   - Ensure security groups allow your application's access

2. **Using AWS EC2 with PostgreSQL:**
   - Install PostgreSQL on EC2
   - Configure PostgreSQL for remote connections
   - Update connection string with EC2 instance IP/hostname
   - Configure security groups and firewall rules

3. **Connection String for Production:**
   ```json
   {
     "ConnectionStrings": {
       "ProdConnection": "Host=your-rds-endpoint.amazonaws.com;Database=productmanagement;Username=your_user;Password=your_password;SSL Mode=Require"
     }
   }
   ```

## Migration Artifacts

The migration process generated several artifacts for reference:

- `extracted_statements.sql` - All original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.txt` - DMS tool conversion log
- `sql_equivalency_validation_report.json` - Equivalency validation results

## Additional Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL vs SQL Server Syntax Differences](https://wiki.postgresql.org/wiki/Oracle_to_Postgres_Conversion)
- [AWS RDS for PostgreSQL](https://aws.amazon.com/rds/postgresql/)
