# SQL Server to PostgreSQL Migration Report

## Summary
- **Project**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server (Microsoft.Data.SqlClient v5.1.4)
- **Target Database**: PostgreSQL (Npgsql v8.0.3)
- **Source File**: DataAccess/ProductRepository.cs

## SQL Statement Processing

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool failure | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Failure Details
All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed due to infrastructure issues:
- **Error Type 1**: "Metadata model creation did not complete after 15 attempts" (5 statements)
- **Error Type 2**: "DMS Schema Conversion can't access the S3 resource 'atx-db-modernization-789616364195-us-east-1'" (2 statements)

## SQL Equivalency Tool Failure Details
All 7 statement pairs were submitted to the SQL Equivalency validation tool. All returned ERROR:
- **Error**: "'uniqueID'" - systemic infrastructure error affecting all validations

## Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied with the following rules:
- All schema object names (tables, columns, aliases) converted to lowercase
- `SCOPE_IDENTITY()` replaced with `RETURNING ... INTO` clause
- `GETDATE()` replaced with `NOW()`
- `BEGIN TRANSACTION / COMMIT` blocks restructured as `DO $$ ... END $$;` PL/pgSQL blocks
- `DECLARE @var` T-SQL variables converted to PL/pgSQL `DECLARE v_var` syntax
- `SELECT @var = col` assignment syntax converted to `SELECT col INTO v_var`
- Integer division in `ROUND()` addressed with `::numeric` cast where needed

## Static Code Changes

### Package References (AdoCore.csproj)
- **Removed**: `Microsoft.Data.SqlClient` v5.1.4
- **Added**: `Npgsql` v8.0.3

### Import Changes (ProductRepository.cs)
- **Removed**: `using Microsoft.Data.SqlClient;`
- **Added**: `using Npgsql;`

### Class Replacements (ProductRepository.cs)
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

### Connection String Changes (appsettings.json)
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=productmanagement;Username=postgres;Password=postgres`

### Column Name References (MapProductFromReader)
- All reader column indexers updated to lowercase to match PostgreSQL schema conventions

## Statements Requiring Manual Review
All 7 statements require manual review due to:
1. DMS tool infrastructure failure preventing automated conversion validation
2. SQL Equivalency tool infrastructure failure preventing automated equivalency validation

## Artifacts Generated
- `extracted_statements.sql` - Complete catalog of original MS SQL statements
- `converted_statements.sql` - Complete catalog of converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
- `migration_report.md` - This report
