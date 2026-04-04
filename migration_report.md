# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-04
**Application:** AdoCore (.NET 9.0, ADO.NET)
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)
**Target Database:** PostgreSQL 13 (postgres)

---

## Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Files modified | 3 |
| Package references changed | 1 |
| Class replacements | 4 types |
| Connection strings updated | 2 |
| Build status (final) | **Success** |

---

## Files Modified

### 1. AdoCore.csproj
- **Change:** Package reference swap
- **Removed:** `Microsoft.Data.SqlClient` Version 5.1.4
- **Added:** `Npgsql` Version 8.0.1
- **Preserved:** Microsoft.Extensions.Configuration 8.0.0, Microsoft.Extensions.Configuration.Json 8.0.0, Microsoft.Extensions.DependencyInjection 8.0.0

### 2. DataAccess/ProductRepository.cs
- **Using directive:** `using Microsoft.Data.SqlClient` -> `using Npgsql`
- **Class replacements:**
  - `SqlConnection` -> `NpgsqlConnection`
  - `SqlCommand` -> `NpgsqlCommand` (7 instances)
  - `SqlDataReader` -> `NpgsqlDataReader`
- **SQL statement changes:** 7 statements converted from MS SQL Server to PostgreSQL syntax
- **Column reader mappings:** Updated to lowercase column names matching PostgreSQL schema

### 3. appsettings.json
- **DevConnection:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` -> `Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres`
- **ProdConnection:** Same transformation applied

---

## SQL Statement Conversions

### DMS MCP Tool Results
- **Total DMS attempts:** 6 (including retries with different parameters)
- **DMS successes:** 0
- **DMS failures:** 6
- **DMS error:** `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **Fallback:** Manual conversion using DMS schema_mapping_tool results and lowercase schema object naming

### Schema Mapping (from DMS schema_mapping_tool - Successful)
| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| dbo.Products | productmanagement_dbo.products |
| dbo.ProductHistory | productmanagement_dbo.producthistory |
| dbo.ProductStats | productmanagement_dbo.productstats |
| GETDATE() | clock_timestamp() |
| SCOPE_IDENTITY() | RETURNING clause |
| DECLARE @var / BEGIN TRANSACTION | Writable CTEs |

### Statement Details

#### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Key Changes:** CTE renamed productstats_cte (avoid table name conflict), all identifiers lowercased, schema prefixed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

#### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG Window Functions, LEFT JOIN, parameterized WHERE
- **Key Changes:** CTE renamed producthistory_cte (avoid table name conflict), all identifiers lowercased, schema prefixed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

#### Statement 3: InsertProductAsync
- **Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Key Changes:** SCOPE_IDENTITY() replaced with RETURNING, GETDATE() -> clock_timestamp(), DECLARE/@var removed, transaction block replaced with writable CTEs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

#### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Key Changes:** DECLARE/@var replaced with CTE old_values, GETDATE() -> clock_timestamp(), transaction block replaced with writable CTEs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

#### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE, CASE
- **Key Changes:** DECLARE/@var replaced with CTE old_values, GETDATE() -> clock_timestamp(), transaction block replaced with writable CTEs
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

#### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK, PERCENT_RANK Window Functions, BETWEEN, CASE
- **Key Changes:** All identifiers lowercased, schema prefixed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

#### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Key Changes:** All identifiers lowercased, schema prefixed, added ::numeric cast for integer division in ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## SQL Equivalency Validation Results

### Equivalency Tool Results
- **Tool:** sql-equivalency___validate_sql_equivalence
- **Statements validated:** 7/7 (all submitted)
- **Equivalent:** 0
- **Non-equivalent:** 0
- **Errors:** 7
- **Systemic error:** `'uniqueID'` - All 7 submissions returned the same error
- **Note:** This is a tool-level systemic error, not related to SQL conversion quality

### Detailed Report
The complete equivalency validation report is available in `sql_equivalency_validation_report.json`.

---

## Transformation Artifacts
1. **extracted_statements.sql** - Catalog of all 7 original MS SQL statements
2. **converted_statements.sql** - Catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency report with all 7 statement details
4. **migration_report.md** - This report

---

## Build Verification
- **Final build result:** Success (0 errors, 10 warnings)
- **Warnings:** Pre-existing nullable reference warnings (CS8618, CS8601, CS8600, CS8603, CS8625) - not introduced by migration
- **Output:** `AdoCore -> AdoCore.dll`

---

## Manual Interventions
All 7 SQL statements required manual conversion due to DMS tool failure:
- **Reason:** DMS metadata model creation consistently failed after maximum poll attempts
- **Approach:** Used DMS schema_mapping_tool to retrieve accurate target schema, then applied manual conversion with lowercase schema object naming rules
- **Documentation:** Each conversion is documented in sql_equivalency_validation_report.json with:
  - Original MS SQL statement
  - Converted PostgreSQL statement
  - DMS failure reason
  - Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
