# Migration Report: SQL Server to PostgreSQL

## Overview
- **Project**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-04-20
- **DMS Migration Project ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL statements processed** | 7 |
| **Statements successfully converted by DMS** | 0 |
| **Statements requiring manual intervention** | 7 |
| **Statements validated as equivalent** | 0 |
| **Statements validated as non-equivalent** | 0 |
| **Statements with equivalency errors** | 7 |

### DMS Conversion Details
All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion. All 7 failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS schema_mapping_tool was successful and provided the schema mapping used for manual conversion:
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`

### Manual Conversion Applied (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
For all 7 statements, manual conversion was applied with the following rules:
1. All table and column names converted to lowercase
2. Schema prefix `productmanagement_dbo` applied per DMS schema mapping
3. SQL Server-specific functions replaced with PostgreSQL equivalents
4. Transaction blocks restructured to use PostgreSQL-compatible CTE patterns

### SQL Equivalency Validation
All 7 statement pairs were validated through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence). All 7 returned ERROR status with error `'uniqueID'`. This appears to be a tool infrastructure issue, not a conversion quality issue.

---

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Source**: CTE with AVG() OVER(), COUNT(*) OVER(), CASE, ROUND, INNER JOIN
- **Conversion**: Table/column names to lowercase, schema prefix added
- **DMS Result**: FAILED
- **Equivalency**: ERROR (tool issue)

### Statement 2: GetProductByIdAsync
- **Source**: CTE with LAG() OVER(), CASE with NULL check, ROUND, LEFT JOIN
- **Conversion**: Table/column names to lowercase, schema prefix added
- **DMS Result**: FAILED
- **Equivalency**: ERROR (tool issue)

### Statement 3: InsertProductAsync
- **Source**: DECLARE, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY(), GETDATE()
- **Conversion**: Restructured to writable CTE pattern, SCOPE_IDENTITY() → RETURNING, GETDATE() → CURRENT_TIMESTAMP
- **DMS Result**: FAILED
- **Equivalency**: ERROR (tool issue)

### Statement 4: UpdateProductAsync
- **Source**: BEGIN TRANSACTION/COMMIT, DECLARE variables, GETDATE()
- **Conversion**: Restructured to writable CTE pattern with old_values CTE, GETDATE() → CURRENT_TIMESTAMP
- **DMS Result**: FAILED
- **Equivalency**: ERROR (tool issue)

### Statement 5: DeleteProductAsync
- **Source**: BEGIN TRANSACTION/COMMIT, DECLARE variables, GETDATE(), CASE
- **Conversion**: Restructured to writable CTE pattern, GETDATE() → CURRENT_TIMESTAMP, CASE preserved
- **DMS Result**: FAILED
- **Equivalency**: ERROR (tool issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: CTE with RANK() OVER(), PERCENT_RANK() OVER(), CASE, BETWEEN
- **Conversion**: Table/column names to lowercase, schema prefix added
- **DMS Result**: FAILED
- **Equivalency**: ERROR (tool issue)

### Statement 7: GetLowStockProductsAsync
- **Source**: CTE with AVG/MIN/MAX OVER(), CASE, ROUND
- **Conversion**: Table/column names to lowercase, schema prefix added, added CAST(stockquantity AS NUMERIC) for integer division
- **DMS Result**: FAILED
- **Equivalency**: ERROR (tool issue)

---

## File Changes Summary

### Modified Files

#### 1. sourceCode/DataAccess/ProductRepository.cs
- **SQL Statements**: All 7 SQL strings replaced with PostgreSQL-converted versions
- **Using Directive**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **ADO.NET Classes**:
  - `SqlConnection` → `NpgsqlConnection` (field, constructor, method return type)
  - `SqlCommand` → `NpgsqlCommand` (7 instances)
  - `SqlDataReader` → `NpgsqlDataReader` (1 instance in MapProductFromReader)
- **Reader Column Names**: Updated to lowercase to match PostgreSQL schema (e.g., `reader["ProductId"]` → `reader["productid"]`)

#### 2. sourceCode/AdoCore.csproj
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`

#### 3. sourceCode/appsettings.json
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same transformation as DevConnection

### Created Files (Artifacts)

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report (JSON format) |
| `dms_conversion_log.md` | Detailed DMS conversion attempt log |
| `migration_report.md` | This migration report |

---

## Package Dependency Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|-------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

Other packages remain unchanged:
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

---

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL Equivalent | Occurrences |
|-----------------|----------------------|-------------|
| SqlConnection | NpgsqlConnection | 3 (field, constructor, method) |
| SqlCommand | NpgsqlCommand | 7 (one per SQL method) |
| SqlDataReader | NpgsqlDataReader | 1 (MapProductFromReader) |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed - not applicable) |
| TLS | `TrustServerCertificate=True` | (removed - not applicable) |

---

## Build Status
- **Final Build**: ✅ **SUCCESS**
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference type warnings, not related to migration)

---

## Issues and Warnings

### 1. DMS Tool Failure
All 7 DMS conversion attempts failed with: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**Impact**: Manual conversion was required for all statements. Schema mapping from DMS schema_mapping_tool was used to ensure correct table/column name mapping.

### 2. SQL Equivalency Tool Failure  
All 7 equivalency validation attempts returned ERROR with: `'uniqueID'`

**Impact**: Equivalency could not be automatically validated. All results are marked as ERROR in the equivalency report. Manual review of converted statements is recommended.

### 3. Integer Division in PostgreSQL
Statement 7 (GetLowStockProductsAsync) required explicit `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation in PostgreSQL, which differs from SQL Server behavior.

### 4. Transaction Block Restructuring
Statements 3, 4, and 5 contained SQL Server-specific transaction patterns (DECLARE variables, BEGIN TRANSACTION/COMMIT, SCOPE_IDENTITY()) that were restructured to use PostgreSQL writable CTE patterns. This structural change maintains the same functional behavior but uses a different execution pattern.

---

## Recommendations for Manual Review
1. **Test all 7 SQL operations** against a PostgreSQL database to verify functional correctness
2. **Review writable CTE patterns** (Statements 3-5) to ensure they execute atomically as expected
3. **Verify schema mapping** - Ensure `productmanagement_dbo` schema exists in PostgreSQL
4. **Test connection strings** with actual PostgreSQL credentials
5. **Re-run SQL equivalency validation** when tool infrastructure issue is resolved
