# Migration Report: Microsoft SQL Server to PostgreSQL

## Executive Summary
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating package dependencies, replacing ADO.NET classes, updating connection strings, and converting database setup scripts.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Status
The DMS MCP Statement Conversion Tool (dms-mcp___statement_conversion_tool) was attempted for all 7 SQL statements but consistently failed with the error:
```
Metadata model creation failed: {'error': 'Metadata model creation did not complete after N attempts'}
```

The DMS Schema Mapping Tool (dms-mcp___schema_mapping_tool) was **successfully** used to obtain target schema mappings for:
- `Products` → `products` (in schema `productmanagement_dbo`)
- `ProductHistory` → `producthistory` (in schema `productmanagement_dbo`)
- `ProductStats` → `productstats` (in schema `productmanagement_dbo`)

These schema mappings informed the manual conversion approach.

## SQL Equivalency Validation
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was used for all 7 statement pairs. All returned ERROR status with error `'uniqueID'`. See `sql_equivalency_validation_report.json` for the complete detailed report.

## Files Changed

### 1. sourceCode/DataAccess/ProductRepository.cs
- **SQL Statements**: All 7 SQL statements converted from MS SQL Server to PostgreSQL syntax
- **Using Directives**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **ADO.NET Classes**:
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand` (7 instances)
  - `SqlDataReader` → `NpgsqlDataReader`
- **Key SQL Conversions**:
  - `SCOPE_IDENTITY()` → PostgreSQL `RETURNING` clause with data-modifying CTEs
  - `GETDATE()` → `NOW()`
  - `DECLARE @variable / SET @variable` → PostgreSQL CTEs (WITH clause)
  - All table/column names converted to lowercase per DMS schema mapping
  - CTE names adjusted to avoid conflict with table names (e.g., `productstats_cte`)

### 2. sourceCode/AdoCore.csproj
- **Package Reference**: `Microsoft.Data.SqlClient` v5.1.4 → `Npgsql` v8.0.6

### 3. sourceCode/appsettings.json
- **Connection Strings**: Converted from SQL Server to PostgreSQL format
  - `Server=localhost` → `Host=localhost`
  - Added `Port=5432`
  - Removed `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`
  - Added `Username=postgres;Password=postgres` (placeholder credentials)

### 4. sourceCode/Scripts/01_InitialSetup.sql
- Converted from SQL Server to PostgreSQL syntax
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `GETDATE()` → `NOW()`
- `nvarchar` → `varchar`
- `GO` statements removed
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
- `SCOPE_IDENTITY()` → `RETURNING` clause
- Conditional checks converted to PostgreSQL equivalents

### 5. sourceCode/Database/Scripts/01_InitialSetup.sql
- Full conversion from SQL Server to PostgreSQL syntax including:
  - All table definitions with lowercase names
  - `bit` → `boolean`
  - `datetime` → `timestamp without time zone`
  - Trigger converted from SQL Server syntax to PostgreSQL function + trigger pattern
  - `SYSTEM_USER` → `current_user`
  - All stored procedures converted to PostgreSQL functions
  - Sample data inserts preserved with PostgreSQL syntax

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: CTE name changed to `productstats_cte` to avoid conflict with `productstats` table. All identifiers lowercase.
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 2: GetProductByIdAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: CTE name changed to `producthistory_cte`. LAG window functions preserved (PostgreSQL compatible). All identifiers lowercase.
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 3: InsertProductAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Transaction block restructured using data-modifying CTEs. `SCOPE_IDENTITY()` replaced with `RETURNING` clause. `GETDATE()` → `NOW()`.
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 4: UpdateProductAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE/variable pattern replaced with CTEs. `GETDATE()` → `NOW()`. All identifiers lowercase.
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 5: DeleteProductAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE/variable pattern replaced with CTEs. `GETDATE()` → `NOW()`. CASE expression preserved. All identifiers lowercase.
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: RANK/PERCENT_RANK window functions preserved (PostgreSQL compatible). BETWEEN clause preserved. All identifiers lowercase.
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

### Statement 7: GetLowStockProductsAsync
- **Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: AVG/MIN/MAX window functions preserved. Added `CAST(stockquantity AS NUMERIC)` for proper division. All identifiers lowercase.
- **Equivalency**: ERROR (tool returned `'uniqueID'` error)

## ADO.NET Class Replacements Summary

| Original (SQL Server) | Replacement (PostgreSQL) | Occurrences |
|----------------------|-------------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## Build Verification
All steps verified with `dotnet build AdoCore.sln` - **Build succeeded with 0 errors** at each step.

## Artifacts Generated
- `extracted_statements.sql` - All 7 original MS SQL Server statements
- `converted_statements.sql` - All 7 converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Comprehensive equivalency validation report
- `migration_report.md` - This report

## Notes and Recommendations
1. **DMS Tool Failures**: All DMS statement conversion attempts failed due to metadata model creation timeouts. The schema mapping tool worked correctly, confirming the DMS service was partially available.
2. **Equivalency Validation Errors**: All SQL equivalency validations returned ERROR with `'uniqueID'` error. Manual review of the converted statements is recommended.
3. **Connection Strings**: Placeholder credentials (postgres/postgres) are used. Update with actual credentials before deployment.
4. **Data-Modifying CTEs**: The transaction blocks (Insert, Update, Delete) were converted using PostgreSQL's data-modifying CTE pattern. This is a PostgreSQL-specific feature that allows combining multiple DML operations in a single statement.
5. **Integer Division**: The `StockPercentageOfAverage` calculation includes an explicit `CAST(stockquantity AS NUMERIC)` to avoid integer division truncation in PostgreSQL.
