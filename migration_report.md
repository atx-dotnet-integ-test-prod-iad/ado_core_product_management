# SQL Server to PostgreSQL Migration Report
## AdoCore Application - ProductRepository.cs

### Migration Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS | 0 |
| Requiring Manual Intervention | 7 |
| Equivalency Validated as EQUIVALENT | 0 |
| Equivalency Validated as NOT_EQUIVALENT | 0 |
| Equivalency Validation ERROR | 7 |

### DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was invoked for all 7 SQL statements with parameters:
- `schema_name`: "dbo"
- `database_name`: "ProductManagement"
- `region`: "us-east-1"

**All 7 invocations failed** with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Per the transformation definition, manual conversion was applied with lowercase schema object names for PostgreSQL compatibility (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

### SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was invoked for all 7 statement pairs.

**All 7 validations returned ERROR** with error:
```
'uniqueID'
```

This is an internal tool error unrelated to the statements themselves. Per the transformation definition, all are marked as ERROR status without agent judgment.

---

### Statement Conversion Details

#### Statement 1: GetAllProductsAsync
- **Source Method**: `GetAllProductsAsync()`
- **DMS Status**: FAILED
- **Conversion Method**: Manual with lowercase schema
- **Key Changes**:
  - Table/column names lowercased (Products -> products, ProductId -> productid, etc.)
  - CTE and window functions (AVG, COUNT OVER) are compatible in PostgreSQL
  - ROUND function compatible
  - CASE expressions compatible

#### Statement 2: GetProductByIdAsync
- **Source Method**: `GetProductByIdAsync(int productId)`
- **DMS Status**: FAILED
- **Conversion Method**: Manual with lowercase schema
- **Key Changes**:
  - Table/column names lowercased
  - LAG window function compatible in PostgreSQL
  - Parameter @ProductId syntax compatible with Npgsql

#### Statement 3: InsertProductAsync
- **Source Method**: `InsertProductAsync(Product product)`
- **DMS Status**: FAILED
- **Conversion Method**: Manual with lowercase schema
- **Key Changes**:
  - `SCOPE_IDENTITY()` replaced with `RETURNING productid` clause
  - `GETDATE()` replaced with `NOW()`
  - Single SQL block with DECLARE/SET restructured to multiple separate SQL commands within ADO.NET transaction
  - Table/column names lowercased

#### Statement 4: UpdateProductAsync
- **Source Method**: `UpdateProductAsync(Product product)`
- **DMS Status**: FAILED
- **Conversion Method**: Manual with lowercase schema
- **Key Changes**:
  - `DECLARE @var` pattern replaced with C# variables + separate SELECT query
  - `GETDATE()` replaced with `NOW()`
  - Single SQL block restructured to multiple separate SQL commands within ADO.NET transaction
  - Table/column names lowercased

#### Statement 5: DeleteProductAsync
- **Source Method**: `DeleteProductAsync(int productId)`
- **DMS Status**: FAILED
- **Conversion Method**: Manual with lowercase schema
- **Key Changes**:
  - `DECLARE @var` pattern replaced with C# variables + separate SELECT query
  - `GETDATE()` replaced with `NOW()`
  - Single SQL block restructured to multiple separate SQL commands within ADO.NET transaction
  - CASE expression in UPDATE compatible
  - Table/column names lowercased

#### Statement 6: GetProductsByPriceRangeAsync
- **Source Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **DMS Status**: FAILED
- **Conversion Method**: Manual with lowercase schema
- **Key Changes**:
  - Table/column names lowercased
  - RANK() and PERCENT_RANK() window functions compatible in PostgreSQL
  - BETWEEN clause compatible
  - CASE expressions compatible

#### Statement 7: GetLowStockProductsAsync
- **Source Method**: `GetLowStockProductsAsync(int threshold)`
- **DMS Status**: FAILED
- **Conversion Method**: Manual with lowercase schema
- **Key Changes**:
  - Table/column names lowercased
  - AVG, MIN, MAX window functions compatible
  - Added `::numeric` cast for integer division to produce decimal results
  - CASE expressions compatible
  - ROUND function compatible

---

### Files Modified During Migration

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | All SQL statements replaced with PostgreSQL equivalents; SqlClient classes replaced with Npgsql |
| `AdoCore.csproj` | Modified | Microsoft.Data.SqlClient 5.1.4 replaced with Npgsql 8.0.0 |
| `appsettings.json` | Modified | Connection strings updated from SQL Server to PostgreSQL format |
| `extracted_statements.sql` | New | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | New | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | New | Comprehensive equivalency validation report |
| `migration_report.md` | New | This migration report |

### Package Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|--------------------| --------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.0 |

### Class/Type Replacements

| Original | Replacement |
|----------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |

### Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | _(removed - not applicable)_ |
| TrustServerCertificate | `True` | _(removed - not applicable)_ |

### SQL Syntax Changes Applied

| SQL Server Syntax | PostgreSQL Equivalent |
|------------------|---------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE; SET @var = ...` | C# variables with separate SELECT query |
| `BEGIN TRANSACTION; ... COMMIT;` (in SQL) | ADO.NET `BeginTransactionAsync()` with `NpgsqlTransaction` |
| `StockQuantity / AvgStock` (integer division) | `stockquantity::numeric / avgstock` |

### Statements Requiring Manual Review

All 7 statements required manual conversion due to DMS tool failure and could not be validated for equivalency due to SQL Equivalency tool errors. These should be manually verified against the target PostgreSQL database:

1. **GetAllProductsAsync** - CTE with window functions (verify AVG/COUNT OVER behavior)
2. **GetProductByIdAsync** - CTE with LAG window function
3. **InsertProductAsync** - Transaction with RETURNING clause (verify productid is returned correctly)
4. **UpdateProductAsync** - Multi-command transaction (verify atomicity)
5. **DeleteProductAsync** - Multi-command transaction (verify cascade behavior)
6. **GetProductsByPriceRangeAsync** - RANK/PERCENT_RANK window functions
7. **GetLowStockProductsAsync** - Integer division with ::numeric cast

### Build Status

Final build: **SUCCESS** (0 errors, warnings are pre-existing nullable reference warnings)

---

*Report generated: 2026-05-06*
*Migration tool: AWS DMS MCP Statement Conversion Tool*
*Validation tool: SQL Equivalency MCP Tool*
