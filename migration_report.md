# SQL Server to PostgreSQL Migration Report

## Summary

This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Converted by DMS MCP Tool | 0 |
| Statements Requiring Manual Conversion | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |

## DMS MCP Tool Results

All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following configuration:
- **migration_project_identifier**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **database_name**: `ProductManagement`
- **schema_name**: `dbo`
- **region**: `us-east-1`

**All 7 calls failed with the same error:**
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Per the transformation definition, manual conversion was applied with lowercase schema object names (`DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

## SQL Equivalency Tool Results

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 validations returned ERROR status** with error `'uniqueID'`. This is a tool-side error, not a statement-level issue. All equivalency statuses are recorded as-is from the tool output.

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: CTE with window functions (AVG, COUNT)
- **Key Changes**: Schema objects lowercased (Products→products, ProductId→productid, etc.)
- **PostgreSQL Compatibility**: CTE and window functions are fully compatible

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: CTE with LAG window functions
- **Key Changes**: Schema objects lowercased
- **PostgreSQL Compatibility**: LAG window function is fully compatible

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**:
  - `SCOPE_IDENTITY()` → writable CTE with `INSERT...RETURNING`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → single writable CTE (atomic)
  - `DECLARE @var` → eliminated, using CTE chaining
- **PostgreSQL Compatibility**: Writable CTEs are PostgreSQL-specific feature

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction with DECLARE variables, GETDATE()
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice/@OldStock` → CTE `old_values` subquery
  - `BEGIN TRANSACTION/COMMIT` → single writable CTE
- **PostgreSQL Compatibility**: Writable CTEs ensure atomic execution

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction with DECLARE variables, GETDATE(), CASE
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice/@OldStock` → CTE `old_values` subquery
  - `BEGIN TRANSACTION/COMMIT` → single writable CTE
  - CASE expression preserved (compatible)
- **PostgreSQL Compatibility**: Writable CTEs ensure atomic execution

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: CTE with RANK and PERCENT_RANK window functions
- **Key Changes**: Schema objects lowercased
- **PostgreSQL Compatibility**: RANK and PERCENT_RANK are fully compatible

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: CTE with AVG/MIN/MAX window functions
- **Key Changes**: Schema objects lowercased, added `CAST(stockquantity AS NUMERIC)` for integer division in ROUND
- **PostgreSQL Compatibility**: Window functions compatible; explicit CAST needed for numeric precision

## Code Changes

### File: DataAccess/ProductRepository.cs
| Change | From | To |
|--------|------|-----|
| Using directive | `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| Connection field type | `SqlConnection` | `NpgsqlConnection` |
| Command type | `SqlCommand` | `NpgsqlCommand` |
| Reader type | `SqlDataReader` | `NpgsqlDataReader` |
| All 7 SQL statements | MS SQL syntax | PostgreSQL syntax |
| Column name references in MapProductFromReader | PascalCase (`ProductId`) | lowercase (`productid`) |

### File: AdoCore.csproj
| Change | From | To |
|--------|------|-----|
| Package reference | `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

### File: appsettings.json
| Change | From | To |
|--------|------|-----|
| Connection format | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres` |
| Server parameter | `Server=` | `Host=` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Removed parameters | `MultipleActiveResultSets`, `TrustServerCertificate` | N/A |

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency report with all 7 pairs |
| dms_conversion_summary.md | sourceCode/ | DMS failure documentation |
| migration_report.md | sourceCode/ | This report |

## Build Verification

Final build result: **SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference warnings)

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```
