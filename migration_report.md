# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS Tool | 0 |
| Requiring Manual Intervention (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| With Equivalency Validation Errors | 7 |

## DMS Tool Status

All 7 SQL statements were submitted to the DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) using:
- Migration Project ARN: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- Schema: `dbo`
- Database: `ProductManagement`

**All 7 conversions failed** with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

However, the DMS `schema_mapping_tool` **was successful** and provided the schema mappings used for manual conversion:

| Source Table | Target Table | Target Schema |
|---|---|---|
| Products | products | productmanagement_dbo |
| ProductHistory | producthistory | productmanagement_dbo |
| ProductStats | productstats | productmanagement_dbo |

## SQL Equivalency Tool Status

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 validations returned ERROR** with:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a tool infrastructure issue, not a statement-level problem.

## Manual Conversion Rules Applied

Since DMS conversion failed, the following manual conversion rules were applied per the transformation definition (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):

1. **Schema Mapping**: All table references updated to use `productmanagement_dbo` schema prefix with lowercase names (from DMS schema_mapping_tool output)
2. **Column Names**: All column references converted to lowercase
3. **GETDATE()** → `clock_timestamp()` (matching DMS schema DDL defaults)
4. **SCOPE_IDENTITY()** → `RETURNING productid` clause
5. **DECIMAL(18,2)** → `NUMERIC(18,2)`
6. **Transaction Handling**: SQL Server multi-statement batches with `DECLARE`/`SET` refactored to separate Npgsql commands within C# managed transactions
7. **Integer Division**: Added `CAST(... AS NUMERIC)` for proper `ROUND()` behavior with integer operands

## Statement-by-Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source**: CTE with ProductStats, window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Key Changes**: Table → `productmanagement_dbo.products`, CTE name → `productstats_cte`, all identifiers lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure error)

### Statement 2: GetProductByIdAsync
- **Source**: CTE with ProductHistory, LAG window function, parameterized WHERE
- **Key Changes**: Table → `productmanagement_dbo.products`, CTE name → `producthistory_cte`, all identifiers lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure error)

### Statement 3: InsertProductAsync
- **Source**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Changes**: SCOPE_IDENTITY() → RETURNING clause, GETDATE() → clock_timestamp(), split into separate commands
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure error)

### Statement 4: UpdateProductAsync
- **Source**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT history
- **Key Changes**: DECLARE/SET variables → C# variables via separate SELECT, GETDATE() → clock_timestamp()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure error)

### Statement 5: DeleteProductAsync
- **Source**: Transaction block with DECLARE, SELECT INTO variables, DELETE, UPDATE stats with CASE
- **Key Changes**: Same as Statement 4 pattern, GETDATE() → clock_timestamp()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure error)

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN
- **Key Changes**: Table → `productmanagement_dbo.products`, all identifiers lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure error)

### Statement 7: GetLowStockProductsAsync
- **Source**: CTE with AVG/MIN/MAX OVER, CASE, ROUND
- **Key Changes**: Table → `productmanagement_dbo.products`, CAST for integer division, all identifiers lowercase
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure error)

## File-by-File Change Summary

### DataAccess/ProductRepository.cs
- **Using Directive**: `Microsoft.Data.SqlClient` → `Npgsql`
- **ADO.NET Classes**:
  - `SqlConnection` → `NpgsqlConnection` (field, constructor, method signatures)
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`
- **SQL Statements**: All 7 replaced with PostgreSQL equivalents
- **Transaction Handling**: Refactored from SQL batch to C# managed transactions
- **Column References**: Updated from PascalCase to lowercase in MapProductFromReader

### AdoCore.csproj
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`
- Note: Used 8.0.6 instead of 8.0.1 to avoid known vulnerability (GHSA-x9vc-6hfv-hg8c)

### appsettings.json
- **Connection Strings**: Converted from SQL Server to PostgreSQL format
  - `Server=` → `Host=`
  - `Database=ProductManagement` → `Database=postgres`
  - Removed: `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`
  - Added: `Port=5432`, `Username=postgres`, `Password=postgres`

## Build Verification

Final build status: **SUCCESS** (0 errors, 10 warnings - all pre-existing nullable reference warnings)

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS conversion tool was unavailable (all returned same infrastructure error)
2. SQL Equivalency validation tool returned errors for all statement pairs
3. Manual conversions were applied based on DMS schema mapping output

## Artifacts

| Artifact | Location | Description |
|---|---|---|
| Extracted Statements | `sourceCode/extracted_statements.sql` | All 7 original MS SQL statements |
| Converted Statements | `sourceCode/converted_statements.sql` | All 7 PostgreSQL converted statements |
| Equivalency Report | `sourceCode/sql_equivalency_validation_report.json` | Full validation report with all 7 pairs |
| Migration Report | `sourceCode/migration_report.md` | This report |
