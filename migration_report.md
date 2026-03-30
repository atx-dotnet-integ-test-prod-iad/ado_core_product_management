# Migration Report: MS SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-03-30  
**Source Database:** SQL Server (Microsoft.Data.SqlClient 5.1.4)  
**Target Database:** PostgreSQL (Npgsql 8.0.6)  
**Application Framework:** .NET 9.0 ADO.NET  

---

## SQL Statement Conversion Results

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status

The DMS MCP tool (`dms-mcp___statement_conversion_tool`) was **non-functional** during this migration session. All attempts to convert SQL statements failed with the same error:

- **Error:** `Metadata model creation/conversion did not complete after 15 attempts`
- **Attempts Made:** 4 separate calls with different configurations (default settings, increased poll attempts to 30, poll interval to 15s, explicit server_name)
- **Smallest Statement Tested:** `SELECT GETDATE()` - still failed, confirming infrastructure-level issue

### Manual Conversion Approach

Due to DMS failure, all 7 statements were manually converted following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` rule:

1. All schema object names (tables, columns, aliases) converted to lowercase
2. SQL Server-specific functions converted to PostgreSQL equivalents
3. Transaction syntax updated for PostgreSQL compatibility

### SQL Equivalency Tool Status

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) returned `ERROR` with `'uniqueID'` for all 7 statement pairs. This was a consistent tool infrastructure issue, not a statement-specific problem. Each statement was individually validated as required.

---

## Statement-by-Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source Method:** `ProductRepository.GetAllProductsAsync()`
- **SQL Type:** CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase schema objects (Products→products, ProductId→productid, etc.)
- **Equivalency Status:** ERROR (tool infrastructure issue)

### Statement 2: GetProductByIdAsync
- **Source Method:** `ProductRepository.GetProductByIdAsync()`
- **SQL Type:** CTE with LAG window function, LEFT JOIN, CASE with ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase schema objects
- **Equivalency Status:** ERROR (tool infrastructure issue)

### Statement 3: InsertProductAsync
- **Source Method:** `ProductRepository.InsertProductAsync()`
- **SQL Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @NewProductId` → removed (using `lastval()` directly)
- **Equivalency Status:** ERROR (tool infrastructure issue)

### Statement 4: UpdateProductAsync
- **Source Method:** `ProductRepository.UpdateProductAsync()`
- **SQL Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → subquery pattern (PostgreSQL doesn't support DECLARE in plain SQL)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
- **Equivalency Status:** ERROR (tool infrastructure issue)

### Statement 5: DeleteProductAsync
- **Source Method:** `ProductRepository.DeleteProductAsync()`
- **SQL Type:** Transaction block with DECLARE, DELETE, CASE in UPDATE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `DECLARE @OldPrice/@OldStock` → INSERT...SELECT pattern to capture values before DELETE
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - CASE expression preserved (PostgreSQL compatible)
- **Equivalency Status:** ERROR (tool infrastructure issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Source Method:** `ProductRepository.GetProductsByPriceRangeAsync()`
- **SQL Type:** CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase schema objects
- **Equivalency Status:** ERROR (tool infrastructure issue)

### Statement 7: GetLowStockProductsAsync
- **Source Method:** `ProductRepository.GetLowStockProductsAsync()`
- **SQL Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - Lowercase schema objects
  - `StockQuantity / AvgStock` → `stockquantity::numeric / avgstock` (explicit numeric cast for integer division precision in ROUND)
- **Equivalency Status:** ERROR (tool infrastructure issue)

---

## Files Changed

| File | Change Description |
|------|-------------------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `DataAccess/ProductRepository.cs` | Converted 7 SQL statements to PostgreSQL; replaced all SqlClient classes with Npgsql equivalents |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |

### Detailed File Changes

#### AdoCore.csproj
- **Removed:** `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added:** `<PackageReference Include="Npgsql" Version="8.0.6" />`
- **Note:** Npgsql 8.0.0 (specified in plan) had a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c), upgraded to 8.0.6

#### DataAccess/ProductRepository.cs
- **Import:** `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **Field:** `private SqlConnection _connection;` → `private NpgsqlConnection _connection;`
- **Method:** `Task<SqlConnection> GetConnectionAsync()` → `Task<NpgsqlConnection> GetConnectionAsync()`
- **Constructor:** `new SqlConnection(...)` → `new NpgsqlConnection(...)`
- **Commands:** `new SqlCommand(...)` → `new NpgsqlCommand(...)` (7 instances)
- **Reader:** `MapProductFromReader(SqlDataReader reader)` → `MapProductFromReader(NpgsqlDataReader reader)`
- **SQL Strings:** All 7 SQL statements converted to PostgreSQL syntax

#### appsettings.json
- **DevConnection:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection:** Same transformation as DevConnection

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Project root | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency validation report with all 7 statement pairs |
| `migration_report.md` | Project root | This report |

---

## Build Status

- **Final Build:** ✅ **SUCCESS** (0 errors, 10 warnings)
- All warnings are pre-existing nullable reference warnings, not related to the migration
- No vulnerability warnings after Npgsql upgrade to 8.0.6

---

## Items Requiring Manual Review

1. **SQL Equivalency Validation:** All 7 statement pairs returned ERROR from the equivalency tool due to infrastructure issues. Manual review of the converted SQL statements is recommended to verify semantic equivalence.

2. **Transaction Block Conversions (Statements 3, 4, 5):** The original MS SQL used `DECLARE @var` for local variables within transaction blocks. Since PostgreSQL plain SQL doesn't support variable declarations outside PL/pgSQL, these were converted to use subqueries and `lastval()`. This is a significant structural change that should be verified against the actual PostgreSQL database.

3. **Integer Division in Statement 7:** Added explicit `::numeric` cast for `stockquantity / avgstock` to ensure proper decimal division for the ROUND function in PostgreSQL (integer division in PostgreSQL truncates).

4. **Connection String Credentials:** The connection strings use placeholder values (`postgres`/`postgres`). These should be updated with actual credentials before production deployment.
