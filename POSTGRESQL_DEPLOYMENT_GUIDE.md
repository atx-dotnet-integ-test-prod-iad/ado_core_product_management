# PostgreSQL Migration Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the migrated ADO.NET application from Microsoft SQL Server to PostgreSQL.

## Prerequisites
- PostgreSQL 13 or higher installed
- .NET SDK (for building the application)
- PostgreSQL client tools (psql)
- Database administrator credentials

## Database Setup

### Step 1: Create PostgreSQL Database

```bash
# Connect to PostgreSQL as superuser
psql -U postgres

# Create the database
CREATE DATABASE "ProductManagement";

# Connect to the new database
\c ProductManagement
```

### Step 2: Execute Schema Migration Script

```bash
# Run the PostgreSQL schema setup script
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

**What this script does:**
- Creates `productmanagement_dbo` schema
- Creates all required tables: products, producthistory, productstats, categories, suppliers
- Sets up indexes for optimal query performance
- Creates triggers for automatic history tracking
- Inserts sample data (19 products, 20 categories, 8 suppliers)
- Initializes product statistics

### Step 3: Verify Database Schema

```sql
-- Connect to database
psql -U postgres -d ProductManagement

-- Verify tables were created
\dt productmanagement_dbo.*

-- Expected output:
-- productmanagement_dbo.categories
-- productmanagement_dbo.producthistory
-- productmanagement_dbo.products
-- productmanagement_dbo.productstats
-- productmanagement_dbo.suppliers

-- Verify data was loaded
SELECT COUNT(*) FROM productmanagement_dbo.products;  -- Should return 19
SELECT COUNT(*) FROM productmanagement_dbo.categories;  -- Should return 20
SELECT COUNT(*) FROM productmanagement_dbo.suppliers;  -- Should return 8
```

## Application Configuration

### Step 4: Update Connection Strings

Edit `appsettings.json` and replace the placeholder passwords:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_ACTUAL_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=YOUR_PROD_USER;Password=YOUR_PROD_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20"
  },
  "Environment": "Development"
}
```

**Connection String Parameters:**
- `Host`: PostgreSQL server hostname (default: localhost)
- `Port`: PostgreSQL port (default: 5432)
- `Database`: Database name (ProductManagement)
- `Username`: PostgreSQL user with appropriate permissions
- `Password`: User password (REQUIRED - replace placeholder)
- `Pooling`: Enable connection pooling (recommended: true)
- `MinPoolSize`: Minimum pool size (recommended: 1)
- `MaxPoolSize`: Maximum pool size (recommended: 20)

### Step 5: Upgrade Npgsql Package (Recommended)

The current version (8.0.0) has a known vulnerability. Upgrade to a patched version:

```bash
dotnet remove package Npgsql
dotnet add package Npgsql --version 8.0.5  # Or latest stable version
```

### Step 6: Build the Application

```bash
# Build the project
dotnet build AdoCore.csproj

# Verify build succeeds with 0 errors
# Expected: "Build succeeded. 0 Error(s)"
```

## Integration Testing

### Step 7: Test Database Connectivity

Create a simple test to verify connectivity:

```bash
# Run the application (if it has a test mode)
dotnet run --project AdoCore.csproj

# Or create a simple test script
```

### Step 8: Validate Repository Operations

Test each repository method against PostgreSQL:

1. **GetAllProductsAsync** - Test CTE query execution
2. **GetProductByIdAsync** - Test LAG window function
3. **InsertProductAsync** - Test transaction with RETURNING clause
4. **UpdateProductAsync** - Test 4-statement transaction
5. **DeleteProductAsync** - Test 4-statement transaction with history
6. **GetProductsByPriceRangeAsync** - Test RANK functions
7. **GetLowStockProductsAsync** - Test aggregate window functions

### Step 9: Verify Transaction Atomicity

Test transaction rollback scenarios:

```sql
-- Test concurrent operations
-- Insert product with invalid data to trigger rollback
-- Verify history table and stats table remain consistent
```

## SQL Statement Equivalency Validation

### Statements Requiring Manual Testing

Three SQL statements returned UNKNOWN from the equivalency tool and require manual validation with actual data:

1. **Statement 2 (GetProductByIdAsync)**: LAG window function
   - Test with products that have previous/next records
   - Verify LAG function returns correct previous price

2. **Statement 3 (InsertProductAsync)**: Multi-statement transaction
   - Insert new product
   - Verify INSERT into products, producthistory, and productstats
   - Test RETURNING clause returns correct productid

3. **Statement 6 (GetProductsByPriceRangeAsync)**: RANK and PERCENT_RANK window functions
   - Test with various price ranges
   - Verify ranking is consistent with SQL Server behavior
   - Compare PERCENT_RANK calculation results

### Testing Checklist

- [ ] Database created and schema loaded
- [ ] Connection strings updated with actual credentials
- [ ] Application builds without errors
- [ ] Connection to PostgreSQL succeeds
- [ ] All 7 repository methods execute successfully
- [ ] Statement 2 (LAG function) validated with test data
- [ ] Statement 3 (INSERT transaction) validated with test data
- [ ] Statement 6 (RANK functions) validated with test data
- [ ] Transaction atomicity verified (rollback on error)
- [ ] Trigger for product history works correctly
- [ ] ProductStats table updates correctly
- [ ] Performance testing completed
- [ ] Npgsql package upgraded to patched version

## Troubleshooting

### Common Issues

**Issue: Connection refused**
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check firewall allows port 5432
- Verify PostgreSQL accepts connections in pg_hba.conf

**Issue: Authentication failed**
- Verify username/password in connection string
- Check PostgreSQL user has necessary permissions
- Review pg_hba.conf authentication method

**Issue: Schema not found**
- Ensure 01_InitialSetup_PostgreSQL.sql executed successfully
- Verify schema exists: `\dn productmanagement_dbo`
- Check for error messages in psql output

**Issue: Window function errors**
- PostgreSQL window function syntax differs slightly from SQL Server
- Review converted_statements.sql for exact syntax
- Test queries individually in psql

## Security Recommendations

1. **Never commit passwords to source control**
   - Use environment variables or secret management
   - Add appsettings.json to .gitignore if it contains credentials

2. **Use least privilege principle**
   - Create dedicated database user for application
   - Grant only necessary permissions
   - Avoid using postgres superuser in production

3. **Enable SSL/TLS connections**
   - Add `SslMode=Require` to connection string
   - Configure PostgreSQL to require SSL

4. **Regular security updates**
   - Keep PostgreSQL updated
   - Keep Npgsql package updated
   - Monitor security advisories

## Performance Tuning

1. **Connection Pooling**
   - Already enabled in connection string
   - Adjust MinPoolSize/MaxPoolSize based on load

2. **Indexes**
   - All necessary indexes created by setup script
   - Monitor query performance and add indexes as needed

3. **Query Optimization**
   - Use EXPLAIN ANALYZE to profile queries
   - Review execution plans for window functions

4. **Database Maintenance**
   - Schedule regular VACUUM and ANALYZE
   - Monitor table bloat
   - Review and archive old producthistory records

## Migration Report Summary

### Transformation Statistics
- **Total SQL Statements**: 7
- **Successfully Converted**: 7 (4 by DMS tool, 3 manually)
- **Equivalency Validation**: 4 EQUIVALENT, 3 ERROR (require manual testing)
- **ADO.NET Classes Replaced**: 19
- **Package Changes**: Microsoft.Data.SqlClient → Npgsql 8.0.0

### Key Transformations Applied
1. SQL Server data types → PostgreSQL types (IDENTITY → SERIAL, NVARCHAR → VARCHAR, etc.)
2. T-SQL syntax → PostgreSQL syntax (TOP → LIMIT, GETDATE() → CURRENT_TIMESTAMP)
3. Window functions adapted (LAG, RANK, PERCENT_RANK, AVG, COUNT, MIN, MAX)
4. Multi-statement transactions converted to application-level transaction management
5. RETURNING clause for INSERT operations
6. Trigger syntax converted from T-SQL to PL/pgSQL

## Support and Resources

- **Migration Report**: See migration_report.json for detailed transformation log
- **SQL Equivalency Report**: See sql_equivalency_validation_report.json for validation details
- **Conversion Log**: See dms_conversion_log.json for DMS tool output
- **Original Statements**: See extracted_statements.sql
- **Converted Statements**: See converted_statements.sql

## Next Steps

1. Complete database setup following this guide
2. Execute integration tests
3. Validate statements marked ERROR in equivalency report
4. Deploy to staging environment
5. Perform load testing
6. Create backup and rollback procedures
7. Update operational documentation
8. Train team on PostgreSQL-specific behaviors

## Contact

For issues or questions related to this migration, please refer to the migration artifacts listed above or contact your database administrator.
