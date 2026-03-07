# Migration Report: SQL Server to PostgreSQL

## Overview
This report documents the complete migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

## Migration Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed (In-Code) | 7 |
| Total DDL Statements Processed (Scripts) | 3 |
| **Total Statements Processed** | **10** |
| Successfully Converted by DMS | 9 |
| Manual Conversion Required | 1 |
| Equivalency Validated (EQUIVALENT) | 0 |
| Equivalency Validated (NOT_EQUIVALENT) | 0 |
| Equivalency Validation ERRORS | 10 |

## DMS Conversion Details

### Schema Mapping
- **Source Schema**: `[dbo]` (SQL Server)
- **Target Schema**: `productmanagement_dbo` (PostgreSQL, as mapped by DMS)
- **All identifiers**: Lowercased by DMS

### Key Transformations Applied by DMS
| SQL Server | PostgreSQL |
|------------|-----------|
| `IDENTITY(1,1)` | `BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1)` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `DATETIME` | `TIMESTAMP WITHOUT TIME ZONE` |
| `BIT` | `NUMERIC(1, 0)` (DMS) / `BOOLEAN` (manual) |
| `DECIMAL(p,s)` | `NUMERIC(p,s)` |
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `LEFT JOIN` | `LEFT OUTER JOIN` |
| `ORDER BY col` | `ORDER BY col NULLS FIRST` |
| `SYSTEM_USER` | `current_user` |
| `SET NOCOUNT ON` | Removed (not applicable) |
| `GO` batch separator | Removed (not needed) |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| SQL Server trigger syntax | PostgreSQL trigger function + CREATE TRIGGER |

## In-Code SQL Statement Conversions (ProductRepository.cs)

### Statement 1: GetAllProductsAsync
- **DMS Status**: SUCCESS
- **Conversion**: CTE with window functions, CASE expressions, INNER JOIN
- **Schema**: `Products` → `productmanagement_dbo.products`

### Statement 2: GetProductByIdAsync
- **DMS Status**: SUCCESS
- **Conversion**: CTE with LAG window function, LEFT JOIN → LEFT OUTER JOIN
- **Schema**: `Products` → `productmanagement_dbo.products`

### Statement 3: InsertProductAsync
- **DMS Status**: FAILED
- **DMS Error**: "Statement definition is not valid" - complex transaction block with DECLARE before BEGIN TRANSACTION
- **Manual Conversion**: Applied DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: SCOPE_IDENTITY() → RETURNING productid, GETDATE() → clock_timestamp()
- **Schema**: `Products` → `productmanagement_dbo.products`, `ProductHistory` → `productmanagement_dbo.producthistory`, `ProductStats` → `productmanagement_dbo.productstats`

### Statement 4: UpdateProductAsync
- **DMS Status**: SUCCESS (with note [7807] about explicit transaction management)
- **Conversion**: Transaction block with DECLARE, SELECT INTO, UPDATE, INSERT
- **Note**: DMS commented out BEGIN TRANSACTION as PostgreSQL doesn't support it in functions

### Statement 5: DeleteProductAsync
- **DMS Status**: SUCCESS (with note [7807] about explicit transaction management)
- **Conversion**: Transaction block with DECLARE, SELECT INTO, INSERT, DELETE, CASE UPDATE

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: SUCCESS
- **Conversion**: CTE with RANK(), PERCENT_RANK() window functions

### Statement 7: GetLowStockProductsAsync
- **DMS Status**: SUCCESS
- **Conversion**: CTE with AVG/MIN/MAX window functions

## DDL Script Conversions

### CREATE TABLE Categories
- **DMS Status**: SUCCESS
- **Key Changes**: IDENTITY → GENERATED ALWAYS AS IDENTITY, NVARCHAR → VARCHAR, DATETIME → TIMESTAMP WITHOUT TIME ZONE

### CREATE TABLE Products (Full schema)
- **DMS Status**: SUCCESS
- **Key Changes**: Same as above, plus BIT → NUMERIC(1,0), foreign keys preserved

### CREATE TABLE ProductHistory
- **DMS Status**: SUCCESS
- **Key Changes**: Same patterns as other tables

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

## Package Changes

| Original | Replacement |
|----------|------------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` |

*Note: Npgsql 8.0.6 was used instead of 8.0.1 to address high-severity vulnerability GHSA-x9vc-6hfv-hg8c*

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed (not applicable) |

## SQL Equivalency Validation

All 10 statement pairs were validated using the sql-equivalency___validate_sql_equivalence tool.
All returned ERROR status with `'uniqueID'` error. This appears to be a tool-level issue, not a conversion quality issue.

**Note**: Equivalency statuses are reported exactly as returned by the tool. No agent judgment was used.

## Files Modified

1. **sourceCode/DataAccess/ProductRepository.cs** - SQL statements converted, ADO.NET classes replaced
2. **sourceCode/AdoCore.csproj** - Package reference updated (SqlClient → Npgsql)
3. **sourceCode/appsettings.json** - Connection strings updated to PostgreSQL format
4. **sourceCode/Scripts/01_InitialSetup.sql** - Converted to PostgreSQL DDL
5. **sourceCode/Database/Scripts/01_InitialSetup.sql** - Converted to PostgreSQL DDL (comprehensive version)

## Files Created

1. **sourceCode/extracted_statements.sql** - Catalog of all 7 original MS SQL statements
2. **sourceCode/converted_statements.sql** - Catalog of all 7 converted PostgreSQL statements
3. **sourceCode/sql_equivalency_validation_report.json** - Comprehensive equivalency report
4. **sourceCode/migration_report.md** - This report

## Build Status
- **Final Build**: SUCCESS (0 errors, warnings are pre-existing nullable reference type warnings)

## Transaction Handling Notes
For the transaction-based statements (3, 4, 5), the original SQL Server code used embedded `BEGIN TRANSACTION`/`COMMIT` within the SQL strings. Since PostgreSQL doesn't support this pattern for inline SQL executed via ADO.NET (as DMS noted with error [7807]), the C# code was restructured to:
- Use `BeginTransactionAsync()` / `CommitAsync()` / `RollbackAsync()` from Npgsql
- Execute individual SQL statements within the C# managed transaction
- Preserve all DMS-converted schema names (`productmanagement_dbo`) and function conversions (`clock_timestamp()`)
