# SQL Server to PostgreSQL Migration Report

## Summary
- **Application**: AdoCore (.NET 9.0 Console Application)
- **Source Database**: Microsoft SQL Server (Microsoft.Data.SqlClient 5.1.4)
- **Target Database**: PostgreSQL (Npgsql 8.0.3)
- **Migration Date**: 2026-07-06

## SQL Statement Processing

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention (DMS failure) | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Failures

All 7 statements failed DMS conversion with the same error:
- **Error**: `Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}`
- **Root Cause**: DMS service unable to create metadata model (infrastructure/permissions issue with S3 bucket access)

## SQL Equivalency Tool Errors

All 7 statement pairs failed equivalency validation with the same error:
- **Error**: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`
- **Root Cause**: Internal tool error (not related to statement content)

## Manual Conversion Applied

Since DMS failed, manual conversion was applied with the following rules per transformation instructions:
1. All schema object names converted to lowercase (tables, columns, aliases)
2. `SCOPE_IDENTITY()` → `RETURNING productid INTO variable`
3. `GETDATE()` → `NOW()`
4. T-SQL `DECLARE @var` / `BEGIN TRANSACTION` blocks → PostgreSQL `DO $$` anonymous blocks
5. `StockQuantity / AvgStock` → `stockquantity::numeric / avgstock` (explicit cast for integer division)

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.3` |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |
| `DataAccess/ProductRepository.cs` | Replaced all SQL Server ADO.NET classes with Npgsql equivalents; converted all 7 SQL statements to PostgreSQL |

## Static Code Changes

| Original | Replaced With |
|----------|---------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Removed | `MultipleActiveResultSets=true;TrustServerCertificate=True` | N/A |

## Artifacts Generated

1. `extracted_statements.sql` - Complete catalog of all original MS SQL statements
2. `converted_statements.sql` - Complete catalog of all converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
4. `migration_report.md` - This report

## Statements Requiring Manual Review

All 7 statements should be manually reviewed since:
1. DMS tool was unavailable for automated conversion
2. SQL Equivalency tool returned errors for all validation attempts
3. Manual conversion applied lowercase schema naming conventions

### Statement List

1. **GetAllProductsAsync** - CTE with AVG/COUNT window functions, CASE expressions
2. **GetProductByIdAsync** - CTE with LAG window function, percentage calculation
3. **InsertProductAsync** - Transaction block with RETURNING (was SCOPE_IDENTITY), NOW() (was GETDATE)
4. **UpdateProductAsync** - DO $$ block with local variables (was DECLARE @vars), NOW()
5. **DeleteProductAsync** - DO $$ block with local variables, CASE expression in UPDATE
6. **GetProductsByPriceRangeAsync** - CTE with RANK/PERCENT_RANK window functions
7. **GetLowStockProductsAsync** - CTE with AVG/MIN/MAX window functions, ::numeric cast
