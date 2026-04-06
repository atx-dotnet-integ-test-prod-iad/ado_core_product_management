# Migration Report: MS SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, replacing database access classes, updating package references, and modifying connection strings.

## Migration Statistics

| Metric | Count |
|---|---|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Manual Conversion After DMS Failure** | 7 |
| **Validated as Equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

## DMS Tool Status
The DMS `statement_conversion_tool` was unable to process any SQL statements due to persistent metadata model creation/conversion timeouts. Multiple attempts were made:
1. Short identifier format rejected by DMS
2. Full ARN identifier accepted but metadata model conversion timed out (15 poll attempts)
3. Extended timeout (30 poll attempts, 15s interval) exceeded 300s total execution timeout
4. Even simplest possible query (`SELECT GETDATE()`) failed with metadata model creation timeout

The DMS `schema_mapping_tool` was successful and provided accurate target schema mappings used for manual conversion.

## SQL Equivalency Tool Status
The SQL Equivalency validation tool returned ERROR status (`'uniqueID'`) for all 7 statement pairs. This was a systemic infrastructure issue - even a trivial `SELECT 1` statement pair returned the same error. All 7 pairs are marked as ERROR per the transformation definition requirements.

## Files Modified

### 1. AdoCore.csproj (Package References)
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`

### 2. DataAccess/ProductRepository.cs (SQL Statements + ADO.NET Classes)

#### SQL Statement Changes:
| # | Method | Key Changes |
|---|---|---|
| 1 | GetAllProductsAsync | All identifiers lowercased (Products→products, ProductId→productid, etc.) |
| 2 | GetProductByIdAsync | All identifiers lowercased |
| 3 | InsertProductAsync | SCOPE_IDENTITY()→RETURNING, GETDATE()→NOW(), DECLARE/BEGIN TRANSACTION→writeable CTE |
| 4 | UpdateProductAsync | DECLARE→CTE, GETDATE()→NOW(), BEGIN TRANSACTION→writeable CTE |
| 5 | DeleteProductAsync | DECLARE→CTE, GETDATE()→NOW(), BEGIN TRANSACTION→writeable CTE, CASE preserved |
| 6 | GetProductsByPriceRangeAsync | All identifiers lowercased |
| 7 | GetLowStockProductsAsync | All identifiers lowercased, added CAST(... AS NUMERIC) for integer division |

#### ADO.NET Class Changes:
| Original (SqlClient) | Replacement (Npgsql) | Occurrences |
|---|---|---|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 4 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

### 3. appsettings.json (Connection Strings)
- **Before**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After**: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### 4. README.md (Documentation)
- Updated title and description
- Updated prerequisites (PostgreSQL 13+ instead of SQL Server 2019+)
- Updated connection string examples
- Updated NuGet package list
- Updated troubleshooting and deployment sections

## Transformation Artifacts

| Artifact | Status | Description |
|---|---|---|
| `extracted_statements.sql` | ✅ Created | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | ✅ Created | Catalog of all 7 converted PostgreSQL statements with originals |
| `sql_equivalency_validation_report.json` | ✅ Created | Comprehensive JSON report with all 7 statement pairs |
| `migration_report.md` | ✅ Created | This report |
| `dms_conversion_log.md` | ✅ Created | Detailed log of all DMS tool interactions |

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. **DMS conversion was unavailable** - all statements were manually converted
2. **SQL Equivalency validation returned ERROR** - tool infrastructure issue prevented validation

### Statement-by-Statement Review

| # | Method | Conversion Method | Equivalency Status | Review Priority |
|---|---|---|---|---|
| 1 | GetAllProductsAsync | Manual (lowercase schema) | ERROR | Low - straightforward CTE, only identifier casing changes |
| 2 | GetProductByIdAsync | Manual (lowercase schema) | ERROR | Low - straightforward CTE, only identifier casing changes |
| 3 | InsertProductAsync | Manual (lowercase schema) | ERROR | **HIGH** - major restructuring: SCOPE_IDENTITY→RETURNING CTE pattern |
| 4 | UpdateProductAsync | Manual (lowercase schema) | ERROR | **HIGH** - major restructuring: DECLARE→writeable CTE pattern |
| 5 | DeleteProductAsync | Manual (lowercase schema) | ERROR | **HIGH** - major restructuring: DECLARE→writeable CTE pattern |
| 6 | GetProductsByPriceRangeAsync | Manual (lowercase schema) | ERROR | Low - straightforward CTE, only identifier casing changes |
| 7 | GetLowStockProductsAsync | Manual (lowercase schema) | ERROR | Medium - added CAST for integer division fix |

## Post-Migration Fix: MapProductFromReader Column Name Casing

**Issue**: The `MapProductFromReader` method was using PascalCase column names (e.g., `reader["ProductId"]`, `reader["Name"]`) to access data from `NpgsqlDataReader`. However, since all SQL queries were converted to use lowercase identifiers (e.g., `productid`, `name`), PostgreSQL returns column names in lowercase. This mismatch would cause `IndexOutOfRangeException` at runtime.

**Fix Applied**: Updated all column name references in `MapProductFromReader` from PascalCase to lowercase:
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`

## Build Status
- **Final Build**: ✅ **Build succeeded** with 0 errors and 10 warnings
- All 10 warnings are pre-existing nullable reference type warnings (CS8600, CS8601, CS8603, CS8618, CS8625)
- No new warnings introduced by the migration

## Schema Mapping Reference (from DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) | Schema |
|---|---|---|
| `[dbo].[Products]` | `products` | `productmanagement_dbo` |
| `[dbo].[ProductHistory]` | `producthistory` | `productmanagement_dbo` |
| `[dbo].[ProductStats]` | `productstats` | `productmanagement_dbo` |
