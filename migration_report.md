# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successful DMS conversions | 0 |
| Manual conversions (DMS failure) | 7 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with `schema_name='dbo'`. All 7 returned the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

As per the migration plan, manual conversion was applied with lowercase schema object names, documented with reason `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
The equivalency statuses in the report are recorded exactly as returned by the tool.

---

## File-by-File Change Summary

### 1. DataAccess/ProductRepository.cs
**Changes:**
- **Using directive**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **ADO.NET class replacements**:
  - `SqlConnection` → `NpgsqlConnection` (field declaration, `GetConnectionAsync()` return type and constructor)
  - `SqlCommand` → `NpgsqlCommand` (7 method usages)
  - `SqlDataReader` → `NpgsqlDataReader` (`MapProductFromReader` parameter type)
- **SQL Statement 1 (GetAllProductsAsync)**: CTE with window functions - schema objects lowercased (Products→products, ProductId→productid, Price→price, etc.)
- **SQL Statement 2 (GetProductByIdAsync)**: CTE with LAG window functions - schema objects lowercased
- **SQL Statement 3 (InsertProductAsync)**: Transaction block converted from T-SQL (DECLARE/SCOPE_IDENTITY/GETDATE) to PostgreSQL writable CTE with RETURNING/NOW()
- **SQL Statement 4 (UpdateProductAsync)**: Transaction block converted from T-SQL (DECLARE/@var) to PostgreSQL writable CTE with old_values subquery/NOW()
- **SQL Statement 5 (DeleteProductAsync)**: Transaction block converted from T-SQL (DECLARE/@var) to PostgreSQL writable CTE with old_values subquery/NOW()
- **SQL Statement 6 (GetProductsByPriceRangeAsync)**: CTE with RANK/PERCENT_RANK - schema objects lowercased
- **SQL Statement 7 (GetLowStockProductsAsync)**: CTE with AVG/MIN/MAX window functions - schema objects lowercased, added CAST(stockquantity AS NUMERIC) for proper integer division

### 2. AdoCore.csproj
**Changes:**
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`
- **Note**: Version 8.0.6 used instead of 8.0.1 to address known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)
- **Unchanged**: Microsoft.Extensions.Configuration 8.0.0, Microsoft.Extensions.Configuration.Json 8.0.0, Microsoft.Extensions.DependencyInjection 8.0.0

### 3. appsettings.json
**Changes:**
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same transformation as DevConnection
- **Removed SQL Server parameters**: `Server=`, `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`
- **Added PostgreSQL parameters**: `Host=`, `Username=`, `Password=`

### 4. Files NOT Modified (no database-specific code)
- Program.cs
- Business/ProductService.cs
- CLI/CommandLineInterface.cs
- CLI/InteractiveMenu.cs
- Models/Product.cs

---

## SQL Conversion Details

### Key T-SQL to PostgreSQL Conversions Applied

| T-SQL Feature | PostgreSQL Equivalent |
|--------------|----------------------|
| `SCOPE_IDENTITY()` | `INSERT ... RETURNING productid` (writable CTE) |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE` | Eliminated via writable CTEs |
| `SET @var = SCOPE_IDENTITY()` | Writable CTE with RETURNING |
| `SELECT @var = col FROM table` | CTE subquery (`WITH old_values AS (SELECT ...)`) |
| `BEGIN TRANSACTION ... COMMIT` | Writable CTE (single atomic statement) |
| `DECIMAL(18,2)` | `NUMERIC(18,2)` |
| Integer division `(int/int)` | `CAST(x AS NUMERIC) / y` |
| Schema objects (PascalCase) | Lowercase (PostgreSQL convention) |

### Statements Requiring Manual Intervention

All 7 statements required manual intervention due to DMS tool failure. Manual conversion applied the following rules:
1. All schema object names converted to lowercase
2. T-SQL specific functions replaced with PostgreSQL equivalents
3. Transaction blocks restructured using writable CTEs
4. Variable declarations eliminated through CTE-based approach

---

## Final Validation Results

| Check | Result |
|-------|--------|
| No `Microsoft.Data.SqlClient` references in .cs files | ✅ PASS |
| No `SqlConnection`/`SqlCommand`/`SqlDataReader`/`SqlParameter` in .cs files | ✅ PASS |
| No SQL Server connection string format in appsettings.json | ✅ PASS |
| `Npgsql` package reference exists in .csproj | ✅ PASS (8.0.6) |
| All 7 SQL statement pairs in equivalency report | ✅ PASS |
| Project compiles successfully | ✅ PASS (0 errors) |

---

## Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Complete equivalency validation report |
| migration_report.md | sourceCode/ | This report |

---

## Build Result
```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```
All warnings are pre-existing nullable reference type warnings, not introduced by the migration.
