# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET data access classes, updating package dependencies, and updating connection strings.

## Migration Statistics

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Tool Conversion Attempts | 7 |
| DMS Tool Successful Conversions | 0 |
| DMS Tool Failed Conversions | 7 |
| Manual Conversions (DMS Failure Fallback) | 7 |
| SQL Equivalency Validations Performed | 7 |
| Equivalency Status: EQUIVALENT | 0 |
| Equivalency Status: NOT_EQUIVALENT | 0 |
| Equivalency Status: ERROR | 7 |

## DMS Conversion Results

All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) with the following configuration:
- **Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Schema Name**: `dbo`
- **Region**: `us-east-1`

All 7 statements failed with the same error: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`

### Per-Statement DMS Results

| # | Method | DMS Status | Conversion Method |
|---|--------|-----------|-------------------|
| 1 | GetAllProductsAsync | FAILED | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 2 | GetProductByIdAsync | FAILED | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 3 | InsertProductAsync | FAILED | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 4 | UpdateProductAsync | FAILED | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 5 | DeleteProductAsync | FAILED | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 6 | GetProductsByPriceRangeAsync | FAILED | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| 7 | GetLowStockProductsAsync | FAILED | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |

## SQL Equivalency Validation Results

All 7 statement pairs were submitted to the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence). All returned ERROR status with error message `'uniqueID'`, indicating a service-side issue with the tool.

| # | Method | Equivalency Status | Tool Error |
|---|--------|--------------------|------------|
| 1 | GetAllProductsAsync | ERROR | 'uniqueID' |
| 2 | GetProductByIdAsync | ERROR | 'uniqueID' |
| 3 | InsertProductAsync | ERROR | 'uniqueID' |
| 4 | UpdateProductAsync | ERROR | 'uniqueID' |
| 5 | DeleteProductAsync | ERROR | 'uniqueID' |
| 6 | GetProductsByPriceRangeAsync | ERROR | 'uniqueID' |
| 7 | GetLowStockProductsAsync | ERROR | 'uniqueID' |

**Note**: Equivalency statuses are reported exactly as returned by the SQL Equivalency tool. No agent judgment was used to determine equivalency.

## SQL Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, AVG/COUNT window functions, CASE, ROUND, ORDER BY
- **Changes**: All schema object names lowercased (Products → products, ProductId → productid, etc.)
- **SQL Functions**: Compatible between SQL Server and PostgreSQL (AVG OVER, COUNT OVER, CASE, ROUND)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, CASE, ROUND
- **Changes**: All schema object names lowercased
- **SQL Functions**: LAG window function compatible between both databases

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Changes**: 
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause on INSERT
  - `GETDATE()` → `NOW()`
  - `DECLARE @variable` / `SET @variable` → Eliminated; restructured as separate ADO.NET commands with C# variables
  - `BEGIN TRANSACTION/COMMIT` → ADO.NET `BeginTransactionAsync()/CommitAsync()` with `NpgsqlTransaction`
  - All schema object names lowercased

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Changes**:
  - `DECLARE @OldPrice / @OldStock` → Eliminated; values read via separate SELECT command into C# variables
  - `GETDATE()` → `NOW()`
  - Transaction block → ADO.NET managed transaction
  - All schema object names lowercased

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Changes**:
  - Same variable elimination approach as Statement 4
  - `GETDATE()` → `NOW()`
  - `CASE WHEN TotalProducts > 1 THEN ... ELSE 0 END` → Lowercased but syntax preserved (PostgreSQL compatible)
  - Transaction block → ADO.NET managed transaction
  - All schema object names lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() window functions, BETWEEN, CASE
- **Changes**: All schema object names lowercased
- **SQL Functions**: RANK, PERCENT_RANK, BETWEEN all compatible

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Changes**: 
  - All schema object names lowercased
  - Added `CAST(stockquantity AS DECIMAL)` for integer division to produce correct decimal results in PostgreSQL

## Package Dependency Changes

| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

**Note**: Npgsql version was set to 8.0.6 (not 8.0.1 as initially planned) to avoid known security vulnerability (GHSA-x9vc-6hfv-hg8c).

Unchanged packages:
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

## ADO.NET Class Replacements

| Original (Microsoft.Data.SqlClient) | Replacement (Npgsql) |
|--------------------------------------|---------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `new SqlConnection(...)` | `new NpgsqlConnection(...)` |
| `new SqlCommand(...)` | `new NpgsqlCommand(...)` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All SQL statements replaced, ADO.NET classes replaced, transaction handling restructured |
| `AdoCore.csproj` | Microsoft.Data.SqlClient → Npgsql package reference |
| `appsettings.json` | Connection strings converted to PostgreSQL format |

## Files Unchanged

| File | Reason |
|------|--------|
| `Program.cs` | No SQL Server dependencies (uses IConfiguration/DI) |
| `Business/ProductService.cs` | No SQL Server dependencies |
| `CLI/CommandLineInterface.cs` | No SQL Server dependencies |
| `CLI/InteractiveMenu.cs` | No SQL Server dependencies |
| `Models/Product.cs` | POCO with no SQL Server dependencies |

## Build Status

**Final Build**: ✅ Succeeded (0 errors, 10 warnings)

Warnings are nullable reference type warnings (CS8601, CS8618, CS8600, CS8603, CS8625) that existed in the original codebase and are unrelated to the migration.

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | All 7 original MS SQL statements with metadata |
| `converted_statements.sql` | Project root | All 7 converted PostgreSQL statements with metadata |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency validation report |
| `migration_report.md` | Project root | This report |

## Post-Validation Fix: MapProductFromReader Column Names

During post-validation review, the `MapProductFromReader` method in `ProductRepository.cs` was found to use **PascalCase** column names (e.g., `reader["ProductId"]`, `reader["Name"]`) in the data reader indexer, while all SQL queries return **lowercase** column names (e.g., `productid`, `name`) due to the lowercase schema conversion. In PostgreSQL, unquoted identifiers are automatically lowercased, so this would cause runtime `IndexOutOfRangeException` errors.

**Fix Applied**: Updated all column name references in `MapProductFromReader` to use lowercase:
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`

Note: The `reader["price"]` and `reader["stockquantity"]` references in `UpdateProductAsync` and `DeleteProductAsync` were already correctly lowercased.

Build verified: 0 errors, 10 warnings (same pre-existing nullable reference type warnings).

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS tool failed for all conversions (metadata model creation timeout)
2. SQL Equivalency tool returned ERROR for all validations (service-side 'uniqueID' error)
3. Manual conversions applied lowercase schema naming convention per the DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA policy

**Recommendation**: Verify the converted SQL statements against the actual PostgreSQL database schema to ensure column and table names match exactly.
