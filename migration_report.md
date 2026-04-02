# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13 (postgres)
- **Application Framework**: .NET 9.0 / ADO.NET
- **DMS Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

---

## Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention (DMS failure) | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency errors | 7 |

### DMS Tool Status
The DMS statement_conversion_tool was unavailable during migration due to persistent timeout errors:
- **Error**: "Metadata model conversion/creation did not complete after multiple attempts"
- **Attempts**: 4+ separate invocations across different SQL statements
- **DMS Schema Mapping Tool**: Successfully returned schema mappings for all 3 tables

### SQL Equivalency Tool Status
The SQL Equivalency tool returned ERROR for all 7 statement pairs:
- **Error**: `'uniqueID'` - a systemic service error not related to input quality
- **All 7 pairs individually validated** through the tool
- **No agent judgment** was used for equivalency determination

---

## Schema Mapping (from DMS schema_mapping_tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |

### Key Conversions Applied
| SQL Server | PostgreSQL |
|------------|------------|
| `SCOPE_IDENTITY()` | `lastval()` |
| `GETDATE()` | `clock_timestamp()` |
| `BEGIN TRANSACTION` | `BEGIN` |
| `DECLARE @var` / `SET @var` | Restructured with subqueries / `INSERT...SELECT` |
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| `nvarchar(n)` | `VARCHAR(n)` |
| `decimal(18,2)` | `NUMERIC(18,2)` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |

---

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE and window functions (AVG OVER, COUNT OVER)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names lowercased per DMS schema mapping; CTE alias renamed to avoid conflict with table name

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE and LAG window function, parameterized
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names lowercased; CTE alias renamed

### Statement 3: InsertProductAsync
- **Type**: Transaction block with SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: SCOPE_IDENTITY() -> lastval(), GETDATE() -> clock_timestamp(), DECLARE/SET removed, BEGIN TRANSACTION -> BEGIN

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, UPDATE, INSERT history
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE @var removed, reordered operations (INSERT...SELECT for history before UPDATE), GETDATE() -> clock_timestamp()

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE variables, DELETE, INSERT history, UPDATE stats
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE @var removed, reordered operations (history/stats before DELETE), GETDATE() -> clock_timestamp()

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names lowercased per DMS schema mapping

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names lowercased; added CAST for integer division

---

## Files Modified

| File | Changes |
|------|---------|
| `sourceCode/DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; `using Microsoft.Data.SqlClient` → `using Npgsql`; `SqlConnection` → `NpgsqlConnection`; `SqlCommand` → `NpgsqlCommand`; `SqlDataReader` → `NpgsqlDataReader` |
| `sourceCode/AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.9` |
| `sourceCode/appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |

## Files Not Modified (no SQL or SqlClient usage)

| File | Reason |
|------|--------|
| `sourceCode/Program.cs` | No database access code |
| `sourceCode/Business/ProductService.cs` | No database access code |
| `sourceCode/CLI/CommandLineInterface.cs` | No database access code |
| `sourceCode/CLI/InteractiveMenu.cs` | No database access code |
| `sourceCode/Models/Product.cs` | No database access code |

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | All 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Comprehensive equivalency validation results |
| `migration_report.md` | `sourceCode/` | This report |

---

## Build Status
- **Final Build**: ✅ **SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference type warnings)
- **Compilation Target**: net9.0

---

## Package Dependencies (After Migration)

| Package | Version | Status |
|---------|---------|--------|
| ~~Microsoft.Data.SqlClient~~ | ~~5.1.4~~ | **Removed** |
| **Npgsql** | **8.0.9** | **Added** |
| Microsoft.Extensions.Configuration | 8.0.0 | Unchanged |
| Microsoft.Extensions.Configuration.Json | 8.0.0 | Unchanged |
| Microsoft.Extensions.DependencyInjection | 8.0.0 | Unchanged |

---

## Connection String Changes

| Setting | Before (SQL Server) | After (PostgreSQL) |
|---------|--------------------|--------------------|
| DevConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres` |
| ProdConnection | Same as Dev | Same as Dev |

---

## Notes and Recommendations

1. **DMS Tool Unavailability**: The DMS statement_conversion_tool experienced persistent timeouts during this migration. All 7 SQL statements were manually converted using schema mapping data from the DMS schema_mapping_tool.

2. **SQL Equivalency Tool Error**: The SQL Equivalency tool returned systemic errors ('uniqueID') for all 7 statement pairs. Manual review of the converted statements is recommended.

3. **Npgsql Version**: Updated from planned 8.0.1 to 8.0.9 to address known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

4. **Transaction Handling**: The transaction blocks in statements 3, 4, and 5 were restructured to avoid T-SQL DECLARE/SET patterns by using INSERT...SELECT and subqueries instead. The operation order was adjusted to capture old values before modifications.

5. **Schema Prefix**: All table references now use the `productmanagement_dbo` schema prefix as determined by DMS schema mapping. Ensure the PostgreSQL database has this schema created.
