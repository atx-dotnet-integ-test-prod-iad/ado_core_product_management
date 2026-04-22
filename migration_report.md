# Migration Report: SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-22  
**Source Database:** SQL Server (ProductManagement)  
**Target Database:** PostgreSQL (postgres)  
**Application Framework:** .NET 9.0, ADO.NET  

---

## 1. SQL Statements Processed

| Metric | Count |
|---|---|
| Total SQL statements processed | 7 |
| DMS conversion successes | 0 |
| DMS conversion failures | 7 |
| Manual conversions (with DMS schema mapping) | 7 |
| SQL Equivalency validations performed | 7 |
| Equivalent (per tool) | 0 |
| Non-equivalent (per tool) | 0 |
| Equivalency errors (per tool) | 7 |

### DMS Conversion Details
The DMS MCP statement_conversion_tool consistently failed for all 7 statements with the error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS schema_mapping_tool was successfully used to obtain target schema mappings:
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`

All 7 statements were manually converted using the DMS schema mapping output and applying lowercase schema object names per the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` methodology.

### SQL Equivalency Validation Details
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) returned ERROR for all 7 statement pairs with the error `'uniqueID'`. This appears to be an infrastructure issue with the tool. All pairs are documented in `sql_equivalency_validation_report.json`.

---

## 2. Statement Conversion Summary

### Statement #1: GetAllProductsAsync
- **Type:** SELECT with CTE, window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE/WHEN
- **Key Changes:** Products → productmanagement_dbo.products, column names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement #2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG() window function, LEFT JOIN, parameterized query
- **Key Changes:** Products → productmanagement_dbo.products, column names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement #3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), multi-table operations
- **Key Changes:** SCOPE_IDENTITY() → lastval(), GETDATE() → clock_timestamp(), BEGIN TRANSACTION → BEGIN, DECLARE removed
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement #4: UpdateProductAsync
- **Type:** Transaction block with DECLARE variables, UPDATE, INSERT, multi-table operations
- **Key Changes:** DECLARE variables → subquery-based INSERT...SELECT, GETDATE() → clock_timestamp(), reordered operations
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement #5: DeleteProductAsync
- **Type:** Transaction block with DECLARE variables, DELETE, INSERT, multi-table operations
- **Key Changes:** DECLARE variables → subquery-based INSERT...SELECT, GETDATE() → clock_timestamp(), reordered operations
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement #6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK() OVER, PERCENT_RANK() OVER, BETWEEN
- **Key Changes:** Products → productmanagement_dbo.products, column names lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement #7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER(), CASE/WHEN, ROUND
- **Key Changes:** Products → productmanagement_dbo.products, column names lowercased, added CAST for integer division
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

---

## 3. Files Modified

| File | Change Description |
|---|---|
| `DataAccess/ProductRepository.cs` | Replaced SqlClient types with Npgsql, re-integrated 7 converted PostgreSQL SQL statements, updated reader column names to lowercase |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |

## 4. Files Created

| File | Description |
|---|---|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report for all 7 statement pairs |
| `dms_conversion_summary.md` | DMS failure details and manual conversion notes |
| `migration_report.md` | This report |

---

## 5. Package Dependency Changes

| Original Package | Version | Replacement Package | Version |
|---|---|---|---|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

**Note:** Npgsql 8.0.6 was used instead of 8.0.0 to avoid a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

---

## 6. Connection String Changes

### DevConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Database=postgres;Username=postgres;Password=postgres`

### ProdConnection
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Database=postgres;Username=postgres;Password=postgres`

### Key Changes:
- `Server=` → `Host=`
- `Database=ProductManagement` → `Database=postgres` (target database name from transformation-preferences.json)
- `Trusted_Connection=True` → `Username=postgres;Password=postgres` (PostgreSQL authentication)
- Removed SQL Server-specific parameters: `MultipleActiveResultSets`, `TrustServerCertificate`

---

## 7. ADO.NET Type Replacements

| SQL Server Type | Npgsql Replacement |
|---|---|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

---

## 8. T-SQL to PostgreSQL Syntax Conversions

| T-SQL Syntax | PostgreSQL Equivalent |
|---|---|
| `SCOPE_IDENTITY()` | `lastval()` |
| `GETDATE()` | `clock_timestamp()` |
| `BEGIN TRANSACTION` / `COMMIT` | `BEGIN` / `COMMIT` |
| `DECLARE @var TYPE` | Subquery-based approach / INSERT...SELECT |
| `SET @var = SCOPE_IDENTITY()` | Direct use of `lastval()` |
| Integer division | `CAST(column AS NUMERIC)` for explicit conversion |

---

## 9. Schema Mapping (from DMS schema_mapping_tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

Column names are all lowercase in PostgreSQL target schema (e.g., `ProductId` → `productid`, `StockQuantity` → `stockquantity`).

---

## 10. Build Verification

**Final build result:** ✅ **Build succeeded** with 0 errors.

All nullable reference warnings pre-existed in the original codebase and are not related to the migration.

---

## 11. Remaining Items for Manual Review

1. **SQL Equivalency validation errors:** All 7 statement pairs returned ERROR from the equivalency tool due to an infrastructure issue (`'uniqueID'` error). Manual review of the converted statements is recommended.
2. **Transaction handling:** The converted transaction blocks use `BEGIN`/`COMMIT` embedded in SQL strings. Consider using Npgsql's native transaction support (`NpgsqlTransaction`) for better error handling.
3. **Integer division in GetLowStockProductsAsync:** Added explicit `CAST(stockquantity AS NUMERIC)` to prevent integer division in PostgreSQL.
4. **OVERRIDING SYSTEM VALUE in InsertProductAsync:** Required because PostgreSQL target uses `GENERATED ALWAYS AS IDENTITY` for the productid column.
5. **Connection string passwords:** The current configuration uses placeholder credentials. Production deployment should use environment variables or a secrets manager.
