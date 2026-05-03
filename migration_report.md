# AdoCore Migration Report: Microsoft SQL Server → PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-05-03 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Type** | .NET 9.0 ADO.NET Console Application |
| **Package Migration** | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |

## SQL Statement Processing

### Total Statements

| Category | Count |
|----------|-------|
| **Total SQL statements processed** | 13 |
| **Statements from ProductRepository.cs** | 7 |
| **Statements from SQL setup scripts** | 6 |
| **Statements successfully converted by DMS** | 0 |
| **Statements requiring manual intervention** | 13 |
| **Statements validated as equivalent** | 0 |
| **Statements validated as non-equivalent** | 0 |
| **Statements with equivalency validation errors** | 13 |

### DMS Tool Status

The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) consistently failed for ALL statements with the following error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple retry attempts were made with varying poll configurations (15-30 attempts, 10-20 second intervals). All attempts failed.

**DMS Schema Mapping Tool** (`dms-mcp___schema_mapping_tool`) **succeeded** and was used to obtain the correct target schema naming conventions:
- Schema: `dbo` → `productmanagement_dbo`
- Table/column names: All converted to lowercase
- Data types properly mapped (e.g., `IDENTITY` → `GENERATED ALWAYS AS IDENTITY`, `nvarchar` → `varchar`, `bit` → `numeric(1,0)`)

### SQL Equivalency Tool Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) consistently returned ERROR with `'uniqueID'` for ALL statement pairs. This appears to be a service-side issue unrelated to the statements themselves. All 13 statement pairs were submitted to the tool and the ERROR status was recorded directly from the tool output.

### Manual Conversion Approach

Since DMS failed, all statements were manually converted applying:
1. **Lowercase schema object names** per DMS schema mapping output
2. **SQL Server to PostgreSQL syntax conversions**:
   - `SCOPE_IDENTITY()` → `RETURNING` clause
   - `GETDATE()` → `NOW()`
   - `DECLARE @var` → C# managed variables / PostgreSQL `DECLARE`
   - `BEGIN TRANSACTION` / `COMMIT` → C# `BeginTransactionAsync()` / `CommitAsync()`
   - `ROUND` with integer division → `CAST` to `NUMERIC` for proper division
   - `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
   - `NVARCHAR(n)` → `VARCHAR(n)`
   - `BIT` → `NUMERIC(1,0)`
   - `DATETIME` → `TIMESTAMP WITHOUT TIME ZONE`
   - SQL Server stored procedures → PostgreSQL functions (plpgsql)
   - SQL Server triggers (inserted/deleted) → PostgreSQL trigger functions (NEW/OLD + TG_OP)
   - `SYSTEM_USER` → `CURRENT_USER`

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL; SqlClient → Npgsql; column name references lowercased; transaction blocks restructured |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Complete conversion to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Complete conversion to PostgreSQL syntax |

## Files NOT Modified (No SQL Server Dependencies)

- `Program.cs` - No SQL client references
- `Business/ProductService.cs` - No SQL client references
- `Models/Product.cs` - No SQL client references
- `CLI/CommandLineInterface.cs` - No SQL client references
- `CLI/InteractiveMenu.cs` - No SQL client references

## Package Dependency Changes

```xml
<!-- Removed -->
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />

<!-- Added -->
<PackageReference Include="Npgsql" Version="8.0.6" />
```

Note: Version 8.0.6 was selected instead of 8.0.0 to resolve a known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c).

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server | PostgreSQL |
|-----------|-----------|
| `Server=` | `Host=` |
| `Database=` | `Database=` (unchanged) |
| `Trusted_Connection=True` | Removed (use Username/Password) |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed |
| N/A | `Username=postgres` (added) |
| N/A | `Password=postgres` (added) |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

## Schema Mapping (from DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) |
|-------------------|-------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |
| `dbo.Categories` | `productmanagement_dbo.categories` |
| `dbo.Suppliers` | `productmanagement_dbo.suppliers` |

All column names converted to lowercase (e.g., `ProductId` → `productid`, `StockQuantity` → `stockquantity`).

## Build Verification

**Final Build: SUCCEEDED**
- 0 Errors
- 10 Warnings (all pre-existing nullable reference type warnings from the original codebase)

## Artifacts Generated

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements from ProductRepository.cs |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete validation report with 13 statement pairs |
| `dms_conversion_failure_summary.sql` | Documentation of DMS tool failures |
| `migration_report.md` | This report |

## Statements Requiring Manual Review

All 13 statements should be manually reviewed since:
1. DMS statement conversion tool was unavailable (metadata model creation error)
2. SQL equivalency tool returned ERROR for all pairs (service-side 'uniqueID' error)

The manual conversions follow standard SQL Server → PostgreSQL conversion patterns and were validated against DMS schema mapping output for naming conventions.

## Exit Criteria Verification

| Criteria | Status |
|----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ |
| All SqlClient classes replaced with Npgsql equivalents | ✅ |
| ALL SQL statements processed through DMS tool | ✅ (all attempted, all failed) |
| Comprehensive catalog of all SQL statements | ✅ |
| ALL statement pairs validated through SQL Equivalency tool | ✅ (all attempted, all ERROR) |
| Comprehensive equivalency report generated | ✅ (13 entries) |
| No agent judgment used for equivalency | ✅ (all from tool) |
| DMS failures documented with manual conversion | ✅ |
| Connection strings updated | ✅ |
| Transaction handling updated | ✅ |
| Application compiles without errors | ✅ |
