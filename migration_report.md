# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview
- **Project**: AdoCore (.NET ADO.NET Application)
- **Migration Date**: 2026-04-02
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Method**: Manual conversion with lowercase schema mapping (DMS tool unavailable)

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed (inline code) | 7 |
| Total SQL statements processed (scripts) | 13 |
| **Total SQL statements processed** | **20** |
| Successfully converted by DMS | 0 |
| Manually converted (DMS failure) | 20 |
| Validated as equivalent (by tool) | 0 |
| Validated as non-equivalent (by tool) | 0 |
| Equivalency validation errors | 20 |

## DMS Tool Status
- **Status**: UNAVAILABLE (persistent infrastructure error)
- **Error**: "Metadata model creation/conversion did not complete after 15 attempts"
- **Attempts**: 5 total attempts (including diagnostic queries)
- **Impact**: All 20 statements required manual conversion
- **Fallback**: Applied `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` rules

## SQL Equivalency Tool Status
- **Status**: UNAVAILABLE (persistent infrastructure error)
- **Error**: "'uniqueID'" for all 20 statement pair validations
- **Impact**: All 20 statement pairs marked as ERROR
- **Note**: Tool was called for every statement pair as required; errors are infrastructure-level

## Files Modified

### Source Code Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Converted 7 SQL statements to PostgreSQL, replaced SqlClient with Npgsql |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.1 |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |

### SQL Script Files
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL: CREATE TABLE, stored procedures → functions |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL: all DDL, triggers, procedures, sample data |

### New Artifact Files
| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original SQL statements from C# code |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report for all 20 statement pairs |
| `dms_conversion_issues.log` | Documentation of DMS tool failures |
| `migration_report.md` | This report |

## Dependency Changes

| Component | Before | After |
|-----------|--------|-------|
| NuGet Package | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.1 |
| Using Directive | `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| Connection Class | `SqlConnection` | `NpgsqlConnection` |
| Command Class | `SqlCommand` | `NpgsqlCommand` |
| Reader Class | `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|--------------------|--------------------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Result sets | `MultipleActiveResultSets=true` | (removed - not needed) |
| Certificate | `TrustServerCertificate=True` | (removed - not applicable) |

## SQL Conversion Details

### Inline Code Statements (ProductRepository.cs)

#### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Key Changes**: Lowercase all identifiers
- **Conversion**: Straightforward - all syntax PostgreSQL compatible

#### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, parameterized query
- **Key Changes**: Lowercase all identifiers
- **Conversion**: Straightforward - LAG is PostgreSQL compatible

#### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY, multi-table operations
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Writable CTE pattern
  - `DECLARE @var` → CTE subqueries

#### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE variables, UPDATE, INSERT history
- **Key Changes**: 
  - `DECLARE @OldPrice/@OldStock` → CTE `old_values`
  - `GETDATE()` → `NOW()`
  - Transaction → Writable CTE pattern

#### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, DELETE, history logging
- **Key Changes**: Same as Statement 4 pattern
  - `GETDATE()` → `NOW()`
  - Transaction → Writable CTE pattern
  - `CASE` expression preserved (compatible)

#### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK, PERCENT_RANK, BETWEEN
- **Key Changes**: Lowercase all identifiers
- **Conversion**: Straightforward - all window functions PostgreSQL compatible

#### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes**: 
  - Lowercase all identifiers
  - `StockQuantity / AvgStock` → `CAST(stockquantity AS DECIMAL) / avgstock` (integer division fix)

### Script Statements (DDL)

| # | Type | Key Conversions |
|---|------|-----------------|
| 8 | CREATE TABLE Products (simple) | IDENTITY → SERIAL, NVARCHAR → VARCHAR, DATETIME → TIMESTAMP, GETDATE() → NOW() |
| 9 | CREATE TABLE Categories | Same DDL conversions as above |
| 10 | CREATE TABLE Suppliers | BIT → BOOLEAN, DEFAULT 1 → DEFAULT TRUE |
| 11 | CREATE TABLE ProductHistory | Same DDL conversions |
| 12 | CREATE TABLE ProductStats | Same DDL conversions |
| 13 | sp_GetAllProducts | CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION, SET NOCOUNT ON removed |
| 14 | sp_GetProductById | Same procedure → function pattern, @param → p_param |
| 15 | sp_InsertProduct | SCOPE_IDENTITY() → RETURNING INTO, procedure → function |
| 16 | sp_UpdateProduct | GETDATE() → NOW(), procedure → function |
| 17 | sp_DeleteProduct | Procedure → function |
| 18 | UPDATE ProductStats | IsDiscontinued = 1 → isdiscontinued = TRUE, GETDATE() → NOW() |
| 19 | CREATE TRIGGER | Statement-level trigger → row-level trigger with function, SYSTEM_USER → CURRENT_USER |
| 20 | CREATE TABLE Products (full) | All DDL conversions + BIT → BOOLEAN, FK constraints lowercased |

## Build Verification
- **Final Build Status**: ✅ SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference warnings, not migration-related)

## Statements Requiring Manual Review
All 20 statements were manually converted due to DMS tool unavailability.
All 20 equivalency validations returned ERROR due to equivalency tool infrastructure issues.

**Recommendation**: Once the DMS and SQL Equivalency tools are available, re-run the
equivalency validation for all 20 statement pairs to confirm correctness.

## Conversion Rules Applied (Manual)
1. **Schema objects**: All table names, column names, CTE names, aliases → lowercase
2. **Data types**: `NVARCHAR` → `VARCHAR`, `DATETIME` → `TIMESTAMP`, `BIT` → `BOOLEAN`, `INT IDENTITY(1,1)` → `SERIAL`
3. **Functions**: `GETDATE()` → `NOW()`, `SCOPE_IDENTITY()` → `RETURNING` clause, `SYSTEM_USER` → `CURRENT_USER`
4. **Procedures**: `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION` (PL/pgSQL)
5. **Triggers**: Statement-level → row-level with separate function, `inserted`/`deleted` → `NEW`/`OLD`, `TG_OP`
6. **Transactions**: `BEGIN TRANSACTION/COMMIT` → Writable CTE pattern for atomic multi-table operations
7. **Control flow**: `IF NOT EXISTS (SELECT * FROM sys.objects ...)` → `DROP ... IF EXISTS`, `CREATE TABLE IF NOT EXISTS`
8. **Batch separator**: `GO` → removed (not needed in PostgreSQL)
9. **Boolean values**: `DEFAULT 0`/`DEFAULT 1` → `DEFAULT FALSE`/`DEFAULT TRUE`
10. **Integer division**: Added `CAST(... AS DECIMAL)` where integer division could occur in ROUND
