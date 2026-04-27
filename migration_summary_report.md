# Migration Summary Report
## SQL Server to PostgreSQL Migration - AdoCore Application

### Migration Overview
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement database)
- **Target Database**: PostgreSQL 13 (postgres database)
- **Migration Date**: 2026-04-27

---

### SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Tool Conversion Successes | 0 |
| DMS Tool Conversion Failures | 7 |
| Manual Conversions (DMS Failure) | 7 |
| Equivalency Validated as EQUIVALENT | 0 |
| Equivalency Validated as NOT_EQUIVALENT | 0 |
| Equivalency Validated as ERROR | 7 |

### DMS Tool Status
- **Statement Conversion Tool**: FAILED for all 7 statements
  - Error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
  - Multiple retry attempts with increased poll intervals (15s, 20s, 30s) all failed
- **Schema Mapping Tool**: SUCCESS
  - Successfully retrieved schema mappings for Products, ProductHistory, ProductStats tables
  - Schema mapping: `dbo.Products` → `productmanagement_dbo.products` (lowercase)

### SQL Equivalency Tool Status
- **Tool Status**: ERROR for all 7 statement pairs
  - Consistent error: "'uniqueID'" (service-level error)
  - All 7 pairs were submitted as required; error is a tool-side issue, not a statement issue

### Conversion Method Applied
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Schema Mapping Source**: DMS schema_mapping_tool (successful) provided target schema names

### Key SQL Conversions Applied

| MS SQL Server | PostgreSQL | Statements Affected |
|---------------|-----------|-------------------|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` (CTE) | Statement 3 (Insert) |
| `GETDATE()` | `NOW()` | Statements 3, 4, 5 |
| `DECLARE @var / SET @var` | CTE `WITH old_values AS (...)` | Statements 3, 4, 5 |
| `BEGIN TRANSACTION / COMMIT` | Removed (C# transaction management) | Statements 3, 4, 5 |
| PascalCase identifiers | lowercase identifiers | All 7 statements |
| `StockQuantity / AvgStock` | `stockquantity::NUMERIC / avgstock` | Statement 7 |
| Column reader `["ProductId"]` | Column reader `["productid"]` | MapProductFromReader |

### Statements Converted (Detail)

1. **GetAllProductsAsync()** - CTE with AVG/COUNT window functions → lowercase identifiers
2. **GetProductByIdAsync()** - CTE with LAG window function → lowercase identifiers
3. **InsertProductAsync()** - Transaction block → CTE with INSERT...RETURNING, NOW()
4. **UpdateProductAsync()** - Transaction block with DECLARE → CTE with old_values, NOW()
5. **DeleteProductAsync()** - Transaction block with DECLARE → CTE with old_values, NOW()
6. **GetProductsByPriceRangeAsync()** - CTE with RANK/PERCENT_RANK → lowercase identifiers
7. **GetLowStockProductsAsync()** - CTE with AVG/MIN/MAX → lowercase, NUMERIC cast

---

### Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.9 |

> Note: Npgsql 8.0.9 used instead of 8.0.1 (specified in plan) to avoid known vulnerability GHSA-x9vc-6hfv-hg8c.

### ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 4 (field, return type, constructor, new) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

### Connection String Changes

| Parameter | Before | After |
|-----------|--------|-------|
| Server | `Server=localhost` | `Host=localhost` |
| Port | N/A | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed |
| TLS | `TrustServerCertificate=True` | Removed |

---

### Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient → Npgsql |
| `DataAccess/ProductRepository.cs` | SQL statements (7), imports, ADO.NET classes, column reader names |
| `appsettings.json` | Connection strings (DevConnection, ProdConnection) |

### New Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements with source locations |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements with originals |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report for all 7 statement pairs |
| `migration_summary_report.md` | This migration summary report |

### Build Status
- **Final Build**: ✅ SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **All Steps**: Completed successfully (Steps 1-6)

### Statements Requiring Manual Review
All 7 statements were manually converted due to DMS tool failure and equivalency tool errors:
- All statements should be reviewed for correctness against the PostgreSQL target schema
- CTE-based approach for INSERT/UPDATE/DELETE (Statements 3, 4, 5) uses writable CTEs which require PostgreSQL 9.1+
- The `@param` syntax in SQL strings is compatible with Npgsql's parameter handling
