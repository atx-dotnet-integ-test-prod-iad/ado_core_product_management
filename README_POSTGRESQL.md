# ADO.NET Core PostgreSQL Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with PostgreSQL, following best practices for data access and application architecture.

**MIGRATION STATUS**: This application has been successfully migrated from Microsoft SQL Server to PostgreSQL using AWS Database Migration Service patterns.

## Prerequisites

- Visual Studio 2022 or later (optional, for IDE development)
- .NET 9.0 SDK or later
- PostgreSQL 13 or later (download from https://www.postgresql.org/download/)
- pgAdmin 4 (included with PostgreSQL installer) or Azure Data Studio with PostgreSQL extension

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs      # PostgreSQL data access using Npgsql
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Database/
│   └── Scripts/
│       ├── 01_InitialSetup.sql              # Original SQL Server script (DEPRECATED)
│       └── 01_InitialSetup_PostgreSQL.sql   # PostgreSQL setup script (USE THIS)
├── Program.cs
├── AdoCore.csproj
└── appsettings.json
```

## Setup Instructions

### Step 1: Install PostgreSQL

#### Windows:
1. Download PostgreSQL installer from https://www.postgresql.org/download/windows/
2. Run the installer (recommended: PostgreSQL 15 or later)
3. During installation:
   - Set a password for the `postgres` superuser (remember this!)
   - Default port: 5432 (recommended)
   - Install pgAdmin 4 when prompted
4. Verify installation:
   ```bash
   psql --version
   # Should show: psql (PostgreSQL) 15.x or later
   ```

#### macOS:
```bash
# Using Homebrew
brew install postgresql@15
brew services start postgresql@15

# Verify installation
psql --version
```

#### Linux (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify installation
psql --version
```

### Step 2: Create Database

#### Option A: Using psql Command Line
```bash
# Connect to PostgreSQL
psql -U postgres

# At the psql prompt, create the database:
CREATE DATABASE "ProductManagement";

# Connect to the new database:
\c ProductManagement

# Exit psql:
\q
```

#### Option B: Using pgAdmin 4
1. Open pgAdmin 4
2. Connect to your PostgreSQL server (localhost)
3. Right-click "Databases" → "Create" → "Database"
4. Database name: `ProductManagement`
5. Click "Save"

### Step 3: Run Database Setup Script

#### Option A: Using psql Command Line
```bash
# Navigate to the project directory
cd /path/to/AdoCore

# Run the PostgreSQL setup script
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

#### Option B: Using pgAdmin 4
1. In pgAdmin, connect to ProductManagement database
2. Click "Tools" → "Query Tool"
3. Open `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
4. Click the "Execute" button (▶) or press F5
5. Verify: You should see "Query returned successfully" with no errors

### Step 4: Update Connection String (if needed)

The default connection string in `appsettings.json` is:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432;Pooling=true",
    "ProdConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432;Pooling=true"
  },
  "Environment": "Development"
}
```

**Update if needed:**
- `Host`: Your PostgreSQL server address (default: localhost)
- `Database`: Database name (default: ProductManagement)
- `Username`: PostgreSQL username (default: postgres)
- `Password`: Your PostgreSQL password (set during installation)
- `Port`: PostgreSQL port (default: 5432)

### Step 5: Build and Run the Application

#### Using Command Line:
```bash
# Navigate to project directory
cd /path/to/AdoCore/sourceCode

# Restore NuGet packages
dotnet restore

# Build the project
dotnet build

# Run the application
dotnet run
```

#### Using Visual Studio:
1. Open `AdoCore.sln` in Visual Studio
2. Right-click solution → "Restore NuGet Packages"
3. Press F5 to run with debugging, or Ctrl+F5 to run without debugging

## Running the Application

### Interactive Mode (Menu-Driven)

Run without arguments to enter interactive mode:
```bash
dotnet run
```

You'll see:
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

# Update product (ID, Name, Price, Stock, Description)
dotnet run -- update 1 "Gaming Mouse Pro" 59.99 15 "Updated gaming mouse"

# Delete product
dotnet run -- delete 1

# Update stock quantity
dotnet run -- stock 1 20
```

## Key Features

- **PostgreSQL Integration**: Uses Npgsql for native PostgreSQL connectivity
- **Async/Await Patterns**: All database operations use modern async patterns
- **Transaction Support**: Proper transaction handling with PostgreSQL
- **Resource Management**: IAsyncDisposable for proper cleanup
- **Parameterized Queries**: SQL injection prevention
- **Connection Pooling**: Efficient connection management
- **Window Functions**: Advanced SQL queries using PostgreSQL window functions
- **CTEs**: Common Table Expressions for complex queries

## PostgreSQL-Specific Features Used

- `RETURNING` clause for INSERT operations
- `CURRENT_TIMESTAMP` for timestamps
- `SERIAL` for auto-increment columns
- PostgreSQL triggers with PL/pgSQL
- Window functions (AVG OVER, LAG, RANK, PERCENT_RANK)
- Native PostgreSQL data types

## Migration Notes

This application was migrated from SQL Server to PostgreSQL. Key changes include:

### Database Changes:
- `IDENTITY` → `SERIAL` for auto-increment columns
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `SCOPE_IDENTITY()` → `RETURNING` clause
- `nvarchar` → `VARCHAR`
- `bit` → `BOOLEAN`
- `datetime` → `TIMESTAMP`
- T-SQL stored procedures → PL/pgSQL functions
- T-SQL triggers → PL/pgSQL triggers

### Code Changes:
- `Microsoft.Data.SqlClient` → `Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- Connection string format updated for PostgreSQL

## Testing the Application

1. **Verify Database Connection**:
   ```bash
   dotnet run -- list
   # Should display 19 sample products
   ```

2. **Test Insert Operation**:
   ```bash
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   # Should return new product ID
   ```

3. **Test Retrieve Operation**:
   ```bash
   dotnet run -- get 1
   # Should display product details
   ```

4. **Test Update Operation**:
   ```bash
   dotnet run -- update 1 "Updated Name" 39.99 10 "Updated Description"
   # Should update successfully
   ```

5. **Test Delete Operation**:
   ```bash
   dotnet run -- delete 20
   # Should delete the test product
   ```

## Troubleshooting

### Connection Issues

**Error: "Could not connect to server"**
- Verify PostgreSQL is running: `pg_isready`
- Check connection string in `appsettings.json`
- Ensure PostgreSQL is listening on port 5432
- Verify firewall settings allow port 5432

**Error: "password authentication failed"**
- Update password in `appsettings.json` to match your PostgreSQL password
- Reset PostgreSQL password if needed:
  ```bash
  # As postgres user
  psql -U postgres
  ALTER USER postgres WITH PASSWORD 'newpassword';
  ```

**Error: "database ProductManagement does not exist"**
- Create the database (see Step 2)
- Verify database name matches exactly (case-sensitive)

### Build Issues

**Error: "Package Npgsql not found"**
```bash
dotnet restore
```

**Error: "Cannot find type NpgsqlConnection"**
- Ensure Npgsql package is installed (version 8.0.5 or later)
- Clean and rebuild:
  ```bash
  dotnet clean
  dotnet build
  ```

### Runtime Issues

**Error: "relation 'products' does not exist"**
- Run the database setup script (Step 3)
- Verify script completed without errors

**Error: "Timeout expired"**
- Check PostgreSQL server status
- Verify network connectivity to database host
- Increase timeout in connection string if needed:
  ```
  Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Timeout=30;
  ```

## Required NuGet Packages

- **Npgsql** (8.0.5): PostgreSQL data provider for .NET
- **Microsoft.Extensions.Configuration** (9.0.0): Configuration framework
- **Microsoft.Extensions.Configuration.Json** (9.0.0): JSON configuration provider
- **Microsoft.Extensions.DependencyInjection** (9.0.0): Dependency injection

## Security Considerations

⚠️ **Important**: The default configuration uses hardcoded credentials for demonstration purposes only.

**Production Deployment:**
1. **Never commit credentials** to source control
2. Use environment variables for sensitive data:
   ```bash
   export POSTGRES_PASSWORD="your-secure-password"
   ```
3. Use connection string with environment variable:
   ```json
   "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=${POSTGRES_PASSWORD};Port=5432"
   ```
4. Consider using **AWS Secrets Manager** or **Azure Key Vault** for production
5. Use SSL/TLS for database connections:
   ```
   Host=localhost;Database=ProductManagement;Username=postgres;Password=***;SSL Mode=Require
   ```
6. Apply principle of least privilege (create application-specific database user)

## Best Practices Implemented

- ✅ Modern async/await patterns throughout
- ✅ Proper resource disposal with IAsyncDisposable
- ✅ Transaction management with rollback support
- ✅ Parameterized queries for SQL injection prevention
- ✅ Connection pooling for performance
- ✅ Error handling and logging
- ✅ Separation of concerns (layered architecture)
- ✅ Configuration management with IConfiguration
- ✅ Window functions for advanced analytics
- ✅ Proper NULL handling

## Sample Data

The setup script includes:
- **20 Categories** (hierarchical structure)
- **8 Suppliers** (various countries)
- **19 Products** (laptops, desktops, peripherals, etc.)
- **Product Statistics** (automated tracking)
- **Product History** (automatic change logging via triggers)

## Database Schema

```
Categories (20 rows)
├── Electronics
│   ├── Computers
│   │   ├── Laptops (3 products)
│   │   └── Desktops (2 products)
│   ├── Peripherals
│   │   ├── Keyboards (2 products)
│   │   └── Mice (2 products)
│   ├── Audio
│   │   ├── Headphones (2 products)
│   │   └── Speakers (2 products)
│   └── Storage (2 products)
├── Gaming
│   ├── Gaming PCs (1 product)
│   └── Gaming Accessories
└── Office
    ├── Printers (2 products)
    └── Networking (2 products)
```

## Performance Notes

- Connection pooling is enabled by default (improves performance)
- All queries use prepared statements (better performance and security)
- Indexes created on foreign keys and frequently queried columns
- Window functions may be slower on very large datasets (millions of rows)
- Consider adding `EXPLAIN ANALYZE` before queries for performance tuning

## Advanced Usage

### Using Transactions Manually

```csharp
var repository = new ProductRepository(configuration);
await repository.ExecuteInTransactionAsync(async () => {
    // Your database operations here
    await repository.InsertProductAsync(product1);
    await repository.UpdateProductAsync(product2);
    // All operations commit together or rollback on error
});
```

### Custom Queries

Add new methods to `ProductRepository.cs` using the same patterns:
```csharp
public async Task<List<Product>> GetProductsByCategoryAsync(int categoryId)
{
    var connection = await GetConnectionAsync();
    const string sql = @"
        SELECT * FROM Products 
        WHERE CategoryId = @CategoryId 
        ORDER BY Name";
    
    using var command = new NpgsqlCommand(sql, connection);
    command.Parameters.AddWithValue("@CategoryId", categoryId);
    
    // Execute and map results...
}
```

## Support and Resources

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **PL/pgSQL Guide**: https://www.postgresql.org/docs/current/plpgsql.html
- **.NET Data Access**: https://learn.microsoft.com/en-us/dotnet/standard/data/

## Migration Documentation

Complete migration documentation available in:
- `MIGRATION_REPORT.txt` - Detailed migration report
- `sql_equivalency_validation_report.json` - SQL statement equivalency validation
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.txt` - DMS conversion process log

---

**Note**: This application has been fully migrated from SQL Server to PostgreSQL. The original SQL Server script (`01_InitialSetup.sql`) is preserved for reference but should not be used. Always use `01_InitialSetup_PostgreSQL.sql` for PostgreSQL deployments.
