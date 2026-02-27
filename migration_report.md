# Migration Report: MS SQL Server to PostgreSQL
## AdoCore Application - ADO.NET Database Migration

### Migration Date: 2026-02-27
### Migration Project ARN: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

---

## Executive Summary

The AdoCore .NET application has been migrated from Microsoft SQL Server to PostgreSQL. All SQL statements, package references, ADO.NET class references, and connection strings have been updated for PostgreSQL compatibility.

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL statements processed** | 7 |
| **Statements converted by DMS tool** | 0 |
| **Statements requiring manual conversion** | 7 |
| **Statements validated as equivalent** | 0 |
| **Statements validated as non-equivalent** | 0 |
| **Statements with equivalency validation errors** | 7 |

### DMS Tool Results
All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp____statement_conversion_tool). All 7 failed with the same error:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion method applied**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Manual conversion rules applied**:
  - All schema object names converted to lowercase
  - SCOPE_IDENTITY() → RETURNING productid
  - GETDATE() → NOW()
  - DECLARE @var / SET → removed or converted to subqueries
  - BEGIN TRANSACTION / COMMIT → BEGIN / COMMIT

### SQL Equivalency Tool Results
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence). All 7 returned ERROR:
- **Error**: `'uniqueID'` (service-level issue, not related to SQL content)
- **Status**: All 7 marked as ERROR per tool output (no agent judgment applied)

---

## Statement Details

### Statement 1: GetAllProductsAsync
- **Location**: DataAccess/ProductRepository.cs, GetAllProductsAsync() method
- **Type**: SELECT with CTE, Window Functions (AVG, COUNT), CASE, INNER JOIN
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Schema object names to lowercase
- **Equivalency Status**: ERROR (tool error)

### Statement 2: GetProductByIdAsync
- **Location**: DataAccess/ProductRepository.cs, GetProductByIdAsync() method
- **Type**: SELECT with CTE, LAG() Window Function, CASE, LEFT JOIN
- **Parameters**: @ProductId
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Schema object names to lowercase
- **Equivalency Status**: ERROR (tool error)

### Statement 3: InsertProductAsync
- **Location**: DataAccess/ProductRepository.cs, InsertProductAsync() method
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Parameters**: @Name, @Description, @Price, @StockQuantity
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: SCOPE_IDENTITY() → RETURNING productid, GETDATE() → NOW(), DECLARE/SET removed, schema names to lowercase
- **Equivalency Status**: ERROR (tool error)

### Statement 4: UpdateProductAsync
- **Location**: DataAccess/ProductRepository.cs, UpdateProductAsync() method
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE()
- **Parameters**: @ProductId, @Name, @Description, @Price, @StockQuantity
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: DECLARE/SELECT INTO vars → subqueries, GETDATE() → NOW(), schema names to lowercase
- **Equivalency Status**: ERROR (tool error)

### Statement 5: DeleteProductAsync
- **Location**: DataAccess/ProductRepository.cs, DeleteProductAsync() method
- **Type**: Transaction block with DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE, CASE, GETDATE()
- **Parameters**: @ProductId
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: DECLARE/SELECT INTO vars → subqueries, GETDATE() → NOW(), schema names to lowercase
- **Equivalency Status**: ERROR (tool error)

### Statement 6: GetProductsByPriceRangeAsync
- **Location**: DataAccess/ProductRepository.cs, GetProductsByPriceRangeAsync() method
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN, CASE
- **Parameters**: @MinPrice, @MaxPrice
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Schema object names to lowercase
- **Equivalency Status**: ERROR (tool error)

### Statement 7: GetLowStockProductsAsync
- **Location**: DataAccess/ProductRepository.cs, GetLowStockProductsAsync() method
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND()
- **Parameters**: @Threshold
- **DMS Status**: FAILED
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Schema object names to lowercase, added CAST for integer division
- **Equivalency Status**: ERROR (tool error)

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | 7 SQL statements replaced with PostgreSQL equivalents; `using Microsoft.Data.SqlClient` → `using Npgsql`; SqlConnection → NpgsqlConnection; SqlCommand → NpgsqlCommand; SqlDataReader → NpgsqlDataReader |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.8` |
| `appsettings.json` | Connection strings updated from SQL Server to PostgreSQL format |

## Files Unchanged

| File | Reason |
|------|--------|
| `Program.cs` | No SQL Server imports or database code |
| `Business/ProductService.cs` | Business logic only, no database code |
| `CLI/CommandLineInterface.cs` | UI only, no database code |
| `CLI/InteractiveMenu.cs` | UI only, no database code |
| `Models/Product.cs` | POCO model, no database code |

---

## Package Changes

| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.8 |

Note: Npgsql version was upgraded from 8.0.1 (plan) to 8.0.8 to address known high severity vulnerability GHSA-x9vc-6hfv-hg8c.

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

---

## ADO.NET Type Changes

| SQL Server Type | PostgreSQL (Npgsql) Type |
|----------------|--------------------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| SqlParameter | NpgsqlParameter (not used explicitly) |

---

## Build Status

- **Final build**: ✅ **SUCCESS** (0 errors, 10 warnings)
- All warnings are pre-existing nullable reference type warnings, not introduced by the migration

---

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. The DMS tool was unavailable (metadata model creation failed) - all conversions were done manually
2. The SQL Equivalency tool returned errors for all pairs - equivalency could not be verified automatically
3. The DECLARE/SELECT INTO variable patterns (Statements 3, 4, 5) were restructured to use subqueries for Npgsql ADO.NET compatibility

**Recommendation**: Test all 7 SQL operations against a PostgreSQL database to verify functional equivalence:
- GetAllProductsAsync (Statement 1)
- GetProductByIdAsync (Statement 2)
- InsertProductAsync (Statement 3)
- UpdateProductAsync (Statement 4)
- DeleteProductAsync (Statement 5)
- GetProductsByPriceRangeAsync (Statement 6)
- GetLowStockProductsAsync (Statement 7)

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | sourceCode/ | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | sourceCode/ | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | sourceCode/ | Complete equivalency report with all 7 entries |
| `dms_failure_summary.md` | sourceCode/ | Detailed DMS failure documentation |
| `migration_report.md` | sourceCode/ | This comprehensive migration summary |
