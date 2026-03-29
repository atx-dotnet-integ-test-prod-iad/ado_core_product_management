# Migration Report: SQL Server to PostgreSQL - AdoCore Application

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-29 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **DMS Migration Project** | arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU |

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Statements Converted by DMS** | 0 |
| **Statements Requiring Manual Intervention** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Errors** | 7 |

### DMS Conversion Details

All 7 SQL statements were submitted to the DMS MCP Statement Conversion Tool. All failed with the error:
> Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}

The DMS Schema Mapping Tool was successfully used to retrieve target schema information:
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`

Manual conversions were applied using these DMS-provided schema mappings with lowercase naming conventions per the transformation definition (reason: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

### SQL Equivalency Validation Details

All 7 statement pairs were validated using the SQL Equivalency MCP Tool. All returned ERROR with:
> `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`

This appears to be a system-level issue with the equivalency tool, not specific to any individual statement.

### Statement-by-Statement Details

| # | Method | Conversion | Key Changes | Equivalency |
|---|--------|-----------|-------------|-------------|
| 1 | GetAllProductsAsync | Manual | CTE renamed to `productstats_cte`, lowercase columns/tables, schema prefix | ERROR |
| 2 | GetProductByIdAsync | Manual | CTE renamed to `producthistory_cte`, lowercase columns/tables, schema prefix | ERROR |
| 3 | InsertProductAsync | Manual | `SCOPE_IDENTITY()` → `RETURNING`, `GETDATE()` → `clock_timestamp()`, split to app-level txn | ERROR |
| 4 | UpdateProductAsync | Manual | `DECLARE @var` → C# vars, `GETDATE()` → `clock_timestamp()`, split to app-level txn | ERROR |
| 5 | DeleteProductAsync | Manual | `DECLARE @var` → C# vars, `GETDATE()` → `clock_timestamp()`, split to app-level txn | ERROR |
| 6 | GetProductsByPriceRangeAsync | Manual | Lowercase columns/tables, schema prefix added | ERROR |
| 7 | GetLowStockProductsAsync | Manual | Lowercase columns/tables, schema prefix, `CAST(stockquantity AS NUMERIC)` for division | ERROR |

## Package Changes

| Change | Before | After |
|--------|--------|-------|
| **Database Provider Package** | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

## Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `SqlTransaction` (cast) | `NpgsqlTransaction` (cast) | 11 |

## Connection String Updates

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| **Server/Host** | `Server=localhost` | `Host=localhost` |
| **Port** | (default 1433) | `Port=5432` |
| **Database** | `Database=ProductManagement` | `Database=postgres` |
| **Authentication** | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| **MultipleActiveResultSets** | `true` | Removed (not applicable) |
| **TrustServerCertificate** | `True` | Removed (not applicable) |

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; transaction methods restructured; ADO.NET types replaced with Npgsql equivalents; column name references lowercased |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient to Npgsql |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

## Artifacts Generated

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements with source context |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements with change notes |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report for all 7 statement pairs |
| `dms_failure_summary.log` | Detailed DMS failure documentation for all 7 statements |
| `migration_report.md` | This report |

## Build Status

**Final Build: SUCCESS** (0 errors, 10 pre-existing warnings)

All warnings are pre-existing nullable reference type warnings (CS8618, CS8601, CS8600, CS8603, CS8625) that existed before the migration and are not related to the PostgreSQL migration changes.

## Key SQL Conversion Patterns Applied

### 1. Schema Object Naming
- All table names converted to lowercase with `productmanagement_dbo` schema prefix
- All column names converted to lowercase
- CTE aliases renamed to avoid conflicts with physical table names

### 2. SQL Server → PostgreSQL Function Mapping
- `SCOPE_IDENTITY()` → `RETURNING productid` clause
- `GETDATE()` → `clock_timestamp()`
- `DECLARE @var` / `SET @var` → C# local variables
- Integer division: Added `CAST(... AS NUMERIC)` for proper decimal results

### 3. Transaction Handling
- SQL Server batch transactions (`BEGIN TRANSACTION`/`COMMIT`) → Application-level transactions via `NpgsqlConnection.BeginTransactionAsync()`
- Each SQL statement within a transaction is now executed as a separate `NpgsqlCommand` with the transaction assigned

### 4. Parameter Syntax
- `@param` syntax preserved (compatible with both SQL Server and Npgsql)
- `command.Parameters.AddWithValue()` method preserved (compatible with Npgsql)
