# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| Migration Date | 2026-03-06 |
| Source Database | Microsoft SQL Server 2019 |
| Target Database | PostgreSQL 13 |
| Application Type | .NET 9.0 ADO.NET Console Application |
| Migration Tool | AWS DMS MCP Statement Conversion Tool |

## SQL Statement Conversion Results

| # | Method | DMS Status | Conversion Method | Notes |
|---|--------|------------|-------------------|-------|
| 1 | GetAllProductsAsync | SUCCESS | DMS_TOOL | CTE with AVG/COUNT OVER, INNER JOIN. DMS added NULLS FIRST to ORDER BY. |
| 2 | GetProductByIdAsync | SUCCESS | DMS_TOOL | CTE with LAG, LEFT JOIN converted to LEFT OUTER JOIN. |
| 3 | InsertProductAsync | FAILED | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | DMS error: "Statement definition is not valid." Transaction block with DECLARE/SCOPE_IDENTITY not supported. Manual conversion: SCOPE_IDENTITY() → RETURNING productid, GETDATE() → clock_timestamp(). |
| 4 | UpdateProductAsync | SUCCESS | DMS_TOOL | DMS warning [7807]: BEGIN TRANSACTION not supported in functions. GETDATE() → clock_timestamp(). DECLARE → application-level variables. |
| 5 | DeleteProductAsync | SUCCESS | DMS_TOOL | DMS warning [7807]: BEGIN TRANSACTION not supported in functions. GETDATE() → clock_timestamp(). CASE WHEN preserved. |
| 6 | GetProductsByPriceRangeAsync | SUCCESS | DMS_TOOL | RANK/PERCENT_RANK preserved. DMS added NULLS FIRST. |
| 7 | GetLowStockProductsAsync | SUCCESS | DMS_TOOL | AVG/MIN/MAX OVER preserved. DMS added NULLS FIRST. |

### DMS Conversion Summary
- **Total Statements**: 7
- **DMS Successful**: 6 (85.7%)
- **DMS Failed (Manual Conversion)**: 1 (14.3%)

## SQL Equivalency Validation Results

All 7 statement pairs were submitted to the SQL Equivalency validation tool (sql-equivalency___validate_sql_equivalence).

| # | Method | Equivalency Status | Tool Output |
|---|--------|--------------------|-------------|
| 1 | GetAllProductsAsync | ERROR | `{'uniqueID'}` |
| 2 | GetProductByIdAsync | ERROR | `{'uniqueID'}` |
| 3 | InsertProductAsync | ERROR | `{'uniqueID'}` |
| 4 | UpdateProductAsync | ERROR | `{'uniqueID'}` |
| 5 | DeleteProductAsync | ERROR | `{'uniqueID'}` |
| 6 | GetProductsByPriceRangeAsync | ERROR | `{'uniqueID'}` |
| 7 | GetLowStockProductsAsync | ERROR | `{'uniqueID'}` |

### Equivalency Summary
- **Total Validated**: 7
- **Equivalent**: 0
- **Non-Equivalent**: 0
- **Error**: 7 (all returned `'uniqueID'` error - tool infrastructure issue)

> **Note**: All 7 equivalency checks returned the same `'uniqueID'` error, indicating a tool-level infrastructure issue rather than individual statement problems. No agent judgment was used to determine equivalency status.

## Schema Mapping (from DMS)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| dbo.Products | productmanagement_dbo.products |
| dbo.ProductHistory | productmanagement_dbo.producthistory |
| dbo.ProductStats | productmanagement_dbo.productstats |
| All column names | Lowercased (e.g., ProductId → productid) |
| GETDATE() | clock_timestamp() |
| SCOPE_IDENTITY() | RETURNING productid |
| IDENTITY(1,1) | GENERATED ALWAYS AS IDENTITY |
| datetime | TIMESTAMP WITHOUT TIME ZONE |
| decimal(18,2) | NUMERIC(18,2) |
| nvarchar | VARCHAR |

## Package Changes

| Action | Package | Version |
|--------|---------|---------|
| Removed | Microsoft.Data.SqlClient | 5.1.4 |
| Added | Npgsql | 8.0.6 |

## ADO.NET Class Replacements

| SQL Server | PostgreSQL (Npgsql) |
|------------|---------------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlTransaction | NpgsqlTransaction |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | Removed (not applicable) |
| TrustServerCertificate | True | Removed (not applicable) |

## Files Modified

| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | All 7 SQL statements converted, ADO.NET classes replaced, imports updated, column name references lowercased, transaction handling restructured |
| AdoCore.csproj | Microsoft.Data.SqlClient → Npgsql 8.0.6 |
| appsettings.json | Connection strings converted to PostgreSQL format |

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | Original 7 MS SQL statements catalog |
| converted_statements.sql | sourceCode/ | Converted 7 PostgreSQL statements catalog |
| sql_equivalency_validation_report.json | sourceCode/ | Complete equivalency validation report for all 7 statement pairs |
| migration_report.md | sourceCode/ | This report |

## Build Status

- **Final Build**: SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **No remaining SQL Server references** in the codebase

## Manual Interventions Required

1. **Statement 3 (InsertProductAsync)**: DMS could not convert the complete transaction block with DECLARE/SCOPE_IDENTITY(). Manual conversion applied:
   - Replaced single SQL block with application-level transaction using BeginTransactionAsync/CommitAsync/RollbackAsync
   - Replaced SCOPE_IDENTITY() with PostgreSQL RETURNING clause
   - Applied lowercase schema object names per DMS schema mapping
   - Replaced GETDATE() with clock_timestamp() (consistent with DMS conversions)

2. **Statements 4 & 5 (Update/Delete)**: DMS converted successfully but noted that BEGIN TRANSACTION is not supported in PostgreSQL functions (warning [7807]). Restructured to application-level transaction handling with individual SQL statements.
