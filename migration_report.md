# Migration Report: MS SQL Server to PostgreSQL

## Overview
This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-02-20  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  
**Application Framework:** .NET 9.0, ADO.NET  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS failure | 7 |
| Statements validated as equivalent (by SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent (by SQL Equivalency tool) | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`).  
**All 7 failed** with the error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`  
DMS ARN: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

Manual conversion was performed for all 7 statements following DMS failure.

### SQL Equivalency Tool Status
All 7 statement pairs (original MS SQL + converted PostgreSQL) were submitted to the SQL Equivalency validation tool (`sql-equivalency___validate_sql_equivalence`).  
**All 7 returned ERROR** with: `{"equivalence_status": "ERROR", "error": "'uniqueID'"}`  
This was a persistent infrastructure error affecting all validation attempts.

---

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Source:** `DataAccess/ProductRepository.cs`
- **Type:** SELECT with CTE, window functions (AVG, COUNT OVER), CASE, ROUND, ORDER BY CASE
- **Conversion:** No SQL changes needed (PostgreSQL-compatible as-is)
- **DMS Status:** Failed - Metadata model creation error
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 2: GetProductByIdAsync
- **Source:** `DataAccess/ProductRepository.cs`
- **Type:** SELECT with CTE, LAG window function, CASE, ROUND, parameterized
- **Conversion:** No SQL changes needed (PostgreSQL-compatible as-is)
- **DMS Status:** Failed - Metadata model creation error
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 3: InsertProductAsync
- **Source:** `DataAccess/ProductRepository.cs`
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion:** Major restructuring
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING` via writable CTE
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId` → removed (CTE chain handles data flow)
  - `BEGIN TRANSACTION/COMMIT` → removed (application-level transaction via NpgsqlTransaction)
- **DMS Status:** Failed - Metadata model creation error
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 4: UpdateProductAsync
- **Source:** `DataAccess/ProductRepository.cs`
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, GETDATE()
- **Conversion:** Major restructuring
  - `DECLARE @OldPrice/@OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → removed (application-level transaction)
  - Writable CTEs used to chain UPDATE, INSERT history, UPDATE stats
- **DMS Status:** Failed - Metadata model creation error
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 5: DeleteProductAsync
- **Source:** `DataAccess/ProductRepository.cs`
- **Type:** Transaction block with DECLARE, DELETE, UPDATE with CASE, GETDATE()
- **Conversion:** Major restructuring
  - `DECLARE @OldPrice/@OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → removed (application-level transaction)
  - Writable CTEs used to chain INSERT history, DELETE, UPDATE stats
  - `CASE` expression preserved as-is
- **DMS Status:** Failed - Metadata model creation error
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 6: GetProductsByPriceRangeAsync
- **Source:** `DataAccess/ProductRepository.cs`
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK() window functions, CASE
- **Conversion:** No SQL changes needed (PostgreSQL-compatible as-is)
- **DMS Status:** Failed - Metadata model creation error
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 7: GetLowStockProductsAsync
- **Source:** `DataAccess/ProductRepository.cs`
- **Type:** SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion:** Minor change
  - Added `CAST(StockQuantity AS decimal)` for integer division in ROUND
- **DMS Status:** Failed - Metadata model creation error
- **Equivalency Status:** ERROR (tool infrastructure error)

---

## Files Modified During Migration

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, ADO.NET classes replaced with Npgsql |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient to Npgsql |
| `appsettings.json` | Connection strings updated to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL/functions |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion to PostgreSQL DDL/triggers/functions |

---

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.1 |

No other package changes were required.

---

## ADO.NET Class Replacements

| MS SQL Server Class | Npgsql Equivalent |
|---------------------|-------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

`AddWithValue`, `ExecuteReaderAsync`, `ExecuteScalarAsync`, `ExecuteNonQueryAsync`, `BeginTransactionAsync`, `CommitAsync`, `RollbackAsync` are all compatible with Npgsql.

---

## Connection String Changes

| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|--------------------|--------------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | Removed (not applicable) |
| TrustServerCertificate | `True` | Removed (not applicable) |

---

## SQL Script File Changes

### Scripts/01_InitialSetup.sql
- `IDENTITY(1,1)` → `SERIAL`
- `datetime` → `timestamp`
- `GETDATE()` → `NOW()`
- `nvarchar` → `varchar`
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
- SQL Server `IF NOT EXISTS` patterns → PostgreSQL equivalents

### Database/Scripts/01_InitialSetup.sql
- All DDL converted to PostgreSQL syntax
- `bit` → `boolean`
- `IDENTITY(1,1)` → `SERIAL`
- SQL Server trigger syntax → PostgreSQL trigger function + trigger
- `SYSTEM_USER` → `current_user`
- Stored procedures → PostgreSQL functions
- `GO` statements removed
- `IF EXISTS (SELECT * FROM sys.objects...)` → `DROP TABLE IF EXISTS...CASCADE`

---

## Statements Requiring Manual Review

All 7 statements could not be validated via the SQL Equivalency tool due to persistent infrastructure errors. Manual review is recommended for:

1. **Statement 3 (InsertProductAsync):** Complex writable CTE chain replacing SCOPE_IDENTITY pattern
2. **Statement 4 (UpdateProductAsync):** Writable CTE chain replacing DECLARE variable pattern
3. **Statement 5 (DeleteProductAsync):** Writable CTE chain replacing DECLARE variable pattern with CASE

---

## Build Status

**Final build: ✅ SUCCESS**
- 0 Errors
- 12 Warnings (pre-existing nullable reference warnings)

---

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Project root | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency validation report |
| `migration_report.md` | Project root | This report |
