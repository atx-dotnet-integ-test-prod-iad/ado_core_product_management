# Migration Report: MS SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET ADO.NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating database driver packages, replacing ADO.NET class references, and updating connection string configurations.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS Tool | 0 |
| Requiring Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

### DMS Tool Status
The DMS MCP tool (dms-mcp___statement_conversion_tool) was invoked for all 7 statements but consistently failed with timeout errors:
- **Error**: "Metadata model creation/conversion did not complete after 15 attempts"
- **Root Cause**: DMS metadata model creation and conversion operations timed out for all statements
- **Fallback**: Manual conversion was performed with lowercase schema object names per transformation rules

### SQL Equivalency Tool Status
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was invoked for all 7 statement pairs but returned ERROR for all:
- **Error**: "'uniqueID'" for all statement pairs
- **Root Cause**: Appears to be an infrastructure/tool issue, not a conversion quality issue
- **Note**: All equivalency statuses are recorded as ERROR as returned by the tool

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, ADO.NET classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 replaced with Npgsql 8.0.6 |
| `appsettings.json` | Connection strings converted from SQL Server to PostgreSQL format |

## Package Dependency Changes

| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |
| Microsoft.Extensions.Configuration 8.0.0 | Microsoft.Extensions.Configuration 8.0.0 (unchanged) |
| Microsoft.Extensions.Configuration.Json 8.0.0 | Microsoft.Extensions.Configuration.Json 8.0.0 (unchanged) |
| Microsoft.Extensions.DependencyInjection 8.0.0 | Microsoft.Extensions.DependencyInjection 8.0.0 (unchanged) |

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL/Npgsql)
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres
```

### Mapping Details
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | Removed - replaced with `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable to PostgreSQL) |
| `TrustServerCertificate=True` | Removed |

## Class Replacement Summary

| SQL Server (Microsoft.Data.SqlClient) | PostgreSQL (Npgsql) |
|---------------------------------------|---------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Key Changes**: All schema objects lowercased (Products→products, ProductId→productid, etc.)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, ROUND
- **Key Changes**: All schema objects lowercased, LAG window function compatible
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING` with CTE chain
  - `GETDATE()` → `NOW()`
  - `DECLARE @variable` / `SET @variable` → CTE-based approach
  - `BEGIN TRANSACTION` / `COMMIT` → Single CTE with data-modifying statements
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, GETDATE()
- **Key Changes**:
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - Transaction block → CTE with data-modifying statements
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO, INSERT, DELETE, CASE, GETDATE()
- **Key Changes**:
  - Same patterns as Statement 4
  - `CASE` expression in UPDATE compatible with PostgreSQL
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Key Changes**: All schema objects lowercased, window functions compatible
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX OVER(), CASE, ROUND
- **Key Changes**: All schema objects lowercased, added `::numeric` cast for integer division in ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Reference Scripts Note
The following SQL script files exist in the project but are reference/setup scripts and were NOT modified during this migration:
- `Database/Scripts/01_InitialSetup.sql` - Database and table creation script (SQL Server syntax)
- `Scripts/01_InitialSetup.sql` - Simplified setup script (SQL Server syntax)

These scripts would need separate conversion if used to provision the PostgreSQL database.

## Transformation Artifacts
1. `extracted_statements.sql` - All 7 original MS SQL statements with documentation
2. `converted_statements.sql` - All 7 converted PostgreSQL statements with conversion notes
3. `sql_equivalency_validation_report.json` - Complete equivalency validation report for all 7 pairs
4. `migration_report.md` - This report
5. `dms_conversion_log.md` - Detailed DMS tool invocation log

## Post-Validation Fix: DataReader Column Name Casing

During post-migration validation, a runtime compatibility issue was identified and fixed in the `MapProductFromReader` method of `DataAccess/ProductRepository.cs`:

- **Issue**: The `MapProductFromReader` method referenced column names using PascalCase (e.g., `reader["ProductId"]`, `reader["Name"]`), but all SQL queries were converted to use lowercase column names (e.g., `productid`, `name`). PostgreSQL returns column names in lowercase, which would cause `KeyNotFoundException` at runtime.
- **Fix**: Updated all `reader["ColumnName"]` references to use lowercase column names matching the converted SQL statements:
  - `reader["ProductId"]` → `reader["productid"]`
  - `reader["Name"]` → `reader["name"]`
  - `reader["Description"]` → `reader["description"]`
  - `reader["Price"]` → `reader["price"]`
  - `reader["StockQuantity"]` → `reader["stockquantity"]`
  - `reader["CreatedDate"]` → `reader["createddate"]`
  - `reader["ModifiedDate"]` → `reader["modifieddate"]`

## Build Status
**Final build: SUCCEEDED** (0 errors, 10 warnings - all pre-existing nullable reference type warnings)
