# Migration Report: SQL Server to PostgreSQL

## Overview
- **Project**: AdoCore - Product Management Application
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-04-06
- **Framework**: .NET 9.0 with ADO.NET

## Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed (from C# code) | 7 |
| DMS Tool Conversion Successes | 0 |
| DMS Tool Conversion Failures | 7 |
| Manual Conversions (DMS Failure) | 7 |
| SQL Equivalency Validations Attempted | 7 |
| SQL Equivalency Results: EQUIVALENT | 0 |
| SQL Equivalency Results: NOT_EQUIVALENT | 0 |
| SQL Equivalency Results: ERROR | 7 |
| Database Setup Scripts Converted | 2 |
| Files Modified | 4 |
| Files Created | 5 |

## DMS Tool Status
The DMS MCP tool (dms-mcp___statement_conversion_tool) was unavailable throughout the migration. All attempts to use the tool resulted in:
- **Error**: "Metadata model creation/conversion did not complete after N attempts"
- **Attempts**: Multiple attempts with varying poll settings (5s/10, 10s/15, 15s/30) all failed
- **Fallback**: Manual conversion was applied using lowercase schema object naming convention per migration guidelines

## SQL Equivalency Tool Status
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) returned errors for all validation attempts:
- **Error**: `'uniqueID'` (service-level error)
- **All 7 statement pairs**: Marked as ERROR per tool output (not agent judgment)

## Files Modified

### 1. sourceCode/DataAccess/ProductRepository.cs
- **SQL Statements**: All 7 SQL statements converted from T-SQL to PostgreSQL
  - Schema object names lowercased (Products → products, ProductId → productid, etc.)
  - `SCOPE_IDENTITY()` → `INSERT ... RETURNING productid`
  - `GETDATE()` → `NOW()`
  - T-SQL `DECLARE @variable` / `SET @variable` → C# variables with separate SQL commands
  - Transaction blocks restructured from single T-SQL block to C#-managed transactions with multiple NpgsqlCommand calls
  - `CAST(x AS DECIMAL)` → `x::numeric` (PostgreSQL cast syntax)
  - Column name references in reader lowercased for PostgreSQL
- **ADO.NET Classes**: All replaced
  - `using Microsoft.Data.SqlClient` → `using Npgsql`
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`

### 2. sourceCode/AdoCore.csproj
- **Package**: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6`
  - Note: Npgsql 8.0.1 was originally planned but had known vulnerability (GHSA-x9vc-6hfv-hg8c), upgraded to 8.0.6

### 3. sourceCode/appsettings.json
- **Connection Strings**: Updated from SQL Server to PostgreSQL format
  - `Server=` → `Host=`
  - Removed: `Trusted_Connection=True`, `MultipleActiveResultSets=true`, `TrustServerCertificate=True`
  - Added: `Username=postgres`, `Password=postgres`

### 4. sourceCode/Scripts/01_InitialSetup.sql
- Converted from T-SQL to PostgreSQL
- Key conversions:
  - `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
  - `NVARCHAR` → `VARCHAR`
  - `[dbo].[tablename]` → `tablename` (lowercase)
  - `GETDATE()` → `NOW()`
  - `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION` (PL/pgSQL)
  - `GO` batch separators → removed
  - `IF NOT EXISTS (SELECT * FROM sys.objects...)` → `CREATE TABLE IF NOT EXISTS`
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `IF NOT EXISTS (SELECT TOP 1 1...)` → `DO $$ BEGIN IF NOT EXISTS ... END IF; END; $$;`

### 5. sourceCode/Database/Scripts/01_InitialSetup.sql
- Comprehensive conversion from T-SQL to PostgreSQL
- Additional conversions beyond above:
  - `BIT` → `BOOLEAN`
  - `DEFAULT 1` (for bit) → `DEFAULT TRUE`
  - `DEFAULT 0` (for bit) → `DEFAULT FALSE`
  - `SYSTEM_USER` → `CURRENT_USER`
  - SQL Server trigger syntax → PostgreSQL trigger function + trigger
  - `IF EXISTS (SELECT * FROM sys.objects...)` → `DROP ... IF EXISTS`
  - `USE DatabaseName` → removed (PostgreSQL doesn't support USE)
  - Self-referencing foreign keys preserved
  - Indexes converted with lowercase naming

## Files Created

| File | Purpose |
|------|---------|
| sourceCode/extracted_statements.sql | Catalog of all 7 original MS SQL statements |
| sourceCode/converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sourceCode/sql_equivalency_validation_report.json | Comprehensive equivalency validation report |
| sourceCode/migration_report.md | This report |

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Changes**: Schema objects lowercased only; SQL syntax already PostgreSQL-compatible

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Changes**: Schema objects lowercased only; SQL syntax already PostgreSQL-compatible

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Changes**: Major restructure - SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), DECLARE variables → C# variables, single SQL block → multiple NpgsqlCommand calls in C# transaction

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Changes**: GETDATE() → NOW(), DECLARE variables → C# variables, single SQL block → multiple NpgsqlCommand calls in C# transaction

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Changes**: GETDATE() → NOW(), DECLARE variables → C# variables, single SQL block → multiple NpgsqlCommand calls in C# transaction

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK/PERCENT_RANK Window Functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Changes**: Schema objects lowercased only; SQL syntax already PostgreSQL-compatible

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned `'uniqueID'` error)
- **Changes**: Schema objects lowercased, added `::numeric` cast for integer division in ROUND function

## Items Requiring Manual Review

1. **SQL Equivalency**: All 7 statement pairs returned ERROR from the equivalency tool. Manual review of SQL conversions is recommended.
2. **Connection Credentials**: The PostgreSQL connection string uses placeholder credentials (postgres/postgres). Production credentials should be configured via environment variables or a secure secrets manager.
3. **Transaction Restructuring**: Statements 3, 4, and 5 were restructured from single T-SQL blocks to multiple C# commands within a transaction. This maintains the same transactional guarantees but changes the execution pattern.
4. **Database Scripts**: The setup scripts have been converted but not validated against a live PostgreSQL instance. Manual testing is recommended.
5. **DMS Tool Availability**: All DMS conversions failed. If the DMS tool becomes available, re-running the conversions would provide authoritative PostgreSQL equivalents.

## Build Status
- **Final Build**: ✅ Success (0 errors, 10 warnings - all pre-existing nullable reference warnings)
