# SQL Server to PostgreSQL Migration Report - AdoCore Application

## Summary
- **Total SQL Statements Processed**: 7
- **Statements Successfully Converted by DMS**: 0
- **Statements Requiring Manual Conversion (DMS Failure)**: 7
- **Statements Validated as Equivalent**: 0
- **Statements Validated as Non-Equivalent**: 0
- **Statements with Equivalency Validation Errors**: 7

## DMS Tool Failures
All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed with infrastructure errors:
- **Error Type 1**: "Metadata model creation did not complete after 15 attempts" (4 statements)
- **Error Type 2**: "DMS Schema Conversion can't access the S3 resource 'atx-db-modernization-789616364195-us-east-1'" (3 statements)

## SQL Equivalency Tool Failures
All 7 statement pairs were submitted to the SQL Equivalency tool. All returned errors:
- **Error**: "'uniqueID'" - Internal tool error affecting all validations

## Manual Conversion Applied (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
Since DMS failed for all statements, manual conversion was applied with the following rules:
1. All schema object names converted to lowercase (tables, columns, aliases)
2. `SCOPE_IDENTITY()` replaced with `RETURNING` clause
3. `GETDATE()` replaced with `NOW()`
4. T-SQL `BEGIN TRANSACTION`/`COMMIT` blocks with variables replaced with PostgreSQL writable CTEs
5. T-SQL `DECLARE @variable` / `SET @variable` patterns replaced with CTE-based value capture
6. Integer division cast to `::numeric` where needed for proper decimal results

## Files Modified
1. **DataAccess/ProductRepository.cs** - All SQL statements converted, ADO.NET classes migrated:
   - `using Microsoft.Data.SqlClient` → `using Npgsql`
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - Column name references in reader updated to lowercase

2. **AdoCore.csproj** - Package reference updated:
   - `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.3`

3. **appsettings.json** - Connection strings updated:
   - SQL Server format → PostgreSQL format (Host, Username, Password)

## Artifacts Generated
- `extracted_statements.sql` - All 7 original MS SQL statements
- `converted_statements.sql` - All 7 converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Full equivalency validation report
- `migration_report.md` - This file

## Statements Requiring Manual Review
All 7 statements should be manually reviewed since:
1. DMS conversion was unavailable (infrastructure access errors)
2. SQL Equivalency tool was non-functional (internal 'uniqueID' error)

### Statement Details

| # | Method | Type | Key Conversions |
|---|--------|------|-----------------|
| 1 | GetAllProductsAsync | SELECT with CTE + Window Functions | Lowercase only |
| 2 | GetProductByIdAsync | SELECT with CTE + LAG | Lowercase only |
| 3 | InsertProductAsync | INSERT + Transaction | SCOPE_IDENTITY→RETURNING, GETDATE→NOW, Transaction→Writable CTE |
| 4 | UpdateProductAsync | UPDATE + Transaction | Variables→CTE capture, GETDATE→NOW, Transaction→Writable CTE |
| 5 | DeleteProductAsync | DELETE + Transaction | Variables→CTE capture, GETDATE→NOW, Transaction→Writable CTE |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE + RANK/PERCENT_RANK | Lowercase only |
| 7 | GetLowStockProductsAsync | SELECT with CTE + AVG/MIN/MAX | Lowercase + ::numeric cast |
