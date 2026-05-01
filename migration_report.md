# Migration Report: MS SQL Server to PostgreSQL (ADO.NET Application)

## Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Files Modified | 3 (ProductRepository.cs, AdoCore.csproj, appsettings.json) |
| Files Created | 4 (extracted_statements.sql, converted_statements.sql, sql_equivalency_validation_report.json, migration_report.md) |
| Package Changes | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| DMS Successful Conversions | 0 (service error) |
| Manual Conversions Required | 7 |
| Equivalency Tool Validations | 7 attempted, 7 errors (service error) |

---

## DMS Conversion Results

All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with `schema_name='dbo'`. All 7 failed with the same error:

**DMS Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

Since DMS failed, all 7 statements were manually converted applying lowercase schema object names for PostgreSQL compatibility, documented as `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

### Statement 1: GetAllProductsAsync
- **Source Method:** `GetAllProductsAsync()`
- **Type:** CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
- **Parameters:** None
- **DMS Status:** FAILED
- **Manual Conversion:** Lowercase schema objects (Products→products, ProductId→productid, etc.)
- **Key Changes:** No SQL syntax changes needed (CTE, window functions, CASE, ROUND are PostgreSQL-compatible)

### Statement 2: GetProductByIdAsync
- **Source Method:** `GetProductByIdAsync(int productId)`
- **Type:** CTE with LAG() window function, LEFT JOIN, CASE, ROUND
- **Parameters:** @ProductId
- **DMS Status:** FAILED
- **Manual Conversion:** Lowercase schema objects
- **Key Changes:** No SQL syntax changes needed (LAG(), ROUND are PostgreSQL-compatible)

### Statement 3: InsertProductAsync
- **Source Method:** `InsertProductAsync(Product product)`
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Parameters:** @Name, @Description, @Price, @StockQuantity
- **DMS Status:** FAILED
- **Manual Conversion:** 
  - `DECLARE @NewProductId INT; SET @NewProductId = SCOPE_IDENTITY()` → `LASTVAL()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `SELECT @NewProductId` → `SELECT LASTVAL()`
  - All table/column names to lowercase

### Statement 4: UpdateProductAsync
- **Source Method:** `UpdateProductAsync(Product product)`
- **Type:** Transaction block with DECLARE variables, SELECT into variables, GETDATE()
- **Parameters:** @ProductId, @Name, @Description, @Price, @StockQuantity
- **DMS Status:** FAILED
- **Manual Conversion:**
  - `DECLARE @OldPrice / @OldStock` + `SELECT INTO` → replaced with subqueries `(SELECT price FROM products WHERE productid = @ProductId)`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - All table/column names to lowercase

### Statement 5: DeleteProductAsync
- **Source Method:** `DeleteProductAsync(int productId)`
- **Type:** Transaction block with DECLARE variables, DELETE, CASE, GETDATE()
- **Parameters:** @ProductId
- **DMS Status:** FAILED
- **Manual Conversion:**
  - `DECLARE @OldPrice / @OldStock` + `SELECT INTO` → replaced with subqueries
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - Reordered: log + stats update before DELETE (to capture old values via subqueries)
  - All table/column names to lowercase

### Statement 6: GetProductsByPriceRangeAsync
- **Source Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type:** CTE with RANK()/PERCENT_RANK() window functions, BETWEEN, CASE
- **Parameters:** @MinPrice, @MaxPrice
- **DMS Status:** FAILED
- **Manual Conversion:** Lowercase schema objects
- **Key Changes:** No SQL syntax changes needed (RANK, PERCENT_RANK, BETWEEN are PostgreSQL-compatible)

### Statement 7: GetLowStockProductsAsync
- **Source Method:** `GetLowStockProductsAsync(int threshold)`
- **Type:** CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Parameters:** @Threshold
- **DMS Status:** FAILED
- **Manual Conversion:**
  - Added `CAST(stockquantity AS NUMERIC)` to prevent integer division in ROUND
  - All table/column names to lowercase

---

## Equivalency Validation Results

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). Two rounds of validation were performed:

**Round 1 (Initial):** All 7 returned ERROR with `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`. Statements 4 and 5 were validated using DO $ block versions.

**Round 2 (Re-attempt):** All 7 re-submitted with corrected statements for 4 and 5 (using actual deployed inline subquery versions from ProductRepository.cs). All 7 again returned ERROR with the same service-level error.

**Equivalency Tool Error:** `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`

**Known Limitation:** The SQL Equivalency tool consistently returns a service-level error (`'uniqueID'`) for all statement pairs across multiple retry attempts. This is a tool-side issue, not a reflection of conversion quality. All 7 statements require manual equivalency review.

| # | Statement | Conversion Method | Equivalency Status | Deployed Matches Validated |
|---|-----------|-------------------|--------------------|---------------------------|
| 1 | GetAllProductsAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR | Yes |
| 2 | GetProductByIdAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR | Yes |
| 3 | InsertProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR | Yes |
| 4 | UpdateProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR | Yes (updated to subquery version) |
| 5 | DeleteProductAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR | Yes (updated to subquery version) |
| 6 | GetProductsByPriceRangeAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR | Yes |
| 7 | GetLowStockProductsAsync | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | ERROR | Yes |

**Note:** Per transformation rules, equivalency status comes solely from the tool output. The ERROR status is due to a persistent service-level issue with the SQL Equivalency tool, not a reflection of the conversion quality. Statements 4 and 5 were re-validated in Round 2 using the actual deployed inline subquery versions (not the initial DO $ block versions) to ensure the validated code matches what is deployed in ProductRepository.cs.

---

## Code Changes Summary

### ADO.NET Class Replacements (ProductRepository.cs)
| Original (SQL Server) | Replacement (PostgreSQL) |
|-----------------------|-------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `new SqlConnection(...)` | `new NpgsqlConnection(...)` |
| `new SqlCommand(...)` | `new NpgsqlCommand(...)` |

### Package Changes (AdoCore.csproj)
| Action | Package | Version |
|--------|---------|---------|
| Removed | Microsoft.Data.SqlClient | 5.1.4 |
| Added | Npgsql | 8.0.6 |
| Unchanged | Microsoft.Extensions.Configuration | 8.0.0 |
| Unchanged | Microsoft.Extensions.Configuration.Json | 8.0.0 |
| Unchanged | Microsoft.Extensions.DependencyInjection | 8.0.0 |

### Connection String Changes (appsettings.json)
| Parameter | SQL Server | PostgreSQL |
|-----------|------------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | (removed - not applicable) |
| TrustServerCertificate | `True` | (removed - not applicable) |

---

## Statements Requiring Manual Review

All 7 statements should be manually reviewed since:
1. DMS tool was unavailable for automated conversion (persistent metadata model error)
2. SQL Equivalency tool was unavailable for automated validation (persistent 'uniqueID' service error confirmed across 2 retry rounds)
3. Statements 4 and 5 (UpdateProductAsync, DeleteProductAsync) had structural changes to handle SQL Server's DECLARE/SET variable pattern using PostgreSQL-compatible inline subqueries
4. The converted_statements.sql catalog and sql_equivalency_validation_report.json have been updated to reflect the actual deployed inline subquery versions for statements 4 and 5

---

## Artifacts

| File | Description | Status |
|------|-------------|--------|
| `extracted_statements.sql` | All 7 original MS SQL statements | Complete |
| `converted_statements.sql` | All 7 converted PostgreSQL statements | Complete |
| `sql_equivalency_validation_report.json` | Equivalency validation report with all 7 pairs | Complete |
| `migration_report.md` | This comprehensive migration report | Complete |

---

## Build Status

**Final Build:** SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)
