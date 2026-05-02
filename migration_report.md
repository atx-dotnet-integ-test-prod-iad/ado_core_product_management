# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| **Total Inline SQL Statements Processed** | 7 |
| **Successfully Converted by DMS** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **With Equivalency Errors** | 7 |
| **Database Script Files Converted** | 2 |

## Migration Date
2026-05-02

## Source Application
- **Application**: AdoCore (.NET 9.0)
- **Original Database**: Microsoft SQL Server
- **Original Driver**: Microsoft.Data.SqlClient 5.1.4
- **Target Database**: PostgreSQL
- **Target Driver**: Npgsql 8.0.6

---

## DMS Tool Status

All 7 inline SQL statements from `ProductRepository.cs` were passed to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) for conversion. **All 7 failed** with the following error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**DMS Configuration Used:**
- Migration Project: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- Database: `ProductManagement`
- Schema: `dbo`
- Region: `us-east-1`

Per the transformation definition, since DMS failed, manual conversion was applied with the reason `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`, applying lowercase schema object names for PostgreSQL compatibility.

---

## SQL Equivalency Validation

All 7 statement pairs were passed to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). **All 7 returned ERROR** with:

```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

**Important**: No agent judgment was used to determine equivalency. All statuses come exclusively from the SQL Equivalency tool.

---

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetAllProductsAsync()` method
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE WHEN, ROUND
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes**: All identifiers lowercased (Products→products, ProductId→productid, etc.)
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 2: GetProductByIdAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductByIdAsync()` method
- **Type**: CTE with LAG window function, LEFT JOIN, parameterized with @ProductId
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes**: All identifiers lowercased
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 3: InsertProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `InsertProductAsync()` method
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes**:
  - SCOPE_IDENTITY() → RETURNING clause (PostgreSQL idiom)
  - GETDATE() → NOW()
  - DECLARE @var / SET @var → application-level variable management
  - BEGIN TRANSACTION/COMMIT → NpgsqlTransaction (app-level)
  - All identifiers lowercased
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 4: UpdateProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `UpdateProductAsync()` method
- **Type**: Transaction block with DECLARE variables, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes**:
  - DECLARE @OldPrice / @OldStock → application-level variables
  - SELECT INTO @var → separate SELECT query with app-level reader
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → NpgsqlTransaction (app-level)
  - All identifiers lowercased
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 5: DeleteProductAsync
- **Source**: `DataAccess/ProductRepository.cs` - `DeleteProductAsync()` method
- **Type**: Transaction block with DECLARE variables, DELETE, CASE WHEN, GETDATE()
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes**:
  - DECLARE @OldPrice / @OldStock → application-level variables
  - SELECT INTO @var → separate SELECT query with app-level reader
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → NpgsqlTransaction (app-level)
  - All identifiers lowercased
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetProductsByPriceRangeAsync()` method
- **Type**: CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE WHEN
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes**: All identifiers lowercased
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Source**: `DataAccess/ProductRepository.cs` - `GetLowStockProductsAsync()` method
- **Type**: CTE with AVG/MIN/MAX OVER window functions, CASE WHEN, ROUND
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Changes**: All identifiers lowercased, added CAST for integer division in ROUND
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

---

## Static Code Changes

### Package Dependencies (AdoCore.csproj)
| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |

### ADO.NET Class Replacements (ProductRepository.cs)
| Original | Replacement |
|----------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (if used) |

### Connection String Changes (appsettings.json)
| Parameter | Original | New |
|-----------|----------|-----|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed (not applicable) |

### Database Scripts Converted
| Script | Conversions Applied |
|--------|-------------------|
| `Scripts/01_InitialSetup.sql` | IDENTITY→SERIAL, GETDATE→NOW, NVARCHAR→VARCHAR, GO→removed, stored procs→functions, IF NOT EXISTS→PostgreSQL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Same as above + BIT→BOOLEAN, triggers→PostgreSQL trigger syntax, sys.objects→DROP IF EXISTS |

---

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | All 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Comprehensive equivalency validation report |
| `migration_report.md` | `sourceCode/` | This report |

---

## Files Modified

1. `DataAccess/ProductRepository.cs` - SQL statements + ADO.NET classes
2. `AdoCore.csproj` - Package dependencies
3. `appsettings.json` - Connection strings
4. `Scripts/01_InitialSetup.sql` - Database setup script
5. `Database/Scripts/01_InitialSetup.sql` - Database setup script (full version)

## Files Created

1. `extracted_statements.sql` - Catalog of original SQL statements
2. `converted_statements.sql` - Catalog of converted SQL statements
3. `sql_equivalency_validation_report.json` - Equivalency validation report
4. `migration_report.md` - This migration report

## Files Verified (No Changes Needed)

1. `Program.cs` - No SQL Server-specific references
