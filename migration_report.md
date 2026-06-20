# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Failures
All 7 statements failed DMS conversion due to infrastructure issues:
- 5 statements: "Metadata model creation did not complete after 15 attempts"
- 2 statements: "DMS Schema Conversion can't access your S3 bucket 'atx-db-modernization-789616364195-us-east-1'"

## SQL Equivalency Tool Errors
All 7 statement pairs returned ERROR from the SQL Equivalency tool with message: "'uniqueID'"
This appears to be a service-side infrastructure issue unrelated to the SQL statements themselves.

## Manual Conversion Rules Applied (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
1. All schema object names converted to lowercase (tables, columns, aliases)
2. SCOPE_IDENTITY() replaced with INSERT...RETURNING pattern using writable CTEs
3. GETDATE() replaced with NOW()
4. T-SQL variable declarations (DECLARE @var) replaced with CTE-based approaches
5. BEGIN TRANSACTION/COMMIT blocks replaced with single atomic CTE statements
6. Integer division addressed with ::numeric cast where needed
7. CTE name "ProductHistory" renamed to "producthistory_cte" to avoid conflict with table name "producthistory"

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - SQL statements, using directives, class references
2. `sourceCode/AdoCore.csproj` - Package reference Microsoft.Data.SqlClient -> Npgsql
3. `sourceCode/appsettings.json` - Connection strings updated to PostgreSQL format

## Artifacts Generated
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Comprehensive equivalency report

## Static Code Changes
- `Microsoft.Data.SqlClient` -> `Npgsql`
- `SqlConnection` -> `NpgsqlConnection`
- `SqlCommand` -> `NpgsqlCommand`
- `SqlDataReader` -> `NpgsqlDataReader`
- Connection string: `Server=` -> `Host=`, removed `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`; added `Username`/`Password`
