# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL using Npgsql as the ADO.NET data provider.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool processing | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all 7 SQL statements but failed consistently with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN:** `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

Multiple retry attempts were made with varying parameters (increased poll attempts, explicit server name, simplified queries) - all failed with the same error. Per the transformation definition, manual conversion was applied with lowercase schema object names (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was invoked for all 7 statement pairs but returned ERROR for all with:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a service infrastructure issue unrelated to the SQL content quality.

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Method:** `GetAllProductsAsync()`
- **Type:** CTE with window functions (AVG, COUNT OVER), CASE/WHEN, ROUND, INNER JOIN
- **Conversion:** Schema objects lowercased; SQL syntax is PostgreSQL-compatible
- **Key Changes:** `Products` → `products`, `ProductId` → `productid`, `Price` → `price`, etc.

### Statement 2: GetProductByIdAsync
- **Method:** `GetProductByIdAsync(int productId)`
- **Type:** CTE with LAG window function, LEFT JOIN, parameterized query
- **Conversion:** Schema objects lowercased; SQL syntax is PostgreSQL-compatible
- **Key Changes:** `Products` → `products`, `ProductHistory` → `producthistory`

### Statement 3: InsertProductAsync
- **Method:** `InsertProductAsync(Product product)`
- **Type:** Transaction block with SCOPE_IDENTITY(), GETDATE(), multi-table INSERT/UPDATE
- **Conversion:** Significant syntax changes required
- **Key Changes:**
  - `DECLARE @NewProductId INT; SET @NewProductId = SCOPE_IDENTITY();` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Used `currval(pg_get_serial_sequence('products', 'productid'))` for subsequent inserts

### Statement 4: UpdateProductAsync
- **Method:** `UpdateProductAsync(Product product)`
- **Type:** Transaction block with DECLARE variables, SELECT INTO variables, GETDATE()
- **Conversion:** Restructured to eliminate DECLARE/SET pattern
- **Key Changes:**
  - Removed DECLARE/SET variable pattern (not supported in PostgreSQL inline SQL)
  - Used subquery for logging old values in INSERT INTO producthistory
  - Used `SELECT AVG(price) FROM products` for statistics update
  - `GETDATE()` → `NOW()`

### Statement 5: DeleteProductAsync
- **Method:** `DeleteProductAsync(int productId)`
- **Type:** Transaction block with DECLARE variables, CASE expression, DELETE/INSERT/UPDATE
- **Conversion:** Restructured to eliminate DECLARE/SET pattern
- **Key Changes:**
  - Removed DECLARE/SET variable pattern
  - Used subquery to capture values before delete in INSERT INTO producthistory
  - Used `COALESCE(AVG(price), 0)` for safe average calculation after deletion
  - `GETDATE()` → `NOW()`

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type:** CTE with RANK(), PERCENT_RANK() window functions, BETWEEN
- **Conversion:** Schema objects lowercased; SQL syntax is PostgreSQL-compatible
- **Key Changes:** `Products` → `products`, `RankedProducts` → `rankedproducts`

### Statement 7: GetLowStockProductsAsync
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **Type:** CTE with AVG/MIN/MAX OVER() window functions, ROUND
- **Conversion:** Schema objects lowercased; added explicit numeric cast for integer division
- **Key Changes:**
  - `Products` → `products`, `StockAnalysis` → `stockanalysis`
  - `ROUND((StockQuantity / AvgStock) * 100, 2)` → `ROUND((stockquantity::numeric / avgstock) * 100, 2)`

## File Changes Summary

| File | Change |
|------|--------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; SqlClient→Npgsql types |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.3 |
| `appsettings.json` | SQL Server connection string → PostgreSQL format |
| `extracted_statements.sql` | New: catalog of all original MS SQL statements |
| `converted_statements.sql` | New: catalog of all converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | New: comprehensive equivalency validation report |
| `migration_report.md` | New: this report |

## Type Replacements

| SQL Server Type | PostgreSQL (Npgsql) Type |
|-----------------|--------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Transformation

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not supported) |
| Trust Cert | `TrustServerCertificate=True` | Removed (not applicable) |

## Statements Requiring Manual Review

All 7 statements were manually converted due to DMS tool failure and could not be validated for equivalency due to SQL Equivalency tool errors. These should be reviewed against a live PostgreSQL database to confirm functional correctness:

1. **InsertProductAsync** - Complex: Uses RETURNING clause and currval() for cross-statement reference
2. **UpdateProductAsync** - Complex: Restructured from DECLARE/SET pattern to subquery pattern
3. **DeleteProductAsync** - Complex: Restructured from DECLARE/SET pattern with COALESCE safety
4. **GetAllProductsAsync** - Low risk: Only lowercase conversion, syntax unchanged
5. **GetProductByIdAsync** - Low risk: Only lowercase conversion, syntax unchanged
6. **GetProductsByPriceRangeAsync** - Low risk: Only lowercase conversion, syntax unchanged
7. **GetLowStockProductsAsync** - Medium risk: Added ::numeric cast for integer division in ROUND()

## Build Status

✅ The project compiles successfully with 0 errors after all changes.

## Artifacts Generated

1. `extracted_statements.sql` - Complete catalog of all 7 original MS SQL statements
2. `converted_statements.sql` - Complete catalog of all 7 converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency report (all ERROR due to tool issue)
4. `migration_report.md` - This report
