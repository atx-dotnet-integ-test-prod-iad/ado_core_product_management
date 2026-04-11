# Migration Report: SQL Server to PostgreSQL

## Project: AdoCore - Product Management System
**Date:** 2026-04-11  
**Migration Type:** Microsoft SQL Server → PostgreSQL  
**Framework:** .NET 9.0 ADO.NET  

---

## Executive Summary

This report documents the migration of the AdoCore .NET ADO.NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting 7 SQL statements, updating package dependencies, replacing ADO.NET class references, updating connection strings, and converting SQL setup scripts.

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention (DMS failure) | 7 |
| Statements validated as EQUIVALENT (SQL Equivalency tool) | 0 |
| Statements validated as NOT_EQUIVALENT | 0 |
| Statements with equivalency validation ERROR | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`). All failed with the same error:
- **Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Fallback:** Manual conversion with lowercase schema object names (`DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`)

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR:
- **Error:** `'uniqueID'`
- **Note:** This is a tool-side error, not a statement equivalency issue

---

## Statement Details

### Statement 1: GetAllProductsAsync
- **Method:** `ProductRepository.GetAllProductsAsync()`
- **Type:** CTE with AVG/COUNT window functions, CASE, ROUND, ORDER BY with CASE
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, CTE alias changed to avoid conflict with table name
- **Equivalency Status:** ERROR (tool error)

### Statement 2: GetProductByIdAsync
- **Method:** `ProductRepository.GetProductByIdAsync(int)`
- **Type:** CTE with LAG window function, parameterized query
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, CTE alias changed
- **Equivalency Status:** ERROR (tool error)

### Statement 3: InsertProductAsync
- **Method:** `ProductRepository.InsertProductAsync(Product)`
- **Type:** Transaction block with DECLARE, SCOPE_IDENTITY(), GETDATE(), INSERT/UPDATE
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** 
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - Transaction block restructured to use app-level Npgsql transactions with separate commands
  - Table/column names lowercased
- **Equivalency Status:** ERROR (tool error)

### Statement 4: UpdateProductAsync
- **Method:** `ProductRepository.UpdateProductAsync(Product)`
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `DECLARE @var` → Separate SELECT query to get old values
  - `GETDATE()` → `NOW()`
  - Transaction block restructured to use app-level Npgsql transactions
  - Table/column names lowercased
- **Equivalency Status:** ERROR (tool error)

### Statement 5: DeleteProductAsync
- **Method:** `ProductRepository.DeleteProductAsync(int)`
- **Type:** Transaction block with DECLARE, SELECT INTO, INSERT, DELETE, UPDATE with CASE
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `DECLARE @var` → Separate SELECT query to get old values
  - `GETDATE()` → `NOW()`
  - Transaction block restructured to use app-level Npgsql transactions
  - CASE expression compatible between SQL Server and PostgreSQL
  - Table/column names lowercased
- **Equivalency Status:** ERROR (tool error)

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** `ProductRepository.GetProductsByPriceRangeAsync(decimal, decimal)`
- **Type:** CTE with RANK, PERCENT_RANK, BETWEEN, CASE
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, CTE name lowercased
- **Equivalency Status:** ERROR (tool error)

### Statement 7: GetLowStockProductsAsync
- **Method:** `ProductRepository.GetLowStockProductsAsync(int)`
- **Type:** CTE with AVG/MIN/MAX window functions, ROUND, CASE
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - Table/column names lowercased
  - Added explicit `CAST(stockquantity AS DECIMAL)` for integer division
  - CTE name lowercased
- **Equivalency Status:** ERROR (tool error)

---

## Files Modified During Migration

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements replaced with PostgreSQL equivalents; all SqlClient classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings updated to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |

---

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |
| `Microsoft.Extensions.Configuration 8.0.0` | `Microsoft.Extensions.Configuration 8.0.0` (unchanged) |
| `Microsoft.Extensions.Configuration.Json 8.0.0` | `Microsoft.Extensions.Configuration.Json 8.0.0` (unchanged) |
| `Microsoft.Extensions.DependencyInjection 8.0.0` | `Microsoft.Extensions.DependencyInjection 8.0.0` (unchanged) |

**Note:** Npgsql version 8.0.6 was used instead of 8.0.0 to address a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

---

## ADO.NET Class Replacements

| SQL Server (Microsoft.Data.SqlClient) | PostgreSQL (Npgsql) |
|---------------------------------------|---------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

---

## SQL Setup Script Conversions

### Scripts/01_InitialSetup.sql (Simple)
| SQL Server Feature | PostgreSQL Equivalent |
|-------------------|----------------------|
| `IDENTITY(1,1)` | `SERIAL` |
| `GETDATE()` | `NOW()` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `IF NOT EXISTS (...)` | `CREATE TABLE IF NOT EXISTS` / `DO $$ ... $$` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SET NOCOUNT ON` | Removed (not applicable) |
| `GO` | Removed (not needed) |

### Database/Scripts/01_InitialSetup.sql (Complex)
| SQL Server Feature | PostgreSQL Equivalent |
|-------------------|----------------------|
| `[dbo].[TableName]` | `tablename` (lowercase, no schema prefix) |
| `IDENTITY(1,1)` | `SERIAL` |
| `BIT` | `BOOLEAN` |
| `GETDATE()` | `NOW()` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `SYSTEM_USER` | `current_user` |
| SQL Server trigger syntax | PostgreSQL trigger function + trigger |
| `IF EXISTS (SELECT * FROM sys.objects ...)` | `DROP ... IF EXISTS` |
| `GO` batch separator | Removed |

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | All 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Complete equivalency validation results |
| `dms_failure_log.txt` | `sourceCode/` | DMS tool failure documentation |
| `migration_report.md` | `sourceCode/` | This report |

---

## Build Status

- **Final Build:** ✅ SUCCESS (0 errors, 10 warnings)
- **Warnings:** All pre-existing nullable reference warnings, not migration-related
- **Vulnerable Packages:** None (Npgsql 8.0.6 is clean)

---

## Known Limitations and Recommendations

1. **DMS Tool Unavailability:** All SQL statements failed DMS conversion due to metadata model creation issues. Manual conversion was performed with lowercase schema object names per the fallback rules.

2. **SQL Equivalency Validation:** All statement pair validations returned ERROR from the equivalency tool. Manual review of the converted statements is recommended.

3. **Transaction Restructuring:** The Insert, Update, and Delete methods were restructured from single SQL Server multi-statement blocks to multiple Npgsql commands within application-managed transactions. This maintains the same transactional guarantees while being compatible with Npgsql's parameterized query handling.

4. **Connection Strings:** Development/Production connection strings use placeholder credentials (`postgres/postgres`). For production deployment, these should be configured through environment variables or a secure configuration provider.

5. **Integer Division:** PostgreSQL performs integer division differently than SQL Server. An explicit `CAST(... AS DECIMAL)` was added in the `GetLowStockProductsAsync` query to ensure correct decimal division behavior.
