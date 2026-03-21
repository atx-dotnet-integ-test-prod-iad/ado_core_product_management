# Migration Report: SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore - ADO.NET Core Data Management Application
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Framework**: .NET 9.0
- **Migration Date**: 2026-03-21

## Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed (from code) | 7 |
| DMS Conversions Attempted | 7 |
| DMS Conversions Succeeded | 0 |
| DMS Conversions Failed | 7 |
| Manual Conversions (DMS failure fallback) | 7 |
| Equivalency Validations Attempted | 7 |
| Equivalency Results: EQUIVALENT | 0 |
| Equivalency Results: NOT_EQUIVALENT | 0 |
| Equivalency Results: ERROR | 7 |
| Database Scripts Converted | 2 |
| Total Files Modified | 6 |

## DMS MCP Tool Results

All 7 SQL statements from ProductRepository.cs were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`). All conversions failed:

| # | Method | DMS Error |
|---|--------|-----------|
| 1 | GetAllProductsAsync | Metadata model conversion did not complete after 15 attempts |
| 2 | GetProductByIdAsync | Metadata model conversion did not complete after 15 attempts |
| 3 | InsertProductAsync | Statement definition is not valid |
| 4 | UpdateProductAsync | Metadata model conversion did not complete after 15 attempts |
| 5 | DeleteProductAsync | Metadata model conversion did not complete after 15 attempts |
| 6 | GetProductsByPriceRangeAsync | Metadata model creation did not complete after 15 attempts |
| 7 | GetLowStockProductsAsync | Metadata model creation did not complete after 15 attempts |

**Fallback**: All 7 statements were manually converted applying lowercase schema object naming conventions for PostgreSQL compatibility, with conversion_method: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Equivalency Validation Results

All 7 statement pairs were passed through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR with `'uniqueID'` - a consistent tool-side issue.

Per the transformation definition: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR."

Full report available in: `sql_equivalency_validation_report.json`

## SQL Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Changes**: Schema objects lowercased (Products→products, ProductId→productid, etc.)
- **PostgreSQL Compatible**: Yes (window functions, CTEs work the same)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Changes**: Schema objects lowercased
- **PostgreSQL Compatible**: Yes (LAG, CTEs work the same)

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `NOW()`
  - `DECLARE @var / SET @var` → Application-level variable handling
  - `BEGIN TRANSACTION / COMMIT` → Application-level `BeginTransactionAsync()`
  - Single batch → Multiple commands within app transaction

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, SELECT INTO, UPDATE, GETDATE()
- **Changes**:
  - `DECLARE @OldPrice / @OldStock` → C# variables (`oldPrice`, `oldStock`)
  - `SELECT @var = col` → Separate SELECT query in C# with reader
  - `GETDATE()` → `NOW()`
  - Single batch → Multiple commands within app transaction

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT, INSERT, DELETE, UPDATE, CASE
- **Changes**:
  - Same DECLARE/variable handling as Statement 4
  - `GETDATE()` → `NOW()`
  - Single batch → Multiple commands within app transaction

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Changes**: Schema objects lowercased
- **PostgreSQL Compatible**: Yes (RANK, PERCENT_RANK work the same)

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Changes**:
  - Schema objects lowercased
  - Added `::numeric` cast for integer division in ROUND (`stockquantity::numeric / avgstock`)

## Schema Object Name Changes

All schema object names (tables, columns, aliases) were converted to lowercase for PostgreSQL compatibility:

| SQL Server | PostgreSQL |
|-----------|------------|
| Products | products |
| ProductId | productid |
| ProductHistory | producthistory |
| ProductStats | productstats |
| StockQuantity | stockquantity |
| CreatedDate | createddate |
| ModifiedDate | modifieddate |
| AvgPrice | avgprice |
| TotalProducts | totalproducts |
| PriceCategory | pricecategory |
| (all other columns) | (lowercase equivalents) |

## Static Code Changes

### Package Dependencies (AdoCore.csproj)
- **Removed**: `Microsoft.Data.SqlClient` v5.1.4
- **Added**: `Npgsql` v8.0.6

### ADO.NET Class Replacements (ProductRepository.cs)
| SQL Server Class | Npgsql Class | Count |
|-----------------|--------------|-------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `SqlTransaction` | `NpgsqlTransaction` | 11 |

### Connection Strings (appsettings.json)
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `True` | (removed - not supported) |
| TrustServerCertificate | `True` | (removed - not applicable) |

## Database Setup Scripts Converted

### Database/Scripts/01_InitialSetup.sql (Full setup)
- Converted all CREATE TABLE with IDENTITY → SERIAL
- Converted NVARCHAR/VARCHAR → VARCHAR
- Converted DATETIME → TIMESTAMP
- Converted BIT → BOOLEAN
- Converted GETDATE() → NOW()
- Removed GO statements
- Removed [dbo]. schema prefix and brackets
- Converted stored procedures to PostgreSQL functions (PL/pgSQL)
- Converted trigger to PostgreSQL trigger function + trigger definition
- Converted SYSTEM_USER → current_user
- Converted IF NOT EXISTS sys.objects checks → DROP IF EXISTS

### Scripts/01_InitialSetup.sql (Simple setup)
- Same conversions as above (simpler version)
- Converted EXEC sp_InsertProduct → PERFORM sp_insertproduct
- Converted IF NOT EXISTS check → DO block with IF NOT EXISTS

## Files Modified

1. `sourceCode/DataAccess/ProductRepository.cs` - SQL statements + ADO.NET classes
2. `sourceCode/AdoCore.csproj` - Package reference
3. `sourceCode/appsettings.json` - Connection strings
4. `sourceCode/README.md` - Documentation updated for PostgreSQL
5. `sourceCode/Database/Scripts/01_InitialSetup.sql` - Full setup script
6. `sourceCode/Scripts/01_InitialSetup.sql` - Simple setup script

## Artifacts Generated

1. `extracted_statements.sql` - Original MS SQL statements catalog
2. `converted_statements.sql` - Converted PostgreSQL statements catalog
3. `sql_equivalency_validation_report.json` - Equivalency validation report
4. `migration_report.md` - This report

## Build Status

- **Final Build**: ✅ Success (0 Errors, 10 Warnings)
- All warnings are pre-existing nullable reference warnings from the original code

## Manual Interventions Required

1. **All 7 SQL conversions** were done manually due to DMS tool failures
2. **All 7 equivalency checks** returned ERROR from the tool - manual review recommended
3. **Transaction blocks** (InsertProductAsync, UpdateProductAsync, DeleteProductAsync) required structural changes from single SQL batch to multiple C# commands with application-level transactions
4. **Integer division** in GetLowStockProductsAsync required `::numeric` cast for PostgreSQL ROUND function
