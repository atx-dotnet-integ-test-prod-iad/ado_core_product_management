# Migration Report: MS SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention (DMS Failed)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

## DMS Tool Status

The DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) was invoked for all 7 SQL statements. All 7 calls failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

- **Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Database Name**: `ProductManagement`
- **Schema Name**: `dbo`
- **Region**: `us-east-1`

**Note**: The DMS `schema_mapping_tool` was functional and successfully provided schema mapping information for all three tables (Products, ProductHistory, ProductStats), which was used to guide the manual conversion.

### DMS Schema Mapping Results

| Source Object | Target Object | Target Schema |
|---------------|---------------|---------------|
| `dbo.Products` | `products` | `productmanagement_dbo` |
| `dbo.ProductHistory` | `producthistory` | `productmanagement_dbo` |
| `dbo.ProductStats` | `productstats` | `productmanagement_dbo` |

### Key Schema Transformations from DMS Mapping

- All table names: lowercase (e.g., `Products` → `products`)
- All column names: lowercase (e.g., `ProductId` → `productid`, `StockQuantity` → `stockquantity`)
- Schema: `dbo` → `productmanagement_dbo`
- `int IDENTITY(1,1)` → `INTEGER GENERATED ALWAYS AS IDENTITY`
- `datetime` → `TIMESTAMP WITHOUT TIME ZONE`
- `decimal(18,2)` → `NUMERIC(18,2)`
- `nvarchar(n)` → `VARCHAR(n)`
- `bit` → `NUMERIC(1,0)`
- `GETDATE()` → `clock_timestamp()`

## SQL Equivalency Validation Status

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) was invoked for all 7 statement pairs. All 7 calls returned ERROR:

```json
{
  "equivalence_status": "ERROR",
  "error": "'uniqueID'"
}
```

This is a systematic tool error unrelated to statement quality. All equivalency results were marked as ERROR per the tool output. No agent judgment was used.

## Detailed Statement Conversion Report

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: CTE with window functions (AVG, COUNT), CASE, ROUND, INNER JOIN
- **DMS Status**: Failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (tool error)
- **Key Changes**:
  - CTE name: `ProductStats` → `productstats_cte` (disambiguated from table name)
  - Table: `Products` → `productmanagement_dbo.products`
  - All column/alias names lowercased

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: CTE with LAG() window function, parameterized query
- **DMS Status**: Failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (tool error)
- **Key Changes**:
  - CTE name: `ProductHistory` → `producthistory_cte` (disambiguated from table name)
  - Table: `Products` → `productmanagement_dbo.products`
  - All column/alias names lowercased

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SCOPE_IDENTITY(), GETDATE()
- **DMS Status**: Failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (tool error)
- **Key Changes**:
  - `DECLARE @NewProductId / SCOPE_IDENTITY()` → Writable CTE with `INSERT...RETURNING productid`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION / COMMIT` → Writable CTE (single atomic statement)
  - Tables: `Products` → `productmanagement_dbo.products`, `ProductHistory` → `productmanagement_dbo.producthistory`, `ProductStats` → `productmanagement_dbo.productstats`

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, variable assignment, GETDATE()
- **DMS Status**: Failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (tool error)
- **Key Changes**:
  - `DECLARE @OldPrice / @OldStock` → Writable CTE `old_values` subquery
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION / COMMIT` → Writable CTE (single atomic statement)
  - Tables lowercased with `productmanagement_dbo` schema prefix

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, CASE expression, GETDATE()
- **DMS Status**: Failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (tool error)
- **Key Changes**:
  - `DECLARE @OldPrice / @OldStock` → Writable CTE `old_values` subquery
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION / COMMIT` → Writable CTE (single atomic statement)
  - `DELETE FROM Products` → `DELETE FROM productmanagement_dbo.products`
  - Tables lowercased with `productmanagement_dbo` schema prefix

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: CTE with RANK(), PERCENT_RANK() window functions, BETWEEN
- **DMS Status**: Failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (tool error)
- **Key Changes**:
  - CTE name: `RankedProducts` → `rankedproducts`
  - Table: `Products` → `productmanagement_dbo.products`
  - All column/alias names lowercased

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status**: Failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (tool error)
- **Key Changes**:
  - CTE name: `StockAnalysis` → `stockanalysis`
  - Table: `Products` → `productmanagement_dbo.products`
  - Added `CAST(stockquantity AS NUMERIC)` for integer division fix
  - All column/alias names lowercased

## Code Changes Summary

### Package Dependencies (AdoCore.csproj)
- **Removed**: `Microsoft.Data.SqlClient` Version `5.1.4`
- **Added**: `Npgsql` Version `8.0.6`
- **Preserved**: `Microsoft.Extensions.Configuration` 8.0.0, `Microsoft.Extensions.Configuration.Json` 8.0.0, `Microsoft.Extensions.DependencyInjection` 8.0.0

### Type Replacements (DataAccess/ProductRepository.cs)
| Original (MS SQL) | Replacement (PostgreSQL) | Count |
|--------------------|---------------------------|-------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

### Connection String Updates (appsettings.json)
| Parameter | Original (SQL Server) | Updated (PostgreSQL) |
|-----------|----------------------|---------------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed |
| Certificate | `TrustServerCertificate=True` | Removed |

### Column Reference Updates (MapProductFromReader)
All column name string references updated from PascalCase to lowercase to match PostgreSQL naming:
- `ProductId` → `productid`
- `Name` → `name`
- `Description` → `description`
- `Price` → `price`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`

## Build Status

| Step | Build Result |
|------|-------------|
| Step 3 (SQL Re-integration) | ✅ Success |
| Step 4 (Package Update) | ❌ Failed (expected - types not yet updated) |
| Step 5 (Type Replacement) | ✅ Success |
| Step 6 (Connection Strings) | ✅ Success |
| **Final Build** | **✅ Success (0 errors)** |

## Artifacts

| File | Description | Status |
|------|-------------|--------|
| `extracted_statements.sql` | All 7 original MS SQL statements | ✅ Complete |
| `converted_statements.sql` | All 7 converted PostgreSQL statements | ✅ Complete |
| `sql_equivalency_validation_report.json` | Equivalency validation for all 7 pairs | ✅ Complete |
| `migration_report.md` | This comprehensive report | ✅ Complete |

## Notes and Recommendations

1. **DMS Tool Failure**: The DMS statement conversion tool consistently failed with a metadata model creation error. Schema mapping was obtained from the DMS schema_mapping_tool and used for manual conversion.

2. **SQL Equivalency Tool Failure**: The SQL Equivalency tool returned systematic errors for all pairs. Manual review of converted statements is recommended.

3. **Writable CTEs**: Statements 3, 4, and 5 were restructured from T-SQL transaction blocks with DECLARE/SET to PostgreSQL writable CTEs. This maintains atomicity while being compatible with Npgsql parameterized queries.

4. **Schema Prefix**: All table references now use the `productmanagement_dbo` schema prefix as determined by the DMS schema mapping. The target PostgreSQL database must have this schema configured.

5. **Integer Division**: In Statement 7, an explicit `CAST(stockquantity AS NUMERIC)` was added to prevent integer division truncation in PostgreSQL (which differs from SQL Server behavior).
