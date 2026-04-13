# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-13 |
| **Source Database** | Microsoft SQL Server 2019 (ProductManagement) |
| **Target Database** | PostgreSQL 13 (postgres) |
| **Application Type** | .NET 9.0 ADO.NET Application |
| **DMS Migration Project** | arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU |

---

## SQL Statement Conversion Results

### Overview

| Category | Count |
|----------|-------|
| **Total SQL Statements Processed** | 7 |
| **DMS Conversion Successful** | 0 |
| **DMS Conversion Failed (Manual Conversion Applied)** | 7 |
| **Equivalency Validated as EQUIVALENT** | 0 |
| **Equivalency Validated as NOT_EQUIVALENT** | 0 |
| **Equivalency Validation ERROR** | 7 |

### DMS Tool Status

All 7 SQL statements were submitted to the DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`). All 7 failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Per the transformation definition, manual conversion was applied using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach, guided by schema mappings successfully retrieved from the DMS schema mapping tool.

### SQL Equivalency Tool Status

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Per the transformation definition, ERROR results are documented as-is. No agent judgment was used to determine equivalency.

### Schema Mappings Used

Schema mappings were successfully retrieved from the DMS `schema_mapping_tool`:

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

### Statement-by-Statement Details

#### Statement 1: GetAllProductsAsync
- **Source Method**: `ProductRepository.GetAllProductsAsync()`
- **Type**: CTE with AVG/COUNT window functions, INNER JOIN, CASE/WHEN, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: CTE renamed to `productstats_cte`, table/column lowercase, schema prefix added

#### Statement 2: GetProductByIdAsync
- **Source Method**: `ProductRepository.GetProductByIdAsync(int productId)`
- **Type**: CTE with LAG window function, LEFT JOIN, CASE/WHEN, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: CTE renamed to `producthistory_cte`, table/column lowercase, schema prefix added

#### Statement 3: InsertProductAsync
- **Source Method**: `ProductRepository.InsertProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: `SCOPE_IDENTITY()` → `lastval()`, `GETDATE()` → `NOW()`, `BEGIN TRANSACTION` → `BEGIN`, `DECLARE @var` removed

#### Statement 4: UpdateProductAsync
- **Source Method**: `ProductRepository.UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: DECLARE/SET variables → subqueries, `GETDATE()` → `NOW()`, `BEGIN TRANSACTION` → `BEGIN`

#### Statement 5: DeleteProductAsync
- **Source Method**: `ProductRepository.DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: DECLARE/SET variables → SELECT subquery for history insert, `GETDATE()` → `NOW()`, `BEGIN TRANSACTION` → `BEGIN`

#### Statement 6: GetProductsByPriceRangeAsync
- **Source Method**: `ProductRepository.GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: CTE renamed to `rankedproducts`, table/column lowercase, schema prefix added

#### Statement 7: GetLowStockProductsAsync
- **Source Method**: `ProductRepository.GetLowStockProductsAsync(int threshold)`
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR
- **Key Changes**: CTE renamed to `stockanalysis`, `CAST(stockquantity AS NUMERIC)` added for integer division, table/column lowercase

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements replaced with PostgreSQL equivalents; `using Microsoft.Data.SqlClient` → `using Npgsql`; SqlConnection/SqlCommand/SqlDataReader → NpgsqlConnection/NpgsqlCommand/NpgsqlDataReader |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |

---

## Package Changes

| Package | Before | After |
|---------|--------|-------|
| Microsoft.Data.SqlClient | 5.1.4 | **Removed** |
| Npgsql | N/A | **8.0.6 (Added)** |
| Microsoft.Extensions.Configuration | 8.0.0 | 8.0.0 (Unchanged) |
| Microsoft.Extensions.Configuration.Json | 8.0.0 | 8.0.0 (Unchanged) |
| Microsoft.Extensions.DependencyInjection | 8.0.0 | 8.0.0 (Unchanged) |

---

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres
```

---

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL (Npgsql) Class | Occurrences |
|-----------------|--------------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 4 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

---

## Build Status

- **Final Build**: ✅ **Success** (0 errors, 10 warnings - all pre-existing nullable reference warnings)
- **Build Command**: `dotnet build`
- **Output Assembly**: `AdoCore.dll`

---

## Artifacts Generated

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements with source annotations |
| `converted_statements.sql` | All 7 converted PostgreSQL statements with conversion notes |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report for all 7 pairs |
| `migration_report.md` | This comprehensive migration summary |

---

## Manual Interventions Required

All 7 SQL statements required manual conversion due to DMS tool failure. The following SQL Server → PostgreSQL transformations were applied:

1. **Schema Objects**: All table and column names converted to lowercase per PostgreSQL conventions, with `productmanagement_dbo` schema prefix as indicated by DMS schema mapping
2. **SCOPE_IDENTITY()** → `lastval()` - PostgreSQL equivalent for retrieving last generated identity value
3. **GETDATE()** → `NOW()` - PostgreSQL equivalent for current timestamp
4. **BEGIN TRANSACTION** → `BEGIN` - PostgreSQL transaction syntax
5. **DECLARE @variable / SET @variable** → Subqueries or restructured queries - PostgreSQL doesn't support T-SQL variable declarations in the same way within a plain SQL batch
6. **Integer Division** → `CAST(column AS NUMERIC)` added where integer division could produce truncated results
7. **CTE Naming** → CTE names updated to avoid conflicts with table names (e.g., `ProductStats` CTE → `productstats_cte`)
