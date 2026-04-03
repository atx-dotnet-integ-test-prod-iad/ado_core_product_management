# Migration Report: SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| Migration Date | 2026-04-03 |
| Source Database | Microsoft SQL Server 2019 |
| Target Database | PostgreSQL 13 |
| Application Framework | .NET 9.0 (ADO.NET) |
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS | 0 |
| Requiring Manual Intervention | 7 |
| Validated as Equivalent | 0 |
| Validated as Non-Equivalent | 0 |
| With Equivalency Errors | 7 |

## DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was unavailable during this migration. All attempts to use it resulted in timeout errors:

- **Attempt 1**: Statement 1 (GetAllProductsAsync) with `max_poll_attempts=15` → Error: "Metadata model conversion did not complete after 15 attempts"
- **Attempt 2**: Statement 1 retry with `max_poll_attempts=30` → Error: "Command execution timed out after 300 seconds"
- **Attempt 3**: Simple test `SELECT SCOPE_IDENTITY()` with `max_poll_attempts=25` → Error: "Metadata model creation did not complete after 25 attempts"
- **Attempt 4**: Simple test `SELECT GETDATE()` with `max_poll_attempts=20` → Error: "Metadata model creation did not complete after 20 attempts"

Per transformation definition, all 7 statements were manually converted with conversion method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was called for all 7 statement pairs. All 7 returned ERROR status with error `'uniqueID'`. Per transformation definition, these are documented as ERROR (not determined by agent judgment).

## Detailed Statement Conversion Report

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: CTE with AVG/COUNT window functions
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: All schema object names lowercased (Products→products, ProductId→productid, etc.)

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: CTE with LAG window function
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: All schema object names lowercased, parameter @ProductId preserved for Npgsql compatibility

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with SCOPE_IDENTITY()/GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING` clause with CTE + `currval(pg_get_serial_sequence(...))`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @NewProductId INT` → CTE with RETURNING pattern
  - All schema object names lowercased

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE/GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → Replaced with subquery pattern (read before update)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Reordered: history logging and stats update before product update to capture old values
  - All schema object names lowercased

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE/CASE/GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - `DECLARE @OldPrice`/`@OldStock` → Replaced with subquery pattern
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Reordered: history logging and stats update before delete to capture product info
  - All schema object names lowercased

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: CTE with RANK/PERCENT_RANK
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: All schema object names lowercased

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: CTE with AVG/MIN/MAX window functions
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**:
  - All schema object names lowercased
  - Added `::numeric` cast for integer division in ROUND() to avoid PostgreSQL integer truncation

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statements, updated using directive, replaced SqlClient classes with Npgsql equivalents, updated column reader names to lowercase |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax |

## New Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This migration report |

## Key Conversion Rules Applied

| SQL Server | PostgreSQL |
|-----------|------------|
| `SCOPE_IDENTITY()` | `RETURNING` clause + `currval()` |
| `GETDATE()` | `NOW()` |
| `BEGIN TRANSACTION` | `BEGIN` |
| `DECLARE @variable` | Subquery/CTE patterns |
| `IDENTITY(1,1)` | `SERIAL` |
| `[dbo].[TableName]` | `tablename` (lowercase, no brackets) |
| `nvarchar` | `varchar` |
| `[bit]` | `boolean` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `GO` | Removed (not needed in PostgreSQL) |
| `SYSTEM_USER` | `CURRENT_USER` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `Server=` | `Host=` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |

## Package Changes

| Original | Replacement |
|----------|------------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

Note: Npgsql v8.0.2 was initially specified in the plan but had a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c). Upgraded to v8.0.6 which resolves the vulnerability.

## Build Status

The application compiles successfully after all migrations with 0 errors and only pre-existing nullable reference warnings.
