# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual conversion (DMS failure) | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Failures

All 7 SQL statements failed DMS conversion due to infrastructure issues:
- Error 1: "Metadata model creation did not complete after 15 attempts"
- Error 2: "DMS Schema Conversion can't access the S3 resource 'atx-db-modernization-789616364195-us-east-1'"

## SQL Equivalency Tool Failures

All 7 statement pairs returned ERROR from the SQL Equivalency tool:
- Error: "'uniqueID'" - Internal tool error preventing validation

## Manual Conversion Applied

All statements were manually converted using the rule: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Key Conversions Applied:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. `SCOPE_IDENTITY()` replaced with `RETURNING productid` via writable CTEs
3. `GETDATE()` replaced with `NOW()`
4. `BEGIN TRANSACTION`/`COMMIT` blocks refactored to writable CTEs (data-modifying CTEs)
5. `DECLARE @var` variable assignments refactored to CTE subqueries
6. SQL Server stored procedures (`CREATE OR ALTER PROCEDURE`) converted to PostgreSQL functions (`CREATE OR REPLACE FUNCTION`)
7. `IDENTITY(1,1)` replaced with `SERIAL`
8. `NVARCHAR` replaced with `VARCHAR`
9. `DATETIME` replaced with `TIMESTAMP`
10. `BIT` replaced with `BOOLEAN`
11. `SYSTEM_USER` replaced with `current_user`
12. SQL Server trigger syntax (inserted/deleted pseudo-tables) converted to PostgreSQL trigger functions (NEW/OLD)
13. `GO` batch separators removed
14. `IF NOT EXISTS (SELECT * FROM sys.objects ...)` replaced with `DROP ... IF EXISTS` / `CREATE TABLE IF NOT EXISTS`
15. `SET NOCOUNT ON` removed (not needed in PostgreSQL)
16. `Trusted_Connection=True` connection string replaced with `Username`/`Password` PostgreSQL format
17. `Server=` replaced with `Host=`
18. `MultipleActiveResultSets=true` and `TrustServerCertificate=True` removed (SQL Server specific)

## Files Modified

| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | Replaced all SQL statements, SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader, Microsoft.Data.SqlClient→Npgsql |
| AdoCore.csproj | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.3 |
| appsettings.json | SQL Server connection strings → PostgreSQL connection strings |
| Database/Scripts/01_InitialSetup.sql | Full schema conversion to PostgreSQL syntax |
| Scripts/01_InitialSetup.sql | Simplified schema conversion to PostgreSQL syntax |

## New Files Created

| File | Purpose |
|------|---------|
| extracted_statements.sql | Catalog of all original MS SQL statements |
| converted_statements.sql | Catalog of all converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Comprehensive equivalency validation report |

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool infrastructure failures preventing automated conversion
2. SQL Equivalency tool errors preventing automated validation
3. Manual conversion applied with lowercase schema mapping rules

### Statement Details:

1. **GetAllProductsAsync** - CTE with window functions (AVG OVER, COUNT OVER). Direct lowercase conversion - PostgreSQL supports these natively.
2. **GetProductByIdAsync** - CTE with LAG window function. Direct lowercase conversion - PostgreSQL supports LAG natively.
3. **InsertProductAsync** - Transaction with SCOPE_IDENTITY/GETDATE. Converted to writable CTE with RETURNING/NOW().
4. **UpdateProductAsync** - Transaction with DECLARE/GETDATE. Converted to writable CTE with NOW().
5. **DeleteProductAsync** - Transaction with DECLARE/GETDATE. Converted to writable CTE with NOW().
6. **GetProductsByPriceRangeAsync** - CTE with RANK/PERCENT_RANK. Direct lowercase conversion - PostgreSQL supports these natively.
7. **GetLowStockProductsAsync** - CTE with AVG/MIN/MAX OVER. Lowercase + CAST for integer division in ROUND.
