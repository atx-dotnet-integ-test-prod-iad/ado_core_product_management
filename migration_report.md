# Migration Report: SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13 (postgres)
- **Migration Date**: 2026-03-05
- **DMS Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 12 |
| Successfully converted by DMS | 11 |
| DMS conversion failures (manual conversion) | 1 |
| Equivalency validated as EQUIVALENT | 0 |
| Equivalency validated as NOT_EQUIVALENT | 0 |
| Equivalency validation errors | 12 |

## SQL Statement Conversion Details

### Application Code (ProductRepository.cs) - 7 Statements

| # | Method | DMS Status | Conversion Method | Equivalency |
|---|--------|-----------|-------------------|-------------|
| 1 | GetAllProductsAsync | ✅ Success | DMS_TOOL | ERROR |
| 2 | GetProductByIdAsync | ✅ Success | DMS_TOOL | ERROR |
| 3 | InsertProductAsync | ❌ Failed | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR |
| 4 | UpdateProductAsync | ✅ Success (with warning) | DMS_TOOL | ERROR |
| 5 | DeleteProductAsync | ✅ Success (with warning) | DMS_TOOL | ERROR |
| 6 | GetProductsByPriceRangeAsync | ✅ Success | DMS_TOOL | ERROR |
| 7 | GetLowStockProductsAsync | ✅ Success | DMS_TOOL | ERROR |

### Database Script Statements - 5 Statements

| # | Statement | DMS Status | Conversion Method | Equivalency |
|---|-----------|-----------|-------------------|-------------|
| 8 | sp_GetAllProducts SELECT | ✅ Success | DMS_TOOL | ERROR |
| 9 | sp_GetProductById SELECT | ✅ Success | DMS_TOOL | ERROR |
| 10 | sp_InsertProduct INSERT | ✅ Success | DMS_TOOL | ERROR |
| 11 | sp_UpdateProduct UPDATE | ✅ Success | DMS_TOOL | ERROR |
| 12 | sp_DeleteProduct DELETE | ✅ Success | DMS_TOOL | ERROR |

## DMS Conversion Failures

### Statement 3: InsertProductAsync
- **DMS Error**: `Metadata model creation failed: Statement definition is not valid.`
- **Reason**: DMS could not parse the multi-statement transaction block with DECLARE/SET/SCOPE_IDENTITY()
- **Manual Conversion Applied**:
  - SCOPE_IDENTITY() → INSERT...RETURNING clause
  - GETDATE() → clock_timestamp()
  - Transaction management moved to C# code (BeginTransactionAsync)
  - All schema object names converted to lowercase

### Statements 4 & 5: UpdateProductAsync / DeleteProductAsync
- **DMS Warning**: `[7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions.]`
- **Resolution**: DMS successfully converted the SQL but flagged transaction management. Transaction handling restructured to use C# managed transactions.

## Equivalency Validation

All 12 statement pairs were validated through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence). All returned ERROR status with error message `'uniqueID'`. This appears to be a systemic issue with the equivalency tool, not related to the quality of conversions.

**Per transformation definition**: Equivalency status comes exclusively from the tool output - no agent judgment was applied.

## Key Schema Conversions

| SQL Server | PostgreSQL |
|-----------|-----------|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |
| `[dbo].[Categories]` | `productmanagement_dbo.categories` |
| `[dbo].[Suppliers]` | `productmanagement_dbo.suppliers` |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` |
| `nvarchar` | `VARCHAR` |
| `bit` | `NUMERIC(1,0)` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `SYSTEM_USER` | `CURRENT_USER` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| SQL Server trigger syntax | PostgreSQL trigger function + trigger |

## Package Dependency Changes

| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.1` |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Class |
|-----------------|--------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | (removed - not applicable) |
| TrustServerCertificate | `True` | (removed - not applicable) |

## Files Modified

1. `sourceCode/DataAccess/ProductRepository.cs` - SQL statements, ADO.NET classes, transaction handling
2. `sourceCode/AdoCore.csproj` - Package reference
3. `sourceCode/appsettings.json` - Connection strings
4. `sourceCode/Scripts/01_InitialSetup.sql` - PostgreSQL database setup
5. `sourceCode/Database/Scripts/01_InitialSetup.sql` - PostgreSQL comprehensive setup

## Artifacts Generated

1. `sourceCode/extracted_statements.sql` - Catalog of all 12 original SQL Server statements
2. `sourceCode/converted_statements.sql` - Catalog of all 12 converted PostgreSQL statements
3. `sourceCode/sql_equivalency_validation_report.json` - Comprehensive equivalency report
4. `sourceCode/migration_report.md` - This migration report

## Build Status

✅ **Build Successful** - Application compiles without errors after migration.
- 0 compilation errors
- Pre-existing nullable warnings preserved (not introduced by migration)
- NU1903 warning for Npgsql 8.0.1 known vulnerability (version specified by plan)
