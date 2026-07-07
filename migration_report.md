# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS failure**: 7
- **DMS Failure Reason**: Infrastructure issues - S3 access permissions and metadata model creation timeouts
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7
- **Equivalency Tool Error**: Systemic error "'uniqueID'" on all attempts (infrastructure issue)

## Conversion Method Applied
All 7 statements were manually converted using `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` rules:
- All schema object names (tables, columns, aliases) converted to lowercase
- `SCOPE_IDENTITY()` → `RETURNING ... INTO` + `currval(pg_get_serial_sequence(...))`
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION` / `COMMIT` → `DO $$ ... BEGIN ... END $$;` (PL/pgSQL anonymous block)
- `DECLARE @var TYPE` → `DECLARE v_var TYPE` (in DO block)
- `SET @var = expr` → removed (using RETURNING INTO or SELECT INTO)
- Integer division for ROUND with StockQuantity uses `::numeric` cast
- CTE syntax, window functions (LAG, RANK, PERCENT_RANK, AVG OVER, etc.) preserved as-is (PostgreSQL compatible)

## DMS Tool Errors (All 7 Statements)
| Statement | Error |
|-----------|-------|
| 1 - GetAllProducts | Metadata model creation did not complete after 15 attempts |
| 2 - GetProductById | Metadata model creation did not complete after 15 attempts |
| 3 - InsertProduct | DMS Schema Conversion can't access the S3 resource |
| 4 - UpdateProduct | Metadata model creation did not complete after 15 attempts |
| 5 - DeleteProduct | DMS Schema Conversion can't access the S3 resource |
| 6 - GetProductsByPriceRange | Metadata model creation did not complete after 15 attempts |
| 7 - GetLowStockProducts | DMS Schema Conversion can't access the S3 resource |

## SQL Equivalency Tool Errors (All 7 Statements)
All 7 statement pairs returned the same error from the SQL Equivalency tool:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
This is a systemic infrastructure issue unrelated to the SQL content.

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - All SQL statements converted, SqlClient → Npgsql
2. `sourceCode/AdoCore.csproj` - Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.3
3. `sourceCode/appsettings.json` - Connection strings updated to PostgreSQL format

## Artifacts Generated
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Full equivalency validation report
4. `sourceCode/migration_report.md` - This report

## Code Changes Summary

### Package Dependencies
- Removed: `Microsoft.Data.SqlClient 5.1.4`
- Added: `Npgsql 8.0.3` (CVE scan: PASS)

### ADO.NET Class Replacements
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `using Microsoft.Data.SqlClient` → `using Npgsql`

### Connection String Changes
- `Server=localhost` → `Host=localhost`
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- Removed: `MultipleActiveResultSets=true;TrustServerCertificate=True`

### SQL Statement Changes
- All table/column names lowercased for PostgreSQL compatibility
- T-SQL transaction blocks converted to PL/pgSQL anonymous blocks (DO $$ ... END $$)
- SCOPE_IDENTITY() replaced with RETURNING clause + currval()
- GETDATE() replaced with NOW()
- Added ::numeric cast for integer division in ROUND()
