# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the migration of the ADO.NET Core application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-03-07  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**DMS Migration Project ARN:** `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements converted by DMS tool | 6 |
| Statements requiring manual intervention | 1 |
| Equivalency validations: EQUIVALENT | 0 |
| Equivalency validations: NOT_EQUIVALENT | 0 |
| Equivalency validations: ERROR | 7 |

### DMS Conversion Details

| # | Method | DMS Status | Conversion Method | Notes |
|---|--------|------------|-------------------|-------|
| 1 | GetAllProductsAsync | Success | DMS_TOOL | CTE with window functions converted successfully |
| 2 | GetProductByIdAsync | Success (retry) | DMS_TOOL | Initial transient error, succeeded on retry |
| 3 | InsertProductAsync | Failed | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | "Statement definition is not valid" - multi-statement transaction block |
| 4 | UpdateProductAsync | Success | DMS_TOOL | Warning 7807: BEGIN TRAN not supported in PG functions |
| 5 | DeleteProductAsync | Success | DMS_TOOL | Warning 7807: BEGIN TRAN not supported in PG functions |
| 6 | GetProductsByPriceRangeAsync | Success | DMS_TOOL | RANK/PERCENT_RANK converted successfully |
| 7 | GetLowStockProductsAsync | Success | DMS_TOOL | AVG/MIN/MAX window functions converted successfully |

### Key SQL Transformations Applied

- **Schema prefix:** `dbo.Products` → `productmanagement_dbo.products` (DMS-provided schema mapping)
- **All identifiers:** Converted to lowercase (DMS standard)
- **GETDATE()** → `clock_timestamp()`
- **SCOPE_IDENTITY()** → `RETURNING productid` clause
- **DECLARE @var** → PostgreSQL `DECLARE var_Name TYPE` (DMS) or CTE-based approach (re-integration)
- **BEGIN TRANSACTION/COMMIT** → Commented out by DMS (Warning 7807), handled via CTE-based atomic operations
- **LEFT JOIN** → `LEFT OUTER JOIN` (DMS standard)
- **ORDER BY** → Added `NULLS FIRST` (DMS standard for PostgreSQL compatibility)

### SQL Equivalency Validation

All 7 statement pairs were submitted to the SQL Equivalency validation tool (`sql-equivalency___validate_sql_equivalence`). The tool returned ERROR (`'uniqueID'`) for all 7 statements. This appears to be a systemic tool issue rather than an equivalency problem, as even trivial `SELECT 1` statements produced the same error.

**Per transformation rules:** All statuses are recorded as ERROR from the tool output. No agent judgment was used to determine equivalency.

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; All ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader) |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings converted to PostgreSQL format (Host, Username, Password) |
| `README.md` | Updated all references from SQL Server to PostgreSQL |

## Files Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Full equivalency validation report with all 7 statement pairs |
| `migration_report.md` | This report |

---

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.6 |

*Note: Npgsql 8.0.1 was initially selected but upgraded to 8.0.6 to resolve known vulnerability GHSA-x9vc-6hfv-hg8c.*

---

## Connection String Changes

**Before (SQL Server):**
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

**After (PostgreSQL):**
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres
```

---

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Class |
|-----------------|--------------------------|
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

---

## Build Status

**Final Build:** ✅ **SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference type warnings)

---

## Issues and Warnings

1. **DMS Statement 3 Failure:** The InsertProductAsync transaction block with DECLARE, SCOPE_IDENTITY(), and multi-table operations was rejected by DMS as "Statement definition is not valid." This was manually converted using lowercase schema naming convention consistent with DMS output patterns.

2. **DMS Warning 7807 (Statements 4, 5):** DMS flagged that PostgreSQL does not support explicit transaction management commands (BEGIN TRAN, SAVE TRAN) in functions. The DECLARE/BEGIN/END blocks from DMS were restructured to CTE-based atomic operations for Npgsql parameter compatibility.

3. **SQL Equivalency Tool Error:** All 7 equivalency validations returned ERROR with `'uniqueID'` - a systemic tool issue. This requires manual review of all statement pairs.

4. **Npgsql Security:** Initial Npgsql 8.0.1 had known vulnerability GHSA-x9vc-6hfv-hg8c. Upgraded to 8.0.6 which resolved the issue.

---

## Recommendations for Manual Review

1. Validate all 7 converted SQL statements against a live PostgreSQL database
2. Verify the `productmanagement_dbo` schema exists in the target PostgreSQL database
3. Review the CTE-based transaction replacements (statements 3, 4, 5) for correctness
4. Test all CRUD operations end-to-end
5. Verify connection pooling behavior with Npgsql
