# Migration Report: SQL Server to PostgreSQL

## Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 22 |
| Statements from application code (ProductRepository.cs) | 7 |
| Statements from database setup scripts | 15 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 22 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 22 |

## DMS MCP Tool Status

The DMS MCP tool (`dms-mcp___statement_conversion_tool`) was attempted for every SQL statement but consistently failed with the following error across all attempts:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Attempts made**: 7+ individual calls with varying parameters (different poll intervals, max attempts, statement complexity levels). All returned the same error.

**Resolution**: As per transformation definition guidelines, manual conversion was applied with lowercase schema object names (`DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

## SQL Equivalency Tool Status

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) was called for every statement pair but consistently returned ERROR with:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a tool-side infrastructure issue, not related to the SQL statement content. All 22 statement pairs are marked as ERROR in the equivalency report per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR."

## Files Modified

### Application Code
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statements with PostgreSQL equivalents, replaced `using Microsoft.Data.SqlClient` with `using Npgsql`, replaced `SqlConnection` → `NpgsqlConnection`, `SqlCommand` → `NpgsqlCommand`, `SqlDataReader` → `NpgsqlDataReader` |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

### Database Scripts
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL syntax (full version with all tables, triggers, functions) |

### Documentation
| File | Changes |
|------|---------|
| `README.md` | Updated all references from SQL Server to PostgreSQL |

### Migration Artifacts
| File | Description |
|------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements from application code |
| `converted_statements.sql` | All 7 converted PostgreSQL statements for application code |
| `sql_equivalency_validation_report.json` | Comprehensive validation report for all 22 statement pairs |

## Key Conversions Applied

### SQL Syntax Conversions
| SQL Server | PostgreSQL | Context |
|-----------|------------|---------|
| `SCOPE_IDENTITY()` | `lastval()` | InsertProductAsync |
| `GETDATE()` | `NOW()` | All timestamps |
| `DECLARE @var TYPE; SET @var = ...` | Subqueries / temp patterns | UpdateProductAsync, DeleteProductAsync |
| `BEGIN TRANSACTION / COMMIT` | Removed from inline SQL (handled by ADO.NET) | Transaction blocks |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` | CREATE TABLE DDL |
| `[nvarchar](n)` | `VARCHAR(n)` | All string columns |
| `[datetime]` | `TIMESTAMP` | All date columns |
| `[bit]` | `BOOLEAN` | Boolean columns |
| `DEFAULT 1/0` (bit) | `DEFAULT TRUE/FALSE` | Boolean defaults |
| `[dbo].[tablename]` | `tablename` (lowercase) | All schema references |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | Stored procedures |
| `SYSTEM_USER` | `CURRENT_USER` | Trigger audit column |
| `GO` | Removed | Batch separator |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP TABLE IF EXISTS` / `CREATE TABLE IF NOT EXISTS` | DDL conditionals |
| SQL Server trigger syntax (`inserted`/`deleted`) | PostgreSQL trigger function with `NEW`/`OLD` | Trigger conversion |

### ADO.NET Class Replacements
| SQL Server | PostgreSQL (Npgsql) |
|-----------|-------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### Connection String Conversion
| SQL Server | PostgreSQL |
|-----------|------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |

## Build Status

**Final build: ✅ SUCCESS** - 0 errors, 10 warnings (pre-existing nullable reference warnings)

## Detailed Statement Listing

### Application Code Statements (1-7)

| # | Method | Key Conversions | DMS Status | Equivalency |
|---|--------|----------------|------------|-------------|
| 1 | GetAllProductsAsync | Schema lowercase, CTE preserved | FAILED | ERROR |
| 2 | GetProductByIdAsync | Schema lowercase, LAG window func preserved | FAILED | ERROR |
| 3 | InsertProductAsync | SCOPE_IDENTITY→lastval, GETDATE→NOW, removed DECLARE/transaction | FAILED | ERROR |
| 4 | UpdateProductAsync | Restructured with subqueries, GETDATE→NOW | FAILED | ERROR |
| 5 | DeleteProductAsync | Restructured with subqueries, GETDATE→NOW | FAILED | ERROR |
| 6 | GetProductsByPriceRangeAsync | Schema lowercase, RANK/PERCENT_RANK preserved | FAILED | ERROR |
| 7 | GetLowStockProductsAsync | Schema lowercase, added CAST for integer division | FAILED | ERROR |

### Database Script Statements (8-22)

| # | Object | Key Conversions | DMS Status | Equivalency |
|---|--------|----------------|------------|-------------|
| 8 | CREATE TABLE categories | IDENTITY→GENERATED ALWAYS, nvarchar→varchar, datetime→timestamp | FAILED | ERROR |
| 9 | CREATE TABLE suppliers | bit→boolean, DEFAULT 1→DEFAULT TRUE | FAILED | ERROR |
| 10 | CREATE TABLE products (full) | All type mappings, FK constraints preserved | FAILED | ERROR |
| 11 | CREATE TABLE producthistory | IDENTITY→GENERATED ALWAYS, type mappings | FAILED | ERROR |
| 12 | CREATE TABLE productstats | Type mappings, GETDATE→NOW | FAILED | ERROR |
| 13 | INSERT categories | Schema lowercase | FAILED | ERROR |
| 14 | INSERT suppliers | Schema lowercase | FAILED | ERROR |
| 15 | INSERT products | Schema lowercase | FAILED | ERROR |
| 16 | UPDATE productstats | IsDiscontinued=1→isdiscontinued=TRUE, GETDATE→NOW | FAILED | ERROR |
| 17 | CREATE TRIGGER | SQL Server→PostgreSQL trigger function pattern | FAILED | ERROR |
| 18 | sp_GetAllProducts | PROCEDURE→FUNCTION, RETURNS TABLE | FAILED | ERROR |
| 19 | sp_GetProductById | PROCEDURE→FUNCTION with parameter | FAILED | ERROR |
| 20 | sp_InsertProduct | SCOPE_IDENTITY→RETURNING, PROCEDURE→FUNCTION | FAILED | ERROR |
| 21 | sp_UpdateProduct | PROCEDURE→FUNCTION, GETDATE→NOW | FAILED | ERROR |
| 22 | sp_DeleteProduct | PROCEDURE→FUNCTION | FAILED | ERROR |

## Notes

1. All DMS failures are due to a service-side issue ("Unknown metadata model creation status: RECEIVED"), not statement-level incompatibility.
2. All SQL Equivalency errors are due to a service-side issue ("'uniqueID'"), not statement-level differences.
3. Window functions (LAG, RANK, PERCENT_RANK, AVG OVER, COUNT OVER) are compatible between SQL Server and PostgreSQL and were preserved with lowercase schema object names.
4. The Npgsql library supports `@ParamName` parameter syntax, so no parameter syntax changes were needed in the application code.
5. Transaction handling in `ExecuteInTransactionAsync` uses the standard `DbTransaction` interface, which Npgsql implements fully.
