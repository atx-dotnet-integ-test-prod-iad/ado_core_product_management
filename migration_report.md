# Migration Report: MS SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating package dependencies, replacing ADO.NET class references, updating connection strings, and converting database setup scripts.

## Migration Statistics

### SQL Statement Conversion
| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| DMS tool conversion attempts | 7 |
| DMS tool successful conversions | 0 |
| DMS tool failed conversions | 7 |
| Manual conversions (DMS failure fallback) | 7 |

### SQL Equivalency Validation
| Metric | Count |
|--------|-------|
| Total statement pairs validated | 7 |
| Equivalent (per tool) | 0 |
| Non-equivalent (per tool) | 0 |
| Error (per tool) | 7 |

**Note:** All DMS tool calls failed with: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`. Manual conversions were applied using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` method per the transformation definition. All SQL Equivalency tool validations returned ERROR with `'uniqueID'` error (service-side issue). All equivalency statuses are from the tool output only—no agent judgment was used.

## DMS Tool Failure Details
- **Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS ARN:** `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Schema:** dbo
- **Database:** ProductManagement
- **Region:** us-east-1
- All 7 statements were attempted through DMS, all failed with the same error
- Manual conversion with lowercase schema object names was applied as fallback

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL; SqlClient classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 removed; Npgsql 8.0.1 added |
| `appsettings.json` | Connection strings updated to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted from T-SQL to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted from T-SQL to PostgreSQL syntax |

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.1 |
| `Microsoft.Extensions.Configuration` 8.0.0 | `Microsoft.Extensions.Configuration` 8.0.0 (unchanged) |
| `Microsoft.Extensions.Configuration.Json` 8.0.0 | `Microsoft.Extensions.Configuration.Json` 8.0.0 (unchanged) |
| `Microsoft.Extensions.DependencyInjection` 8.0.0 | `Microsoft.Extensions.DependencyInjection` 8.0.0 (unchanged) |

## ADO.NET Class Replacements

| Original (SqlClient) | Replacement (Npgsql) |
|-----------------------|----------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed (not applicable) |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes:** Schema objects lowercased (Products→products, ProductId→productid, etc.)
- **SQL Features:** CTE, AVG/COUNT OVER(), CASE, ROUND, INNER JOIN
- **Equivalency Status:** ERROR (tool error: 'uniqueID')

### Statement 2: GetProductByIdAsync
- **Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes:** Schema objects lowercased
- **SQL Features:** CTE, LAG OVER(), CASE, ROUND, LEFT JOIN
- **Equivalency Status:** ERROR (tool error: 'uniqueID')

### Statement 3: InsertProductAsync
- **Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes:** SCOPE_IDENTITY()→RETURNING clause via writable CTE; GETDATE()→NOW(); BEGIN TRANSACTION/COMMIT→single CTE statement
- **SQL Features:** INSERT, RETURNING, writable CTE
- **Equivalency Status:** ERROR (tool error: 'uniqueID')

### Statement 4: UpdateProductAsync
- **Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes:** DECLARE/@var→CTE subquery; GETDATE()→NOW(); BEGIN TRANSACTION/COMMIT→writable CTE
- **SQL Features:** UPDATE, writable CTE, subquery
- **Equivalency Status:** ERROR (tool error: 'uniqueID')

### Statement 5: DeleteProductAsync
- **Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes:** DECLARE/@var→CTE subquery; GETDATE()→NOW(); BEGIN TRANSACTION/COMMIT→writable CTE; CASE preserved
- **SQL Features:** DELETE, writable CTE, CASE
- **Equivalency Status:** ERROR (tool error: 'uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes:** Schema objects lowercased
- **SQL Features:** CTE, RANK/PERCENT_RANK OVER(), BETWEEN, CASE
- **Equivalency Status:** ERROR (tool error: 'uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes:** Schema objects lowercased; added `::numeric` cast for integer division in ROUND
- **SQL Features:** CTE, AVG/MIN/MAX OVER(), CASE, ROUND
- **Equivalency Status:** ERROR (tool error: 'uniqueID')

## SQL Setup Script Conversion Details

### Key T-SQL to PostgreSQL Conversions Applied:
- `GO` batch separators → removed
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- `NVARCHAR(n)` → `VARCHAR(n)`
- `BIT` → `BOOLEAN`
- `DEFAULT 1/0` → `DEFAULT TRUE/FALSE`
- `GETDATE()` → `NOW()`
- `SCOPE_IDENTITY()` → `RETURNING` clause
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql`
- `SET NOCOUNT ON` → removed
- `IF NOT EXISTS (SELECT * FROM sys.objects...)` → `DROP ... IF EXISTS` / `CREATE TABLE IF NOT EXISTS`
- `SYSTEM_USER` → `current_user`
- `[dbo].[tablename]` → `tablename`
- Square bracket identifiers `[...]` → removed
- T-SQL trigger (using `inserted`/`deleted`) → PostgreSQL trigger function with `TG_OP`/`NEW`/`OLD`

## Statements Requiring Manual Review
All 7 SQL statements should be reviewed due to:
1. DMS tool failure - manual conversions applied
2. SQL Equivalency tool returned ERROR for all statements (service-side issue)
3. Transaction-based statements (3, 4, 5) were restructured from T-SQL multi-statement transactions to PostgreSQL writable CTEs

## Transformation Artifacts
- `extracted_statements.sql` - Complete catalog of all 7 original MS SQL statements
- `converted_statements.sql` - Complete catalog of all 7 converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Full equivalency validation report with all 7 statement pairs
- `migration_report.md` - This report
