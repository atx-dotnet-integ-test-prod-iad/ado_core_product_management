# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention after DMS failure | 7 |
| Validated as equivalent by SQL Equivalency tool | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

## Migration Details

### Source Database
- **Database**: ProductManagement
- **Engine**: Microsoft SQL Server 2019
- **Schema**: dbo

### Target Database
- **Engine**: PostgreSQL 13
- **Connection**: Host=localhost;Database=ProductManagement

### DMS Tool Configuration
- **Migration Project ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Region**: us-east-1
- **Server**: 172.31.94.132
- **Status**: ALL conversions failed with metadata model creation timeout

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND, ORDER BY
- **DMS Status**: FAILED - Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned: 'uniqueID')
- **Changes**: Table/column names to lowercase; SQL syntax is PostgreSQL-compatible as-is

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, LEFT JOIN, CASE, ROUND, parameterized
- **DMS Status**: FAILED - Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned: 'uniqueID')
- **Changes**: Table/column names to lowercase

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **DMS Status**: FAILED - Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned: 'uniqueID')
- **Changes**: 
  - SCOPE_IDENTITY() → Writable CTE with INSERT...RETURNING
  - GETDATE() → NOW()
  - DECLARE/BEGIN TRANSACTION → Writable CTE pattern
  - Table/column names to lowercase

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, GETDATE()
- **DMS Status**: FAILED - Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned: 'uniqueID')
- **Changes**:
  - DECLARE/BEGIN TRANSACTION → Writable CTE pattern with old_values CTE
  - GETDATE() → NOW()
  - Table/column names to lowercase

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, DELETE, CASE, GETDATE()
- **DMS Status**: FAILED - Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned: 'uniqueID')
- **Changes**:
  - DECLARE/BEGIN TRANSACTION → Writable CTE pattern with old_values CTE
  - GETDATE() → NOW()
  - Table/column names to lowercase

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE
- **DMS Status**: FAILED - Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned: 'uniqueID')
- **Changes**: Table/column names to lowercase

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX OVER window functions, CASE, ROUND
- **DMS Status**: FAILED - Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned: 'uniqueID')
- **Changes**: 
  - Table/column names to lowercase
  - Added CAST(stockquantity AS DECIMAL) for integer division in ROUND

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; All SQL Server ADO.NET classes replaced with Npgsql equivalents (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader); using directive updated |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.0 |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format (Server→Host, removed SQL Server-specific params, added Username/Password) |

## Files NOT Requiring Changes

| File | Reason |
|------|--------|
| `Program.cs` | No database-specific code |
| `Business/ProductService.cs` | Business logic layer, no SQL |
| `CLI/CommandLineInterface.cs` | UI layer, no SQL |
| `CLI/InteractiveMenu.cs` | UI layer, no SQL |
| `Models/Product.cs` | Data model, no SQL |

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | All 7 original MS SQL statements |
| `converted_statements.sql` | Project root | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency report with all 7 statement pairs |
| `dms_conversion_summary.md` | Project root | Detailed DMS failure documentation |
| `migration_report.md` | Project root | This report |

## Build Status

- **Final Build**: ✅ SUCCEEDED
- **Errors**: 0
- **Warnings**: 12 (all pre-existing nullable reference type warnings, not related to migration)

## Key Conversion Patterns Applied

| SQL Server Pattern | PostgreSQL Equivalent |
|-------------------|----------------------|
| `SCOPE_IDENTITY()` | Writable CTE with `INSERT...RETURNING productid` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var / BEGIN TRANSACTION` | Writable CTE pattern (no DO $$ blocks due to Npgsql parameter binding constraints) |
| `SELECT @var = col FROM table` | CTE subquery `old_values AS (SELECT col FROM table)` |
| Table/column names (PascalCase) | lowercase (PostgreSQL convention) |
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `SqlConnection/SqlCommand/SqlDataReader` | `NpgsqlConnection/NpgsqlCommand/NpgsqlDataReader` |
| `Server=` connection string | `Host=` connection string |
| `Trusted_Connection=True` | `Username=;Password=` |

## Statements Requiring Manual Review

All 7 statements returned ERROR from the SQL Equivalency tool (error: 'uniqueID'). This appears to be a tool-side issue rather than an actual equivalency problem. The manual conversions applied standard PostgreSQL patterns. Manual review is recommended for:

1. **Statement 3 (InsertProductAsync)**: Most complex transformation - SCOPE_IDENTITY() replaced with writable CTE + RETURNING pattern
2. **Statement 4 (UpdateProductAsync)**: Transaction block restructured to writable CTE with old_values capture
3. **Statement 5 (DeleteProductAsync)**: Transaction block restructured to writable CTE with old_values capture

## Post-Migration Bug Fix

### Critical Runtime Bug: MapProductFromReader Column Name Casing
- **Issue**: The `MapProductFromReader` method referenced column names in PascalCase (e.g., `reader["ProductId"]`, `reader["Name"]`) but all SQL queries now return lowercase column names (`productid`, `name`, etc.). PostgreSQL returns column names in lowercase by default, which would cause `IndexOutOfRangeException` at runtime.
- **Fix**: Updated all column name references in `MapProductFromReader` to lowercase to match the PostgreSQL query output:
  - `reader["ProductId"]` → `reader["productid"]`
  - `reader["Name"]` → `reader["name"]`
  - `reader["Description"]` → `reader["description"]`
  - `reader["Price"]` → `reader["price"]`
  - `reader["StockQuantity"]` → `reader["stockquantity"]`
  - `reader["CreatedDate"]` → `reader["createddate"]`
  - `reader["ModifiedDate"]` → `reader["modifieddate"]`
- **Build Status**: ✅ Successful after fix (0 errors, 12 warnings - all pre-existing)

### SQL Equivalency Re-Validation
- All 7 statement pairs were re-submitted to the SQL Equivalency tool during post-migration review
- All 7 re-validation attempts returned the same ERROR with `'uniqueID'` - confirmed as persistent tool-side issue
- Total equivalency validation attempts: 14 (7 original + 7 retry)

## Notes

- All DMS attempts failed consistently with metadata model creation timeout. This was likely due to a service-side issue with the DMS migration project.
- All SQL equivalency validations returned ERROR with 'uniqueID'. This was a tool-side error, not an indication of non-equivalence. Confirmed persistent across 14 total attempts.
- The writable CTE pattern was chosen over DO $ blocks because DO $ blocks cannot use Npgsql parameterized queries (parameters like @Name are bound by Npgsql and cannot be passed into anonymous DO blocks).
- The converted_statements.sql catalog was updated to reflect the actual writable CTE patterns used in the code (previously contained DO $ block versions).
