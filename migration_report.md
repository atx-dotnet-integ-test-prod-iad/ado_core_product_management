# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Statements Successfully Converted by DMS** | 0 |
| **Statements Requiring Manual Intervention** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Validation Errors** | 7 |

## DMS Conversion Results

All 7 SQL statements were submitted to the AWS DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) for conversion from MS SQL Server to PostgreSQL.

**DMS Error**: All 7 statements failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

Multiple retry strategies were attempted (varying poll_attempts: 15/30/45/60, poll_interval: 10/15/20/30 seconds). Even simple SELECT statements failed, confirming this was a DMS infrastructure-level issue.

Per the transformation definition, when DMS fails, manual conversion was applied with lowercase schema object naming for PostgreSQL compatibility (conversion method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

## SQL Equivalency Validation Results

All 7 statement pairs were validated using the SQL Equivalency MCP Tool (`sql-equivalency___validate_sql_equivalence`).

**Result**: All 7 pairs returned `ERROR` with error `'uniqueID'`.

Per the transformation definition, all results are recorded as-is from the tool. No agent judgment was used to determine equivalency.

**Detailed results**: See `sql_equivalency_validation_report.json` for full validation data.

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: CTE with window functions (AVG, COUNT OVER)
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Schema objects lowercased (ProductStats→productstats, Products→products, etc.)
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: CTE with LAG window function
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Schema objects lowercased (ProductHistory→producthistory, Products→products, etc.)
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with SCOPE_IDENTITY
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @NewProductId` → removed (use `lastval()` inline)
  - Schema objects lowercased
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with variable declarations
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @OldPrice/@OldStock` → replaced with subquery approach (INSERT...SELECT from products)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Reordered operations: history INSERT before product UPDATE to capture old values
  - Schema objects lowercased
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DELETE
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @OldPrice/@OldStock` → replaced with subquery approach (INSERT...SELECT from products)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Reordered operations: history INSERT and stats UPDATE before DELETE
  - Schema objects lowercased
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: CTE with RANK/PERCENT_RANK
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Schema objects lowercased (RankedProducts→rankedproducts, Products→products, etc.)
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: CTE with aggregate window functions
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - Schema objects lowercased (StockAnalysis→stockanalysis, Products→products, etc.)
  - `CAST(stockquantity AS NUMERIC)` added for proper integer division in ROUND
- **Equivalency Status**: ERROR

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; All ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader); using directive updated |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.6 |
| `appsettings.json` | Connection strings converted from SQL Server to PostgreSQL format |

## Package/Dependency Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

**Unchanged packages:**
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=<username>;Password=<password>` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Class Mappings

| SQL Server Class | PostgreSQL (Npgsql) Class |
|-----------------|--------------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

## Build Status

The application compiles successfully after all migration changes:
- **Build Result**: SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference warnings, not related to migration)

## Artifact Files

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Detailed equivalency validation report for all 7 statement pairs |
| `dms_failure_summary.md` | Documentation of DMS conversion failures |
| `migration_report.md` | This comprehensive migration report |
