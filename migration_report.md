# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-22/23 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Migration Project ARN** | arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU |

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention (DMS Failure)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status

The DMS Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 statements but consistently failed with metadata model creation/conversion timeout errors. Multiple retries were attempted with varying parameters (poll_interval, max_poll_attempts).

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) succeeded for all 3 tables and provided the authoritative schema mappings used for manual conversion:
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`

### SQL Equivalency Tool Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs but returned ERROR with `'uniqueID'` for every pair (service-level issue). All results are recorded exactly as returned by the tool.

## Detailed Statement Conversion

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG, COUNT), INNER JOIN, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased, schema prefix `productmanagement_dbo` added
- **Equivalency Status**: ERROR (tool service issue)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased, schema prefix added
- **Equivalency Status**: ERROR (tool service issue)

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @var / SET @var` → Data-modifying CTEs
  - `BEGIN TRANSACTION/COMMIT` → Implicit CTE transaction
- **Equivalency Status**: ERROR (tool service issue)

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @OldPrice / @OldStock` → CTE `old_values`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → Data-modifying CTEs
- **Equivalency Status**: ERROR (tool service issue)

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, DELETE, UPDATE with CASE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `DECLARE @OldPrice / @OldStock` → CTE `old_values`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → Data-modifying CTEs
- **Equivalency Status**: ERROR (tool service issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased, schema prefix added
- **Equivalency Status**: ERROR (tool service issue)

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased, schema prefix added, `::numeric` cast added for integer division
- **Equivalency Status**: ERROR (tool service issue)

## Files Modified

### 1. `DataAccess/ProductRepository.cs`
- Replaced all 7 SQL statements with PostgreSQL equivalents
- Updated column name references in `MapProductFromReader` to lowercase
- Replaced `using Microsoft.Data.SqlClient` → `using Npgsql`
- Replaced all ADO.NET class references:
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`

### 2. `AdoCore.csproj`
- Removed: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- Added: `<PackageReference Include="Npgsql" Version="8.0.0" />`

### 3. `appsettings.json`
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
  → `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same conversion pattern
- Removed SQL Server-specific parameters: `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`
- Added PostgreSQL parameters: `Host`, `Port`, `Username`, `Password`

## Package Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|-------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.0 |

## Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL/Npgsql) |
|----------------------|-------------------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (not used in code) |

## SQL Syntax Conversions Applied

| SQL Server Syntax | PostgreSQL Equivalent |
|------------------|---------------------|
| `SCOPE_IDENTITY()` | `RETURNING` clause with CTE |
| `GETDATE()` | `clock_timestamp()` |
| `DECLARE @var` / `SET @var` | CTE with SELECT |
| `BEGIN TRANSACTION` / `COMMIT` | Data-modifying CTEs (implicit transaction) |
| `ROUND(int/int, 2)` | `ROUND(val::numeric / val, 2)` |
| PascalCase identifiers | lowercase identifiers |
| `dbo.` schema | `productmanagement_dbo.` schema |

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | All 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Comprehensive equivalency report for all 7 pairs |
| `dms_failure_summary.log` | `sourceCode/` | DMS tool failure documentation |
| `migration_report.md` | `sourceCode/` | This report |

## Build Status

**Final build: SUCCESS** (0 errors, 12 warnings - all pre-existing nullable reference type warnings)

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS Statement Conversion Tool failed for all 7 (timeout/metadata model errors)
2. SQL Equivalency Tool returned ERROR for all 7 (service-level `'uniqueID'` error)
3. Manual conversion was applied using DMS Schema Mapping results as the authoritative source for schema/column name mappings

**Recommendation**: Manually verify all 7 converted SQL statements against a PostgreSQL test database to confirm functional correctness.
