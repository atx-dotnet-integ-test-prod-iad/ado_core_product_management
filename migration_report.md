# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-06 |
| **Source Database** | Microsoft SQL Server 2019 (ProductManagement) |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 ADO.NET |
| **Migration Tool** | AWS DMS MCP Statement Conversion Tool |
| **Final Build Status** | ✅ SUCCESS (0 errors) |

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS** | 6 |
| **Requiring Manual Intervention** | 1 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Conversion Details

| # | Statement | Method | DMS Status | Notes |
|---|-----------|--------|------------|-------|
| 1 | GetAllProductsAsync | SELECT with CTE, window functions | DMS_TOOL ✅ | Schema mapped: `[dbo].[Products]` → `productmanagement_dbo.products` |
| 2 | GetProductByIdAsync | SELECT with CTE, LAG function | DMS_TOOL ✅ | Parameterized @ProductId preserved |
| 3 | InsertProductAsync | Transaction block with INSERT, history, stats | DMS_FAILURE_MANUAL ❌ | DMS error: "Statement definition is not valid." - BEGIN/END block with SCOPE_IDENTITY not supported |
| 4 | UpdateProductAsync | Transaction block with UPDATE, history, stats | DMS_TOOL ✅ | GETDATE() → clock_timestamp(), DECLARE vars converted. DMS output adjusted for DO $$ wrapper and SELECT INTO syntax for PL/pgSQL compatibility |
| 5 | DeleteProductAsync | Transaction block with DELETE, history, stats | DMS_TOOL ✅ | Schema mapped, datetime functions converted. DMS output adjusted for DO $$ wrapper and SELECT INTO syntax for PL/pgSQL compatibility |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE, RANK, PERCENT_RANK | DMS_TOOL ✅ | ORDER BY with NULLS FIRST added |
| 7 | GetLowStockProductsAsync | SELECT with CTE, AVG/MIN/MAX | DMS_TOOL ✅ | ORDER BY with NULLS FIRST added |

### SQL Equivalency Validation Details

All 7 statement pairs were validated through the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status due to a service-side issue (error: `'uniqueID'`). Per transformation rules, all are marked as ERROR - no agent judgment was used.

---

## DMS Failure Details

### Statement 3: InsertProductAsync

**DMS Error:** `Metadata model creation failed: Statement definition is not valid.`

**Reason:** The DMS tool cannot process multi-statement transaction blocks containing `BEGIN...END` with `SCOPE_IDENTITY()`. This is a known limitation of the DMS statement conversion tool.

**Manual Conversion Applied:**
- `BEGIN...END` → `DO $$...END $$;` (PostgreSQL anonymous block)
- `SCOPE_IDENTITY()` → `lastval()` (PostgreSQL equivalent)
- `GETDATE()` → `clock_timestamp()` (PostgreSQL equivalent)
- `[dbo].[Products]` → `productmanagement_dbo.products` (lowercase schema mapping)
- `[dbo].[ProductHistory]` → `productmanagement_dbo.producthistory`
- `[dbo].[ProductStats]` → `productmanagement_dbo.productstats`
- All column names converted to lowercase

### Statements 4 & 5: UpdateProductAsync & DeleteProductAsync

**DMS Output Adjustments:** DMS successfully converted these statements but the output required minor adjustments for PL/pgSQL compatibility:
- Added `DO $$` wrapper for anonymous block execution via Npgsql client
- Changed `SELECT price AS var_OldPrice` to `SELECT price, stockquantity INTO var_OldPrice, var_OldStock` (PL/pgSQL variable assignment syntax)
- Changed `@OldPrice`/`@OldStock` references to `var_OldPrice`/`var_OldStock` in subsequent INSERT/UPDATE statements

---

## Schema Mapping Applied by DMS

| Source (MS SQL Server) | Target (PostgreSQL) |
|------------------------|---------------------|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |
| `ProductId` | `productid` |
| `Name` | `name` |
| `Description` | `description` |
| `Price` | `price` |
| `StockQuantity` | `stockquantity` |
| `CreatedDate` | `createddate` |
| `ModifiedDate` | `modifieddate` |
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `lastval()` |
| `DECIMAL(18,2)` | `NUMERIC(18,2)` |
| `INT` | `INTEGER` |
| `DATETIME` | `TIMESTAMP WITHOUT TIME ZONE` |

---

## Code Changes Summary

### Package Dependencies
| Change | Details |
|--------|---------|
| **Removed** | None (Microsoft.Data.SqlClient was not present) |
| **Added/Verified** | Npgsql 8.0.6 ✅ |

### ADO.NET Class Replacements
| SQL Server Class | Npgsql Equivalent | Status |
|-----------------|-------------------|--------|
| SqlConnection | NpgsqlConnection | ✅ Already migrated |
| SqlCommand | NpgsqlCommand | ✅ Already migrated |
| SqlDataReader | NpgsqlDataReader | ✅ Already migrated |
| SqlParameter | NpgsqlParameter | ✅ Already migrated (using AddWithValue) |
| SqlTransaction | NpgsqlTransaction | ✅ Already migrated (BeginTransactionAsync) |

### Import Statement Changes
| Change | Details |
|--------|---------|
| **using Microsoft.Data.SqlClient** | NOT PRESENT ✅ |
| **using System.Data.SqlClient** | NOT PRESENT ✅ |
| **using Npgsql** | PRESENT in ProductRepository.cs ✅ |

### Connection String Changes
| Parameter | SQL Server Format | PostgreSQL Format | Status |
|-----------|------------------|-------------------|--------|
| Server | `Server=` | `Host=localhost` | ✅ |
| Database | `Database=` | `Database=ProductManagement` | ✅ |
| Authentication | `Integrated Security=true` | `Username=postgres;Password=postgres` | ✅ |

### Transaction Handling
- `ExecuteInTransactionAsync` uses `connection.BeginTransactionAsync()` ✅
- `CommitAsync()` and `RollbackAsync()` patterns are PostgreSQL compatible ✅

---

## Files Modified During Migration

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements use PostgreSQL syntax, Npgsql types |
| `AdoCore.csproj` | Npgsql 8.0.6 package reference verified |
| `appsettings.json` | PostgreSQL connection strings verified |
| `Scripts/01_InitialSetup.sql` | PostgreSQL schema setup script |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL database setup with tables, triggers, data |

---

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| Extracted Statements | `extracted_statements.sql` | All 7 original MS SQL Server statements |
| Converted Statements | `converted_statements.sql` | All 7 converted PostgreSQL statements |
| Equivalency Report | `sql_equivalency_validation_report.json` | Complete validation report with all 7 statement pairs |
| Migration Report | `migration_report.md` | This document |

---

## Final Build Verification

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All 10 warnings are pre-existing nullable reference warnings (CS8601, CS8618, CS8600, CS8603, CS8625) unrelated to the migration.

---

## Statements Requiring Manual Review

All 7 statements have equivalency status of ERROR due to SQL Equivalency tool service-side issues. These should be manually reviewed:

1. **GetAllProductsAsync** - CTE with AVG/COUNT window functions, CASE, INNER JOIN, ORDER BY with NULLS FIRST
2. **GetProductByIdAsync** - CTE with LAG window function, LEFT OUTER JOIN, parameterized query
3. **InsertProductAsync** ⚠️ - DMS failed, manually converted DO $$ block with lastval()
4. **UpdateProductAsync** - DO $$ block with variable declarations, clock_timestamp(), DMS output adjusted for PL/pgSQL compatibility
5. **DeleteProductAsync** - DO $$ block with CASE expression in UPDATE, DMS output adjusted for PL/pgSQL compatibility
6. **GetProductsByPriceRangeAsync** - CTE with RANK/PERCENT_RANK, BETWEEN, ORDER BY with NULLS FIRST
7. **GetLowStockProductsAsync** - CTE with AVG/MIN/MAX window functions, ORDER BY with NULLS FIRST
