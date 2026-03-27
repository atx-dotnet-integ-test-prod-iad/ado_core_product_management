# AdoCore Migration Report: MS SQL Server to PostgreSQL

## Executive Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET class references, package dependencies, and connection strings.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention (DMS failure) | 7 |
| Statements validated as EQUIVALENT by SQL Equivalency tool | 0 |
| Statements validated as NOT_EQUIVALENT | 0 |
| Statements with equivalency validation ERROR | 7 |

## DMS Tool Status

The DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements but consistently failed with metadata model creation/conversion timeouts. Multiple retry strategies were employed:

- Default settings (15 attempts, 10s interval): Failed
- Increased settings (25 attempts, 10s interval): Failed
- Extended settings (30 attempts, 15s interval): Failed
- Tested with simple statements (e.g., `SELECT GETDATE()`): Also failed
- Tested with explicit database_name parameter: Also failed

**Error:** `"Metadata model creation/conversion failed: {'error': 'Metadata model creation did not complete after N attempts'}"`

However, the DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) successfully returned schema mappings for all tables, confirming:
- `dbo.Products` → `productmanagement_dbo.products` (all columns lowercase)
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory` (all columns lowercase)
- `dbo.ProductStats` → `productmanagement_dbo.productstats` (all columns lowercase)

## SQL Equivalency Validation Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs. All 7 returned ERROR status with the error `'uniqueID'`. This appears to be a systemic issue with the tool, not related to the quality of the conversions.

## Conversion Method

All statements were converted using: **DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA**

Key conversion rules applied based on DMS schema mappings:
- All schema object names (tables, columns) converted to lowercase
- `SCOPE_IDENTITY()` → `RETURNING productid` clause
- `GETDATE()` → `NOW()`
- `DECLARE @variable` → Application-level variables with multi-command transaction pattern
- `BEGIN TRANSACTION/COMMIT` → Application-managed transactions via `BeginTransactionAsync()/CommitAsync()`
- CTE names adjusted to avoid conflicts with PostgreSQL table names (e.g., `ProductStats` CTE → `productstats_cte`)
- Integer division in `ROUND()` fixed with `::numeric` cast

## Detailed Statement Listing

### Statement 1: GetAllProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetAllProductsAsync()`
- **SQL Server Constructs:** CTE, AVG/COUNT window functions, ROUND, CASE, ORDER BY
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Changes:** CTE renamed from `ProductStats` to `productstats_cte`, all identifiers lowercased

### Statement 2: GetProductByIdAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetProductByIdAsync(int productId)`
- **SQL Server Constructs:** CTE, LAG window function, ROUND, CASE, parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Changes:** CTE renamed from `ProductHistory` to `producthistory_cte`, all identifiers lowercased

### Statement 3: InsertProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `InsertProductAsync(Product product)`
- **SQL Server Constructs:** DECLARE, SCOPE_IDENTITY(), BEGIN TRANSACTION/COMMIT, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Changes:** 
  - Single batch → three separate NpgsqlCommand executions within app-managed transaction
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - All identifiers lowercased

### Statement 4: UpdateProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `UpdateProductAsync(Product product)`
- **SQL Server Constructs:** BEGIN TRANSACTION/COMMIT, DECLARE variables, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Changes:**
  - Single batch → four separate NpgsqlCommand executions within app-managed transaction
  - `DECLARE @OldPrice/DECLARE @OldStock` → C# variables populated via initial SELECT
  - `GETDATE()` → `NOW()`
  - All identifiers lowercased

### Statement 5: DeleteProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `DeleteProductAsync(int productId)`
- **SQL Server Constructs:** BEGIN TRANSACTION/COMMIT, DECLARE variables, CASE WHEN, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Changes:**
  - Single batch → four separate NpgsqlCommand executions within app-managed transaction
  - `DECLARE @OldPrice/DECLARE @OldStock` → C# variables populated via initial SELECT
  - `GETDATE()` → `NOW()`
  - All identifiers lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **SQL Server Constructs:** CTE, RANK, PERCENT_RANK window functions, CASE, BETWEEN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Changes:** All identifiers lowercased, RANK/PERCENT_RANK syntax compatible with PostgreSQL

### Statement 7: GetLowStockProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetLowStockProductsAsync(int threshold)`
- **SQL Server Constructs:** CTE, AVG/MIN/MAX window functions, ROUND, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Key Changes:** All identifiers lowercased, `StockQuantity / AvgStock` → `stockquantity::numeric / avgstock` (integer division fix)

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` Version `5.1.4` | `Npgsql` Version `8.0.6` |
| `Microsoft.Extensions.Configuration` Version `8.0.0` | (unchanged) |
| `Microsoft.Extensions.Configuration.Json` Version `8.0.0` | (unchanged) |
| `Microsoft.Extensions.DependencyInjection` Version `8.0.0` | (unchanged) |

## ADO.NET Class Reference Changes

| SQL Server Type | Npgsql Type |
|----------------|-------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

## Connection String Changes

| Setting | Before (SQL Server) | After (PostgreSQL) |
|---------|--------------------|--------------------|
| DevConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres` |
| ProdConnection | Same as above | Same as above |

## Files Modified

1. **sourceCode/DataAccess/ProductRepository.cs** - SQL statements, ADO.NET types, using directives
2. **sourceCode/AdoCore.csproj** - Package reference (SqlClient → Npgsql)
3. **sourceCode/appsettings.json** - Connection strings

## Artifacts Generated

1. **sourceCode/extracted_statements.sql** - Complete catalog of all 7 original MS SQL Server statements
2. **sourceCode/converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements
3. **sourceCode/sql_equivalency_validation_report.json** - Comprehensive equivalency report for all 7 statement pairs
4. **sourceCode/migration_report.md** - This report

## Build Status

**Final Build: SUCCESS** - 0 Errors, 10 Warnings (all pre-existing nullable reference warnings)

## Items Requiring Manual Review

1. **DMS Tool Failures:** All 7 statements failed DMS conversion due to metadata model timeouts. Manual conversions were applied with lowercase schema object names. These should be reviewed for correctness.
2. **SQL Equivalency Errors:** All 7 equivalency checks returned ERROR due to `'uniqueID'` error in the equivalency tool. Manual review of conversion correctness is recommended.
3. **Transaction Restructuring:** Statements 3, 4, 5 were restructured from single SQL batches to multi-command patterns with application-managed transactions. This changes the execution model but preserves transactional atomicity.
4. **Connection String Credentials:** The PostgreSQL connection strings use placeholder credentials (postgres/postgres). Production credentials should be configured via environment variables or secure configuration.
