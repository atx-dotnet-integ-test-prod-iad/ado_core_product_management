# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
- **Migration Date**: 2026-04-27
- **Application**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Approach**: Manual conversion with lowercase schema (DMS tool unavailable)

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 17 |
| Code Statements (ProductRepository.cs) | 7 |
| Script Statements (SQL Setup Files) | 10 |
| DMS Conversion Successes | 0 |
| DMS Conversion Failures | 17 |
| Manual Conversions Required | 17 |
| Equivalency Validations: EQUIVALENT | 0 |
| Equivalency Validations: NOT_EQUIVALENT | 0 |
| Equivalency Validations: ERROR | 17 |

## DMS Tool Status
All 17 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion. All attempts failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
Per the transformation definition, manual conversion was applied using lowercase schema object names with the documented reason: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Equivalency Tool Status
All 17 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence). All returned ERROR status:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
Per the transformation definition, these are marked as ERROR in the report. Agent judgment was NOT used for equivalency determination.

## Files Modified

### Application Code
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 MS SQL statements with PostgreSQL equivalents; Replaced `using Microsoft.Data.SqlClient` with `using Npgsql`; Replaced `SqlConnection`→`NpgsqlConnection`, `SqlCommand`→`NpgsqlCommand`, `SqlDataReader`→`NpgsqlDataReader`; Updated column references to lowercase |

### Configuration
| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.6` |
| `appsettings.json` | Updated connection strings from SQL Server format (`Server=localhost;Trusted_Connection=True;...`) to PostgreSQL format (`Host=localhost;Username=postgres;Password=postgres`) |

### SQL Scripts
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted from MS SQL to PostgreSQL: CREATE TABLE (SERIAL, VARCHAR, TIMESTAMP, NOW()), stored procedures→functions, sample data |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion: 5 CREATE TABLEs, indexes, trigger, 5 stored procedures→functions, sample data inserts, statistics update |

## Key Conversion Patterns Applied

### SQL Syntax Conversions
| MS SQL Server | PostgreSQL | Notes |
|--------------|------------|-------|
| `IDENTITY(1,1)` | `SERIAL` | Auto-incrementing primary keys |
| `NVARCHAR(n)` | `VARCHAR(n)` | Unicode is default in PostgreSQL |
| `BIT` | `BOOLEAN` | With `DEFAULT 1` → `DEFAULT TRUE` |
| `DATETIME` | `TIMESTAMP` | Timestamp without timezone |
| `GETDATE()` | `NOW()` | Current timestamp |
| `SCOPE_IDENTITY()` | `RETURNING productid` | Return new ID with INSERT |
| `DECLARE @var` / `SET @var` | CTE with subquery | Restructured for writable CTEs |
| `BEGIN TRANSACTION` / `COMMIT` | Managed by Npgsql | `BeginTransactionAsync()` / `CommitAsync()` |
| `[dbo].[tablename]` | `tablename` | Lowercase, no schema prefix |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | PostgreSQL uses functions |
| `SET NOCOUNT ON` | Removed | Not applicable in PostgreSQL |
| `SYSTEM_USER` | `current_user` | Current session user |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `DROP TABLE IF EXISTS` | PostgreSQL catalog approach |
| `GO` separator | Removed | Not needed in PostgreSQL |
| SQL Server trigger (inserted/deleted) | PostgreSQL trigger function (NEW/OLD/TG_OP) | Row-level trigger pattern |

### Schema Object Name Conversions
All schema object names converted to lowercase per the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` rule:
- `Products` → `products`
- `ProductId` → `productid`
- `ProductHistory` → `producthistory`
- `ProductStats` → `productstats`
- `Categories` → `categories`
- `Suppliers` → `suppliers`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`
- All other column/table/alias names similarly lowercased

### Package Dependency Changes
| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |
| `Microsoft.Extensions.Configuration 8.0.0` | `Microsoft.Extensions.Configuration 8.0.0` (unchanged) |
| `Microsoft.Extensions.Configuration.Json 8.0.0` | `Microsoft.Extensions.Configuration.Json 8.0.0` (unchanged) |
| `Microsoft.Extensions.DependencyInjection 8.0.0` | `Microsoft.Extensions.DependencyInjection 8.0.0` (unchanged) |

Note: Npgsql upgraded from 8.0.1 (plan specification) to 8.0.6 to address known security vulnerability GHSA-x9vc-6hfv-hg8c.

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not supported) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Class Replacements
| MS SQL Server | Npgsql |
|--------------|--------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `AddWithValue()` | `AddWithValue()` (compatible) |
| `BeginTransactionAsync()` | `BeginTransactionAsync()` (compatible) |
| `CommitAsync()` | `CommitAsync()` (compatible) |
| `RollbackAsync()` | `RollbackAsync()` (compatible) |
| `ConnectionState.Open` | `ConnectionState.Open` (compatible) |

## Build Status
- **Final Build**: **SUCCESS** (0 errors, 0 security warnings)
- **Warnings**: Standard nullable reference type warnings (pre-existing, not related to migration)

## Transformation Artifacts
1. `extracted_statements.sql` - Complete catalog of all 7 original MS SQL statements from code
2. `converted_statements.sql` - Complete catalog of all 7 converted PostgreSQL statements for code
3. `sql_equivalency_validation_report.json` - Comprehensive JSON report with all 17 statement pairs
4. `migration_report.md` - This report

## Statements Requiring Manual Review
All 17 statements should be manually reviewed since:
1. DMS tool was unavailable for automated conversion verification
2. SQL Equivalency tool returned ERROR for all pairs (tool-level error, not conversion error)
3. Manual conversions applied standard MS SQL → PostgreSQL patterns with lowercase schema naming

## Known Limitations
1. The `ExecuteInTransactionAsync` method in `ProductRepository.cs` provides transaction support via Npgsql's `BeginTransactionAsync()`. The individual SQL statements (Insert, Update, Delete) use writable CTEs instead of explicit transaction blocks since they are executed as single commands.
2. Connection string uses placeholder credentials (`postgres/postgres`) - these should be updated for production use.
3. PostgreSQL parameter syntax uses `@param` format which is supported by Npgsql but native PostgreSQL prefers `$1` positional parameters. Npgsql handles this translation transparently.
