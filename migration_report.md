# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Conversion Successful | 0 |
| DMS Conversion Failed (Manual Override) | 7 |
| SQL Equivalency: Equivalent | 0 |
| SQL Equivalency: Not Equivalent | 0 |
| SQL Equivalency: Error | 7 |
| Files Modified | 3 |
| Files Created (Artifacts) | 5 |
| Build Status | Success (0 errors, 10 warnings) |

## DMS Tool Results

### Statement Conversion Tool (dms-mcp___statement_conversion_tool)
- **Status**: FAILED for all 7 statements
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Action Taken**: Manual conversion applied using DMS schema mapping results with lowercase schema object names
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### Schema Mapping Tool (dms-mcp___schema_mapping_tool)
- **Status**: SUCCEEDED for all 3 tables
- **Mappings**:
  - `dbo.Products` → `productmanagement_dbo.products` (all columns lowercase)
  - `dbo.ProductHistory` → `productmanagement_dbo.producthistory` (all columns lowercase)
  - `dbo.ProductStats` → `productmanagement_dbo.productstats` (all columns lowercase)

## SQL Equivalency Validation

### Tool: sql-equivalency___validate_sql_equivalence
- **Status**: All 7 statement pairs returned ERROR
- **Error**: `'uniqueID'` (tool-side configuration issue)
- **Action Taken**: All errors documented as-is per transformation definition requirements
- **Agent Judgment Used**: NO - all statuses come directly from the tool

### Detailed Results

| # | Method | Statement | Equivalency |
|---|--------|-----------|-------------|
| 1 | GetAllProductsAsync | CTE with AVG/COUNT window functions | ERROR |
| 2 | GetProductByIdAsync | CTE with LAG window function | ERROR |
| 3 | InsertProductAsync | Transaction block → Writeable CTE | ERROR |
| 4 | UpdateProductAsync | Transaction block → Writeable CTE | ERROR |
| 5 | DeleteProductAsync | Transaction block → Writeable CTE | ERROR |
| 6 | GetProductsByPriceRangeAsync | CTE with RANK/PERCENT_RANK | ERROR |
| 7 | GetLowStockProductsAsync | CTE with AVG/MIN/MAX window functions | ERROR |

Full details are in `sql_equivalency_validation_report.json`.

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **SQL Server Constructs**: CTE, AVG/COUNT window functions, CASE, ROUND, INNER JOIN, ORDER BY
- **PostgreSQL Changes**: Table/column names to lowercase, CTE alias renamed to avoid table conflict
- **Key Conversions**: `Products` → `products`, `ProductId` → `productid`, etc.

### Statement 2: GetProductByIdAsync
- **SQL Server Constructs**: CTE, LAG window function, CASE, ROUND, LEFT JOIN
- **PostgreSQL Changes**: Table/column names to lowercase, CTE alias renamed
- **Key Conversions**: `Products` → `products`, `@ProductId` parameter preserved

### Statement 3: InsertProductAsync
- **SQL Server Constructs**: DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE, COMMIT
- **PostgreSQL Changes**: Restructured to writeable CTE with RETURNING clause
- **Key Conversions**:
  - `DECLARE @NewProductId INT` + `SCOPE_IDENTITY()` → `INSERT ... RETURNING productid`
  - `BEGIN TRANSACTION` / `COMMIT` → Single atomic CTE statement
  - `GETDATE()` → `NOW()`
  - All table/column names to lowercase

### Statement 4: UpdateProductAsync
- **SQL Server Constructs**: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **PostgreSQL Changes**: Restructured to writeable CTE capturing old values
- **Key Conversions**:
  - `DECLARE @OldPrice` / `SELECT @OldPrice = Price` → CTE `old_values`
  - `BEGIN TRANSACTION` / `COMMIT` → Single atomic CTE statement
  - `GETDATE()` → `NOW()`

### Statement 5: DeleteProductAsync
- **SQL Server Constructs**: BEGIN TRANSACTION, DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE, CASE, GETDATE()
- **PostgreSQL Changes**: Restructured to writeable CTE capturing old values before delete
- **Key Conversions**:
  - `DECLARE @OldPrice` / `SELECT @OldPrice = Price` → CTE `old_values`
  - `DELETE FROM Products` → `DELETE FROM products ... RETURNING productid`
  - `GETDATE()` → `NOW()`

### Statement 6: GetProductsByPriceRangeAsync
- **SQL Server Constructs**: CTE, RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **PostgreSQL Changes**: Table/column names to lowercase
- **Key Conversions**: Direct 1:1 translation with lowercase names

### Statement 7: GetLowStockProductsAsync
- **SQL Server Constructs**: CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **PostgreSQL Changes**: Table/column names to lowercase, integer division fix
- **Key Conversions**:
  - `ROUND((StockQuantity / AvgStock) * 100, 2)` → `ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2)`
  - CAST added to prevent integer division in PostgreSQL

## File Changes

### Modified Files

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements replaced with PostgreSQL equivalents; SqlClient → Npgsql classes; column references to lowercase |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | SQL Server connection strings → PostgreSQL format |

### Created Artifacts

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `dms_failure_summary.sql` | DMS failure documentation |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
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
| MARS | `MultipleActiveResultSets=true` | Removed (N/A) |
| TLS | `TrustServerCertificate=True` | Removed |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `Microsoft.Data.SqlClient` (namespace) | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Manual Interventions Required

All 7 SQL statements required manual conversion due to DMS statement_conversion_tool failure. The conversions were guided by:
1. DMS schema_mapping_tool results (for correct table/column name mappings)
2. Standard SQL Server → PostgreSQL conversion rules
3. Lowercase schema naming convention as per DMS schema mappings

## Known Issues and Recommendations

1. **SQL Equivalency Validation**: All 7 statement pairs returned ERROR from the equivalency tool due to a `'uniqueID'` error. Manual review of the converted statements is recommended.

2. **Writeable CTEs**: Statements 3, 4, and 5 use PostgreSQL writeable CTEs (data-modifying CTEs). These are a PostgreSQL-specific feature and should be tested against the actual database.

3. **Connection String Credentials**: The placeholder credentials (`Username=postgres;Password=postgres`) should be replaced with actual production credentials or environment variable references.

4. **Integer Division**: Statement 7 includes an explicit CAST to NUMERIC to prevent integer division in PostgreSQL (SQL Server performs implicit decimal division).

## Build Verification

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All warnings are pre-existing nullable reference warnings, not introduced by the migration.
