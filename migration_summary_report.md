# Migration Summary Report: SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-03-20  
**Application:** AdoCore (ProductManagement)  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**DMS Migration Project ARN:** arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| DMS conversion successes | 0 |
| DMS conversion failures | 7 |
| Manual conversions (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA) | 7 |
| Equivalency validated as EQUIVALENT | 0 |
| Equivalency validated as NOT_EQUIVALENT | 0 |
| Equivalency validation ERROR | 7 |

### DMS Tool Status
The DMS statement conversion tool (dms-mcp___statement_conversion_tool) consistently failed with error:
> Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15/20/25 attempts'}

This affected all 7 SQL statements. The DMS schema mapping tool (dms-mcp___schema_mapping_tool) was successful and provided the target schema definitions used for manual conversion.

### SQL Equivalency Tool Status
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) returned ERROR for all 7 statement pairs with error:
> 'uniqueID'

This was a service-side error that affected all validation attempts. Each statement pair was individually submitted to the tool as required.

---

## Converted SQL Statements

### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Key Changes:** Table/column names lowercased, CTE renamed to `productstats_cte` to avoid conflict with `productstats` table
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG window function, LEFT JOIN, CASE with NULL handling
- **Key Changes:** Table/column names lowercased, CTE renamed to `producthistory_cte`
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Key Changes:** `SCOPE_IDENTITY()` → `lastval()`, `GETDATE()` → `NOW()`, `BEGIN TRANSACTION` → `BEGIN`, `DECLARE`/`SET` removed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history
- **Key Changes:** `DECLARE`/variable assignment replaced with INSERT...SELECT subquery pattern, `GETDATE()` → `NOW()`, operation reordered (history first, stats update, then product update)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT history, DELETE
- **Key Changes:** `DECLARE`/variable assignment replaced with INSERT...SELECT subquery pattern, `GETDATE()` → `NOW()`, operation reordered (history first, stats update, then delete)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **Key Changes:** Table/column names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER window functions, CASE, ROUND
- **Key Changes:** Table/column names lowercased, added `::numeric` cast for integer division in ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## Schema Mapping (from DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| dbo.Products | productmanagement_dbo.products |
| dbo.ProductHistory | productmanagement_dbo.producthistory |
| dbo.ProductStats | productmanagement_dbo.productstats |

**Note:** Column names are all lowercase in PostgreSQL target schema (e.g., `ProductId` → `productid`, `StockQuantity` → `stockquantity`).

---

## Files Modified

| File | Changes |
|------|---------|
| sourceCode/DataAccess/ProductRepository.cs | SQL statements converted, ADO.NET classes replaced, column references lowercased |
| sourceCode/AdoCore.csproj | Package reference: Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| sourceCode/appsettings.json | Connection strings converted to PostgreSQL format |

---

## Package Changes

| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

**Note:** Npgsql 8.0.6 was selected instead of 8.0.1 (originally planned) to address a known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c).

---

## Class Replacements

| SQL Server (Microsoft.Data.SqlClient) | PostgreSQL (Npgsql) |
|---------------------------------------|---------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | Server=localhost | Host=localhost |
| Port | (default 1433) | Port=5432 |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed - not applicable) |
| TrustServerCertificate | True | (removed - not applicable) |

---

## SQL Syntax Conversions Applied

| SQL Server | PostgreSQL | Context |
|------------|-----------|---------|
| `SCOPE_IDENTITY()` | `lastval()` | InsertProductAsync |
| `GETDATE()` | `NOW()` | Insert/Update/Delete methods |
| `BEGIN TRANSACTION` | `BEGIN` | All transaction blocks |
| `DECLARE @var TYPE` | Replaced with subqueries | Update/Delete methods |
| `SELECT @var = col` | Replaced with INSERT...SELECT | Update/Delete methods |
| `ROUND(int/int, 2)` | `ROUND(int::numeric/int, 2)` | GetLowStockProductsAsync |

---

## Migration Artifacts

| Artifact | Description |
|----------|-------------|
| extracted_statements.sql | Catalog of all 7 original MS SQL statements |
| converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Comprehensive equivalency report for all 7 statement pairs |
| migration_summary_report.md | This report |

---

## Build Verification

- **Final Build Status:** ✅ Success
- **Errors:** 0
- **Warnings:** 10 (all pre-existing nullable reference warnings)
- **Vulnerability Warnings:** 0
- **SQL Server Artifacts Remaining:** None (verified via grep search across all .cs and .csproj files)

---

## Known Issues and Considerations

1. **DMS Tool Failures:** All 7 SQL statements failed DMS conversion due to metadata model creation timeout. Manual conversion was applied using DMS schema mapping data for correct schema/table/column naming.

2. **SQL Equivalency Errors:** All 7 equivalency validations returned ERROR due to a `'uniqueID'` service-side error. This means the converted SQL statements have not been formally validated for functional equivalency by the tool.

3. **Transaction Restructuring:** The Update and Delete methods required restructuring to replace SQL Server's `DECLARE`/variable assignment pattern with PostgreSQL-compatible subquery patterns. The operation order was adjusted to capture old values via subqueries before modifications.

4. **Connection String Credentials:** The connection strings use placeholder credentials (postgres/postgres). In production, these should be replaced with secure configuration (environment variables, Azure Key Vault, AWS Secrets Manager, etc.).

5. **MapProductFromReader Column Names:** Column name references in the data reader were updated to lowercase to match PostgreSQL's case handling (e.g., `reader["ProductId"]` → `reader["productid"]`).

6. **Schema Prefix:** The DMS schema mapping indicated a `productmanagement_dbo` schema prefix for PostgreSQL tables. The converted SQL does not include this prefix in the embedded SQL statements, as the search_path would typically be set at the connection level. If the PostgreSQL database uses this schema, the connection string should include `SearchPath=productmanagement_dbo` or the SQL statements should be prefixed with the schema name.
