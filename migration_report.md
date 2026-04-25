# SQL Server to PostgreSQL Migration Report
## AdoCore Application - Final Migration Summary

### Migration Overview
- **Date**: 2026-04-25
- **Application**: AdoCore (.NET 9 ADO.NET application)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Status**: COMPLETE

### SQL Statement Processing Summary
| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements attempted via DMS MCP tool | 7 |
| Statements successfully converted by DMS | 0 |
| Statements requiring manual conversion | 7 |
| Manual conversion method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |

### SQL Equivalency Validation Summary
| Metric | Count |
|--------|-------|
| Total statement pairs validated | 7 |
| Equivalent (per tool) | 0 |
| Non-equivalent (per tool) | 0 |
| Error (per tool) | 7 |
| **Note**: All 7 validations returned ERROR with "'uniqueID'" error from the SQL Equivalency tool, indicating a service-level issue. |

### DMS Tool Status
- **Statement Conversion Tool**: FAILED for all statements
  - Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
  - Multiple retry attempts with varying poll configurations all failed
- **Schema Mapping Tool**: SUCCEEDED
  - Successfully retrieved schema mappings for Products, ProductHistory, ProductStats tables
  - Mappings used to inform manual conversion with correct lowercase names

### Files Modified
| File | Change |
|------|--------|
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `DataAccess/ProductRepository.cs` | All SQL statements, imports, ADO.NET classes, column name references |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

### Package Changes
| Original | Replacement |
|----------|-------------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

### Class Replacements
| SQL Server Class | Npgsql Equivalent |
|------------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed (not applicable) |

### SQL Conversion Details

#### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE and window functions
- **Changes**: Table/column names to lowercase, CTE renamed to avoid conflict with `productstats` table
- **T-SQL Functions**: No function changes needed (AVG OVER, COUNT OVER, ROUND, CASE are compatible)

#### Statement 2: GetProductByIdAsync  
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN
- **Changes**: Table/column names to lowercase, CTE renamed to avoid conflict with `producthistory` table
- **T-SQL Functions**: No function changes needed (LAG, ROUND, CASE are compatible)

#### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, multi-table operations
- **Changes**: 
  - `SCOPE_IDENTITY()` → CTE with `INSERT...RETURNING` + `currval(pg_get_serial_sequence(...))`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @var / SET @var` → CTE pattern

#### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
- **Changes**:
  - `DECLARE @var / SELECT @var = col` → Subquery approach (capture old values via subquery before update)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Operation order changed: log history first, then update stats, then update product

#### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE
- **Changes**:
  - `DECLARE @var / SELECT @var = col` → Subquery approach
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Operation order changed: log history first, then update stats, then delete product

#### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK and PERCENT_RANK window functions
- **Changes**: Table/column names to lowercase only
- **T-SQL Functions**: No function changes needed (RANK, PERCENT_RANK, BETWEEN, CASE are compatible)

#### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions
- **Changes**: 
  - Table/column names to lowercase
  - `ROUND(StockQuantity / AvgStock * 100, 2)` → `ROUND(stockquantity::NUMERIC / avgstock * 100, 2)` (explicit cast for integer division)

### Schema Mapping (from DMS Schema Mapping Tool)
| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `[dbo].[Products]` | `products` |
| `[dbo].[ProductHistory]` | `producthistory` |
| `[dbo].[ProductStats]` | `productstats` |
| `ProductId` | `productid` |
| `Name` | `name` |
| `Description` | `description` |
| `Price` | `price` |
| `StockQuantity` | `stockquantity` |
| `CreatedDate` | `createddate` |
| `ModifiedDate` | `modifieddate` |

### Build Status
- **Final build**: SUCCESS (0 errors, 10 warnings)
- **Warnings**: All pre-existing nullable reference warnings (CS8601, CS8618, CS8603, CS8600, CS8625)

### Migration Artifacts
| Artifact | Location |
|----------|----------|
| Original SQL statements | `extracted_statements.sql` |
| Converted SQL statements | `converted_statements.sql` |
| DMS conversion summary | `dms_conversion_summary.txt` |
| SQL Equivalency report | `sql_equivalency_validation_report.json` |
| Migration report | `migration_report.md` |

### Notes
1. **Database/Scripts/01_InitialSetup.sql**: This DDL script contains the original SQL Server schema creation. It is NOT modified as part of this application code migration. A separate database schema migration would need to be performed to create the PostgreSQL schema.
2. **No test files**: The project does not contain unit/integration tests, so test validation is not applicable.
3. **Parameter syntax**: Npgsql supports `@ParamName` syntax, so no parameter placeholder changes were needed.
4. **Transaction handling**: `BeginTransactionAsync`/`CommitAsync`/`RollbackAsync` are supported by Npgsql, so the `ExecuteInTransactionAsync` method required no changes.
