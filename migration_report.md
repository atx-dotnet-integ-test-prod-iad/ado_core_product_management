# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-03-31  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## 1. SQL Statements Processed

### 1.1 Code-Level SQL Statements (ProductRepository.cs)

| # | Method | Statement Type | Conversion Method | Equivalency Status |
|---|--------|---------------|-------------------|-------------------|
| 1 | GetAllProductsAsync | CTE + Window Functions (AVG, COUNT OVER), INNER JOIN, CASE, ROUND | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 2 | GetProductByIdAsync | CTE + LAG Window Function, LEFT JOIN, CASE, ROUND | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 3 | InsertProductAsync | Transaction: INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 4 | UpdateProductAsync | Transaction: DECLARE, SELECT INTO, UPDATE, INSERT, GETDATE() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 5 | DeleteProductAsync | Transaction: DECLARE, SELECT INTO, INSERT, DELETE, UPDATE CASE, GETDATE() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 6 | GetProductsByPriceRangeAsync | CTE + RANK, PERCENT_RANK, BETWEEN, CASE | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 7 | GetLowStockProductsAsync | CTE + AVG, MIN, MAX Window Functions, CASE, ROUND | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |

### 1.2 Statistics

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed (code)** | 7 |
| **Successfully Converted by DMS** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Equivalency: EQUIVALENT** | 0 |
| **Equivalency: NOT_EQUIVALENT** | 0 |
| **Equivalency: ERROR** | 7 |

### 1.3 Script-Level Conversions

| Script File | Key Conversions Applied |
|-------------|----------------------|
| Scripts/01_InitialSetup.sql | GO removed, IDENTITY→SERIAL, nvarchar→varchar, datetime→timestamp, GETDATE()→CURRENT_TIMESTAMP, IF NOT EXISTS→CREATE TABLE IF NOT EXISTS, CREATE OR ALTER PROCEDURE→CREATE OR REPLACE FUNCTION, SCOPE_IDENTITY()→RETURNING |
| Database/Scripts/01_InitialSetup.sql | All above + Trigger syntax converted to PostgreSQL trigger function + trigger, IF EXISTS→DROP IF EXISTS, bit→boolean, bracket notation removed, SYSTEM_USER→current_user, sample data preserved |

---

## 2. DMS Tool Status

The DMS MCP statement conversion tool was attempted for all 7 SQL statements but consistently failed:

- **Error 1:** "Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts"
- **Error 2:** "Command execution timed out after 300 seconds" (with increased poll settings)
- **Error 3:** "Metadata model creation failed: Metadata model creation did not complete after 15 attempts" (even for simple SELECT)

**Resolution:** Manual conversion was applied per transformation definition rules, using lowercase schema object names for PostgreSQL compatibility (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

---

## 3. SQL Equivalency Tool Status

The SQL Equivalency MCP tool was used for all 7 statement pairs but returned consistent errors:

- **Error:** `{"equivalence_status": "ERROR", "error": "'uniqueID'"}`
- **Impact:** All 7 pairs marked as ERROR per transformation rules (no agent judgment used)
- **Note:** Even simplest queries returned the same error, indicating a tool-level issue

---

## 4. Key Conversion Rules Applied

### SQL Syntax Conversions
| MS SQL Server | PostgreSQL |
|---------------|-----------|
| `SCOPE_IDENTITY()` | `currval(pg_get_serial_sequence('table', 'column'))` |
| `GETDATE()` | `CURRENT_TIMESTAMP` |
| `BEGIN TRANSACTION / COMMIT` | `BEGIN / COMMIT` |
| `DECLARE @var TYPE; SET @var = ...` | Subquery approach or PostgreSQL variable syntax |
| `IDENTITY(1,1)` | `SERIAL` |
| `nvarchar(n)` | `varchar(n)` |
| `datetime` | `timestamp` |
| `bit` | `boolean` |
| `[dbo].[TableName]` | `tablename` (lowercase, no brackets) |
| `SYSTEM_USER` | `current_user` |
| `GO` batch separator | Removed (not needed in PostgreSQL) |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| SQL Server trigger syntax | PostgreSQL trigger function + trigger |

### ADO.NET Class Replacements
| MS SQL Server | PostgreSQL (Npgsql) |
|---------------|-------------------|
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Trust Cert | `TrustServerCertificate=True` | Removed (not applicable) |

---

## 5. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted, ADO.NET classes replaced |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings updated to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |

## 6. Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `dms_failure_summary.sql` | DMS failure documentation |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This report |

---

## 7. Build Status

**Build Result:** ✅ SUCCESS  
**Errors:** 0  
**Warnings:** 10 (pre-existing nullable reference warnings, no new warnings)  
**Vulnerability Warnings:** 0 (Npgsql upgraded from 8.0.0 to 8.0.6 to address GHSA-x9vc-6hfv-hg8c)

---

## 8. Issues and Warnings

### Known Issues
1. **DMS Tool Unavailable:** All conversions were done manually due to DMS metadata model creation/conversion timeouts.
2. **SQL Equivalency Tool Error:** All equivalency checks returned ERROR with "'uniqueID'" - tool-level issue, not related to statement quality.
3. **Transaction Restructuring:** Statements 3, 4, 5 (Insert/Update/Delete with transactions) required significant restructuring:
   - `DECLARE @var` / `SET @var` patterns replaced with subqueries
   - `SCOPE_IDENTITY()` replaced with `currval(pg_get_serial_sequence())`
   - These changes maintain functional equivalence but use different PostgreSQL idioms

### Recommendations for Manual Review
1. Verify all 7 SQL statements execute correctly against the target PostgreSQL database
2. Pay special attention to transaction blocks (statements 3, 4, 5) which required structural changes
3. Verify the `ROUND()` function behavior with decimal division matches expectations
4. Review the `stockquantity::numeric` cast in statement 7 for integer-to-numeric division

---

## 9. Transformation Artifacts

- **Original Statements:** `extracted_statements.sql`
- **Converted Statements:** `converted_statements.sql`
- **DMS Failure Log:** `dms_failure_summary.sql`
- **Equivalency Report:** `sql_equivalency_validation_report.json`
- **Migration Report:** `migration_report.md`
