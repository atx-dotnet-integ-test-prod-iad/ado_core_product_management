# Migration Report: SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-03-27  
**Source Database:** SQL Server (ProductManagement)  
**Target Database:** PostgreSQL 13+  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## Summary of Changes

### 1. SQL Statement Conversions (7 statements total)

| # | Method | Type | DMS Status | Equivalency Status |
|---|--------|------|------------|-------------------|
| 1 | GetAllProductsAsync | SELECT with CTE, window functions | DMS Failed | ERROR (tool issue) |
| 2 | GetProductByIdAsync | SELECT with CTE, LAG window function | DMS Failed | ERROR (tool issue) |
| 3 | InsertProductAsync | Transaction with INSERT, RETURNING | DMS Failed | ERROR (tool issue) |
| 4 | UpdateProductAsync | Transaction with UPDATE, history logging | DMS Failed | ERROR (tool issue) |
| 5 | DeleteProductAsync | Transaction with DELETE, history logging | DMS Failed | ERROR (tool issue) |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE, RANK, PERCENT_RANK | DMS Failed | ERROR (tool issue) |
| 7 | GetLowStockProductsAsync | SELECT with CTE, AVG/MIN/MAX window functions | DMS Failed | ERROR (tool issue) |

**DMS Tool Results:**
- All 7 statements attempted through DMS MCP tool
- All 7 failed with: "Metadata model creation failed: Metadata model creation did not complete after 15 attempts"
- Manual conversion applied using DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA rules

**SQL Equivalency Tool Results:**
- All 7 statement pairs validated through SQL Equivalency tool
- All 7 returned ERROR with systemic "'uniqueID'" error
- This is a tool-level issue, not a statement-level issue

### 2. Key SQL Conversion Patterns Applied

| SQL Server | PostgreSQL | Applied In |
|-----------|-----------|------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | InsertProductAsync |
| `GETDATE()` | `NOW()` | Insert, Update, Delete methods |
| `DECLARE @var` | C# variables with separate queries | Update, Delete methods |
| `BEGIN TRANSACTION/COMMIT` | C# `BeginTransactionAsync()`/`CommitAsync()` | Insert, Update, Delete methods |
| `nvarchar` | `varchar` | DDL scripts |
| `datetime` | `timestamp` | DDL scripts |
| `bit` | `boolean` | DDL scripts |
| `IDENTITY(1,1)` | `serial` | DDL scripts |
| `[dbo].[table]` | `table` (lowercase) | DDL scripts |
| `SYSTEM_USER` | `current_user` | Trigger functions |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` | DDL scripts |
| SQL Server triggers (inserted/deleted) | PostgreSQL trigger functions (NEW/OLD/TG_OP) | DDL scripts |
| `GO` batch separator | Removed | DDL scripts |
| Column names (PascalCase) | Column names (lowercase) | All SQL statements |

### 3. Package Dependencies

| Action | Package | Version |
|--------|---------|---------|
| Removed | Microsoft.Data.SqlClient | 5.1.4 |
| Added | Npgsql | 8.0.1 |

### 4. ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|-------------|-------------|
| SqlConnection | NpgsqlConnection | 3 |
| SqlCommand | NpgsqlCommand | 15 |
| SqlDataReader | NpgsqlDataReader | 1 |
| SqlTransaction | NpgsqlTransaction | 11 |

### 5. Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | Removed (not needed) |
| TrustServerCertificate | `True` | Removed (not applicable) |

### 6. Configuration Files Updated

- **appsettings.json** - Connection strings converted to PostgreSQL format
- **AdoCore.csproj** - Package reference updated from Microsoft.Data.SqlClient to Npgsql

### 7. Database Scripts Converted

- **Database/Scripts/01_InitialSetup.sql** - Full DDL conversion to PostgreSQL
- **Scripts/01_InitialSetup.sql** - Full DDL conversion to PostgreSQL

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET classes replaced, transaction handling restructured |
| `AdoCore.csproj` | Package reference: Microsoft.Data.SqlClient → Npgsql |
| `appsettings.json` | Connection strings converted to PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Full DDL conversion to PostgreSQL |
| `Scripts/01_InitialSetup.sql` | Full DDL conversion to PostgreSQL |

## Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This migration report |

---

## Build Status

**Final Build:** ✅ SUCCESS (0 errors)

---

## Statistics

- **Total SQL statements processed:** 7
- **Statements successfully converted by DMS:** 0 (DMS tool unavailable)
- **Statements manually converted:** 7
- **Statements validated as equivalent:** 0
- **Statements validated as non-equivalent:** 0
- **Statements with equivalency validation errors:** 7 (systemic tool error)
- **Total files modified:** 5
- **Total new files created:** 4

---

## Known Issues and Recommendations

1. **DMS Tool Unavailability:** The DMS MCP tool consistently failed with metadata model creation errors. All conversions were performed manually. It is recommended to re-validate conversions when the DMS tool becomes available.

2. **SQL Equivalency Tool Error:** The SQL Equivalency tool returned a systemic "'uniqueID'" error for all statement pairs. Manual review of SQL equivalency is recommended.

3. **Transaction Restructuring:** The Insert, Update, and Delete methods were restructured from SQL-level transactions (using T-SQL BEGIN TRANSACTION/COMMIT) to C#-level ADO.NET transactions. This maintains the same atomicity guarantees but uses a different implementation approach that is more idiomatic for PostgreSQL with ADO.NET.

4. **Integer Division:** In the `GetLowStockProductsAsync` method, an explicit `::numeric` cast was added to prevent integer division issues in PostgreSQL (`ROUND((stockquantity::numeric / avgstock) * 100, 2)`).

5. **Connection String Credentials:** The PostgreSQL connection strings use placeholder credentials (postgres/postgres). These should be updated with actual credentials before deployment.
