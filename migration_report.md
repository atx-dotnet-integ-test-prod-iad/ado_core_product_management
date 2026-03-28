# Migration Report: SQL Server to PostgreSQL

## Summary of Migration Scope

This report documents the migration of the **AdoCore** .NET ADO application from **Microsoft SQL Server** to **PostgreSQL**. The application is a product management CLI tool using ADO.NET for database access with raw SQL statements.

### Application Overview
- **Framework**: .NET 9.0
- **Database Access**: ADO.NET (raw SQL)
- **Original Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Source File with SQL**: `DataAccess/ProductRepository.cs`

---

## SQL Statement Processing

### Total SQL Statements Processed: 7

| # | Method | Statement Type | Complexity |
|---|--------|---------------|------------|
| 1 | GetAllProductsAsync | SELECT with CTE, Window Functions, CASE, ROUND, INNER JOIN | Medium |
| 2 | GetProductByIdAsync | SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND | Medium |
| 3 | InsertProductAsync | Transaction: INSERT, SCOPE_IDENTITY, INSERT (history), UPDATE (stats) | Hard |
| 4 | UpdateProductAsync | Transaction: SELECT (old values), UPDATE, INSERT (history), UPDATE (stats) | Hard |
| 5 | DeleteProductAsync | Transaction: SELECT (old values), INSERT (history), DELETE, UPDATE (stats) | Hard |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE, RANK, PERCENT_RANK, BETWEEN, CASE | Medium |
| 7 | GetLowStockProductsAsync | SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND | Medium |

### DMS Conversion Results

| Metric | Count |
|--------|-------|
| **Total statements attempted through DMS** | 7 |
| **DMS successfully converted** | 0 |
| **DMS failed (timeout)** | 7 |
| **Manually converted (with lowercase schema)** | 7 |

**DMS Failure Details:**
- All 7 statements failed with the same error: "Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts"
- Subsequent retries also timed out after 300 seconds
- Root cause: DMS MCP tool metadata model conversion consistently timed out

### SQL Equivalency Validation Results

| Metric | Count |
|--------|-------|
| **Total statement pairs validated** | 7 |
| **EQUIVALENT** | 0 |
| **NOT_EQUIVALENT** | 0 |
| **ERROR** | 7 |

**Equivalency Tool Error Details:**
- All 7 statement pairs returned ERROR status with error: `'uniqueID'`
- This is a tool-side error, not indicative of conversion quality
- Per transformation rules, all statements marked as ERROR status

---

## Key SQL Conversion Patterns Applied

Since DMS failed for all statements, manual conversion was performed with the following rules per transformation definition:

### Lowercase Schema Object Names
All table names, column names, and aliases converted to lowercase for PostgreSQL:
- `Products` → `products`
- `ProductId` → `productid`
- `ProductHistory` → `producthistory`
- `ProductStats` → `productstats`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`
- etc.

### T-SQL to PostgreSQL Function Conversions
| SQL Server | PostgreSQL | Notes |
|-----------|-----------|-------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (in writable CTE) | Used CTE chaining pattern |
| `GETDATE()` | `NOW()` | Direct equivalent |
| `DECLARE @var TYPE` | CTE-based old value capture | Restructured to avoid procedural SQL |
| `BEGIN TRANSACTION / COMMIT` | Removed from SQL | Handled by ADO.NET transaction management |
| `SET @var = expr` | Replaced with CTE | Eliminated variable assignments |
| Integer division | `::numeric` cast | PostgreSQL requires explicit cast for decimal division |

### Transaction Block Restructuring
Statements 3, 4, and 5 contained T-SQL transaction blocks with DECLARE variables. These were restructured using PostgreSQL writable CTEs:
- **InsertProductAsync**: Used `INSERT ... RETURNING` in CTE chain to capture new product ID
- **UpdateProductAsync**: Used CTE to capture old values, then UPDATE/INSERT/UPDATE in CTE chain
- **DeleteProductAsync**: Used CTE to capture old values, then INSERT(log)/DELETE/UPDATE(stats) in CTE chain

---

## Files Modified

### 1. `DataAccess/ProductRepository.cs`
**Changes:**
- **Using directive**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **Field type**: `private SqlConnection _connection;` → `private NpgsqlConnection _connection;`
- **Method return type**: `Task<SqlConnection>` → `Task<NpgsqlConnection>`
- **Constructor**: `new SqlConnection(...)` → `new NpgsqlConnection(...)`
- **Command creation**: `new SqlCommand(...)` → `new NpgsqlCommand(...)` (7 occurrences)
- **Reader type**: `SqlDataReader` → `NpgsqlDataReader`
- **Column name references**: Updated to lowercase in `MapProductFromReader` (e.g., `reader["ProductId"]` → `reader["productid"]`)
- **All 7 SQL statements**: Replaced with PostgreSQL-compatible equivalents

### 2. `AdoCore.csproj`
**Changes:**
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.6" />`

### 3. `appsettings.json`
**Changes:**
- **DevConnection**: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection**: Same transformation applied
- **Removed parameters**: `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate` (SQL Server-specific)
- **Added parameters**: `Username`, `Password` (PostgreSQL authentication)
- **Changed**: `Server=` → `Host=`

---

## ADO.NET Class Replacements

| Original (Microsoft.Data.SqlClient) | Replacement (Npgsql) | Occurrences |
|--------------------------------------|----------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 4 (field, return type, constructor, variable) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

---

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | *(removed - not applicable)* |
| TLS | `TrustServerCertificate=True` | *(removed)* |

---

## Manual Interventions

All 7 SQL statements required manual conversion due to DMS tool timeout failures.

### Statements Requiring Manual Review
All 7 statements should be reviewed since:
1. DMS conversion was unavailable (all timed out)
2. SQL Equivalency validation returned ERROR for all pairs (tool-side error)
3. Manual conversion applied lowercase schema naming convention

**Priority review items:**
- **InsertProductAsync** (Statement 3): Complex writable CTE chain replacing SCOPE_IDENTITY() + DECLARE pattern
- **UpdateProductAsync** (Statement 4): CTE-based old value capture replacing DECLARE variables
- **DeleteProductAsync** (Statement 5): CTE-based old value capture with CASE expression in stats update

---

## Build Status

| Step | Status |
|------|--------|
| SQL Extraction | ✅ Complete (7/7 statements) |
| DMS Conversion | ❌ Failed (0/7 - all timed out) |
| Manual Conversion | ✅ Complete (7/7 statements) |
| SQL Equivalency Check | ⚠️ ERROR (7/7 - tool error) |
| Code Re-integration | ✅ Complete |
| Package Update | ✅ Complete (Microsoft.Data.SqlClient → Npgsql) |
| Connection String Update | ✅ Complete |
| Build Compilation | ✅ **Successful** (0 errors, 10 pre-existing warnings) |

---

## Artifacts Generated

1. **`extracted_statements.sql`** - All 7 original MS SQL statements with method names and parameters documented
2. **`converted_statements.sql`** - All 7 converted PostgreSQL statements with conversion notes
3. **`sql_equivalency_validation_report.json`** - Comprehensive JSON report with all 7 statement pairs, conversion methods, equivalency statuses, and tool outputs
4. **`migration_report.md`** - This report

---

## Exit Criteria Checklist

- [x] All SQL Server specific packages replaced with PostgreSQL equivalents
- [x] All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents
- [x] ALL SQL statements attempted through DMS MCP tool (7/7 attempted, 0/7 succeeded)
- [x] ALL failed DMS conversions documented with error details
- [x] ALL statement pairs validated through SQL Equivalency tool (7/7 validated, all returned ERROR)
- [x] Comprehensive equivalency validation report generated (sql_equivalency_validation_report.json)
- [x] Connection strings updated to PostgreSQL format
- [x] Application compiles without errors
- [x] Complete catalog of original SQL statements (extracted_statements.sql)
- [x] Complete catalog of converted SQL statements (converted_statements.sql)
- [x] Migration report generated (migration_report.md)
