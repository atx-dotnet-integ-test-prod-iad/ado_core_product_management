# Migration Report: Microsoft SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-02 |
| **Source Database** | Microsoft SQL Server |
| **Target Database** | PostgreSQL |
| **Application Framework** | .NET 9.0 (ADO.NET) |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |
| **Build Status** | ✅ SUCCESS (0 errors) |

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Manually converted (DMS failure) | 7 |
| Validated as EQUIVALENT by SQL Equivalency tool | 0 |
| Validated as NOT_EQUIVALENT by SQL Equivalency tool | 0 |
| SQL Equivalency tool returned ERROR | 7 |

### DMS Tool Status
The DMS MCP Statement Conversion Tool (dms-mcp___statement_conversion_tool) was **unavailable** during this migration. Multiple attempts (4 total) were made with different configurations:
- Attempt 1: Default settings → "Metadata model conversion failed after 15 attempts"
- Attempt 2: max_poll_attempts=30, poll_interval_seconds=15 → Command timed out after 300 seconds
- Attempt 3: max_poll_attempts=30, poll_interval_seconds=15 with simple query → Command timed out after 300 seconds
- Attempt 4: max_poll_attempts=25, poll_interval_seconds=10 → "Metadata model creation failed after 25 attempts"

The DMS Schema Mapping Tool (dms-mcp___schema_mapping_tool) was **available** and successfully provided schema mappings for all three target tables, which were used to guide the manual conversion.

### SQL Equivalency Tool Status
The SQL Equivalency Tool (sql-equivalency___validate_sql_equivalence) was called for all 7 statement pairs. All 7 returned ERROR with message `'uniqueID'`. No agent judgment was used for equivalency determination - all statuses are directly from the tool output.

---

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Source**: `sourceCode/DataAccess/ProductRepository.cs` → `GetAllProductsAsync()`
- **Type**: Complex CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Key Changes**:
  - CTE name `ProductStats` → `productstats_cte` (renamed to avoid conflict with table name `productstats`)
  - All table/column identifiers → lowercase
  - SQL logic and structure preserved

### Statement 2: GetProductByIdAsync
- **Source**: `sourceCode/DataAccess/ProductRepository.cs` → `GetProductByIdAsync(int productId)`
- **Type**: CTE with LAG window function, CASE, ROUND, parameterized @ProductId
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Key Changes**:
  - CTE name `ProductHistory` → `producthistory_cte` (renamed to avoid conflict with table name `producthistory`)
  - All table/column identifiers → lowercase
  - @ProductId parameter preserved (Npgsql supports @ prefix)

### Statement 3: InsertProductAsync
- **Source**: `sourceCode/DataAccess/ProductRepository.cs` → `InsertProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, BEGIN TRANSACTION/COMMIT, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @NewProductId INT` / `SET @NewProductId = SCOPE_IDENTITY()` → C# variable with RETURNING clause
  - `BEGIN TRANSACTION`/`COMMIT` → C# `BeginTransactionAsync()`/`CommitAsync()`
  - Single SQL command → Multiple NpgsqlCommand objects within C# transaction
  - All identifiers → lowercase

### Statement 4: UpdateProductAsync
- **Source**: `sourceCode/DataAccess/ProductRepository.cs` → `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice` / `SELECT @OldPrice = Price` → C# variable with separate SELECT query
  - `BEGIN TRANSACTION`/`COMMIT` → C# `BeginTransactionAsync()`/`CommitAsync()`
  - Single SQL command → Multiple NpgsqlCommand objects within C# transaction
  - All identifiers → lowercase

### Statement 5: DeleteProductAsync
- **Source**: `sourceCode/DataAccess/ProductRepository.cs` → `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice` / `SELECT @OldPrice = Price` → C# variable with separate SELECT query
  - `BEGIN TRANSACTION`/`COMMIT` → C# `BeginTransactionAsync()`/`CommitAsync()`
  - Single SQL command → Multiple NpgsqlCommand objects within C# transaction
  - CASE expression preserved (PostgreSQL compatible)
  - All identifiers → lowercase

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: `sourceCode/DataAccess/ProductRepository.cs` → `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Key Changes**:
  - CTE name `RankedProducts` → `rankedproducts`
  - All table/column identifiers → lowercase
  - RANK(), PERCENT_RANK(), BETWEEN preserved (PostgreSQL compatible)

### Statement 7: GetLowStockProductsAsync
- **Source**: `sourceCode/DataAccess/ProductRepository.cs` → `GetLowStockProductsAsync(int threshold)`
- **Type**: CTE with AVG/MIN/MAX window aggregates, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Key Changes**:
  - CTE name `StockAnalysis` → `stockanalysis`
  - All table/column identifiers → lowercase
  - Window functions preserved (PostgreSQL compatible)

---

## Schema Mapping (from DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) |
|-------------------|-------------------|
| `[dbo].[Products]` | `products` (schema: `productmanagement_dbo`) |
| `[dbo].[ProductHistory]` | `producthistory` (schema: `productmanagement_dbo`) |
| `[dbo].[ProductStats]` | `productstats` (schema: `productmanagement_dbo`) |

### Column Mapping (all lowercased per DMS schema mapping)
| SQL Server | PostgreSQL | Type Change |
|-----------|-----------|-------------|
| `ProductId` (int IDENTITY) | `productid` (INTEGER GENERATED ALWAYS AS IDENTITY) | Identity syntax |
| `Name` (nvarchar) | `name` (VARCHAR) | Unicode → standard varchar |
| `Description` (nvarchar) | `description` (VARCHAR) | Unicode → standard varchar |
| `Price` (decimal(18,2)) | `price` (NUMERIC(18,2)) | decimal → NUMERIC |
| `StockQuantity` (int) | `stockquantity` (INTEGER) | Casing only |
| `CreatedDate` (datetime) | `createddate` (TIMESTAMP WITHOUT TIME ZONE) | Type change |
| `ModifiedDate` (datetime) | `modifieddate` (TIMESTAMP WITHOUT TIME ZONE) | Type change |

---

## Code Changes Summary

### Files Modified

| File | Change Type | Description |
|------|------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | Replaced all SQL statements, ADO.NET classes, and column references |
| `AdoCore.csproj` | Modified | Swapped Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Modified | Updated connection strings to PostgreSQL format |

### Files Created

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This migration report |

### ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|-----------------------|------------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (not used in codebase) |

### Connection String Conversion

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed |

---

## Statements Requiring Manual Review

All 7 statements should be reviewed manually due to:

1. **DMS Tool Unavailability**: All conversions were performed manually since the DMS MCP tool was consistently failing. The manual conversions used DMS Schema Mapping Tool output for accurate schema name mapping.

2. **SQL Equivalency Tool Errors**: All 7 statement pairs returned ERROR from the SQL Equivalency tool with error `'uniqueID'`. This means automated equivalency verification was not achievable.

3. **Structural Changes (Statements 3, 4, 5)**: The transactional statements required structural refactoring from single-command SQL with DECLARE/BEGIN TRANSACTION to multi-command C# transaction patterns. While functionally equivalent, the code structure has changed significantly.

### Recommended Manual Verification Steps
- [ ] Execute each SELECT statement against PostgreSQL with sample data to verify results match SQL Server
- [ ] Test INSERT operation and verify RETURNING clause returns correct ID
- [ ] Test UPDATE operation and verify old values are correctly captured for history
- [ ] Test DELETE operation and verify cascade behavior matches expectations
- [ ] Verify ProductStats table updates are correct in all transaction scenarios
- [ ] Test error handling / rollback behavior for all transactional methods

---

## Build Verification

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
Time Elapsed 00:00:01.27
```

All warnings are nullable reference warnings (pre-existing in the original codebase), not related to the migration.
