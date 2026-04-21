# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-21  
**Application:** AdoCore (.NET 9.0 ADO.NET Application)  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Requiring Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| With Equivalency Validation Errors | 7 |

### DMS Tool Status

The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) failed for all 7 statements with the consistent error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) succeeded and provided target schema mappings which were used to guide manual conversions.

### SQL Equivalency Tool Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) returned ERROR for all 7 statement pairs with the error:
```
{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}
```

All results are documented in `sql_equivalency_validation_report.json`.

---

## Detailed SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Method:** `GetAllProductsAsync()`
- **Type:** CTE with AVG/COUNT window functions
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** All identifiers lowercase, CTE alias renamed to `productstats_cte` to avoid conflict with table name
- **Equivalency Status:** ERROR (tool internal error)

### Statement 2: GetProductByIdAsync
- **Method:** `GetProductByIdAsync(int productId)`
- **Type:** CTE with LAG window functions
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** All identifiers lowercase, CTE alias renamed to `producthistory_cte`
- **Equivalency Status:** ERROR (tool internal error)

### Statement 3: InsertProductAsync
- **Method:** `InsertProductAsync(Product product)`
- **Type:** Transaction block with SCOPE_IDENTITY/GETDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - Single SQL block with DECLARE → Multiple C# commands in transaction
  - Transaction managed at C# level with `BeginTransactionAsync/CommitAsync/RollbackAsync`
- **Equivalency Status:** ERROR (tool internal error)

### Statement 4: UpdateProductAsync
- **Method:** `UpdateProductAsync(Product product)`
- **Type:** Transaction block with DECLARE variables and GETDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → Separate SELECT to capture old values in C#
  - `GETDATE()` → `NOW()`
  - Transaction managed at C# level
- **Equivalency Status:** ERROR (tool internal error)

### Statement 5: DeleteProductAsync
- **Method:** `DeleteProductAsync(int productId)`
- **Type:** Transaction block with DECLARE variables and GETDATE/CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → Separate SELECT to capture old values in C#
  - `GETDATE()` → `NOW()`
  - CASE expression preserved (PostgreSQL compatible)
  - Transaction managed at C# level
- **Equivalency Status:** ERROR (tool internal error)

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type:** CTE with RANK/PERCENT_RANK window functions
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** All identifiers lowercase
- **Equivalency Status:** ERROR (tool internal error)

### Statement 7: GetLowStockProductsAsync
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **Type:** CTE with AVG/MIN/MAX window functions
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** All identifiers lowercase, added `CAST(stockquantity AS NUMERIC)` for integer division in ROUND
- **Equivalency Status:** ERROR (tool internal error)

---

## Files Modified

### Source Code Changes

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Complete migration: 7 SQL statements converted, ADO.NET classes replaced, using directive updated |
| `AdoCore.csproj` | Package reference: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings: SQL Server format → PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax |

### Package Dependency Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

**Note:** Npgsql 8.0.6 was selected instead of 8.0.0 to avoid known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

### Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `True` | Removed (not applicable) |
| TrustServerCertificate | `True` | Removed (not applicable) |

### ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

### SQL Syntax Conversions

| SQL Server | PostgreSQL |
|-----------|-----------|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` clause |
| `GETDATE()` | `NOW()` |
| `DECLARE @variable` | C# variable with separate SELECT |
| `BEGIN TRANSACTION/COMMIT` | C# `BeginTransactionAsync/CommitAsync` |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `nvarchar` | `varchar` |
| `bit` | `boolean` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SYSTEM_USER` | `current_user` |

---

## Schema Mapping (from DMS Schema Mapping Tool)

| Source Table (SQL Server) | Target Table (PostgreSQL) | Target Schema |
|--------------------------|--------------------------|---------------|
| `dbo.Products` | `products` | `productmanagement_dbo` |
| `dbo.ProductHistory` | `producthistory` | `productmanagement_dbo` |
| `dbo.ProductStats` | `productstats` | `productmanagement_dbo` |
| `dbo.Categories` | `categories` | `productmanagement_dbo` |
| `dbo.Suppliers` | `suppliers` | `productmanagement_dbo` |

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | sourceCode root | All 7 original MS SQL statements |
| `converted_statements.sql` | sourceCode root | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | sourceCode root | Complete equivalency validation report |
| `dms_failure_summary.txt` | sourceCode root | DMS tool failure documentation |
| `migration_report.md` | sourceCode root | This report |

---

## Build Validation

- **Final Build Status:** ✅ Success
- **Errors:** 0
- **Warnings:** Pre-existing nullable reference warnings only
- **No remaining references to:**
  - `Microsoft.Data.SqlClient` ✅
  - `SqlConnection`, `SqlCommand`, `SqlDataReader`, `SqlParameter` ✅
  - SQL Server specific connection string parameters ✅

---

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS Statement Conversion Tool failed for all statements
2. SQL Equivalency Tool returned ERROR for all statement pairs
3. Manual conversion was applied using lowercase schema object names based on DMS schema mapping

**Recommendation:** Perform integration testing against a PostgreSQL database to validate all conversions function correctly.
