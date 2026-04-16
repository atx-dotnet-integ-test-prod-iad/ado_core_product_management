# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| Migration Date | 2026-04-16 |
| Source Database | Microsoft SQL Server 2019 |
| Target Database | PostgreSQL 13 |
| Application Framework | .NET 9.0 / ADO.NET |
| Source Package | Microsoft.Data.SqlClient 5.1.4 |
| Target Package | Npgsql 8.0.9 |

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, using statement updated, ADO.NET types replaced |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient to Npgsql |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Manually Converted (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

### DMS Tool Failure Details

All 7 SQL statements were submitted to the DMS MCP statement_conversion_tool (migration project ARN: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`). All returned the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple retry attempts were made with different configurations (varying poll intervals, explicit database names, server names). The DMS Schema Mapping tool was successfully used to confirm target schema mappings.

### SQL Equivalency Tool Results

All 7 statement pairs were submitted to the SQL Equivalency validation tool. All returned the same systemic error:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

### Manual Conversion Approach

Since DMS failed for all statements, manual conversion was applied following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach:

1. All schema object names (tables, columns, aliases) converted to lowercase
2. SQL Server-specific syntax converted to PostgreSQL equivalents:
   - `SCOPE_IDENTITY()` → `RETURNING` clause + `currval(pg_get_serial_sequence(...))`
   - `GETDATE()` → `NOW()`
   - `BEGIN TRANSACTION` / `COMMIT` → `BEGIN` / `COMMIT`
   - `DECLARE @var` / `SET @var` → Eliminated using subqueries and CTEs
   - `ROUND()` with integer operands → Added `CAST(... AS NUMERIC)` for proper decimal division

### Schema Mapping (Confirmed via DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `[dbo].[Products]` | `products` |
| `[dbo].[ProductHistory]` | `producthistory` |
| `[dbo].[ProductStats]` | `productstats` |

Column names confirmed lowercase: `productid`, `name`, `description`, `price`, `stockquantity`, `createddate`, `modifieddate`, etc.

## Statement-by-Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Conversion**: Schema objects lowercased. SQL syntax compatible with PostgreSQL (CTEs, window functions, CASE, ROUND all work natively).
- **DMS Result**: Error
- **Equivalency Result**: ERROR

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE, LAG window function, CASE, ROUND, LEFT JOIN
- **Parameters**: `@ProductId`
- **Conversion**: Schema objects lowercased. LAG, ROUND, CASE all PostgreSQL-compatible.
- **DMS Result**: Error
- **Equivalency Result**: ERROR

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(), multi-table operations
- **Parameters**: `@Name`, `@Description`, `@Price`, `@StockQuantity`
- **Conversion**: Major restructuring required:
  - `DECLARE @NewProductId` + `SET @NewProductId = SCOPE_IDENTITY()` → CTE with `INSERT ... RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `SELECT @NewProductId` → `SELECT currval(pg_get_serial_sequence('products', 'productid'))`
- **DMS Result**: Error
- **Equivalency Result**: ERROR

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE variables, SELECT INTO variables, UPDATE, INSERT
- **Parameters**: `@ProductId`, `@Name`, `@Description`, `@Price`, `@StockQuantity`
- **Conversion**: 
  - `DECLARE @OldPrice` / `SELECT @OldPrice = ...` → Replaced with subquery-based INSERT ... SELECT
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
- **DMS Result**: Error
- **Equivalency Result**: ERROR

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO, INSERT, DELETE, UPDATE with CASE
- **Parameters**: `@ProductId`
- **Conversion**:
  - `DECLARE @OldPrice` / `SELECT @OldPrice = ...` → INSERT ... SELECT to capture values before delete
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Statistics UPDATE references producthistory for deleted product price
- **DMS Result**: Error
- **Equivalency Result**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK, PERCENT_RANK, BETWEEN, CASE
- **Parameters**: `@MinPrice`, `@MaxPrice`
- **Conversion**: Schema objects lowercased. RANK, PERCENT_RANK, BETWEEN, CASE all PostgreSQL-compatible.
- **DMS Result**: Error
- **Equivalency Result**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Parameters**: `@Threshold`
- **Conversion**: Schema objects lowercased. Added `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation in ROUND expression.
- **DMS Result**: Error
- **Equivalency Result**: ERROR

## Package Dependency Changes

| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.9 |

Note: Plan specified Npgsql 8.0.1 but it has a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c). Upgraded to 8.0.9 for security compliance.

## Connection String Migration

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Class Replacement Summary

| SQL Server Type | Npgsql Equivalent | Occurrences |
|----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Project root | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency report with all 7 statement pairs |
| `migration_report.md` | Project root | This report |

## Build Status

Final build: **SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference warnings)

## Files Not Modified (Confirmed No SQL Content)

- `Business/ProductService.cs` - Business logic only, no SQL
- `CLI/CommandLineInterface.cs` - CLI interface only, no SQL
- `CLI/InteractiveMenu.cs` - Menu interface only, no SQL
- `Models/Product.cs` - Data model only, no SQL
- `Program.cs` - Application entry point only, no SQL
- `Scripts/01_InitialSetup.sql` - Database setup script (not application code)
- `Database/Scripts/01_InitialSetup.sql` - Database setup script (not application code)
