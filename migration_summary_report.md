# Migration Summary Report: MS SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-28  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  
**Application Framework:** .NET 9.0 (ADO.NET)  

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
- **Tool:** dms-mcp___statement_conversion_tool
- **Status:** FAILED for all 7 statements
- **Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Action Taken:** Manual conversion applied with lowercase schema object names per transformation definition
- **Conversion Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool Status
- **Tool:** sql-equivalency___validate_sql_equivalence
- **Status:** ERROR for all 7 statement pairs
- **Error:** `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`
- **Note:** Service-side error affecting all validations. Even trivial statements (SELECT 1) returned the same error. All pairs marked as ERROR per transformation definition requirements.

---

## SQL Statements Converted

### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE/WHEN, ROUND, INNER JOIN
- **Key Changes:** Table/column names lowercased
- **DMS Status:** FAILED | **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG window function, parameterized (@ProductId), LEFT JOIN, ROUND, CASE
- **Key Changes:** Table/column names lowercased
- **DMS Status:** FAILED | **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE multiple tables
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `currval(pg_get_serial_sequence('products', 'productid'))`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN;`
  - `DECLARE @NewProductId INT` → Removed (using currval instead)
  - Table/column names lowercased
- **DMS Status:** FAILED | **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT history, UPDATE stats
- **Key Changes:**
  - `DECLARE @OldPrice`/`@OldStock` → Removed (using INSERT...SELECT subquery to capture old values)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN;`
  - History INSERT moved before product UPDATE to capture old values via subquery
  - ProductStats UPDATE uses subquery to get old price before product UPDATE
  - Table/column names lowercased
- **DMS Status:** FAILED | **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT into variables, INSERT history, DELETE, UPDATE stats with CASE
- **Key Changes:**
  - `DECLARE @OldPrice`/`@OldStock` → Removed (using INSERT...SELECT subquery to capture old values)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN;`
  - History INSERT and stats UPDATE moved before DELETE to capture old values
  - Table/column names lowercased
- **DMS Status:** FAILED | **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **Key Changes:** Table/column names lowercased
- **DMS Status:** FAILED | **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER() window functions, CASE, ROUND
- **Key Changes:**
  - Added `CAST(stockquantity AS DECIMAL)` for proper division (avoid integer division)
  - Table/column names lowercased
- **DMS Status:** FAILED | **Equivalency Status:** ERROR

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL; SqlClient classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |

---

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

**Unchanged packages:**
- Microsoft.Extensions.Configuration v8.0.0
- Microsoft.Extensions.Configuration.Json v8.0.0
- Microsoft.Extensions.DependencyInjection v8.0.0

---

## Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 4 (field, method return type, 2 constructor calls) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

**Using directive change:**
- `using Microsoft.Data.SqlClient;` → `using Npgsql;`

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=password` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| SSL | `TrustServerCertificate=True` | Removed |

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| Extracted Statements | `extracted_statements.sql` | All 7 original MS SQL statements |
| Converted Statements | `converted_statements.sql` | All 7 converted PostgreSQL statements |
| Equivalency Report | `sql_equivalency_validation_report.json` | Detailed validation report with 7 statement pairs |
| Migration Report | `migration_summary_report.md` | This report |

---

## Build Status

**Final build result:** ✅ SUCCESS  
**Errors:** 0  
**Warnings:** 10 (all pre-existing nullable reference warnings, not related to migration)

---

## DMS Failure Details

All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) and all failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

This appears to be a service-side issue with the DMS metadata model creation. Multiple retry attempts with different poll intervals (15s, 20s) and max poll attempts (15, 30, 45) were made, all resulting in the same error.

Per the transformation definition, manual conversion was applied with the following rules:
1. All schema object names (tables, columns, views) converted to lowercase
2. SQL Server-specific functions converted to PostgreSQL equivalents
3. Transaction syntax updated (BEGIN TRANSACTION → BEGIN;)
4. Variable declarations replaced with subqueries for ADO.NET compatibility
5. Conversion method documented as `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
