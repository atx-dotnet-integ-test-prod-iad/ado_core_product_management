# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**⚠️ MIGRATION STATUS: This application has been migrated from SQL Server to PostgreSQL**

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- PostgreSQL 12 or later
- pgAdmin 4 or another PostgreSQL management tool

## 🔒 CRITICAL SECURITY REQUIREMENTS

**BEFORE DEPLOYING TO PRODUCTION, YOU MUST:**

### 1. Replace Hardcoded Database Credentials

The current `appsettings.json` contains placeholder credentials (`Username=postgres;Password=postgres`). These are **NOT SECURE** and MUST be replaced before production deployment.

**Recommended Solutions:**

#### Option A: Environment Variables
```bash
# Set environment variables
export DB_HOST="your-db-host"
export DB_PORT="5432"
export DB_NAME="ProductManagement"
export DB_USER="your-secure-username"
export DB_PASSWORD="your-secure-password"
```

Update `appsettings.json` to reference environment variables:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};Username=${DB_USER};Password=${DB_PASSWORD};Pooling=true;MaxPoolSize=100"
  }
}
```

#### Option B: AWS Secrets Manager (Recommended for AWS)
```csharp
// Add AWS.Extensions.NETCore.Setup package
// Retrieve connection string from AWS Secrets Manager
var secretArn = "arn:aws:secretsmanager:region:account:secret:name";
// Implement secret retrieval in Program.cs
```

#### Option C: Azure Key Vault (Recommended for Azure)
```csharp
// Add Azure.Extensions.AspNetCore.Configuration.Secrets package
// Configure Key Vault in Program.cs
```

### 2. Database Schema Setup

Before running the application, ensure your PostgreSQL database has the required schema:

```sql
-- Create database
CREATE DATABASE "ProductManagement";

-- Create tables
CREATE TABLE "Products" (
    "ProductId" SERIAL PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL,
    "Price" DECIMAL(18,2) NOT NULL,
    "StockQuantity" INT NOT NULL,
    "Description" TEXT,
    "CreatedDate" TIMESTAMP DEFAULT NOW(),
    "LastModifiedDate" TIMESTAMP DEFAULT NOW()
);

CREATE TABLE "ProductHistory" (
    "HistoryId" SERIAL PRIMARY KEY,
    "ProductId" INT NOT NULL,
    "Action" VARCHAR(50) NOT NULL,
    "ActionDate" TIMESTAMP DEFAULT NOW(),
    "OldPrice" DECIMAL(18,2),
    "NewPrice" DECIMAL(18,2),
    "OldQuantity" INT,
    "NewQuantity" INT,
    FOREIGN KEY ("ProductId") REFERENCES "Products"("ProductId")
);

CREATE TABLE "ProductStats" (
    "StatId" SERIAL PRIMARY KEY,
    "TotalProducts" INT NOT NULL,
    "TotalValue" DECIMAL(18,2) NOT NULL,
    "LastCalculated" TIMESTAMP DEFAULT NOW()
);
```

### 3. Integration Testing is MANDATORY

⚠️ **CRITICAL**: Due to both MCP tools (DMS and SQL Equivalency) experiencing failures during migration, comprehensive integration testing with an actual PostgreSQL database is **MANDATORY** before production deployment.

**Required Tests:**
- [ ] All 7 SQL statements execute correctly
- [ ] Transaction behavior (Insert, Update, Delete) functions properly
- [ ] Data integrity is maintained across operations
- [ ] Connection pooling works as expected
- [ ] Performance is acceptable for production workload
- [ ] Error handling works correctly
- [ ] All CRUD operations return expected results

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs      (Updated for PostgreSQL/Npgsql)
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Program.cs
├── AdoCore.csproj               (Updated: Npgsql 10.0.1)
├── appsettings.json             (Updated for PostgreSQL)
└── README.md
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
   - Install PostgreSQL if not already installed
   - Open pgAdmin 4 or your preferred PostgreSQL tool
   - Create the `ProductManagement` database
   - Run the schema creation scripts (see above)

4. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - Update the connection string with your PostgreSQL credentials:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=your_user;Password=your_password;Pooling=true;MaxPoolSize=100",
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
   ```

2. **Database Setup**:
   ```bash
   # Ensure PostgreSQL is running
   # Create database and schema using psql or pgAdmin
   psql -U postgres -f database_setup.sql
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd /path/to/AdoCore

   # Restore NuGet packages
   dotnet restore

   # Update connection string in appsettings.json
   # (Use secure credentials, not default postgres/postgres)
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

## Migration Notes

This application was migrated from Microsoft SQL Server to PostgreSQL. Key changes include:

### Package Changes
- **Removed**: `Microsoft.Data.SqlClient` (5.1.4)
- **Added**: `Npgsql` (10.0.1)

### Code Changes
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlTransaction` → `NpgsqlTransaction`
- `SqlParameter` → `NpgsqlParameter`

### SQL Syntax Changes
- `GETDATE()` → `NOW()`
- `SCOPE_IDENTITY()` → `RETURNING` clause
- T-SQL transactions → Application-level transactions (C# BeginTransactionAsync)
- Square brackets `[TableName]` → Double quotes `"TableName"` (when needed)

### Transaction Management
Transactions are now managed at the application level using:
```csharp
using var transaction = await connection.BeginTransactionAsync();
try {
    // Execute commands
    await transaction.CommitAsync();
} catch {
    await transaction.RollbackAsync();
    throw;
}
```

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Application-level transaction support with async operations
- Parameterized queries for security
- Connection pooling and management
- Error handling and logging
- PostgreSQL-specific optimizations

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

1. **Database Connection Issues**:
   - Verify PostgreSQL is running: `sudo systemctl status postgresql` (Linux) or check Services (Windows)
   - Confirm your connection string matches your PostgreSQL configuration
   - Ensure the `ProductManagement` database exists
   - Check firewall rules allow connections on port 5432

2. **Authentication Issues**:
   - Verify username and password in connection string
   - Check PostgreSQL pg_hba.conf for authentication settings
   - Ensure the user has proper permissions on the database

3. **Package Issues**:
   - Make sure all required NuGet packages are restored:
     ```bash
     dotnet restore
     ```
   - Verify Npgsql 10.0.1 (or later) is installed

4. **SQL Execution Issues**:
   - Check that all required tables exist (Products, ProductHistory, ProductStats)
   - Verify table and column names match the queries (PostgreSQL is case-sensitive with quoted identifiers)

## Required NuGet Packages

- `Npgsql` (10.0.1 or later) - PostgreSQL ADO.NET provider
- `Microsoft.Extensions.Configuration` (8.0.0)
- `Microsoft.Extensions.Configuration.Json` (8.0.0)
- `Microsoft.Extensions.DependencyInjection` (8.0.0)

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- **⚠️ REPLACE placeholder credentials before production deployment**
- Connection strings should be stored securely using environment variables or secret management services
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- Use SSL/TLS for database connections in production (add `SslMode=Require` to connection string)
- Implement proper user access controls in PostgreSQL

## Best Practices Implemented

- Modern async/await patterns throughout
- Proper resource disposal with IAsyncDisposable
- Application-level transaction management with async support
- Comprehensive error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices (parameterized queries, connection pooling)
- Dependency injection
- Separation of concerns (layered architecture)
- PostgreSQL-specific optimizations

## Deployment Considerations

### Before Production Deployment:

1. ✅ **Security Audit**:
   - Replace all placeholder credentials
   - Implement proper secret management
   - Enable SSL/TLS for database connections
   - Review and restrict database user permissions

2. ✅ **Integration Testing**:
   - Test all CRUD operations against PostgreSQL
   - Verify transaction behavior
   - Test error handling and recovery
   - Perform load testing

3. ✅ **Database Setup**:
   - Create production database with proper configuration
   - Set up automated backups
   - Configure monitoring and alerting
   - Implement connection pooling limits

4. ✅ **Documentation**:
   - Document deployment procedures
   - Create runbooks for common issues
   - Document all SQL statement conversions
   - Maintain migration audit trail

## Migration Artifacts

The following files document the migration process:

- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_issues.log` - DMS tool failures and manual conversions
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `migration_summary.md` - Comprehensive migration documentation

## Support and Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- .NET Data Access: https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/

## Known Issues and Limitations

1. **MCP Tool Failures**: Both DMS and SQL Equivalency tools failed during migration. All SQL statements were manually converted and require integration testing.

2. **Equivalency Validation**: SQL equivalency could not be automatically verified due to tool errors. Manual verification through integration testing is required.

3. **Test Coverage**: No unit or integration tests were executed during migration. Test development and execution is required before production deployment.

## License

[Include your license information here]
