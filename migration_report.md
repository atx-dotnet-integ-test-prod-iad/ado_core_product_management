# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved transforming all SQL statements, database access code, package dependencies, and connection strings.

## SQL Statement Conversion Statistics

| Metric | Count |
|--------|-------|
| **Total SQL statements processed** | 7 |
| **Statements successfully converted by DMS MCP tool** | 0 |
| **Statements requiring manual intervention after DMS failure** | 7 |
| **Statements validated as equivalent (SQL Equivalency tool)** | 0 |
| **Statements validated as non-equivalent** | 0 |
| **Statements with equivalency validation errors** | 7 |

### DMS Tool Status
All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with migration project ARN `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`. All failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol, converting all schema object names to lowercase for PostgreSQL compatibility.

### SQL Equivalency Tool Status
All 7 statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned `ERROR` status with error `'uniqueID'`.

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure on all conversions
2. Equivalency tool returning ERROR on all validations

| # | Method | Conversion Method | Equivalency Status |
|---|--------|-------------------|-------------------|
| 1 | GetAllProductsAsync() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 2 | GetProductByIdAsync() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 3 | InsertProductAsync() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 4 | UpdateProductAsync() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 5 | DeleteProductAsync() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 6 | GetProductsByPriceRangeAsync() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 7 | GetLowStockProductsAsync() | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |

## Key Conversion Details

### T-SQL to PostgreSQL Conversions Applied
| T-SQL Construct | PostgreSQL Equivalent |
|----------------|----------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var / SET @var` | Removed; handled in C# code |
| `BEGIN TRANSACTION / COMMIT` | Removed from SQL; managed via `NpgsqlTransaction` API |
| Table names (Products, ProductHistory, ProductStats) | Lowercase (products, producthistory, productstats) |
| Column names (ProductId, Name, Price, etc.) | Lowercase (productid, name, price, etc.) |
| `INT IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `DATETIME` | `TIMESTAMP` |

### Transaction Restructuring
Methods `InsertProductAsync`, `UpdateProductAsync`, and `DeleteProductAsync` were restructured:
- Multi-statement T-SQL blocks split into individual SQL statements
- Transaction management moved from SQL strings to C# code using `NpgsqlTransaction` API
- Added `try/catch` with `CommitAsync()` and `RollbackAsync()`

## Files Changed

### 1. DataAccess/ProductRepository.cs
- **Using statement**: `Microsoft.Data.SqlClient` → `Npgsql`
- **Type replacements**: `SqlConnection` → `NpgsqlConnection`, `SqlCommand` → `NpgsqlCommand`, `SqlDataReader` → `NpgsqlDataReader`
- **SQL statements**: All 7 replaced with PostgreSQL equivalents (lowercase schema objects)
- **Transaction restructuring**: 3 methods restructured to use `NpgsqlTransaction` API
- **MapProductFromReader**: Column name references updated to lowercase

### 2. AdoCore.csproj
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.5" />`
- Note: Version 8.0.5 used instead of 8.0.0 to address known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)

### 3. appsettings.json
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=postgres;Username=postgres;Password=postgres`

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements cataloged |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements cataloged |
| sql_equivalency_validation_report.json | sourceCode/ | All 7 statement pairs with equivalency status |
| migration_report.md | sourceCode/ | This report |

## Build Status

- **dotnet build**: ✅ Succeeded with 0 errors, 10 warnings (all pre-existing nullable reference warnings)
- **No remaining SQL Server references** in any .cs or .csproj file

## Final Validation Checklist

1. ✅ All SQL Server packages replaced with PostgreSQL equivalents
2. ✅ All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents
3. ✅ All 7 SQL statements processed through DMS MCP tool (all failed, manual conversion applied)
4. ✅ All 7 statement pairs validated through SQL Equivalency tool (all returned ERROR)
5. ✅ Connection strings updated to PostgreSQL format
6. ✅ Transaction handling updated to use NpgsqlTransaction API
7. ✅ All GETDATE() replaced with NOW()
8. ✅ All SCOPE_IDENTITY() replaced with RETURNING
9. ✅ T-SQL DECLARE/SET patterns removed and restructured
