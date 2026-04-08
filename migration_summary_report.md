# Migration Summary Report
## Microsoft SQL Server to PostgreSQL - AdoCore Application

**Date:** 2026-04-08  
**Application:** AdoCore (.NET 9.0 ADO.NET Application)  
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13 (postgres)  

---

## Executive Summary

This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET class references, and modifying connection strings to support PostgreSQL via Npgsql.

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **DMS Tool Conversion Successes** | 0 |
| **DMS Tool Conversion Failures** | 7 |
| **Manual Conversions Required** | 7 |
| **Equivalency Validated as EQUIVALENT** | 0 |
| **Equivalency Validated as NOT_EQUIVALENT** | 0 |
| **Equivalency Validation ERRORS** | 7 |

### DMS Tool Status
The DMS MCP Statement Conversion Tool (dms-mcp___statement_conversion_tool) consistently failed with timeout errors during metadata model creation/conversion. Multiple attempts were made with varying poll configurations:
- Default (15 attempts, 10s intervals) - Failed
- Extended (20 attempts, 10s intervals) - Failed  
- Maximum (30 attempts, 15s intervals) - Failed/Timed out
- Maximum (40 attempts, 15s intervals) - Failed/Timed out

**DMS Error Message:** "Metadata model creation/conversion did not complete after N attempts"

**Note:** The DMS Schema Mapping Tool (dms-mcp___schema_mapping_tool) was functional and successfully returned schema mappings for all 3 tables, which were used to guide the manual conversion.

### SQL Equivalency Tool Status
The SQL Equivalency Tool (sql-equivalency___validate_sql_equivalence) returned a consistent service-level error for all 7 statement pairs: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`. This was confirmed to be a service infrastructure issue by testing with a trivial query (`SELECT 1`), which also returned the same error. All equivalency statuses are marked as ERROR per the tool's output.

---

## Detailed Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type:** CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Changes:** CTE renamed to `productstats_cte`, all identifiers lowercased, schema prefix `productmanagement_dbo` added
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window function, LEFT JOIN, CASE with ROUND
- **Changes:** CTE renamed to `producthistory_cte`, all identifiers lowercased, schema prefix added
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Type:** Transaction block with DECLARE, SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE()
- **Changes:** Restructured from single T-SQL batch to 3 separate PostgreSQL commands managed by C# ADO.NET transaction. `SCOPE_IDENTITY()` → `RETURNING productid`. `GETDATE()` → `CURRENT_TIMESTAMP`.
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT, GETDATE()
- **Changes:** Restructured from single T-SQL batch to 4 separate PostgreSQL commands managed by C# ADO.NET transaction. `DECLARE @var / SELECT @var = col` → separate SELECT query with C# variable. `GETDATE()` → `CURRENT_TIMESTAMP`.
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT into variables, INSERT, DELETE, CASE, GETDATE()
- **Changes:** Same restructuring pattern as Statement 4. Split into 4 separate PostgreSQL commands. `GETDATE()` → `CURRENT_TIMESTAMP`.
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE
- **Changes:** All identifiers lowercased, schema prefix added. SQL structure unchanged (standard SQL compatible).
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG, MIN, MAX window functions, CASE, ROUND
- **Changes:** All identifiers lowercased, schema prefix added. Added `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation.
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Schema Mapping (from DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

All column names were converted to lowercase as part of the schema migration.

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET classes replaced, column name references updated |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.0 |
| `appsettings.json` | Connection strings updated from SQL Server to PostgreSQL format |

---

## Package Changes

| Action | Package | Version |
|--------|---------|---------|
| **Removed** | Microsoft.Data.SqlClient | 5.1.4 |
| **Added** | Npgsql | 8.0.0 |

---

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Class | Occurrences |
|------------------|---------------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlTransaction` | `NpgsqlTransaction` | 3 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

---

## Connection String Changes

### Development Connection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres`

### Production Connection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres`

### Parameter Mapping
| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `Server=` | `Host=` | Hostname parameter |
| `Database=ProductManagement` | `Database=postgres` | Target DB from transformation preferences |
| `Trusted_Connection=True` | Removed | Windows Auth not applicable |
| `MultipleActiveResultSets=true` | Removed | SQL Server specific |
| `TrustServerCertificate=True` | Removed | SQL Server specific |
| N/A | `Port=5432` | PostgreSQL default port |
| N/A | `Username=postgres` | PostgreSQL authentication |
| N/A | `Password=postgres` | PostgreSQL authentication |

---

## SQL Syntax Conversions Applied

| SQL Server Syntax | PostgreSQL Syntax | Statements Affected |
|-------------------|-------------------|---------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | Statement 3 |
| `GETDATE()` | `CURRENT_TIMESTAMP` | Statements 3, 4, 5 |
| `BEGIN TRANSACTION / COMMIT` | C# `BeginTransactionAsync()` | Statements 3, 4, 5 |
| `DECLARE @var / SET @var = ...` | C# variable + separate SELECT | Statements 3, 4, 5 |
| `SELECT @var = column` | Separate SELECT command | Statements 4, 5 |
| Integer division | `CAST(col AS NUMERIC)` | Statement 7 |

---

## Build Verification

| Step | Build Status | Errors | Warnings |
|------|-------------|--------|----------|
| Step 1 (Extract/Convert) | SUCCESS | 0 | 10 (pre-existing) |
| Step 2 (Re-integrate SQL) | SUCCESS | 0 | 10 (pre-existing) |
| Step 3 (Package/ADO.NET) | SUCCESS | 0 | 10 (pre-existing) |
| Step 4 (Connection Strings) | SUCCESS | 0 | 10 (pre-existing) |
| Step 5 (Reports) | SUCCESS | 0 | 10 (pre-existing) |

All 10 warnings are pre-existing nullable reference type warnings (CS8618, CS8600, CS8601, CS8603, CS8625) that were present in the original codebase before migration.

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | All 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Comprehensive equivalency report with all 7 statement pairs |
| `migration_summary_report.md` | `sourceCode/` | This report |

---

## Manual Interventions

All 7 SQL statements required manual conversion due to DMS tool timeout failures. The conversions were guided by:
1. Schema mappings successfully retrieved from the DMS Schema Mapping Tool
2. Standard SQL Server to PostgreSQL conversion rules (lowercase identifiers, CURRENT_TIMESTAMP, RETURNING clause)
3. Restructuring of T-SQL batch scripts (with DECLARE/@variable patterns) into separate SQL commands managed by C# ADO.NET transactions

---

## Risk Assessment

1. **Equivalency Validation:** All 7 statement pairs returned ERROR from the SQL Equivalency tool due to a service infrastructure issue. Manual review of the conversions is recommended to verify functional equivalency.
2. **Transaction Restructuring:** Statements 3, 4, and 5 were restructured from single T-SQL batch commands to multiple separate commands within C# ADO.NET transactions. This maintains the same transactional guarantees but changes the execution pattern.
3. **Integer Division:** Statement 7 added an explicit CAST to NUMERIC to prevent integer truncation, which may produce slightly different results than the original SQL Server behavior for edge cases.
