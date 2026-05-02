# Migration Report: MS SQL Server to PostgreSQL

## Summary
- **Project**: AdoCore - .NET ADO Application
- **Migration Date**: 2026-05-02
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Method**: Manual conversion with lowercase schema (DMS tool unavailable)

## Overall Results

| Metric | Count |
|--------|-------|
| Total Inline SQL Statements Processed | 7 |
| DMS Conversion Successes | 0 |
| DMS Conversion Failures | 7 |
| Manual Conversions Applied | 7 |
| Equivalency Tool - EQUIVALENT | 0 |
| Equivalency Tool - NOT_EQUIVALENT | 0 |
| Equivalency Tool - ERROR | 7 |

## DMS Tool Status
**Status**: ALL FAILED
**Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
**Impact**: All 7 inline SQL statements required manual conversion with lowercase schema object names as fallback.

## SQL Equivalency Tool Status
**Status**: ALL ERROR
**Error**: `'uniqueID'`
**Impact**: Could not programmatically validate equivalency. All 7 statement pairs returned ERROR from the tool.

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.1` |
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements with PostgreSQL equivalents; replaced all SqlClient types with Npgsql |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted from SQL Server to PostgreSQL syntax |

## Detailed Statement Conversions

### Statement 1: GetAllProductsAsync()
- **Source**: `DataAccess/ProductRepository.cs`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from tool)
- **Changes**: Table/column names lowercased. CTE and window functions (AVG OVER, COUNT OVER) are compatible.

### Statement 2: GetProductByIdAsync()
- **Source**: `DataAccess/ProductRepository.cs`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from tool)
- **Changes**: Table/column names lowercased. LAG window function compatible.

### Statement 3: InsertProductAsync()
- **Source**: `DataAccess/ProductRepository.cs`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from tool)
- **Changes**:
  - `SCOPE_IDENTITY()` → CTE with `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @variable` / `BEGIN TRANSACTION` / `COMMIT` → CTE chain pattern
  - Table/column names lowercased

### Statement 4: UpdateProductAsync()
- **Source**: `DataAccess/ProductRepository.cs`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from tool)
- **Changes**:
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` / `COMMIT` → CTE chain pattern
  - Table/column names lowercased

### Statement 5: DeleteProductAsync()
- **Source**: `DataAccess/ProductRepository.cs`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from tool)
- **Changes**:
  - `DECLARE @OldPrice` / `DECLARE @OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` / `COMMIT` → CTE chain pattern
  - Table/column names lowercased

### Statement 6: GetProductsByPriceRangeAsync()
- **Source**: `DataAccess/ProductRepository.cs`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from tool)
- **Changes**: Table/column names lowercased. RANK/PERCENT_RANK window functions compatible.

### Statement 7: GetLowStockProductsAsync()
- **Source**: `DataAccess/ProductRepository.cs`
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (from tool)
- **Changes**:
  - Table/column names lowercased
  - Added `CAST(stockquantity AS DECIMAL)` for proper integer division behavior

## SQL Script Conversions

### Scripts/01_InitialSetup.sql
- Removed `IF NOT EXISTS (SELECT * FROM sys...)` patterns → `CREATE TABLE IF NOT EXISTS`
- Removed `GO` batch separators
- Removed `USE` statements
- `IDENTITY(1,1)` → `SERIAL`
- `[dbo].[TableName]` → plain lowercase table names
- `GETDATE()` → `NOW()`
- `[nvarchar](N)` → `VARCHAR(N)`
- `[datetime]` → `TIMESTAMP`
- `SCOPE_IDENTITY()` → `RETURNING` clause
- Stored procedures → PostgreSQL functions (`CREATE OR REPLACE FUNCTION`)
- `EXEC sp_InsertProduct` → `PERFORM sp_insertproduct()`

### Database/Scripts/01_InitialSetup.sql
- All changes from above, plus:
- `[bit]` → `BOOLEAN`
- `DEFAULT 1` (bit) → `DEFAULT TRUE`
- `DEFAULT 0` (bit) → `DEFAULT FALSE`
- Trigger converted to PostgreSQL syntax (trigger function + trigger)
- `SYSTEM_USER` → `CURRENT_USER`
- `inserted`/`deleted` pseudo-tables → `NEW`/`OLD` trigger variables
- `IF EXISTS (SELECT 1 FROM inserted)` patterns → `IF TG_OP = 'INSERT'` patterns

## Static Code Changes

### Package Dependencies
- **Removed**: `Microsoft.Data.SqlClient` Version 5.1.4
- **Added**: `Npgsql` Version 8.0.1

### ADO.NET Class Replacements
| Original | Replacement | Occurrences |
|----------|-------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 4 (field, method return type, constructor, instantiation) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader) |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed |
| TLS | `TrustServerCertificate=True` | Removed |

## Artifacts Generated
- `extracted_statements.sql` - Catalog of all 7 original MS SQL statements
- `converted_statements.sql` - Catalog of all 7 converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Detailed equivalency validation report
- `migration_report.md` - This report

## Build Status
- **Final Build**: SUCCESS (0 errors, warnings are pre-existing nullable reference type warnings)

## Items Requiring Manual Review
1. All 7 SQL statement equivalency validations returned ERROR from the SQL Equivalency tool - manual review recommended
2. Transaction handling in statements 3, 4, 5 was restructured from T-SQL `BEGIN TRANSACTION/COMMIT` with `DECLARE` variables to PostgreSQL CTE chains - verify runtime behavior
3. Connection string credentials are placeholder values - update for target environment
