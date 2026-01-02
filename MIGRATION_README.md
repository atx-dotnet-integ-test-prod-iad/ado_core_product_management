# AdoCore - PostgreSQL Migration

This project has been migrated from Microsoft SQL Server to PostgreSQL.

## Prerequisites

- PostgreSQL 12 or higher
- .NET 9.0 SDK
- Npgsql 8.0.5 or higher

## Database Setup

### 1. Install PostgreSQL

Download and install PostgreSQL from [https://www.postgresql.org/download/](https://www.postgresql.org/download/)

### 2. Create Database

Connect to PostgreSQL as the postgres superuser and create the database:

```bash
psql -U postgres
```

```sql
CREATE DATABASE "ProductManagement";
\c ProductManagement
```

### 3. Run Setup Script

Execute the PostgreSQL setup script to create tables, insert sample data, and set up triggers:

```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

Alternatively, from within psql:

```sql
\i Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### 4. Configure Connection String

Update the connection string in `appsettings.json` if needed:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true"
  },
  "Environment": "Development"
}
```

**Important**: Replace `your_password` with your actual PostgreSQL password. Never commit passwords to version control.

### 5. Verify Database Setup

Check that all tables were created:

```sql
\c ProductManagement
SET search_path TO productmanagement_dbo;
\dt
```

You should see the following tables:
- categories
- suppliers
- products
- producthistory
- productstats

## Schema Design

The PostgreSQL schema uses the prefix `productmanagement_dbo` to match the original SQL Server schema naming:

- SQL Server: `dbo.Products` → PostgreSQL: `productmanagement_dbo.products`
- All column names are lowercase in PostgreSQL
- All table names are lowercase in PostgreSQL

## Key Migration Changes

### 1. Package References
- **Removed**: `Microsoft.Data.SqlClient`
- **Added**: `Npgsql` 8.0.5

### 2. ADO.NET Classes
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlParameter` → `NpgsqlParameter`
- `SqlTransaction` → `NpgsqlTransaction`

### 3. SQL Syntax Changes
- `GETDATE()` → `clock_timestamp()`
- `SCOPE_IDENTITY()` → `RETURNING` clause
- `BEGIN TRANSACTION` / `COMMIT` → `BeginTransactionAsync()` / `CommitAsync()`
- Added `NULLS FIRST` to ORDER BY clauses for consistent null handling
- Schema qualified table names: `productmanagement_dbo.products`

### 4. Connection String Format
```
SQL Server: Server=localhost;Database=ProductManagement;Trusted_Connection=true;
PostgreSQL: Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true
```

## Building the Application

```bash
dotnet restore
dotnet build
```

## Running the Application

```bash
dotnet run
```

## SQL Statement Conversion

All SQL statements were converted using the AWS Database Migration Service (DMS) MCP tool. Details are available in:

- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.json` - Detailed conversion log with DMS model IDs
- `sql_equivalency_validation_report.json` - SQL equivalency validation results
- `final_migration_report.md` - Complete migration report

## Validation Results

### Passed Criteria (11/16)
✅ All SQL Server packages replaced with PostgreSQL equivalents  
✅ All ADO.NET classes updated to Npgsql equivalents  
✅ All SQL statements processed through DMS MCP tool  
✅ Comprehensive SQL statement catalog created  
✅ All SQL statement pairs validated through SQL Equivalency tool  
✅ Comprehensive equivalency validation report generated  
✅ No agent judgment used for SQL equivalency  
✅ Failed DMS conversions documented  
✅ Connection strings updated to PostgreSQL format  
✅ Transaction handling updated to PostgreSQL syntax  
✅ Application compiles without errors  
✅ Final report includes SQL statement equivalency status  

### Not Verified (4/16)
⚠️ Database connection not tested (requires PostgreSQL instance)  
⚠️ Database operations not tested (requires PostgreSQL instance)  
⚠️ Transaction atomicity not tested (requires PostgreSQL instance)  
⚠️ Test suite not executed (no tests exist in project)  

### Next Steps

To complete validation, you need to:

1. **Set up PostgreSQL database** using the provided setup script
2. **Update connection string** with actual credentials
3. **Run the application** to verify database connectivity
4. **Test CRUD operations**:
   - GetAllProductsAsync
   - GetProductByIdAsync
   - InsertProductAsync
   - UpdateProductAsync
   - DeleteProductAsync
   - GetProductsByPriceRangeAsync
   - GetLowStockProductsAsync
5. **Verify transaction behavior** (commit/rollback)
6. **(Optional) Create integration tests** for automated verification

## Troubleshooting

### Connection Issues

If you encounter connection errors:
1. Verify PostgreSQL service is running: `systemctl status postgresql` (Linux) or check Services (Windows)
2. Check PostgreSQL is listening on port 5432: `netstat -an | grep 5432`
3. Verify pg_hba.conf allows connections from your application
4. Test connection with psql: `psql -U postgres -d ProductManagement`

### Schema Issues

If tables are not found:
1. Verify the schema exists: `\dn` in psql
2. Check search_path: `SHOW search_path;`
3. Explicitly set search_path in connection string: `Search Path=productmanagement_dbo`

### Case Sensitivity

PostgreSQL is case-sensitive for identifiers. The application uses lowercase names matching PostgreSQL conventions:
- Table names: `products`, `categories`, etc.
- Column names: `productid`, `name`, `price`, etc.

## Additional Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [AWS DMS Documentation](https://docs.aws.amazon.com/dms/)
