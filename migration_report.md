# Migration Report: MS SQL Server to PostgreSQL

## Project: AdoCore - .NET ADO Application
## Date: 2026-05-02

---

## Executive Summary

This report documents the complete migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET data access classes, modifying package references, updating connection strings, and converting database setup scripts.

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool processing | 7 |
| Statements validated as equivalent (by SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status
All 7 SQL statements were passed to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with parameters:
- `schema_name`: `dbo`
- `database_name`: `ProductManagement`

**All 7 failed** with error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

Manual conversion was applied for all 7 statements using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` policy, which converts all schema object names to lowercase for PostgreSQL compatibility.

### SQL Equivalency Tool Status
All 7 statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 returned ERROR** with error: `'uniqueID'`

Per the transformation definition, all equivalency statuses were marked as ERROR based solely on the tool output. No agent judgment was used to determine equivalency.

---

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetAllProductsAsync()` method
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercase schema objects. SQL syntax (CTE, window functions) is compatible between MS SQL and PostgreSQL.
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductByIdAsync()` method
- **Type**: CTE with LAG window functions, LEFT JOIN, CASE with NULL handling, ROUND
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercase schema objects. LAG window functions are compatible.
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `InsertProductAsync()` method
- **Type**: Multi-statement transaction with DECLARE, INSERT, SCOPE_IDENTITY(), ProductHistory logging, ProductStats update
- **DMS Status**: FAILED
- **Manual Conversion**: 
  - `SCOPE_IDENTITY()` → `RETURNING productid` via writeable CTE
  - `GETDATE()` → `NOW()`
  - `DECLARE @var / SET @var` → Eliminated via CTE structure
  - `BEGIN TRANSACTION/COMMIT` → Handled via single CTE statement (atomic)
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `UpdateProductAsync()` method
- **Type**: Multi-statement transaction with DECLARE, variable assignment, UPDATE, ProductHistory logging, ProductStats update
- **DMS Status**: FAILED
- **Manual Conversion**:
  - `DECLARE @var / SELECT @var = col` → CTE subquery (`old_values`)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Handled via single CTE statement (atomic)
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `DeleteProductAsync()` method
- **Type**: Multi-statement transaction with DECLARE, variable assignment, ProductHistory logging, DELETE, ProductStats update with CASE WHEN
- **DMS Status**: FAILED
- **Manual Conversion**:
  - `DECLARE @var / SELECT @var = col` → CTE subquery (`old_values`)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Handled via single CTE statement (atomic)
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductsByPriceRangeAsync()` method
- **Type**: CTE with RANK() OVER, PERCENT_RANK() OVER, BETWEEN, CASE
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercase schema objects. RANK/PERCENT_RANK window functions are compatible.
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetLowStockProductsAsync()` method
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Status**: FAILED
- **Manual Conversion**: Lowercase schema objects. Added `CAST(stockquantity AS DECIMAL)` to handle integer division in PostgreSQL.
- **Equivalency Status**: ERROR

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced `using Microsoft.Data.SqlClient` with `using Npgsql`. Replaced `SqlConnection` → `NpgsqlConnection`, `SqlCommand` → `NpgsqlCommand`, `SqlDataReader` → `NpgsqlDataReader`. Replaced all 7 SQL statements with PostgreSQL equivalents. |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` package reference with `Npgsql 8.0.1`. |
| `appsettings.json` | Updated connection strings from SQL Server format (`Server=`) to PostgreSQL format (`Host=`). Added `Username` and `Password` parameters. Removed `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`. |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax: `SERIAL` instead of `IDENTITY`, `NOW()` instead of `GETDATE()`, `CREATE OR REPLACE FUNCTION` instead of `CREATE OR ALTER PROCEDURE`, `plpgsql` language, removed `GO` statements. |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion to PostgreSQL: `SERIAL`, `NOW()`, `VARCHAR` instead of `NVARCHAR`, `BOOLEAN` instead of `BIT`, `TIMESTAMP` instead of `DATETIME`, trigger functions in `plpgsql`, `DROP IF EXISTS` instead of SQL Server `IF EXISTS` patterns. |

## Transformation Artifacts

| Artifact | Location | Contents |
|----------|----------|----------|
| Extracted SQL Statements | `extracted_statements.sql` | All 7 original MS SQL statements |
| Converted SQL Statements | `converted_statements.sql` | All 7 converted PostgreSQL statements |
| SQL Equivalency Report | `sql_equivalency_validation_report.json` | Complete validation report with all 7 statement pairs |

---

## Key Conversion Patterns Applied

| MS SQL Server | PostgreSQL | Notes |
|---------------|-----------|-------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (via CTE) | Used writeable CTE pattern |
| `GETDATE()` | `NOW()` | Equivalent function |
| `DECLARE @var / SET @var` | CTE subquery | PostgreSQL doesn't support T-SQL variables in plain SQL |
| `BEGIN TRANSACTION / COMMIT` | Single CTE statement | Writeable CTEs are atomic in PostgreSQL |
| `NVARCHAR` | `VARCHAR` | PostgreSQL uses VARCHAR for all text |
| `BIT` | `BOOLEAN` | Direct type mapping |
| `DATETIME` | `TIMESTAMP` | Direct type mapping |
| `IDENTITY(1,1)` | `SERIAL` | Auto-increment column |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | PostgreSQL uses functions with `plpgsql` |
| `SET NOCOUNT ON` | *(removed)* | No equivalent needed in PostgreSQL |
| `GO` | *(removed)* | Batch separator not used in PostgreSQL |
| `SYSTEM_USER` | `current_user` | Current user function |
| `SqlConnection` | `NpgsqlConnection` | ADO.NET class replacement |
| `SqlCommand` | `NpgsqlCommand` | ADO.NET class replacement |
| `SqlDataReader` | `NpgsqlDataReader` | ADO.NET class replacement |
| `Microsoft.Data.SqlClient` | `Npgsql` | Package replacement |
| `Server=` | `Host=` | Connection string parameter |
| `Trusted_Connection=True` | `Username=;Password=` | Authentication method |

---

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS tool failed for all statements (metadata model creation error)
2. SQL Equivalency tool returned ERROR for all statement pairs

**Recommended Actions:**
- Test all 7 SQL statements against an actual PostgreSQL database
- Verify the writeable CTE pattern works correctly for INSERT/UPDATE/DELETE operations
- Validate that the `CAST(stockquantity AS DECIMAL)` in Statement 7 produces correct results
- Verify parameter binding works correctly with Npgsql for all `@param` style parameters

---

## Completeness Verification

- [x] All SQL Server packages replaced with PostgreSQL equivalents
- [x] All SQL Server ADO.NET classes replaced with Npgsql equivalents
- [x] All 7 SQL statements processed through DMS MCP tool (all failed)
- [x] All 7 statements manually converted with lowercase schema names
- [x] Complete catalog of original statements (extracted_statements.sql)
- [x] Complete catalog of converted statements (converted_statements.sql)
- [x] All 7 statement pairs validated through SQL Equivalency tool
- [x] Comprehensive equivalency report generated (sql_equivalency_validation_report.json)
- [x] No agent judgment used for equivalency determination
- [x] Connection strings updated to PostgreSQL format
- [x] Database setup scripts converted to PostgreSQL syntax
- [x] No SQL Server references remain in any .cs files
- [x] Code structure and async patterns preserved
