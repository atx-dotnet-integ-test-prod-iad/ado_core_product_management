# Migration Report: MS SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL using Npgsql as the ADO.NET data provider.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 7 |

## DMS Tool Conversion Results

All 7 SQL statements were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool) with schema_name='dbo'. All failed with the same error:

**Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

As per the transformation plan, manual conversion was applied using lowercase schema object naming convention (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Validation Results

All 7 statement pairs were validated through the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence). All returned ERROR status:

**Error:** `'uniqueID'`

This represents a tool-level error, not a statement-level incompatibility. The equivalency results should be reviewed when the tool is operational.

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure preventing automated conversion verification
2. SQL Equivalency tool returning ERROR status for all pairs

### Statement Details

| # | Method | Type | Key Conversion |
|---|--------|------|----------------|
| 1 | GetAllProductsAsync | CTE + Window Functions | Table/column names to lowercase |
| 2 | GetProductByIdAsync | CTE + LAG Window Function | Table/column names to lowercase |
| 3 | InsertProductAsync | Transaction Block | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW() |
| 4 | UpdateProductAsync | Transaction Block | DECLARE @var → C# variables, GETDATE() → NOW() |
| 5 | DeleteProductAsync | Transaction Block | DECLARE @var → C# variables, GETDATE() → NOW() |
| 6 | GetProductsByPriceRangeAsync | CTE + RANK/PERCENT_RANK | Table/column names to lowercase |
| 7 | GetLowStockProductsAsync | CTE + AVG/MIN/MAX | Table/column names to lowercase, ::numeric cast |

## Key Conversion Patterns Applied

### SQL Syntax
- `SCOPE_IDENTITY()` → `RETURNING productid` clause
- `GETDATE()` → `NOW()`
- `DECLARE @variable` → C# variable with separate SELECT query
- `BEGIN TRANSACTION / COMMIT` → C# managed `BeginTransactionAsync()` / `CommitAsync()`
- Integer division in `ROUND()` → Explicit `::numeric` cast

### Schema Object Names
- All table names converted to lowercase: `Products` → `products`, `ProductHistory` → `producthistory`, `ProductStats` → `productstats`
- All column names converted to lowercase: `ProductId` → `productid`, `StockQuantity` → `stockquantity`, etc.
- All CTE names converted to lowercase: `ProductStats` → `productstats`, `RankedProducts` → `rankedproducts`, etc.

### Package Dependencies
- `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6`

### ADO.NET Classes
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`
- `SqlParameter` → `NpgsqlParameter`

### Connection Strings
- `Server=` → `Host=`
- `Trusted_Connection=True` → `Username=postgres;Password=postgres`
- Removed: `MultipleActiveResultSets=true`, `TrustServerCertificate=True`

## File Changes Summary

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL, ADO.NET classes replaced with Npgsql |
| `AdoCore.csproj` | Microsoft.Data.SqlClient → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

## Migration Artifacts

| Artifact | Status |
|----------|--------|
| `extracted_statements.sql` | ✅ Created - Contains all 7 original MS SQL statements |
| `converted_statements.sql` | ✅ Created - Contains all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | ✅ Created - Contains validation results for all 7 pairs |
| `migration_report.md` | ✅ Created - This document |

## Build Status

The application compiles successfully after all changes:
- **Build Result:** Success (0 errors, 10 warnings)
- **Warnings:** Pre-existing nullable reference warnings only (CS8618, CS8601, CS8600, CS8603, CS8625)

## Notes

1. **Database/Scripts/01_InitialSetup.sql**: This SQL Server setup script remains unchanged as it serves as reference documentation. If a PostgreSQL equivalent is needed for the target database, it should be converted separately to create the lowercase schema tables.

2. **Transaction Management**: The original MS SQL used inline T-SQL transaction blocks. These were restructured to use C# managed transactions (`BeginTransactionAsync`/`CommitAsync`/`RollbackAsync`) which is the recommended pattern for Npgsql and ensures proper cleanup.

3. **Parameter Syntax**: Npgsql supports the `@ParameterName` syntax, so parameter placeholders work without modification.
