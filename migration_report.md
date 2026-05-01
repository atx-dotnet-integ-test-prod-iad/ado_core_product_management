# AdoCore Migration Report: SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-05-01 |
| **Application** | AdoCore (.NET 9.0 ADO.NET Application) |
| **Source Database** | Microsoft SQL Server |
| **Target Database** | PostgreSQL |
| **Total SQL Statements Processed** | 7 |
| **DMS Tool Conversion Success** | 0 |
| **DMS Tool Conversion Failures** | 7 |
| **Manual Conversions (DMS Failure)** | 7 |
| **SQL Equivalency: EQUIVALENT** | 0 |
| **SQL Equivalency: NOT_EQUIVALENT** | 0 |
| **SQL Equivalency: ERROR** | 7 |

## DMS Tool Conversion Results

All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. All returned the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS schema mapping tool (`dms-mcp___schema_mapping_tool`) was successfully used to retrieve target schema mappings:
- `Products` → `productmanagement_dbo.products` (all lowercase columns)
- `ProductHistory` → `productmanagement_dbo.producthistory` (all lowercase columns)
- `ProductStats` → `productmanagement_dbo.productstats` (all lowercase columns)

Manual conversion was applied using these schema mappings with the reason: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

## SQL Equivalency Validation Results

All 7 statement pairs were validated using the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status with the same error: `'uniqueID'`

**Note**: All equivalency statuses were obtained from the tool output. No agent judgment was used to determine equivalency.

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()` in `ProductRepository.cs`
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Key Changes**: All schema objects lowercased, CTE name changed to `productstats_cte` to avoid conflict with table name
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)` in `ProductRepository.cs`
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, CASE, ROUND, parameterized
- **Key Changes**: All schema objects lowercased, CTE name changed to `producthistory_cte`
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)` in `ProductRepository.cs`
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), multi-table operations
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid` with writable CTE
  - `GETDATE()` → `NOW()`
  - `DECLARE @var / SET @var` → Writable CTE pattern
  - `BEGIN TRANSACTION / COMMIT` → Removed (handled by PostgreSQL writable CTE atomicity)
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)` in `ProductRepository.cs`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, GETDATE()
- **Key Changes**:
  - `DECLARE / SELECT INTO` → Writable CTE with `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION / COMMIT` → Removed
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)` in `ProductRepository.cs`
- **Type**: Transaction block with DECLARE, SELECT INTO, DELETE, CASE, GETDATE()
- **Key Changes**:
  - `DECLARE / SELECT INTO` → Writable CTE with `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION / COMMIT` → Removed
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)` in `ProductRepository.cs`
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE, parameterized
- **Key Changes**: All schema objects lowercased. Window functions are PostgreSQL-compatible.
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)` in `ProductRepository.cs`
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND, parameterized
- **Key Changes**: All schema objects lowercased. Added `::numeric` cast for integer division in ROUND.
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | SQL statements converted to PostgreSQL, ADO.NET types replaced with Npgsql |
| `AdoCore.csproj` | Modified | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Modified | Connection strings updated to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL syntax |

## New Artifacts Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `dms_failure_summary.md` | DMS conversion failure documentation |
| `migration_report.md` | This migration report |

## Package Dependency Changes

| Package | Before | After |
|---------|--------|-------|
| Microsoft.Data.SqlClient | 5.1.4 | **Removed** |
| Npgsql | N/A | **8.0.6** |
| Microsoft.Extensions.Configuration | 8.0.0 | 8.0.0 (unchanged) |
| Microsoft.Extensions.Configuration.Json | 8.0.0 | 8.0.0 (unchanged) |
| Microsoft.Extensions.DependencyInjection | 8.0.0 | 8.0.0 (unchanged) |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Type Replacements

| SQL Server Type | Npgsql Type |
|----------------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool conversion failures (all 7 statements)
2. SQL Equivalency tool errors (all 7 statements)

Manual conversion was applied using lowercase schema mapping rules confirmed by DMS schema_mapping_tool results.

## Build Status

**Final Build: SUCCESS** - 0 errors, 10 warnings (all pre-existing nullable reference warnings)
