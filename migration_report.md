# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Type** | MS SQL Server → PostgreSQL |
| **Application Framework** | .NET 9.0, ADO.NET |
| **Source Database Driver** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Database Driver** | Npgsql 8.0.6 |
| **Total SQL Statements Processed** | 7 |
| **Statements Converted by DMS Tool** | 0 (DMS tool failed for all 7) |
| **Statements Manually Converted** | 7 |
| **Manual Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Build Status** | ✅ Success (0 errors) |

## DMS Tool Conversion Results

### DMS Tool Status
The DMS statement conversion tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements using migration project ARN: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`. All 7 attempts failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

| # | Statement | DMS Timestamp | DMS Status |
|---|-----------|---------------|------------|
| 1 | GetAllProductsAsync | 2026-05-04T11:10:21 | FAILED |
| 2 | GetProductByIdAsync | 2026-05-04T11:10:38 | FAILED |
| 3 | InsertProductAsync | 2026-05-04T11:10:53 | FAILED |
| 4 | UpdateProductAsync | 2026-05-04T11:11:08 | FAILED |
| 5 | DeleteProductAsync | 2026-05-04T11:11:23 | FAILED |
| 6 | GetProductsByPriceRangeAsync | 2026-05-04T11:11:38 | FAILED |
| 7 | GetLowStockProductsAsync | 2026-05-04T11:11:53 | FAILED |

### Manual Conversion Rules Applied
Since DMS failed for all statements, manual conversion was applied with lowercase schema mapping:
- All schema object names converted to lowercase (Products→products, ProductHistory→producthistory, ProductStats→productstats)
- All column names converted to lowercase (ProductId→productid, Name→name, Price→price, etc.)
- CTE names renamed to avoid conflicts with table names (ProductStats→productstats_cte, ProductHistory→producthistory_cte)

## SQL Equivalency Validation Results

All 7 statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status with `'uniqueID'` error from the tool. **No agent judgment was used to determine equivalency.**

| # | Method | Equivalency Status | Tool Timestamp | Conversion Method |
|---|--------|--------------------|----------------|-------------------|
| 1 | GetAllProductsAsync | ERROR | 2026-05-04T11:14:09 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 2 | GetProductByIdAsync | ERROR | 2026-05-04T11:14:27 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 3 | InsertProductAsync | ERROR | 2026-05-04T11:14:42 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 4 | UpdateProductAsync | ERROR | 2026-05-04T11:14:57 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 5 | DeleteProductAsync | ERROR | 2026-05-04T11:15:13 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 6 | GetProductsByPriceRangeAsync | ERROR | 2026-05-04T11:15:29 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 7 | GetLowStockProductsAsync | ERROR | 2026-05-04T11:15:44 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |

### Equivalency Summary
- **Statements Processed**: 7
- **Equivalent**: 0
- **Non-Equivalent**: 0
- **Error**: 7

## Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG, COUNT), CASE, ROUND, INNER JOIN
- **Key Changes**: Table/column names to lowercase, CTE renamed from ProductStats to productstats_cte to avoid conflict with productstats table
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, LEFT JOIN, parameterized query
- **Key Changes**: Table/column names to lowercase, CTE renamed from ProductHistory to producthistory_cte to avoid conflict with producthistory table
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**:
  - `DECLARE @NewProductId INT` → removed (using LASTVAL())
  - `BEGIN TRANSACTION` → `BEGIN`
  - `SCOPE_IDENTITY()` → `LASTVAL()`
  - `GETDATE()` → `NOW()`
  - All table/column names to lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO, UPDATE, INSERT
- **Key Changes**:
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE` variables → eliminated, used subquery approach
  - `GETDATE()` → `NOW()`
  - Used `SELECT AVG(price) FROM products` for statistics update
  - All table/column names to lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, INSERT history, DELETE, UPDATE stats
- **Key Changes**:
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE` variables → eliminated, used subquery from products table
  - `GETDATE()` → `NOW()`
  - Used `COALESCE(AVG(price), 0)` for empty table safety
  - All table/column names to lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK, PERCENT_RANK window functions, CASE, BETWEEN
- **Key Changes**: Table/column names to lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes**: Table/column names to lowercase, added `CAST(stockquantity AS NUMERIC)` for integer division fix
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `DataAccess/ProductRepository.cs` | 7 SQL statements converted, using statements updated, ADO.NET classes replaced, reader column names to lowercase |
| `appsettings.json` | Connection strings updated to PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion to PostgreSQL DDL, functions, triggers |
| `Scripts/01_InitialSetup.sql` | Full conversion to PostgreSQL DDL and functions |
| `README.md` | Updated for PostgreSQL prerequisites and instructions |

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.6 |
| `Microsoft.Extensions.Configuration` 8.0.0 | (unchanged) |
| `Microsoft.Extensions.Configuration.Json` 8.0.0 | (unchanged) |
| `Microsoft.Extensions.DependencyInjection` 8.0.0 | (unchanged) |

## Class Replacements

| SQL Server Class | PostgreSQL Class |
|-----------------|------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|------------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (not applicable) |
| SSL | `TrustServerCertificate=True` | (not applicable) |

## SQL Syntax Changes Applied

| SQL Server Syntax | PostgreSQL Syntax |
|-------------------|-------------------|
| `SCOPE_IDENTITY()` | `LASTVAL()` |
| `GETDATE()` | `NOW()` |
| `BEGIN TRANSACTION` | `BEGIN` |
| `DECLARE @Var TYPE` | Eliminated (subqueries used) |
| `SET @Var = expr` | N/A |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `CREATE PROCEDURE` | `CREATE FUNCTION ... LANGUAGE plpgsql` |
| `CREATE TRIGGER ... AS BEGIN` | `CREATE TRIGGER ... EXECUTE FUNCTION` |
| `SYSTEM_USER` | `current_user` |
| `GO` | (removed) |

## Exit Criteria Verification

| # | Criteria | Status |
|---|----------|--------|
| 1 | All SQL Server packages replaced with PostgreSQL equivalents | ✅ |
| 2 | All SqlClient classes replaced with Npgsql equivalents | ✅ |
| 3 | All SQL statements processed through DMS MCP tool | ✅ (7/7 attempted, all failed) |
| 4 | Comprehensive catalog of all SQL statements exists | ✅ (extracted_statements.sql + converted_statements.sql) |
| 5 | All statement pairs validated through SQL Equivalency tool | ✅ (7/7 validated, all ERROR) |
| 6 | Comprehensive equivalency report generated | ✅ (sql_equivalency_validation_report.json) |
| 7 | No agent judgment used for equivalency | ✅ (all statuses from tool output) |
| 8 | DMS failures documented with manual conversions | ✅ (all 7 documented) |
| 9 | Connection strings updated to PostgreSQL format | ✅ |
| 10 | Transaction handling updated to PostgreSQL syntax | ✅ |
| 11 | Application compiles without errors | ✅ (0 errors, 10 warnings) |
| 12 | Database scripts use PostgreSQL DDL | ✅ |

## Artifacts Generated

1. **extracted_statements.sql** - Complete catalog of all 7 original MS SQL statements with source locations
2. **converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements with DMS attempt timestamps and conversion methods
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency validation report with all 7 statement pairs and tool output
4. **migration_report.md** - This report

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS statement conversion tool was unavailable (metadata model creation failure for all 7 attempts)
2. SQL Equivalency tool returned ERROR for all 7 pairs (tool returned `'uniqueID'` error)
3. Manual conversions were applied using lowercase schema mapping conventions

**Recommendation**: Validate all SQL statements against the actual PostgreSQL database to ensure correct behavior, particularly:
- Transaction handling with `BEGIN`/`COMMIT` blocks
- `LASTVAL()` usage for identity column retrieval
- Subquery-based approaches replacing `DECLARE` variables
- Integer division handling with `CAST(... AS NUMERIC)`
