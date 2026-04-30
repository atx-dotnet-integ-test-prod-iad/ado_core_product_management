# Migration Report: SQL Server to PostgreSQL

## Overview
Migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-30  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  
**Framework:** .NET 9.0 with ADO.NET  

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed (inline code) | 7 |
| Total SQL statements processed (scripts) | 11 |
| **Total SQL statements processed** | **18** |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 18 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 18 |

---

## DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for **every** SQL statement but consistently failed with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

All 18 statements were therefore manually converted following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol, which requires:
- Converting all schema object names (tables, columns, views, procedures) to lowercase
- Applying PostgreSQL-compatible syntax transformations

---

## SQL Equivalency Validation Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was attempted for **every** statement pair but consistently returned ERROR status:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

**Note:** All equivalency statuses in the report are recorded as ERROR based exclusively on the tool's output. No agent judgment was used.

---

## Files Modified

### Source Code Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statements with PostgreSQL equivalents; replaced SqlConnection/SqlCommand/SqlDataReader/SqlParameter with NpgsqlConnection/NpgsqlCommand/NpgsqlDataReader/NpgsqlParameter; restructured transaction methods; updated using directive |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |

### Database Script Files
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL: IDENTITY→SERIAL, GETDATE()→NOW(), nvarchar→varchar, stored procedures→functions, removed GO separators, IF NOT EXISTS→PostgreSQL equivalents |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion: IDENTITY→SERIAL, GETDATE()→NOW(), nvarchar→varchar, bit→boolean, stored procedures→functions, trigger→PostgreSQL trigger function, SYSTEM_USER→CURRENT_USER, [dbo].→removed, removed GO separators |

### Artifact Files Created
| File | Description |
|------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements from ProductRepository.cs |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive JSON report with all 18 statement pairs |
| `migration_report.md` | This report |

---

## Detailed Conversion Changes

### SQL Syntax Conversions
| SQL Server | PostgreSQL | Occurrences |
|-----------|-----------|-------------|
| `IDENTITY(1,1)` | `SERIAL` | 8 |
| `GETDATE()` | `NOW()` | 15+ |
| `nvarchar(n)` | `varchar(n)` | 20+ |
| `datetime` | `timestamp` | 15+ |
| `bit` | `boolean` | 2 |
| `SCOPE_IDENTITY()` | `RETURNING productid` | 2 |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | 5 |
| `SET NOCOUNT ON` | Removed (not needed in PostgreSQL) | 5 |
| `GO` batch separator | Removed | 20+ |
| `[dbo].[tablename]` | `tablename` (lowercase) | 20+ |
| `BEGIN TRANSACTION/COMMIT` | C# NpgsqlTransaction | 3 |
| `DECLARE @var` | C# variables or PL/pgSQL DECLARE | 5 |
| `SYSTEM_USER` | `CURRENT_USER` | 3 |
| `EXEC stored_proc` | `SELECT function()` | 3 |
| Integer division | `::numeric` cast | 1 |
| `DEFAULT 1` (bit) | `DEFAULT true` (boolean) | 2 |
| `DEFAULT 0` (bit) | `DEFAULT false` (boolean) | 1 |

### ADO.NET Class Replacements
| SQL Server (Microsoft.Data.SqlClient) | PostgreSQL (Npgsql) |
|---------------------------------------|---------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Connection String Transformation
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| SSL | `TrustServerCertificate=True` | Removed (not applicable) |

---

## Transaction Method Restructuring

The three transaction-based methods (InsertProductAsync, UpdateProductAsync, DeleteProductAsync) required significant restructuring:

**Original approach (SQL Server):** Single SQL string with `DECLARE @var`, `BEGIN TRANSACTION/COMMIT`, `SCOPE_IDENTITY()`

**New approach (PostgreSQL):** Multiple separate SQL commands within a C# `NpgsqlTransaction`:
1. Use `INSERT...RETURNING` instead of `SCOPE_IDENTITY()`
2. Use C# variables instead of T-SQL `DECLARE @var`
3. Manage transactions via `connection.BeginTransactionAsync()`, `CommitAsync()`, `RollbackAsync()`
4. Each command explicitly includes the transaction via `NpgsqlCommand(sql, connection, transaction)`

---

## Build Status

| Step | Build Status |
|------|-------------|
| Step 1: Extract & Convert SQL | ✅ Success |
| Step 2: Re-integrate SQL & Replace ADO.NET | ❌ Failed (expected - Npgsql not yet in .csproj) |
| Step 3: Update Dependencies & Connection Strings | ✅ Success |
| Step 4: Convert Scripts & Final Report | ✅ Success |

**Final Build:** ✅ Success (0 errors, 10 nullable reference warnings - pre-existing)

---

## Items Requiring Manual Review

1. **SQL Equivalency Validation:** All 18 statement pairs returned ERROR from the equivalency tool - manual review of SQL equivalency is recommended
2. **DMS Conversion:** All statements required manual conversion due to DMS failure - review lowercase schema mapping correctness
3. **Connection String Credentials:** Placeholder credentials (postgres/postgres) used - update for production
4. **Transaction Restructuring:** Insert/Update/Delete methods were restructured from single SQL to multiple commands - verify atomicity under concurrent load
5. **Trigger Conversion:** The `trg_Products_History` trigger was converted to PostgreSQL trigger function pattern - verify behavior matches original
6. **Integer Division:** The `StockPercentageOfAverage` calculation uses `::numeric` cast - verify precision

---

## Conclusion

The migration from SQL Server to PostgreSQL has been completed successfully. The application compiles without errors with the Npgsql package. All SQL statements have been converted to PostgreSQL-compatible syntax with lowercase schema object names. Both DMS conversion and SQL equivalency validation tools experienced consistent errors, so all conversions were performed manually following the documented lowercase schema mapping rules. Manual review of converted SQL statements is recommended to confirm functional equivalence.
