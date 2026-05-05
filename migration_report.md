# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed (inline code) | 7 |
| Total SQL statements processed (scripts) | 6 |
| **Total SQL statements processed** | **13** |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 13 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 13 |

## DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was invoked for all 13 SQL statements. All invocations returned the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN:** `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

Due to the systemic DMS failure, all statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach as specified in the transformation definition.

## SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was invoked for all 13 statement pairs. All invocations returned:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR." All statements are marked as ERROR in the equivalency report.

## Code Changes Made

### 1. ProductRepository.cs (DataAccess/ProductRepository.cs)
- Replaced `using Microsoft.Data.SqlClient` → `using Npgsql`
- Replaced `SqlConnection` → `NpgsqlConnection`
- Replaced `SqlCommand` → `NpgsqlCommand`
- Replaced `SqlDataReader` → `NpgsqlDataReader`
- Converted all 7 SQL statements to PostgreSQL syntax with lowercase identifiers
- Restructured transaction blocks (INSERT/UPDATE/DELETE) to use C#-managed `NpgsqlTransaction`
- Replaced `SCOPE_IDENTITY()` with `RETURNING productid`
- Replaced `GETDATE()` with `NOW()`
- Replaced `DECLARE @var` patterns with separate SELECT INTO queries

### 2. AdoCore.csproj
- Removed: `Microsoft.Data.SqlClient` version 5.1.4
- Added: `Npgsql` version 8.0.6

### 3. appsettings.json
- Updated connection strings from SQL Server format to PostgreSQL format
- `Server=localhost` → `Host=localhost`
- `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Username=postgres;Password=postgres`

### 4. Scripts/01_InitialSetup.sql
- Converted all SQL Server DDL/DML to PostgreSQL syntax
- `IDENTITY(1,1)` → `SERIAL`
- `NVARCHAR` → `VARCHAR`
- `DATETIME` → `TIMESTAMP`
- `GETDATE()` → `NOW()`
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
- Removed `GO` separators
- `IF NOT EXISTS (SELECT * FROM sys.objects ...)` → `CREATE TABLE IF NOT EXISTS`
- `EXEC sp_InsertProduct ...` → Direct INSERT statements

### 5. Database/Scripts/01_InitialSetup.sql
- Full conversion of complex script including:
  - DROP/CREATE table patterns → PostgreSQL equivalents
  - `[bit]` → `BOOLEAN`
  - Trigger syntax converted to PostgreSQL trigger function pattern
  - `SYSTEM_USER` → `current_user`
  - All stored procedures → PostgreSQL functions (plpgsql)
  - Index creation (same syntax, lowercase names)
  - Sample data insertion (same logic)

## Conversion Rules Applied (Manual - DMS Failure)

1. **Schema object names**: All converted to lowercase for PostgreSQL compatibility
2. **Data types**: NVARCHAR→VARCHAR, DATETIME→TIMESTAMP, BIT→BOOLEAN, IDENTITY→SERIAL
3. **Functions**: GETDATE()→NOW(), SCOPE_IDENTITY()→RETURNING clause, SYSTEM_USER→current_user
4. **Procedures**: CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION (plpgsql)
5. **Triggers**: SQL Server trigger syntax → PostgreSQL trigger function + CREATE TRIGGER
6. **Transaction handling**: Inline DECLARE/TRANSACTION → C# NpgsqlTransaction with multiple commands
7. **Conditional DDL**: IF NOT EXISTS (sys.objects) → CREATE TABLE IF NOT EXISTS / DROP IF EXISTS

## Build Status

**Final build: SUCCESS** (0 errors, 10 warnings - all pre-existing nullability warnings)

## Artifacts

| Artifact | Location |
|----------|----------|
| Extracted SQL statements | `sourceCode/extracted_statements.sql` |
| Converted SQL statements | `sourceCode/converted_statements.sql` |
| Equivalency validation report | `sourceCode/sql_equivalency_validation_report.json` |
| Migration report | `sourceCode/migration_report.md` |

## Statements Requiring Manual Review

All 13 statements should be manually reviewed as:
1. DMS tool was unavailable (systemic failure) - manual conversion may miss edge cases
2. SQL Equivalency tool returned errors for all pairs - equivalency could not be automatically verified
3. Transaction semantics in PostgreSQL differ from SQL Server - the C# code restructuring for INSERT/UPDATE/DELETE should be validated with integration tests
