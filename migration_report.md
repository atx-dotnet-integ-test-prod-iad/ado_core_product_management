# Migration Report: MS SQL Server to PostgreSQL

## Overview

This report documents the complete migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-03-30  
**Source Database:** Microsoft SQL Server 2019  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

## SQL Statement Processing Summary

### ProductRepository.cs Statements (7 total)

| # | Method | DMS Status | Manual Conversion | Equivalency Status |
|---|--------|-----------|-------------------|-------------------|
| 1 | GetAllProductsAsync | FAILED | Yes - Lowercase schema | ERROR (tool error) |
| 2 | GetProductByIdAsync | FAILED | Yes - Lowercase schema | ERROR (tool error) |
| 3 | InsertProductAsync | FAILED | Yes - Lowercase schema + lastval()/NOW() | ERROR (tool error) |
| 4 | UpdateProductAsync | FAILED | Yes - Lowercase schema + restructured ops | ERROR (tool error) |
| 5 | DeleteProductAsync | FAILED | Yes - Lowercase schema + restructured ops | ERROR (tool error) |
| 6 | GetProductsByPriceRangeAsync | FAILED | Yes - Lowercase schema | ERROR (tool error) |
| 7 | GetLowStockProductsAsync | FAILED | Yes - Lowercase schema + ::numeric cast | ERROR (tool error) |

### Statistics

- **Total SQL statements processed:** 7 (from ProductRepository.cs)
- **Statements successfully converted by DMS MCP tool:** 0
- **Statements requiring manual intervention:** 7
- **Statements validated as equivalent by SQL Equivalency tool:** 0
- **Statements validated as non-equivalent:** 0
- **Statements with equivalency validation errors:** 7

### DMS MCP Tool Failures

All 7 statements were attempted through the DMS MCP statement_conversion_tool (arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU).

**Error:** "Metadata model creation/conversion did not complete after N attempts"

Multiple retry configurations were attempted:
1. Default (15 attempts, 10s interval) - Metadata model conversion timeout
2. Extended (30 attempts, 15s interval) - Command execution timeout (300s)
3. Default with compact SQL - Metadata model creation timeout
4. Extended (25 attempts, 12s interval) with simple query - Metadata model creation timeout
5. Extended with explicit database_name and server_name - Command execution timeout

**Root Cause:** The DMS metadata model creation step consistently fails to complete within the allowed polling time, suggesting an infrastructure or configuration issue with the DMS migration project.

### SQL Equivalency Tool Results

All 7 statement pairs were validated through the sql-equivalency___validate_sql_equivalence tool.

**Error:** All returned `{"equivalence_status": "ERROR", "error": "'uniqueID'"}`

This appears to be a systematic tool issue (possibly related to session/environment configuration) as even the simplest queries produced the same error.

**Important:** No agent judgment was used to determine equivalency. All statuses reflect the tool's actual output.

## Manual Conversion Approach

Since DMS failed for all statements, manual conversion was applied following the transformation definition rules:

### Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

Key conversions applied:
1. **Schema objects:** All table names, column names, and aliases converted to lowercase
   - `Products` → `products`, `ProductId` → `productid`, `StockQuantity` → `stockquantity`
2. **SCOPE_IDENTITY()** → `lastval()` (PostgreSQL sequence value retrieval)
3. **GETDATE()** → `NOW()` (PostgreSQL current timestamp)
4. **BEGIN TRANSACTION/COMMIT** → `BEGIN;/COMMIT;` (PostgreSQL transaction syntax)
5. **DECLARE @var TYPE** → Eliminated (not supported in PostgreSQL plain SQL)
   - Variables replaced with subqueries in transaction blocks
   - Operations reordered to capture old values before modifications
6. **Integer division for ROUND** → `::numeric` cast added where needed
7. **Parameter syntax** → `@param` preserved (Npgsql supports this syntax)

## Package Dependencies Changed

| Original | Replacement |
|----------|------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

## ADO.NET Class Replacements

| Original | Replacement |
|----------|------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## Database Scripts Converted

### Database/Scripts/01_InitialSetup.sql
- `IDENTITY(1,1)` → `SERIAL`
- `NVARCHAR` → `VARCHAR`
- `DATETIME` → `TIMESTAMP`
- `BIT` → `BOOLEAN`
- `[dbo].[tablename]` → `tablename` (lowercase)
- `GETDATE()` → `NOW()`
- `GO` statements removed
- `IF EXISTS (SELECT * FROM sys.objects...)` → `DROP ... IF EXISTS`
- Stored procedures → PostgreSQL functions (`CREATE OR REPLACE FUNCTION`)
- SQL Server trigger → PostgreSQL trigger function + trigger
- `SYSTEM_USER` → `CURRENT_USER`

### Scripts/01_InitialSetup.sql
- Same conversions as above (simpler script)
- `EXEC sp_InsertProduct` → `PERFORM sp_insertproduct()`

## Files Modified

1. `DataAccess/ProductRepository.cs` - SQL statements + ADO.NET classes
2. `AdoCore.csproj` - Package reference
3. `appsettings.json` - Connection strings
4. `Database/Scripts/01_InitialSetup.sql` - Database setup script
5. `Scripts/01_InitialSetup.sql` - Database setup script
6. `README.md` - Documentation

## Files Created (Artifacts)

1. `extracted_statements.sql` - Catalog of all 7 original MS SQL statements
2. `converted_statements.sql` - Catalog of all 7 converted PostgreSQL statements
3. `sql_equivalency_validation_report.json` - Comprehensive equivalency report
4. `dms_failure_summary.sql` - DMS failure documentation
5. `migration_report.md` - This report

## Build Status

**Final Build Result:** ✅ SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure (no automated conversion available for verification)
2. SQL Equivalency tool systematic error (no automated equivalency validation)

### Detailed Statement Review List

1. **GetAllProductsAsync** - CTE with window functions. Manual conversion: lowercase schema only. Low risk - syntax identical between SQL Server and PostgreSQL.

2. **GetProductByIdAsync** - CTE with LAG window function. Manual conversion: lowercase schema only. Low risk - LAG syntax identical.

3. **InsertProductAsync** - Transaction block. Manual conversion: SCOPE_IDENTITY→lastval(), GETDATE→NOW(), BEGIN TRANSACTION→BEGIN. **Medium risk** - lastval() behavior differs from SCOPE_IDENTITY() in concurrent scenarios.

4. **UpdateProductAsync** - Transaction block. Manual conversion: Reordered operations to capture old values via subquery before UPDATE. **Medium risk** - Operation reordering changes execution semantics.

5. **DeleteProductAsync** - Transaction block. Manual conversion: Reordered operations to capture old values via subquery before DELETE. **Medium risk** - Operation reordering changes execution semantics.

6. **GetProductsByPriceRangeAsync** - CTE with RANK/PERCENT_RANK. Manual conversion: lowercase schema only. Low risk - syntax identical.

7. **GetLowStockProductsAsync** - CTE with AVG/MIN/MAX. Manual conversion: lowercase + ::numeric cast for integer division. Low risk - minor syntax difference.
