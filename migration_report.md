# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET ADO.NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-02-27  
**Application:** AdoCore (.NET 9.0)  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  

---

## SQL Statement Processing

### Inline SQL Statements (ProductRepository.cs)

| # | Method | Type | DMS Status | Manual Conversion | Equivalency |
|---|--------|------|------------|-------------------|-------------|
| 1 | GetAllProductsAsync | SELECT with CTE, Window Functions | FAILED | Yes - Lowercase Schema | ERROR |
| 2 | GetProductByIdAsync | SELECT with CTE, LAG | FAILED | Yes - Lowercase Schema | ERROR |
| 3 | InsertProductAsync | Transaction with INSERT, SCOPE_IDENTITY | FAILED | Yes - Lowercase Schema + CTE Rewrite | ERROR |
| 4 | UpdateProductAsync | Transaction with UPDATE, DECLARE | FAILED | Yes - Lowercase Schema + CTE Rewrite | ERROR |
| 5 | DeleteProductAsync | Transaction with DELETE, CASE | FAILED | Yes - Lowercase Schema + CTE Rewrite | ERROR |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE, RANK, PERCENT_RANK | FAILED | Yes - Lowercase Schema | ERROR |
| 7 | GetLowStockProductsAsync | SELECT with CTE, Window Functions | FAILED | Yes - Lowercase Schema | ERROR |

### Totals

- **Total inline SQL statements processed:** 7
- **DMS conversion successes:** 0
- **DMS conversion failures:** 7
- **Manual conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):** 7
- **DMS Failure Reason:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

### SQL Script Files Converted

- `Scripts/01_InitialSetup.sql` - Converted to PostgreSQL syntax
- `Database/Scripts/01_InitialSetup.sql` - Converted to PostgreSQL syntax (full schema)

---

## SQL Equivalency Validation

- **Tool used:** sql-equivalency___validate_sql_equivalence
- **Statements validated:** 7
- **Equivalent:** 0
- **Non-equivalent:** 0
- **Errors:** 7
- **Error details:** All 7 validations returned ERROR with error "'uniqueID'"
- **Report file:** sql_equivalency_validation_report.json

> **Note:** All equivalency statuses are directly from the SQL Equivalency tool output. No agent judgment was used to determine equivalency.

---

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Package: Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.8 |
| `DataAccess/ProductRepository.cs` | SQL statements converted, imports and classes replaced |
| `appsettings.json` | Connection strings updated to PostgreSQL format |
| `README.md` | Updated for PostgreSQL |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |

---

## Package Changes

| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.8 |

> **Note:** Npgsql 8.0.1 had a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c). Upgraded to 8.0.8 to address the security concern.

---

## Class Replacements

| SQL Server (Microsoft.Data.SqlClient) | PostgreSQL (Npgsql) |
|---------------------------------------|---------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed - not applicable) |
| Certificate | `TrustServerCertificate=True` | (removed - not applicable) |

---

## SQL Conversion Patterns Applied

| MS SQL Server | PostgreSQL |
|---------------|-----------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (with writable CTE) |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE; SET @var = ...` | Writable CTE with subquery |
| `BEGIN TRANSACTION; ... COMMIT;` | Writable CTE (single statement) |
| `IDENTITY(1,1)` | `SERIAL` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql` |
| `CREATE TRIGGER ... AFTER INSERT, UPDATE, DELETE` | `CREATE TRIGGER ... FOR EACH ROW EXECUTE FUNCTION` |
| `[bit]` | `BOOLEAN` |
| `[nvarchar]` | `VARCHAR` |
| `[datetime]` | `TIMESTAMP` |
| `SYSTEM_USER` | `current_user` |
| Schema objects (mixed case) | All lowercase |

---

## Build Verification

- **Build command:** `dotnet build`
- **Build result:** SUCCESS
- **Errors:** 0
- **Warnings:** 10 (all pre-existing nullable reference warnings, not related to migration)

---

## Transformation Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| Extracted SQL catalog | `extracted_statements.sql` | Complete (7 statements) |
| Converted SQL catalog | `converted_statements.sql` | Complete (7 conversions) |
| Equivalency report | `sql_equivalency_validation_report.json` | Complete (7 validations) |
| Migration report | `migration_report.md` | This document |

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. **DMS tool failure** - All conversions were performed manually with lowercase schema mapping
2. **Equivalency tool error** - All 7 equivalency validations returned ERROR status

**Recommended actions:**
- Verify the converted PostgreSQL SQL statements execute correctly against the target PostgreSQL database
- Test all CRUD operations (Create, Read, Update, Delete) with sample data
- Verify writable CTEs work correctly for the transaction-like statements (Insert, Update, Delete)
- Confirm window functions produce identical results in PostgreSQL
- Validate that the connection string parameters work with the PostgreSQL server
