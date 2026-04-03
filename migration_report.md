# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the complete migration of the ADO.NET Core application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-03  
**Application:** AdoCore - Product Management System  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  
**Framework:** .NET 9.0  

---

## SQL Statement Conversion Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool failure | 7 |
| Statements validated as equivalent by SQL Equivalency tool | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Issues

The DMS MCP tool (dms-mcp___statement_conversion_tool) consistently failed with metadata model creation/conversion timeouts across all attempts:

1. **Attempt 1:** Full SQL statement, 15 poll attempts @ 10s interval → "Metadata model conversion did not complete after 15 attempts"
2. **Attempt 2:** Full SQL statement (retry), 30 poll attempts @ 15s interval → Command execution timeout (300s)
3. **Attempt 3:** Simple SELECT query, 25 poll attempts @ 10s interval → "Metadata model creation did not complete after 25 attempts"
4. **Attempt 4:** SELECT SCOPE_IDENTITY(), 20 poll attempts @ 10s interval → "Metadata model creation did not complete after 20 attempts"

**Resolution:** All 7 statements were manually converted applying lowercase schema object naming convention, documented with reason `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

### SQL Equivalency Tool Issues

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) returned ERROR with `'uniqueID'` for all 7 statement pairs, including a trivial test query. This indicates a systemic tool-level issue rather than query-specific problems. All statements are marked as ERROR in the equivalency report.

---

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source:** CTE with AVG(Price) OVER(), COUNT(*) OVER(), ROUND, CASE, ORDER BY CASE
- **Conversion:** All identifiers to lowercase; SQL syntax compatible with PostgreSQL
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency:** ERROR (tool systemic error)

### Statement 2: GetProductByIdAsync
- **Source:** CTE with LAG() OVER (ORDER BY), ROUND, CASE with NULL handling
- **Conversion:** All identifiers to lowercase; window functions compatible
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency:** ERROR (tool systemic error)

### Statement 3: InsertProductAsync
- **Source:** DECLARE @variable, BEGIN TRANSACTION/COMMIT, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion:**
  - `DECLARE @NewProductId` + `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Eliminated DECLARE variable pattern
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency:** ERROR (tool systemic error)

### Statement 4: UpdateProductAsync
- **Source:** BEGIN TRANSACTION/COMMIT, DECLARE, SELECT INTO variables, UPDATE with GETDATE()
- **Conversion:**
  - Eliminated DECLARE variables; reordered to INSERT history BEFORE UPDATE
  - `GETDATE()` → `NOW()`
  - Statistics update uses `(SELECT AVG(price) FROM products)` instead of formula with variables
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency:** ERROR (tool systemic error)

### Statement 5: DeleteProductAsync
- **Source:** BEGIN TRANSACTION/COMMIT, DECLARE, SELECT INTO variables, DELETE, CASE/WHEN
- **Conversion:**
  - Eliminated DECLARE variables; reordered to INSERT history BEFORE DELETE
  - `GETDATE()` → `NOW()`
  - Statistics update uses `(SELECT COALESCE(AVG(price), 0) FROM products)` instead of formula with variables
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency:** ERROR (tool systemic error)

### Statement 6: GetProductsByPriceRangeAsync
- **Source:** CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE
- **Conversion:** All identifiers to lowercase; window functions and BETWEEN compatible
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency:** ERROR (tool systemic error)

### Statement 7: GetLowStockProductsAsync
- **Source:** CTE with AVG/MIN/MAX OVER(), ROUND, CASE
- **Conversion:** All identifiers to lowercase; added `::numeric` cast for integer division
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency:** ERROR (tool systemic error)

---

## Files Modified During Migration

| File | Change Description |
|------|-------------------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted; ADO.NET types migrated (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader); import changed to `using Npgsql;` |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL DDL conversion |
| `Scripts/01_InitialSetup.sql` | Simplified PostgreSQL DDL conversion |
| `README.md` | Documentation updated for PostgreSQL |

---

## Package Dependency Changes

| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |
| Microsoft.Extensions.Configuration 8.0.0 | Microsoft.Extensions.Configuration 8.0.0 (unchanged) |
| Microsoft.Extensions.Configuration.Json 8.0.0 | Microsoft.Extensions.Configuration.Json 8.0.0 (unchanged) |
| Microsoft.Extensions.DependencyInjection 8.0.0 | Microsoft.Extensions.DependencyInjection 8.0.0 (unchanged) |

**Note:** Npgsql 8.0.0 initially selected but had known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c). Upgraded to 8.0.6 which has no known vulnerabilities.

---

## Connection String Format Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed (not applicable) |

---

## ADO.NET Class Replacements

| SQL Server Type | PostgreSQL Type | Occurrences |
|----------------|-----------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 4 (field, method return, instantiation, getter) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per data access method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

---

## SQL Syntax Conversion Rules Applied

| SQL Server Syntax | PostgreSQL Syntax |
|-------------------|-------------------|
| `SCOPE_IDENTITY()` | `lastval()` |
| `GETDATE()` | `NOW()` |
| `BEGIN TRANSACTION` | `BEGIN` |
| `DECLARE @variable` | Eliminated (use subqueries/reordering) |
| `SELECT @var = col` | Eliminated (captured via SELECT...FROM subquery) |
| `IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `[dbo].[tablename]` | `tablename` (plain lowercase) |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql` |
| `SYSTEM_USER` | `current_user` |
| `Integer/Integer` | `column::numeric / column` (explicit cast) |

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Project root | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency report for all 7 pairs |
| `dms_conversion_summary.sql` | Project root | DMS tool failure documentation |
| `migration_report.md` | Project root | This report |

---

## Final Verification Checklist

- [x] No remaining references to `Microsoft.Data.SqlClient` in any source files
- [x] No remaining `SqlConnection`, `SqlCommand`, `SqlDataReader` types
- [x] All connection strings in PostgreSQL format
- [x] All SQL statements converted to PostgreSQL syntax
- [x] Build succeeds with zero errors (10 pre-existing warnings)
- [x] All 7 SQL statements processed through DMS MCP tool (failed, manually converted)
- [x] All 7 SQL statement pairs validated through SQL Equivalency tool (returned ERROR)
- [x] Comprehensive equivalency report generated
- [x] All transformation artifacts complete
- [x] No insecure dependencies (Npgsql 8.0.6, no vulnerabilities)
