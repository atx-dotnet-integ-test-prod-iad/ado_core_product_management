# SQL Server to PostgreSQL Migration Report

## Summary
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-07-17

## SQL Statement Processing

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Manually converted (DMS failure) | 7 |
| Validated as equivalent | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 7 |

## DMS Tool Failures
All 7 SQL statements failed DMS conversion due to infrastructure issues:
- **Error 1**: "Metadata model creation did not complete after 15 attempts"
- **Error 2**: "DMS Schema Conversion can't access the S3 resource 'atx-db-modernization-789616364195-us-east-1'"

All statements were manually converted applying lowercase schema object naming conventions per the transformation definition (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Tool Errors
All 7 statement pairs returned ERROR status from the SQL Equivalency tool with error: "'uniqueID'". This appears to be a tool infrastructure issue unrelated to the SQL statements themselves.

## Conversion Details

### Statement 1: GetAllProductsAsync (SELECT with CTE, window functions)
- **Conversion**: Schema objects lowercased; SQL syntax compatible with PostgreSQL as-is
- **Key changes**: Table/column names to lowercase

### Statement 2: GetProductByIdAsync (SELECT with CTE, LAG window function)
- **Conversion**: Schema objects lowercased; SQL syntax compatible with PostgreSQL as-is
- **Key changes**: Table/column names to lowercase

### Statement 3: InsertProductAsync (Transaction with SCOPE_IDENTITY)
- **Conversion**: Major restructure required
- **Key changes**: 
  - `DECLARE @var` / `SET @var = SCOPE_IDENTITY()` → CTE with `RETURNING` clause
  - `BEGIN TRANSACTION/COMMIT` → Single atomic CTE statement
  - `GETDATE()` → `NOW()`
  - Table/column names to lowercase

### Statement 4: UpdateProductAsync (Transaction with variable declarations)
- **Conversion**: Major restructure required
- **Key changes**:
  - `DECLARE @var` → PL/pgSQL `DO $$` block with `DECLARE`
  - `SELECT @var = col` → `SELECT col INTO var`
  - `GETDATE()` → `NOW()`
  - Table/column names to lowercase

### Statement 5: DeleteProductAsync (Transaction with variable declarations)
- **Conversion**: Major restructure required
- **Key changes**:
  - `DECLARE @var` → PL/pgSQL `DO $$` block with `DECLARE`
  - `SELECT @var = col` → `SELECT col INTO var`
  - `GETDATE()` → `NOW()`
  - Table/column names to lowercase

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE, RANK/PERCENT_RANK)
- **Conversion**: Schema objects lowercased; SQL syntax compatible with PostgreSQL as-is
- **Key changes**: Table/column names to lowercase

### Statement 7: GetLowStockProductsAsync (SELECT with CTE, AVG/MIN/MAX window functions)
- **Conversion**: Minor syntax adjustment
- **Key changes**:
  - Added `::numeric` cast for integer division in ROUND function
  - Table/column names to lowercase

## Static Code Changes

### Package References (AdoCore.csproj)
- **Removed**: `Microsoft.Data.SqlClient` Version 5.1.4
- **Added**: `Npgsql` Version 8.0.3 (CVE check: PASS)

### ADO.NET Class Replacements (DataAccess/ProductRepository.cs)
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Updates (appsettings.json)
- `Server=localhost` → `Host=localhost`
- `Database=ProductManagement` → `Database=productmanagement`
- `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Username=postgres;Password=postgres;`

## Files Modified
1. `DataAccess/ProductRepository.cs` - All SQL statements, ADO.NET classes, imports
2. `AdoCore.csproj` - Package reference
3. `appsettings.json` - Connection strings

## Artifacts Generated
1. `extracted_statements.sql` - Complete catalog of original MS SQL statements
2. `converted_statements.sql` - Complete catalog of converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report
