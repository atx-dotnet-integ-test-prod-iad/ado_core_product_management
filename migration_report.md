# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Attribute | Details |
|-----------|---------|
| **Application** | AdoCore - ADO.NET Core Data Management Application |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Migration Date** | 2026-05-03 |
| **Framework** | .NET 9.0 |
| **Migration Approach** | DMS MCP Tool (attempted) + Manual Conversion |

## SQL Statement Processing

### Overview

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS failure | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS MCP Tool Results

All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) as required. All 7 failed with the same error:

- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

Since DMS failed for all statements, manual conversion was applied using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` method as specified in the transformation plan.

### SQL Equivalency Tool Results

All 7 statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR with:

- **Error**: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`

This was a systemic tool error, not related to statement quality. Per plan instructions, all were marked as ERROR (agent judgment was NOT used to determine equivalency).

### Statement-by-Statement Details

| # | Method | Source Location | DMS Status | Equivalency Status | Key Conversions |
|---|--------|----------------|------------|-------------------|-----------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | FAILED | ERROR | Lowercase schema objects |
| 2 | GetProductByIdAsync | ProductRepository.cs | FAILED | ERROR | Lowercase schema objects |
| 3 | InsertProductAsync | ProductRepository.cs | FAILED | ERROR | SCOPE_IDENTITY()→lastval(), GETDATE()→NOW(), removed DECLARE/SET |
| 4 | UpdateProductAsync | ProductRepository.cs | FAILED | ERROR | DECLARE/SET→subqueries, GETDATE()→NOW() |
| 5 | DeleteProductAsync | ProductRepository.cs | FAILED | ERROR | DECLARE/SET→subqueries, GETDATE()→NOW(), reordered operations |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | FAILED | ERROR | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | FAILED | ERROR | CAST(int AS NUMERIC) for division, lowercase schema |

### All Statements Require Manual Review

Due to DMS tool failure and SQL Equivalency tool errors, all 7 statements require manual review:

1. **Statement 1 (GetAllProductsAsync)**: CTE with window functions (AVG, COUNT OVER), CASE, ROUND, INNER JOIN
2. **Statement 2 (GetProductByIdAsync)**: CTE with LAG window function, CASE with NULL handling, LEFT JOIN
3. **Statement 3 (InsertProductAsync)**: Transaction block - SCOPE_IDENTITY→lastval(), GETDATE→NOW()
4. **Statement 4 (UpdateProductAsync)**: Transaction block - DECLARE/SET→subqueries, GETDATE→NOW()
5. **Statement 5 (DeleteProductAsync)**: Transaction block - DECLARE/SET→subqueries, reordered operations
6. **Statement 6 (GetProductsByPriceRangeAsync)**: RANK/PERCENT_RANK window functions, BETWEEN
7. **Statement 7 (GetLowStockProductsAsync)**: AVG/MIN/MAX window functions, integer division fix

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements + ADO.NET class references |
| `appsettings.json` | Updated connection strings to PostgreSQL format |
| `README.md` | Updated documentation for PostgreSQL |

## Package Changes

| Original Package | New Package |
|-----------------|-------------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

## Class Replacements

| Original Class | Replacement Class | Occurrences |
|---------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 4 (field, method return, 2 instantiations) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per query method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

## Import Changes

| Original Import | New Import |
|----------------|------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | *(removed - not applicable)* |
| TLS | `TrustServerCertificate=True` | *(removed - not applicable)* |

## SQL Syntax Conversions Applied

| SQL Server Syntax | PostgreSQL Syntax |
|-------------------|-------------------|
| `SCOPE_IDENTITY()` | `lastval()` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE; SET @var = ...` | Subqueries or inline references |
| `SELECT @var = col FROM table` | Subqueries: `(SELECT col FROM table)` |
| Schema object names (PascalCase) | Lowercase (e.g., `Products` → `products`) |
| `ROUND(int/int, 2)` | `ROUND(CAST(int AS NUMERIC)/int, 2)` |

## Build Status

- **Final Build**: ✅ Succeeded (0 Errors, 10 Warnings - pre-existing nullable warnings)

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Project root | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive validation report with all 7 statement pairs |
| `dms_migration_log.md` | Project root | DMS failure documentation |
| `migration_report.md` | Project root | This report |

## Final Validation Checklist

- [x] All SQL Server packages replaced with PostgreSQL equivalents
- [x] All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents
- [x] ALL 7 SQL statements processed through DMS MCP tool (all failed, documented)
- [x] ALL 7 statement pairs validated through SQL Equivalency tool (all returned ERROR, documented)
- [x] Connection strings updated to PostgreSQL format
- [x] Application compiles without errors
- [x] Complete catalogs and reports generated
- [x] No agent judgment used for equivalency determination
- [x] All DMS failures documented with original statement, error, and manual conversion
