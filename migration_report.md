# SQL Server to PostgreSQL Migration Report

## Summary
- **Project**: AdoCore
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-05-15

## Statistics
- **Total SQL statements processed**: 14 (7 original blocks decomposed into 14 individual statements)
- **Statements successfully converted by DMS MCP tool**: 0
- **Statements requiring manual intervention after DMS tool failure**: 14
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 14

## DMS Tool Failures
All 7 DMS conversion attempts failed with the following errors:
- "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}" (4 occurrences)
- "Metadata model creation failed: {'error': \"Metadata model creation failed: {'default_error_details': {'message': 'Access to Amazon Service denied.'}}\"}" (3 occurrences)

## SQL Equivalency Tool Errors
All 14 equivalency validation attempts returned ERROR with: `'uniqueID'`
This appears to be a systemic tool-side error unrelated to the SQL statements themselves.

## Manual Conversion Rules Applied (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
1. All schema object names converted to lowercase (tables, columns, aliases)
2. `SCOPE_IDENTITY()` → PostgreSQL `RETURNING productid` clause
3. `GETDATE()` → `NOW()`
4. T-SQL `DECLARE`/`SET` variable syntax → Restructured as separate SQL commands managed by C# ADO.NET transactions
5. `BEGIN TRANSACTION`/`COMMIT` → Managed by NpgsqlTransaction in C# code
6. `CAST(x AS DECIMAL)` → `x::numeric` (PostgreSQL cast syntax)

## Files Modified
1. **sourceCode/DataAccess/ProductRepository.cs** - All SQL statements converted, ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader, SqlParameter→NpgsqlParameter)
2. **sourceCode/AdoCore.csproj** - Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.1
3. **sourceCode/appsettings.json** - Connection strings updated from SQL Server format to PostgreSQL format

## Artifacts Generated
1. `extracted_statements.sql` - Complete catalog of all original MS SQL statements
2. `converted_statements.sql` - Complete catalog of all converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This file

## Statements Requiring Manual Review
All 14 statements should be manually reviewed due to:
- DMS tool was unavailable (all conversions failed)
- SQL Equivalency tool returned errors for all validations
- Manual conversion was applied using lowercase schema mapping rules
