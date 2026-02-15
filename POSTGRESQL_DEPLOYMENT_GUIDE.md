# PostgreSQL Migration Deployment Guide

## Overview
This document provides step-by-step instructions for deploying and testing the migrated ADO.NET application with PostgreSQL.

## Prerequisites
1. PostgreSQL 12 or higher installed
2. .NET 9.0 SDK installed
3. PostgreSQL client tools (psql) for running SQL scripts

## Database Setup

### Step 1: Create PostgreSQL Database
Connect to your PostgreSQL server as a superuser and create the database:

```bash
psql -U postgres
```

```sql
CREATE DATABASE "ProductManagement";
\q
```

### Step 2: Run Schema Migration Script
Execute the PostgreSQL schema setup script:

```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

This script will:
- Create all necessary tables (categories, suppliers, products, product_history, product_stats)
- Set up indexes and foreign key constraints
- Create PostgreSQL functions (replacing SQL Server stored procedures)
- Create triggers for product history tracking
- Load sample data for testing

### Step 3: Verify Database Setup
Connect to the database and verify tables and data:

```bash
psql -U postgres -d ProductManagement
```

```sql
-- Check tables
\dt

-- Verify sample data
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;

-- Test a query
SELECT product_id, name, price, stock_quantity FROM products LIMIT 5;

\q
```

## Application Configuration

### Step 4: Update Connection String
The `appsettings.json` file has already been updated with PostgreSQL connection strings. Update the credentials if needed:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true;Timeout=30",
    "ProdConnection": "Host=YOUR_PROD_HOST;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true;Timeout=30"
  }
}
```

Replace:
- `YOUR_PASSWORD` with your PostgreSQL password
- `YOUR_PROD_HOST` with your production PostgreSQL server address (if applicable)

## Build and Run

### Step 5: Build the Application
```bash
dotnet build
```

Expected output:
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### Step 6: Run the Application
```bash
dotnet run
```

The application will start and display a menu with options to:
1. List all products
2. Get product by ID
3. Add new product
4. Update product
5. Delete product
6. Exit

## Testing Database Operations

### Test 1: List All Products
- Select option 1 from the menu
- Should display a list of all products from the sample data
- Verify products are displayed correctly

### Test 2: Get Product by ID
- Select option 2 from the menu
- Enter a product ID (e.g., 1)
- Should display details for that specific product

### Test 3: Add New Product
- Select option 3 from the menu
- Enter product details:
  - Name: Test Product
  - Description: Test Description
  - Price: 99.99
  - Stock Quantity: 10
- Should successfully insert the product and return the new product ID
- Verify by listing all products again

### Test 4: Update Product
- Select option 4 from the menu
- Enter the product ID to update
- Enter new values for name, description, price, and stock quantity
- Should successfully update the product
- Verify changes by getting the product by ID

### Test 5: Delete Product
- Select option 5 from the menu
- Enter the product ID to delete
- Should successfully delete the product
- Verify deletion by trying to get the product by ID

### Test 6: Verify Transaction History
After performing updates, check the product_history table:

```bash
psql -U postgres -d ProductManagement
```

```sql
SELECT * FROM product_history ORDER BY action_date DESC LIMIT 10;
```

This should show all INSERT, UPDATE, and DELETE operations performed by the trigger.

### Test 7: Verify Statistics Updates
Check the product_stats table:

```sql
SELECT * FROM product_stats;
```

## Verifying Migration Compliance

### SQL Statement Conversions
All SQL statements have been processed through the DMS MCP tool and documented in:
- `extracted_statements.sql` - Original SQL Server statements
- `converted_statements.sql` - PostgreSQL converted statements
- `dms_conversion_log.md` - Detailed conversion log

### SQL Equivalency Validation
All statement pairs have been validated using the SQL Equivalency tool:
- Report: `sql_equivalency_validation_report.json`
- Contains validation results for all 7 SQL statement pairs

### Code Changes Summary
1. **Package Migration**: Microsoft.Data.SqlClient → Npgsql 8.0.5
2. **ADO.NET Classes Updated**:
   - SqlConnection → NpgsqlConnection
   - SqlCommand → NpgsqlCommand
   - SqlDataReader → NpgsqlDataReader
   - SqlTransaction → NpgsqlTransaction
3. **SQL Syntax Updates**:
   - GETDATE() → CURRENT_TIMESTAMP
   - SCOPE_IDENTITY() → RETURNING clause
   - Transaction syntax adapted for PostgreSQL

## Troubleshooting

### Connection Issues
If you cannot connect to PostgreSQL:
1. Verify PostgreSQL service is running: `sudo systemctl status postgresql`
2. Check pg_hba.conf for authentication settings
3. Verify connection string credentials
4. Check firewall settings for port 5432

### Build Issues
If the application doesn't build:
1. Verify .NET 9.0 SDK is installed: `dotnet --version`
2. Restore NuGet packages: `dotnet restore`
3. Clean and rebuild: `dotnet clean && dotnet build`

### Runtime Errors
If you encounter runtime errors:
1. Check application logs for specific error messages
2. Verify database connection string in appsettings.json
3. Ensure PostgreSQL database and schema are properly set up
4. Check PostgreSQL logs: `/var/log/postgresql/`

## Exit Criteria Validation

### Automated Validation Completed (11/16 criteria):
✅ 1. SQL Server packages replaced with PostgreSQL equivalents
✅ 2. ADO.NET classes replaced with Npgsql equivalents
✅ 3. All SQL statements processed through DMS MCP tool
✅ 4. Comprehensive catalog of SQL statements exists
✅ 5. All SQL statement pairs validated using SQL Equivalency tool
✅ 6. Comprehensive equivalency validation report generated
✅ 7. No agent judgment used for equivalency determination
✅ 8. Failed DMS conversions documented
✅ 9. Connection strings updated to PostgreSQL format
✅ 10. Transaction handling updated for PostgreSQL
✅ 11. Application compiles without errors
✅ 16. Final report includes complete SQL statement listing with equivalency status

### Manual Validation Required (4 criteria):
⏳ 12. Application successfully connects to PostgreSQL database
⏳ 13. All database operations execute successfully
⏳ 14. Transaction blocks maintain atomicity
⏳ 15. Application passes all unit/integration tests

### Test Pass/Fail Criteria
- ✅ **Pass**: All manual tests above execute successfully without errors
- ❌ **Fail**: Any test fails or produces incorrect results

## Notes
- The migration preserved all original business logic
- No tests were removed or disabled during migration
- All security controls remain intact
- License headers preserved
- Public API names unchanged

## Support
For issues or questions:
1. Review the transformation artifacts in the project root
2. Check the SQL equivalency validation report
3. Consult the DMS conversion log for SQL statement details
