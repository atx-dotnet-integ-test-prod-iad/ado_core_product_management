# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

This report documents the complete migration of the ADO.NET Core application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-05-01  
**Application:** AdoCore - Product Management System  
**Source Database:** Microsoft SQL Server  
**Target Database:** PostgreSQL  
**Framework:** .NET 9.0 with ADO.NET  

---

## 1. SQL Statement Processing Summary

### ProductRepository.cs Statements (7 total)

| # | Method | DMS Conversion | Equivalency Status |
|---|--------|---------------|-------------------|
| 1 | GetAllProductsAsync | FAILED - Manual conversion | ERROR |
| 2 | GetProductByIdAsync | FAILED - Manual conversion | ERROR |
| 3 | InsertProductAsync | FAILED - Manual conversion | ERROR |
| 4 | UpdateProductAsync | FAILED - Manual conversion | ERROR |
| 5 | DeleteProductAsync | FAILED - Manual conversion | ERROR |
| 6 | GetProductsByPriceRangeAsync | FAILED - Manual conversion | ERROR |
| 7 | GetLowStockProductsAsync | FAILED - Manual conversion | ERROR |

### DMS Conversion Results
- **Statements attempted:** 7
- **Successfully converted by DMS:** 0
- **Failed (manual conversion required):** 7
- **DMS Error:** `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Schema Mapping Tool:** Successfully provided schema mappings for all 3 tables

### SQL Equivalency Validation Results
- **Statement pairs validated:** 7
- **Equivalent:** 0
- **Non-equivalent:** 0
- **Errors:** 7
- **Equivalency Tool Error:** `'uniqueID'`

### Manual Conversion Approach
Since DMS statement conversion failed, manual conversions were applied using:
1. Schema mappings from the DMS `schema_mapping_tool` (which worked successfully)
2. Lowercase schema object names per the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` method
3. Standard SQL Server to PostgreSQL syntax conversions

---

## 2. Schema Mappings (from DMS schema_mapping_tool)

| SQL Server Object | PostgreSQL Object |
|-------------------|-------------------|
| `[dbo].[Products]` | `products` (lowercase) |
| `[dbo].[ProductHistory]` | `producthistory` (lowercase) |
| `[dbo].[ProductStats]` | `productstats` (lowercase) |
| `IDENTITY(1,1)` | `GENERATED ALWAYS AS IDENTITY` |
| `GETDATE()` | `clock_timestamp()` / `NOW()` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `nvarchar(n)` | `VARCHAR(n)` |
| `decimal(18,2)` | `NUMERIC(18,2)` |
| `bit` | `BOOLEAN` |

### Column Name Mappings
All column names were converted to lowercase per DMS schema mapping:
- `ProductId` → `productid`
- `Name` → `name`
- `Description` → `description`
- `Price` → `price`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`
- (and all other columns similarly)

---

## 3. Key SQL Syntax Conversions

| SQL Server Syntax | PostgreSQL Syntax | Notes |
|-------------------|-------------------|-------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | Used RETURNING clause for INSERT |
| `GETDATE()` | `NOW()` | PostgreSQL current timestamp |
| `BEGIN TRANSACTION` | `BEGIN` | PostgreSQL transaction syntax |
| `DECLARE @var TYPE` | Restructured to C# variables | PostgreSQL doesn't support T-SQL variables in plain SQL |
| `ROUND(expr, 2)` | `ROUND(expr, 2)` | Same syntax, added CAST for integer division |
| `SYSTEM_USER` | `CURRENT_USER` | PostgreSQL current user |
| `SET NOCOUNT ON` | Removed | Not applicable to PostgreSQL |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | PostgreSQL uses functions |
| `IF NOT EXISTS (SELECT...)` | `CREATE TABLE IF NOT EXISTS` / `DO $$` blocks | PostgreSQL conditional patterns |
| `GO` | Removed | Not applicable to PostgreSQL |

---

## 4. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL, SqlClient → Npgsql classes, lowercase column names in MapProductFromReader |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.0` |
| `appsettings.json` | Connection strings updated to PostgreSQL format |
| `README.md` | Updated all SQL Server references to PostgreSQL |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL DDL syntax with triggers, functions |

---

## 5. Code Changes Detail

### Package Reference Changes
- **Removed:** `Microsoft.Data.SqlClient` v5.1.4
- **Added:** `Npgsql` v8.0.0

### ADO.NET Class Replacements
- `SqlConnection` → `NpgsqlConnection` (3 occurrences)
- `SqlCommand` → `NpgsqlCommand` (15 occurrences)
- `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
- `using Microsoft.Data.SqlClient` → `using Npgsql`

### Connection String Changes
- **Before:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- **After:** `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`

### SQL Statement Restructuring
- **Statements 1, 2, 6, 7** (SELECT queries): Straightforward conversion with lowercase table/column names
- **Statement 3** (INSERT): Restructured from single transaction block with SCOPE_IDENTITY() to separate INSERT with RETURNING clause, plus separate history and stats commands
- **Statements 4, 5** (UPDATE/DELETE): Restructured from DECLARE blocks to C# read-first-then-execute pattern with separate parameterized queries

---

## 6. Artifacts Generated

| Artifact | Description |
|----------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report with all 7 statement pairs |
| `migration_report.md` | This report |

---

## 7. Build Status

- **Final Build:** ✅ SUCCESS (0 errors, warnings are pre-existing nullable reference warnings)
- **Build Command:** `dotnet build sourceCode/AdoCore.csproj`

---

## 8. Exit Criteria Verification

| Criteria | Status |
|----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ Completed |
| All SQL Server ADO.NET classes replaced with Npgsql equivalents | ✅ Completed |
| All SQL statements processed through DMS MCP tool | ✅ Attempted (all 7 failed, manual conversion applied) |
| Comprehensive catalog of all SQL statements | ✅ Generated (extracted_statements.sql, converted_statements.sql) |
| All SQL statement pairs validated for equivalency | ✅ Attempted (all 7 returned ERROR from tool) |
| Comprehensive equivalency validation report generated | ✅ Generated (sql_equivalency_validation_report.json) |
| No agent judgment used for equivalency | ✅ All statuses from tool output only |
| DMS failures documented with manual conversion | ✅ All documented with DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Connection strings updated to PostgreSQL format | ✅ Completed |
| Transaction handling updated for PostgreSQL | ✅ Completed (restructured for PostgreSQL compatibility) |
| Application compiles successfully | ✅ Build succeeded with 0 errors |

---

## 9. Known Issues and Manual Review Items

1. **DMS Statement Conversion Tool Unavailable:** All 7 DMS conversion attempts failed with metadata model creation error. Manual conversions were applied using DMS schema mappings (which worked correctly).

2. **SQL Equivalency Tool Errors:** All 7 equivalency validation attempts returned ERROR with `'uniqueID'` error. The equivalency of converted statements should be verified manually or through integration testing.

3. **Transaction Block Restructuring:** Statements 3, 4, and 5 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync) were significantly restructured from single T-SQL transaction blocks with DECLARE variables to separate parameterized queries in C#. This maintains the same logical functionality but changes the execution pattern.

4. **Integer Division in Statement 7:** Added explicit `CAST(stockquantity AS numeric)` to prevent integer division in PostgreSQL's ROUND function, which differs from SQL Server's implicit numeric conversion.

---

*Report generated as part of MS SQL Server to PostgreSQL migration for ADoCore application.*
