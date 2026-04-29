# Migration Report: SQL Server to PostgreSQL

## Summary
- **Application**: AdoCore - .NET 9.0 ADO.NET Product Management Application
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13 (ProductManagement)
- **Migration Date**: 2026-04-29
- **Migration Method**: DMS Schema Mapping + Manual SQL Conversion (DMS Statement Conversion failed)

## SQL Statement Processing Summary

| Metric | Count |
|---|---|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention (DMS Failed)** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
- **DMS Statement Conversion Tool**: FAILED for all statements
  - Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
  - Attempted 5+ times with varying parameters (poll attempts, intervals, server names)
- **DMS Schema Mapping Tool**: SUCCESS for all 5 tables
  - Successfully retrieved authoritative schema mappings for: Products, ProductHistory, ProductStats, Categories, Suppliers
  - These mappings guided the manual conversion (lowercase identifiers, type mappings)

### SQL Equivalency Tool Status
- **Status**: ERROR for all 7 statement pairs
  - Error: `'uniqueID'` (internal tool infrastructure issue)
  - Each statement pair was individually submitted and validated

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Source**: DataAccess/ProductRepository.cs, lines 43-72
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: CTE name changed to `productstats_cte`, all identifiers lowercased
- **Equivalency**: ERROR (tool infrastructure issue)

### Statement 2: GetProductByIdAsync
- **Source**: DataAccess/ProductRepository.cs, lines 86-113
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: CTE name changed to `producthistory_cte`, all identifiers lowercased
- **Equivalency**: ERROR (tool infrastructure issue)

### Statement 3: InsertProductAsync
- **Source**: DataAccess/ProductRepository.cs, lines 132-155
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Major restructure - DECLARE/SCOPE_IDENTITY()/BEGIN TRANSACTION replaced with PostgreSQL writable CTEs using INSERT...RETURNING
- **Equivalency**: ERROR (tool infrastructure issue)

### Statement 4: UpdateProductAsync
- **Source**: DataAccess/ProductRepository.cs, lines 168-196
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Major restructure - DECLARE variables replaced with CTE-based approach
- **Equivalency**: ERROR (tool infrastructure issue)

### Statement 5: DeleteProductAsync
- **Source**: DataAccess/ProductRepository.cs, lines 204-240
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Major restructure - DECLARE variables replaced with CTE-based approach
- **Equivalency**: ERROR (tool infrastructure issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: DataAccess/ProductRepository.cs, lines 250-270
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Direct lowercase mapping, window functions compatible
- **Equivalency**: ERROR (tool infrastructure issue)

### Statement 7: GetLowStockProductsAsync
- **Source**: DataAccess/ProductRepository.cs, lines 282-305
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Direct lowercase mapping, added CAST for integer division in ROUND
- **Equivalency**: ERROR (tool infrastructure issue)

## File Changes Summary

### Modified Files
| File | Changes |
|---|---|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; SqlClient → Npgsql types; lowercase column names in reader |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | SQL Server connection strings → PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion (DDL, triggers, stored procedures, indexes, data) |
| `Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion (DDL, stored procedures, sample data) |

### New Files (Artifacts)
| File | Purpose |
|---|---|
| `extracted_statements.sql` | All 7 original MS SQL statements with source locations |
| `converted_statements.sql` | All 7 converted PostgreSQL statements with conversion notes |
| `sql_equivalency_validation_report.json` | Complete equivalency report for all 7 statement pairs |
| `dms_conversion_log.md` | Detailed DMS tool interaction log |
| `migration_report.md` | This file - comprehensive migration summary |

## Key Conversion Mappings

### Schema Mapping (from DMS)
| Source | Target |
|---|---|
| `dbo` schema | `productmanagement_dbo` schema |
| PascalCase identifiers | lowercase identifiers |

### Type Mappings (from DMS Schema Mapping)
| SQL Server | PostgreSQL |
|---|---|
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| `nvarchar(n)` | `VARCHAR(n)` |
| `decimal(p,s)` | `NUMERIC(p,s)` |
| `bit` | `BOOLEAN` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `varchar(n)` | `VARCHAR(n)` |

### SQL Syntax Mappings
| SQL Server | PostgreSQL |
|---|---|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING` + CTE |
| `GETDATE()` | `clock_timestamp()` |
| `DECLARE @var` | CTE approach (writable CTEs) |
| `BEGIN TRANSACTION/COMMIT` | Transaction at C# level / writable CTEs |
| `SYSTEM_USER` | `current_user` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| SQL Server triggers | PostgreSQL trigger functions + triggers |
| `GO` batch separator | Removed |
| `IF NOT EXISTS (sys.objects)` | `DROP IF EXISTS` / `CREATE IF NOT EXISTS` |

### Package Mappings
| SQL Server | PostgreSQL |
|---|---|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### Connection String Mapping
| SQL Server | PostgreSQL |
|---|---|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | (removed - not applicable) |
| `TrustServerCertificate=True` | (removed - not applicable) |
| (not set) | `Port=5432` |

## Build Status
- **Final Build**: ✅ **SUCCESS**
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference warnings, no new warnings introduced)

## Statements Requiring Manual Review
All 7 statements require manual review as:
1. DMS Statement Conversion tool failed for all (metadata model creation error)
2. SQL Equivalency tool returned ERROR for all (internal 'uniqueID' error)
3. Manual conversion was applied using DMS schema mapping data

**Particular attention should be paid to:**
- **Statements 3, 4, 5** (Insert/Update/Delete): These were significantly restructured from SQL Server's DECLARE + BEGIN TRANSACTION approach to PostgreSQL's writable CTE approach. The logic is preserved but the execution pattern is different.
- **Statement 7** (GetLowStockProducts): Added explicit CAST to NUMERIC for integer division in ROUND function.
