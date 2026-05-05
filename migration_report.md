# Migration Report: MS SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS | 0 |
| Requiring Manual Intervention | 7 |
| Validated as Equivalent | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |
| Migration Date | 2026-05-05 |
| Source Database | Microsoft SQL Server |
| Target Database | PostgreSQL |
| Source Package | Microsoft.Data.SqlClient 5.1.4 |
| Target Package | Npgsql 8.0.0 |

## DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was used for all 7 SQL statements but consistently failed with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

All statements were manually converted applying lowercase schema object names per the transformation rules (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Validation Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was used for all 7 statement pairs but consistently returned:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a tool infrastructure issue. All pairs are marked as ERROR per the transformation rules (agent judgment was not used).

## File-by-File Breakdown of Changes

### sourceCode/DataAccess/ProductRepository.cs
- **7 SQL statements** converted from MS SQL to PostgreSQL syntax
- **Import**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **Types**: SqlConnection → NpgsqlConnection, SqlCommand → NpgsqlCommand, SqlDataReader → NpgsqlDataReader, SqlTransaction → NpgsqlTransaction
- **Transaction handling**: Restructured to use C# managed transactions for INSERT/UPDATE/DELETE operations (replacing SQL-level DECLARE/SET patterns)
- **SQL Conversions**:
  - GETDATE() → NOW()
  - SCOPE_IDENTITY() → INSERT...RETURNING
  - DECLARE @var / SET @var → C# variables with separate SELECT queries
  - All table/column names → lowercase
  - Integer division → ::numeric cast where needed

### sourceCode/AdoCore.csproj
- Replaced `Microsoft.Data.SqlClient` v5.1.4 with `Npgsql` v8.0.0

### sourceCode/appsettings.json
- Connection strings updated from SQL Server format to PostgreSQL format
- Removed: Server=, Trusted_Connection, MultipleActiveResultSets, TrustServerCertificate
- Added: Host=, Username=, Password=

### sourceCode/Scripts/01_InitialSetup.sql
- Complete rewrite from T-SQL to PostgreSQL syntax
- Stored procedures → PostgreSQL functions (plpgsql)

### sourceCode/Database/Scripts/01_InitialSetup.sql
- Complete rewrite from T-SQL to PostgreSQL syntax
- All tables, indexes, triggers, functions, and sample data converted
- IDENTITY → GENERATED ALWAYS AS IDENTITY
- nvarchar → varchar
- datetime → timestamp
- bit → boolean
- Triggers → PostgreSQL trigger functions
- GO statements removed

## Detailed Statement Conversion Table

| # | Method | MS SQL Features | PostgreSQL Conversion | DMS Status | Equivalency |
|---|--------|----------------|----------------------|-----------|-------------|
| 1 | GetAllProductsAsync | CTE, AVG/COUNT OVER, CASE, ROUND, ORDER BY CASE | Lowercase schema, same window function syntax | FAILED | ERROR |
| 2 | GetProductByIdAsync | CTE, LAG OVER, LEFT JOIN, CASE, ROUND | Lowercase schema, same window function syntax | FAILED | ERROR |
| 3 | InsertProductAsync | DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE, transaction | INSERT RETURNING, NOW(), C# managed transaction | FAILED | ERROR |
| 4 | UpdateProductAsync | DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE(), transaction | Separate SELECT + UPDATE, NOW(), C# managed transaction | FAILED | ERROR |
| 5 | DeleteProductAsync | DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE, CASE, GETDATE() | Separate SELECT + DELETE, CASE, NOW(), C# managed transaction | FAILED | ERROR |
| 6 | GetProductsByPriceRangeAsync | CTE, RANK, PERCENT_RANK, BETWEEN, CASE | Lowercase schema, same window function syntax | FAILED | ERROR |
| 7 | GetLowStockProductsAsync | CTE, AVG/MIN/MAX OVER, CASE, ROUND | Lowercase schema, ::numeric cast for division | FAILED | ERROR |

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS conversion failed for all statements (infrastructure issue)
2. SQL Equivalency validation returned ERROR for all pairs (infrastructure issue)
3. Manual conversions applied lowercase schema naming convention

### Recommended Review Actions:
- Verify PostgreSQL SQL syntax correctness against a live PostgreSQL database
- Validate that window functions (AVG OVER, LAG, RANK, PERCENT_RANK) produce same results
- Test transaction handling (INSERT RETURNING + C# managed transactions) works correctly
- Confirm ROUND() and division behavior matches expectations with PostgreSQL numeric types

## Build Status

**Final Build: SUCCESS** (0 errors, warnings only for nullable reference types which were pre-existing)

## Artifacts Generated

| Artifact | Path | Description |
|----------|------|-------------|
| Extracted Statements | sourceCode/extracted_statements.sql | All 7 original MS SQL statements |
| Converted Statements | sourceCode/converted_statements.sql | All 7 PostgreSQL converted statements |
| Equivalency Report | sourceCode/sql_equivalency_validation_report.json | Full validation report with tool outputs |
| DMS Summary | sourceCode/dms_conversion_summary.md | DMS failure documentation |
| Migration Report | sourceCode/migration_report.md | This file |
