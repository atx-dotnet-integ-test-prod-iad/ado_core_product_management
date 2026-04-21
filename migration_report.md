# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-21 |
| **Source Database** | SQL Server (ProductManagement) |
| **Target Database** | PostgreSQL 13 (postgres) |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |
| **Total SQL Statements** | 7 |
| **DMS Tool Conversions** | 0 (all failed) |
| **Manual Conversions** | 7 |
| **Equivalent (tool verified)** | 0 |
| **Non-Equivalent (tool verified)** | 0 |
| **Equivalency Errors** | 7 (tool service error) |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE, AVG/COUNT window functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: Table/column names converted to lowercase

### Statement 2: GetProductByIdAsync
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: Table/column names converted to lowercase

### Statement 3: InsertProductAsync
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY, GETDATE, multi-table
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @NewProductId INT` removed
  - `SELECT @NewProductId` → `SELECT lastval()`
  - Table/column names converted to lowercase

### Statement 4: UpdateProductAsync
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - `DECLARE @OldPrice/@OldStock` removed, replaced with subquery approach
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Operations reordered: log history (with subquery for old values) before product update
  - Table/column names converted to lowercase

### Statement 5: DeleteProductAsync
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO vars, DELETE, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**:
  - `DECLARE @OldPrice/@OldStock` removed, replaced with subquery approach
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Operations reordered: log history and update stats (with subquery) before delete
  - Table/column names converted to lowercase

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK, PERCENT_RANK window functions, BETWEEN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: Table/column names converted to lowercase

### Statement 7: GetLowStockProductsAsync
- **Source File**: `sourceCode/DataAccess/ProductRepository.cs`
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Equivalency Status**: ERROR (tool error: 'uniqueID')
- **Key Changes**: Table/column names converted to lowercase, `CAST(stockquantity AS NUMERIC)` added for integer division in ROUND

## Files Modified

| File | Changes |
|------|---------|
| `sourceCode/DataAccess/ProductRepository.cs` | All 7 SQL statements converted; SqlClient → Npgsql types; imports updated |
| `sourceCode/AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `sourceCode/appsettings.json` | SQL Server connection strings → PostgreSQL format |

## Package Dependency Changes

| Original | Replacement |
|----------|------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

**Note**: Npgsql 8.0.6 was chosen over 8.0.1 to address a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

## ADO.NET Class Substitutions

| SQL Server Class | Npgsql Replacement |
|-----------------|-------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | _(implicit)_ | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=password` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | _(removed - not supported)_ |
| TrustServerCertificate | `TrustServerCertificate=True` | _(removed - not applicable)_ |

## DMS Tool Failures

All 7 DMS conversion attempts failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

This appears to be a transient infrastructure issue with the DMS metadata model creation service. All statements were subsequently converted manually applying lowercase schema naming conventions per the transformation definition's DMS failure fallback rules.

## SQL Equivalency Tool Errors

All 7 equivalency validations returned ERROR with:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a service-side issue with the SQL Equivalency tool. Per transformation definition, all statements are marked as ERROR (tool output used exclusively, no agent judgment substituted).

## Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | All 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Comprehensive equivalency report |
| `dms_failure_log.txt` | `sourceCode/` | DMS conversion failure documentation |
| `migration_report.md` | `sourceCode/` | This report |

## Build Status

**Final Build**: ✅ **Success** (0 errors, 10 warnings - all pre-existing nullable reference warnings)

## Manual Review Required

Due to DMS and SQL Equivalency tool failures, the following items require manual review:
1. All 7 converted SQL statements should be reviewed for PostgreSQL compatibility
2. Transaction block reordering in UpdateProductAsync and DeleteProductAsync (old values captured via subquery before modification)
3. `lastval()` usage in InsertProductAsync for retrieving the auto-generated ID
4. Integer division handling with `CAST(stockquantity AS NUMERIC)` in GetLowStockProductsAsync
5. SQL script files (Scripts/01_InitialSetup.sql, Database/Scripts/01_InitialSetup.sql) need manual conversion for PostgreSQL schema setup
