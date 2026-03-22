# Microsoft SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-22 |
| **Source Database** | Microsoft SQL Server |
| **Target Database** | PostgreSQL |
| **Application Framework** | .NET 9.0 / ADO.NET |
| **Source Driver** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Driver** | Npgsql 8.0.9 |

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET types replaced |
| `AdoCore.csproj` | Package reference updated |
| `appsettings.json` | Connection strings updated |
| `Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion |

## Files Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements from ProductRepository.cs |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive JSON report with all 13 statement pairs and equivalency results |
| `migration_report.md` | This report |

---

## SQL Statement Processing

### Total Statements Processed: 13

| Category | Count |
|----------|-------|
| ProductRepository.cs inline SQL statements | 7 |
| Setup script SQL blocks (representative) | 6 |
| **Total** | **13** |

### DMS MCP Tool Results

| Metric | Count |
|--------|-------|
| Total DMS conversion attempts | 8 |
| DMS successful conversions | 0 |
| DMS failed conversions | 8 |
| Manual conversions (all statements) | 13 |

**DMS Error:** The DMS MCP tool consistently failed with:
- `"Metadata model creation failed: Metadata model creation did not complete after 15 attempts"`
- `"Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts"`

The DMS tool was tested with multiple configurations including increased poll attempts (25, 30) and extended poll intervals (15s), as well as with minimal queries (e.g., `SELECT GETDATE()`). All attempts failed with the same timeout error.

**Manual Conversion Method:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Validation Results

| Metric | Count |
|--------|-------|
| Total pairs validated | 13 |
| EQUIVALENT | 0 |
| NOT_EQUIVALENT | 0 |
| ERROR | 13 |

**Equivalency Tool Error:** The SQL Equivalency tool returned `ERROR` with `"'uniqueID'"` for all 13 statement pairs. This is a systemic issue with the tool, not related to the SQL statements. The tool was tested with both complex and trivial queries - all returned the same error.

---

## ProductRepository.cs Conversion Details

### Statement 1: GetAllProductsAsync
- **Type:** Complex CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
- **Key Changes:** CTE name `ProductStats` → `productstats_cte` (avoid conflict with table name), all identifiers lowercase
- **Equivalency Status:** ERROR (tool systemic issue)

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window function, LEFT JOIN, CASE, ROUND
- **Key Changes:** CTE name `ProductHistory` → `producthistory_cte`, all identifiers lowercase
- **Equivalency Status:** ERROR (tool systemic issue)

### Statement 3: InsertProductAsync
- **Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), multi-statement
- **Key Changes:** Restructured using PostgreSQL writable CTEs - `SCOPE_IDENTITY()` → `INSERT ... RETURNING`, `GETDATE()` → `NOW()`, eliminated DECLARE variables
- **Equivalency Status:** ERROR (tool systemic issue)

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE variables, SELECT INTO, UPDATE, INSERT history
- **Key Changes:** Restructured using writable CTEs - `old_values` CTE captures pre-update state, `GETDATE()` → `NOW()`, eliminated DECLARE variables
- **Equivalency Status:** ERROR (tool systemic issue)

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE variables, SELECT INTO, INSERT history, DELETE, UPDATE stats with CASE
- **Key Changes:** Restructured using writable CTEs - `old_values` CTE captures pre-delete state, `GETDATE()` → `NOW()`, eliminated DECLARE variables
- **Equivalency Status:** ERROR (tool systemic issue)

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK(), PERCENT_RANK() window functions, CASE, BETWEEN
- **Key Changes:** All identifiers lowercase, window functions directly compatible
- **Equivalency Status:** ERROR (tool systemic issue)

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes:** All identifiers lowercase, added `::numeric` cast for integer division fix in ROUND
- **Equivalency Status:** ERROR (tool systemic issue)

---

## ADO.NET Class Replacements

| Original (Microsoft.Data.SqlClient) | Replacement (Npgsql) | Occurrences |
|--------------------------------------|----------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return type, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader signature) |

**Note:** `command.Parameters.AddWithValue` is compatible with both SqlClient and Npgsql. The `@` parameter prefix is supported by Npgsql. No parameter syntax changes were needed.

**Note:** `ExecuteInTransactionAsync` uses the base `DbTransaction` interface via `BeginTransactionAsync`/`CommitAsync`/`RollbackAsync`, which works with both providers.

---

## Package Dependency Changes

| Old Package | Old Version | New Package | New Version |
|-------------|-------------|-------------|-------------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.9 |

**Note:** Initially planned Npgsql 8.0.1, but upgraded to 8.0.9 due to high-severity vulnerability (GHSA-x9vc-6hfv-hg8c) in version 8.0.1.

---

## Connection String Changes

### Development Connection
| Parameter | SQL Server | PostgreSQL |
|-----------|------------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | *Removed (not applicable)* |
| Certificate | `TrustServerCertificate=True` | *Removed (not applicable)* |

### Production Connection
Same transformation as Development connection.

---

## SQL Server to PostgreSQL Conversion Rules Applied

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| `IDENTITY(1,1)` | `SERIAL` | Auto-incrementing integer |
| `GETDATE()` | `NOW()` | Current timestamp |
| `SCOPE_IDENTITY()` | `RETURNING` clause / `currval()` | Last inserted identity |
| `nvarchar(n)` | `varchar(n)` | Character varying |
| `datetime` | `timestamp` | Date and time |
| `bit` | `boolean` | Boolean type |
| `[dbo].[TableName]` | `tablename` | Lowercase, no schema bracket notation |
| `BEGIN TRANSACTION` / `COMMIT` | Writable CTEs | Single-statement approach for ADO.NET |
| `DECLARE @var` | CTEs / subqueries | Variable elimination |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | Procedure → Function |
| `SET NOCOUNT ON` | *Removed* | Not needed in PostgreSQL |
| `GO` | *Removed* | PostgreSQL uses semicolons |
| `IF NOT EXISTS (sys.objects ...)` | `IF NOT EXISTS` / `DROP IF EXISTS` | PostgreSQL conditional DDL |
| `SYSTEM_USER` | `current_user` | Current user function |
| `IsDiscontinued = 1` | `isdiscontinued = TRUE` | Boolean comparison |
| Integer division in ROUND | `::numeric` cast | Ensure decimal division |

---

## Database Setup Scripts Conversion

### Scripts/01_InitialSetup.sql (Simple)
- Converted CREATE TABLE with IDENTITY → SERIAL
- Converted 5 stored procedures → PostgreSQL functions
- Converted sample data INSERT with conditional check
- Removed GO statements, IF NOT EXISTS sys.objects patterns

### Database/Scripts/01_InitialSetup.sql (Comprehensive)
- Converted 5 CREATE TABLE statements (Categories, Suppliers, Products, ProductHistory, ProductStats)
- Converted data types: nvarchar → varchar, datetime → timestamp, bit → boolean, IDENTITY → SERIAL
- Converted self-referencing FK, multi-table FKs
- Converted 5 indexes (including unique index)
- Converted trigger from SQL Server syntax to PostgreSQL trigger + function pattern
- Converted SYSTEM_USER → current_user
- Converted 5 stored procedures → PostgreSQL functions (RETURNS TABLE/VOID)
- Converted all sample data INSERTs (categories, suppliers, products, productstats)
- Converted UPDATE ProductStats with subqueries

---

## Build Verification

| Step | Build Result |
|------|-------------|
| After SQL statement conversion (Step 2) | Failed (expected - Npgsql not yet in csproj) |
| After dependency + config update (Step 3) | **Success** - 0 errors, 10 warnings |
| After script conversion (Step 4) | **Success** - 0 errors |

**Warnings:** All 10 warnings are pre-existing nullable reference warnings (CS8601, CS8603, CS8618, CS8625, CS8600) not related to the migration.

---

## Issues and Manual Interventions

1. **DMS Tool Unavailable:** The DMS MCP tool consistently timed out for all conversion attempts. All 13 statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` method.

2. **SQL Equivalency Tool Systemic Error:** The equivalency tool returned `ERROR` with `"'uniqueID'"` for all 13 statement pairs, including trivially simple queries. This is a tool-level issue, not related to the SQL statements.

3. **Npgsql Version Security Fix:** Initially planned Npgsql 8.0.1 was found to have a high-severity vulnerability. Upgraded to 8.0.9 which resolved the issue.

4. **Transaction Block Restructuring:** SQL Server transaction blocks with DECLARE variables (InsertProduct, UpdateProduct, DeleteProduct) were restructured using PostgreSQL writable CTEs instead of multi-statement transactions. This approach is cleaner for ADO.NET single-command execution.

5. **CTE Naming Conflict:** The `ProductStats` CTE in GetAllProductsAsync was renamed to `productstats_cte` to avoid conflict with the `productstats` table name.

6. **Integer Division:** Added `::numeric` cast in GetLowStockProductsAsync to ensure decimal division in the `ROUND()` function.
