# Migration Report: MS SQL Server to PostgreSQL
## AdoCore .NET Application

**Migration Date:** 2026-03-27  
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## Executive Summary

This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration encompassed 9 SQL statements, package dependencies, ADO.NET class replacements, connection string updates, and SQL setup scripts.

### Key Metrics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 9 |
| DMS Conversion Successes | 0 |
| DMS Conversion Failures | 9 |
| Manual Conversions Applied | 9 |
| SQL Equivalency Validations Attempted | 9 |
| Equivalency Status: EQUIVALENT | 0 |
| Equivalency Status: NOT_EQUIVALENT | 0 |
| Equivalency Status: ERROR | 9 |
| Build Status | **SUCCESS** (0 errors) |

---

## 1. DMS Conversion Results

All 9 SQL statements were submitted to the AWS DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. All attempts failed with timeout errors during metadata model creation.

**DMS Configuration Used:**
- Migration Project ARN: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- Database Name: `ProductManagement`
- Schema Name: `dbo`
- Server Name: `172.31.94.132`
- Region: `us-east-1`

### Per-Statement DMS Results

| # | Statement Name | DMS Status | Attempt Timestamp | Error |
|---|---------------|------------|-------------------|-------|
| 1 | GetAllProductsAsync | FAILED | 2026-03-26T23:57:47 | Metadata model creation did not complete after 15 attempts |
| 2 | GetProductByIdAsync | FAILED | 2026-03-27T00:00:35 | Metadata model creation did not complete after 15 attempts |
| 3 | InsertProductAsync | FAILED | 2026-03-27T00:03:30 | Metadata model creation did not complete after 15 attempts |
| 4 | UpdateProductAsync | FAILED | 2026-03-27T00:06:16 | Metadata model creation did not complete after 15 attempts |
| 5 | DeleteProductAsync | FAILED | 2026-03-27T00:09:02 | Metadata model creation did not complete after 15 attempts |
| 6 | GetProductsByPriceRangeAsync | FAILED | 2026-03-27T00:11:48 | Metadata model creation did not complete after 15 attempts |
| 7 | GetLowStockProductsAsync | FAILED | 2026-03-27T00:14:37 | Metadata model creation did not complete after 15 attempts |
| 8 | CREATE TABLE Products | FAILED | 2026-03-27T00:17:22 | Metadata model creation did not complete after 15 attempts |
| 9 | sp_GetAllProducts body | FAILED | 2026-03-27T00:20:05 | Metadata model creation did not complete after 15 attempts |

---

## 2. Manual Conversions Applied

Since all DMS conversions failed, manual conversion was applied using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach for all 9 statements.

### Conversion Rules Applied

| MS SQL Server | PostgreSQL |
|--------------|------------|
| `[dbo].[Products]` | `products` |
| `[dbo].[ProductHistory]` | `producthistory` |
| `[dbo].[ProductStats]` | `productstats` |
| `IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `DATETIME` | `TIMESTAMP` |
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `currval(pg_get_serial_sequence())` |
| `BEGIN TRANSACTION` | `BEGIN` |
| `COMMIT TRANSACTION` | `COMMIT` |
| `DECLARE @var / SET @var` | Subqueries / INSERT-SELECT |
| `ROUND(expr, n)` | `ROUND(CAST(expr AS NUMERIC), n)` |
| PascalCase columns | lowercase columns |

---

## 3. SQL Equivalency Validation Results

All 9 statement pairs were validated through the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All validations returned ERROR due to a service-side issue (`'uniqueID'`).

**CRITICAL NOTE:** Equivalency status comes exclusively from the tool output. Agent judgment was NOT used to determine equivalency for any statement.

| # | Statement Name | Equivalency Status | Validation Timestamp | Tool Error |
|---|---------------|-------------------|---------------------|------------|
| 1 | GetAllProductsAsync | ERROR | 2026-03-27T00:25:33 | `'uniqueID'` |
| 2 | GetProductByIdAsync | ERROR | 2026-03-27T00:25:50 | `'uniqueID'` |
| 3 | InsertProductAsync | ERROR | 2026-03-27T00:26:07 | `'uniqueID'` |
| 4 | UpdateProductAsync | ERROR | 2026-03-27T00:26:22 | `'uniqueID'` |
| 5 | DeleteProductAsync | ERROR | 2026-03-27T00:26:39 | `'uniqueID'` |
| 6 | GetProductsByPriceRangeAsync | ERROR | 2026-03-27T00:26:57 | `'uniqueID'` |
| 7 | GetLowStockProductsAsync | ERROR | 2026-03-27T00:27:11 | `'uniqueID'` |
| 8 | CREATE TABLE Products | ERROR | 2026-03-27T00:27:24 | `'uniqueID'` |
| 9 | sp_GetAllProducts body | ERROR | 2026-03-27T00:27:37 | `'uniqueID'` |

---

## 4. Per-Statement Detailed Log

### Statement 1: GetAllProductsAsync
- **Source File:** `sourceCode/DataAccess/ProductRepository.cs`
- **Method:** `GetAllProductsAsync()`
- **Type:** SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Complexity:** Hard
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** `[dbo].[Products]` → `products`, PascalCase → lowercase, `ROUND(expr, 2)` → `ROUND(CAST(expr AS NUMERIC), 2)`

### Statement 2: GetProductByIdAsync
- **Source File:** `sourceCode/DataAccess/ProductRepository.cs`
- **Method:** `GetProductByIdAsync()`
- **Type:** SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Parameters:** @ProductId
- **Complexity:** Hard
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** `[dbo].[Products]` → `products`, PascalCase → lowercase, `ROUND(expr, 2)` → `ROUND(CAST(expr AS NUMERIC), 2)`

### Statement 3: InsertProductAsync
- **Source File:** `sourceCode/DataAccess/ProductRepository.cs`
- **Method:** `InsertProductAsync()`
- **Type:** Transaction with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Parameters:** @Name, @Description, @Price, @StockQuantity
- **Complexity:** Medium
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** `BEGIN TRANSACTION` → `BEGIN`, `SCOPE_IDENTITY()` → `currval(pg_get_serial_sequence())`, `GETDATE()` → `NOW()`, DECLARE removed

### Statement 4: UpdateProductAsync
- **Source File:** `sourceCode/DataAccess/ProductRepository.cs`
- **Method:** `UpdateProductAsync()`
- **Type:** Transaction with DECLARE variables, SELECT INTO, UPDATE, INSERT, GETDATE()
- **Parameters:** @ProductId, @Name, @Description, @Price, @StockQuantity
- **Complexity:** Medium
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** DECLARE/SET → INSERT-SELECT + subquery, `GETDATE()` → `NOW()`

### Statement 5: DeleteProductAsync
- **Source File:** `sourceCode/DataAccess/ProductRepository.cs`
- **Method:** `DeleteProductAsync()`
- **Type:** Transaction with DECLARE variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Parameters:** @ProductId
- **Complexity:** Medium
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** DECLARE/SET → INSERT-SELECT + subquery, `GETDATE()` → `NOW()`

### Statement 6: GetProductsByPriceRangeAsync
- **Source File:** `sourceCode/DataAccess/ProductRepository.cs`
- **Method:** `GetProductsByPriceRangeAsync()`
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Parameters:** @MinPrice, @MaxPrice
- **Complexity:** Hard
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** `[dbo].[Products]` → `products`, PascalCase → lowercase

### Statement 7: GetLowStockProductsAsync
- **Source File:** `sourceCode/DataAccess/ProductRepository.cs`
- **Method:** `GetLowStockProductsAsync()`
- **Type:** SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Parameters:** @Threshold
- **Complexity:** Hard
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** `[dbo].[Products]` → `products`, PascalCase → lowercase, ROUND with CAST

### Statement 8: CREATE TABLE Products
- **Source File:** `sourceCode/Scripts/01_InitialSetup.sql`
- **Type:** DDL with IDENTITY, NVARCHAR, DATETIME, GETDATE()
- **Complexity:** Easy
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** `IDENTITY(1,1)` → `SERIAL`, `NVARCHAR` → `VARCHAR`, `DATETIME` → `TIMESTAMP`, `GETDATE()` → `NOW()`

### Statement 9: sp_GetAllProducts body
- **Source File:** `sourceCode/Scripts/01_InitialSetup.sql`
- **Type:** Simple SELECT inside stored procedure (converted to PostgreSQL function)
- **Complexity:** Easy
- **DMS Status:** FAILED
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** `[dbo].[Products]` → `products`, PascalCase → lowercase, Stored procedure → PostgreSQL function

---

## 5. Static Code Migration Summary

### Package References
| Original | Replacement | Status |
|----------|------------|--------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.9` | ✅ Complete |

### Using Statements
| Original | Replacement | Status |
|----------|------------|--------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` | ✅ Complete |

### ADO.NET Class Replacements
| SQL Server Class | Npgsql Class | Status |
|-----------------|-------------|--------|
| `SqlConnection` | `NpgsqlConnection` | ✅ Complete |
| `SqlCommand` | `NpgsqlCommand` | ✅ Complete |
| `SqlDataReader` | `NpgsqlDataReader` | ✅ Complete |
| `SqlParameter` | `NpgsqlParameter` | ✅ N/A (AddWithValue used) |
| `SqlTransaction` | Npgsql transaction | ✅ Complete |

### Connection Strings
| Parameter | SQL Server Format | PostgreSQL Format | Status |
|-----------|------------------|-------------------|--------|
| Server | `Server=` | `Host=` | ✅ Complete |
| Database | `Database=` | `Database=` | ✅ Complete |
| Auth | `Integrated Security=true` | `Username=;Password=` | ✅ Complete |

---

## 6. Files Modified

| File | Changes |
|------|---------|
| `sourceCode/DataAccess/ProductRepository.cs` | SQL statements, ADO.NET classes, using statements |
| `sourceCode/AdoCore.csproj` | Package reference: SqlClient → Npgsql |
| `sourceCode/appsettings.json` | Connection strings: SQL Server → PostgreSQL format |
| `sourceCode/Scripts/01_InitialSetup.sql` | DDL: SQL Server → PostgreSQL syntax |
| `sourceCode/Database/Scripts/01_InitialSetup.sql` | Full DDL: tables, triggers, functions, indexes, sample data |
| `sourceCode/extracted_statements.sql` | Catalog of all 9 original MS SQL statements |
| `sourceCode/converted_statements.sql` | Catalog of all 9 converted PostgreSQL statements |
| `sourceCode/sql_equivalency_validation_report.json` | Comprehensive equivalency report |
| `sourceCode/migration_report.md` | This migration report |

---

## 7. Build Verification

```
dotnet build
Build succeeded.
    0 Error(s)
    10 Warning(s) (pre-existing nullable reference warnings)
```

**Build Status:** ✅ SUCCESS

---

## 8. Statements Requiring Manual Review

All 9 statements require manual review due to:
1. **DMS Conversion Failure:** All statements failed DMS conversion and were manually converted
2. **Equivalency Validation Error:** All equivalency validations returned ERROR from the tool (service-side `'uniqueID'` error)

**Recommendation:** Perform integration testing against a PostgreSQL database to validate all SQL statements execute correctly and produce expected results.

---

## 9. Transformation Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| Extracted Statements Catalog | `sourceCode/extracted_statements.sql` | ✅ Complete (9/9 statements) |
| Converted Statements Catalog | `sourceCode/converted_statements.sql` | ✅ Complete (9/9 statements) |
| SQL Equivalency Report | `sourceCode/sql_equivalency_validation_report.json` | ✅ Complete (9/9 pairs) |
| Migration Report | `sourceCode/migration_report.md` | ✅ Complete |
