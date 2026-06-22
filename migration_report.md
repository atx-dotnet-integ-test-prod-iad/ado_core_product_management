# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Statements successfully converted by DMS**: 0
- **Statements requiring manual intervention (DMS failure)**: 7
- **Statements validated as equivalent**: 0
- **Statements validated as non-equivalent**: 0
- **Statements with equivalency validation errors**: 7

## DMS Tool Failure Details
All 7 statements failed DMS conversion due to infrastructure issues:
- Error 1: "Metadata model creation did not complete after 15 attempts"
- Error 2: "DMS Schema Conversion can't access S3 bucket 'atx-db-modernization-789616364195-us-east-1'"

All statements were manually converted applying lowercase schema object naming conventions per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA rules.

## SQL Equivalency Tool Failure Details
All 7 statement pairs returned ERROR from the SQL equivalency tool with error "'uniqueID'" - this appears to be a tool infrastructure issue unrelated to the SQL statements themselves.

## Conversion Rules Applied (Manual)
1. All schema object names (tables, columns, aliases) converted to lowercase
2. `SCOPE_IDENTITY()` replaced with `RETURNING productid` clause
3. `GETDATE()` replaced with `NOW()`
4. `DECLARE @variable` blocks replaced with C# application-level variables
5. Transaction blocks split into individual statements managed by C# `BeginTransactionAsync()`
6. Integer division fixed with `::numeric` cast where needed
7. `IDENTITY(1,1)` mapped to `SERIAL` in PostgreSQL table DDL

## Files Modified
1. `sourceCode/DataAccess/ProductRepository.cs` - Complete rewrite of SQL statements and ADO.NET classes
2. `sourceCode/AdoCore.csproj` - Replaced Microsoft.Data.SqlClient with Npgsql
3. `sourceCode/appsettings.json` - Updated connection strings to PostgreSQL format

## Files Created
1. `sourceCode/extracted_statements.sql` - Original MS SQL statements catalog
2. `sourceCode/converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sourceCode/sql_equivalency_validation_report.json` - Full equivalency validation report

## Static Code Changes
| Original | Replacement |
|----------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Microsoft.Data.SqlClient v5.1.4` | `Npgsql v8.0.0` |
| `Server=localhost;Database=...;Trusted_Connection=True` | `Host=localhost;Database=...;Username=postgres;Password=postgres` |

## Connection String Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=` | `Host=` |
| `Database=ProductManagement` | `Database=productmanagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | (removed - not applicable) |
| `TrustServerCertificate=True` | (removed - not applicable) |
