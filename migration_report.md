# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-02 |
| **Source Database** | Microsoft SQL Server 2019 |
| **Target Database** | PostgreSQL 13 |
| **Source Framework** | .NET 9.0 with Microsoft.Data.SqlClient 5.1.4 |
| **Target Framework** | .NET 9.0 with Npgsql 9.0.5 |
| **Total SQL Statements Processed (Repository)** | 7 |
| **Total SQL Scripts Converted** | 2 |
| **DMS Conversion Success** | 0 |
| **DMS Conversion Failures** | 7 (all repository statements) + 1 (script attempt) |
| **Manual Conversions** | 7 (repository) + 2 (scripts) |
| **Equivalency Validations Attempted** | 7 |
| **Equivalency Results: EQUIVALENT** | 0 |
| **Equivalency Results: NOT_EQUIVALENT** | 0 |
| **Equivalency Results: ERROR** | 7 |

## DMS Tool Status

The AWS Database Migration Service (DMS) MCP tool was attempted for all SQL statement conversions. The tool consistently failed with the following error:

```
Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
```

**DMS Configuration Used:**
- Migration Project ARN: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- Region: `us-east-1`
- Schema: `dbo`
- Server: `172.31.94.132`
- Database: `ProductManagement`

**Retry Attempts:**
1. Default poll settings (15 attempts) — Error: Metadata model conversion timeout
2. Extended poll settings (30 attempts, 15s interval) — Command execution timeout after 300s
3. Simple query test — Error: Metadata model creation timeout
4. Script conversion attempt — Error: Metadata model conversion timeout

Due to persistent DMS failures, all conversions were performed manually following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` methodology as specified in the transformation definition.

## SQL Equivalency Validation Status

The SQL Equivalency MCP tool was called for all 7 repository statement pairs. The tool consistently returned an ERROR status:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be an infrastructure/backend issue with the equivalency tool itself, not related to the SQL statements. All 7 statement pairs are marked as ERROR in the validation report.

**Detailed report:** See `sql_equivalency_validation_report.json` for complete statement-level results.

## Files Modified

### Source Code Changes

| File | Change Type | Description |
|------|-----------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | All 7 SQL statements converted to PostgreSQL; ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader); using directive updated; transaction methods restructured for Npgsql compatibility |
| `AdoCore.csproj` | Modified | Microsoft.Data.SqlClient 5.1.4 → Npgsql 9.0.5 |
| `appsettings.json` | Modified | Connection strings converted from SQL Server to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL syntax |

### New Artifacts Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This report |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** Schema objects to lowercase, SQL syntax fully PostgreSQL compatible
- **Equivalency:** ERROR (tool infrastructure issue)

### Statement 2: GetProductByIdAsync
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** Schema objects to lowercase, LAG window function preserved (PostgreSQL compatible)
- **Equivalency:** ERROR (tool infrastructure issue)

### Statement 3: InsertProductAsync
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** SCOPE_IDENTITY() → INSERT...RETURNING; GETDATE() → NOW(); Transaction restructured to ADO.NET-level (BeginTransactionAsync/CommitAsync) with separate commands
- **Equivalency:** ERROR (tool infrastructure issue)

### Statement 4: UpdateProductAsync
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** DECLARE/SET @variable pattern → separate SELECT command; GETDATE() → NOW(); Transaction restructured to ADO.NET-level
- **Equivalency:** ERROR (tool infrastructure issue)

### Statement 5: DeleteProductAsync
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** DECLARE/SET @variable pattern → separate SELECT command; GETDATE() → NOW(); Transaction restructured to ADO.NET-level
- **Equivalency:** ERROR (tool infrastructure issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** Schema objects to lowercase, RANK/PERCENT_RANK preserved (PostgreSQL compatible)
- **Equivalency:** ERROR (tool infrastructure issue)

### Statement 7: GetLowStockProductsAsync
- **Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** Schema objects to lowercase, CAST added for integer division, AVG/MIN/MAX window functions preserved
- **Equivalency:** ERROR (tool infrastructure issue)

## SQL Script Conversion Details

### Scripts/01_InitialSetup.sql
- IF NOT EXISTS with sys.objects → CREATE TABLE IF NOT EXISTS
- IDENTITY(1,1) → SERIAL
- [nvarchar] → VARCHAR
- [datetime] → TIMESTAMP
- GETDATE() → NOW()
- GO → Removed
- CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION with RETURNS TABLE
- SCOPE_IDENTITY() → RETURNING clause
- Sample data insertion preserved with DO $$ block for conditional check

### Database/Scripts/01_InitialSetup.sql
- All table definitions converted (Categories, Suppliers, Products, ProductHistory, ProductStats)
- [bit] → BOOLEAN (with TRUE/FALSE instead of 1/0)
- IDENTITY(1,1) → SERIAL
- [nvarchar] → VARCHAR
- [datetime] → TIMESTAMP
- [dbo].[TableName] → tablename (lowercase, no schema prefix)
- GETDATE() → NOW()
- SYSTEM_USER → CURRENT_USER
- GO → Removed
- Trigger: AFTER INSERT, UPDATE, DELETE → separate trigger function + CREATE TRIGGER with FOR EACH ROW
- Stored procedures → CREATE OR REPLACE FUNCTION with RETURNS TABLE/VOID
- Indexes preserved with lowercase naming
- Foreign key constraints preserved
- Sample data INSERT statements preserved

## ADO.NET Class Migration

| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|--------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (not directly used - AddWithValue pattern preserved) |

## Connection String Migration

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=${PGPASSWORD}` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed (not applicable) |

## Build Verification

The project builds successfully after all migrations:
- **Errors:** 0
- **Warnings:** 10 (all pre-existing CS8600/CS8601/CS8603/CS8618/CS8625 nullable reference type warnings)
- **Output:** `AdoCore.dll` produced successfully

## Manual Interventions Required

All SQL statements required manual conversion due to DMS tool failures. The following methodology was applied:

1. **Schema objects** converted to lowercase per PostgreSQL conventions
2. **T-SQL specific functions** replaced with PostgreSQL equivalents:
   - `SCOPE_IDENTITY()` → `INSERT...RETURNING` / `lastval()`
   - `GETDATE()` → `NOW()`
   - `SYSTEM_USER` → `CURRENT_USER`
3. **Transaction blocks** restructured from embedded T-SQL transactions to ADO.NET-level transactions
4. **Variable declarations** (`DECLARE @var`) replaced with separate SELECT queries or subqueries
5. **Data types** converted: `nvarchar` → `VARCHAR`, `datetime` → `TIMESTAMP`, `bit` → `BOOLEAN`

## Recommendations

1. **Test all database operations** against a PostgreSQL 13 instance to verify runtime behavior
2. **Review equivalency validation errors** — the tool infrastructure issue prevented automated validation; manual testing is recommended
3. **Review connection string security** — ensure `${PGPASSWORD}` environment variable is properly configured in deployment
4. **Consider adding integration tests** for all 7 repository methods against PostgreSQL
5. **Monitor for any case-sensitivity issues** — PostgreSQL treats unquoted identifiers as lowercase by default; all schema objects have been converted to lowercase
