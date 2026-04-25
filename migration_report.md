# Migration Report: Microsoft SQL Server to PostgreSQL
## AdoCore .NET Application

### Migration Date: 2026-04-25
### Migration Type: ADO.NET Database Access Layer Migration

---

## 1. Executive Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration covered all SQL statements in the C# codebase, package dependencies, connection strings, configuration, and database setup scripts.

### Key Statistics
| Metric | Count |
|--------|-------|
| Total SQL statements processed (C# code) | 7 |
| Total SQL statements processed (SQL scripts) | 2 (representative samples) |
| DMS conversion successes | 0 |
| DMS conversion failures | 9 |
| Manual conversions (DMS failure fallback) | 9 |
| SQL equivalency validations attempted | 9 |
| SQL equivalency EQUIVALENT results | 0 |
| SQL equivalency NOT_EQUIVALENT results | 0 |
| SQL equivalency ERROR results | 9 |
| Files modified | 6 |
| New files created | 4 |

---

## 2. DMS Tool Status

The AWS Database Migration Service (DMS) MCP tool was attempted for **every** SQL statement conversion as required. All attempts failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Impact**: All 9 statements required manual conversion using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` policy, which applies lowercase schema object names for PostgreSQL compatibility.

---

## 3. SQL Equivalency Tool Status

The SQL Equivalency MCP tool was invoked for **every** statement pair. All attempts returned:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

**Impact**: All 9 statement pairs are marked as ERROR in the equivalency report. Manual review is recommended to verify correctness of conversions.

---

## 4. Files Modified

### 4.1 Source Code Files

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL; SqlClient types replaced with Npgsql types; Transaction handling restructured for PostgreSQL compatibility |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.1 |
| `appsettings.json` | Connection strings converted from SQL Server to PostgreSQL format |

### 4.2 SQL Script Files

| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax (SERIAL, VARCHAR, TIMESTAMP, CREATE OR REPLACE FUNCTION, etc.) |
| `Database/Scripts/01_InitialSetup.sql` | Comprehensive conversion including tables, triggers, stored procedures, indexes, and sample data |

### 4.3 New Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements from ProductRepository.cs |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report for all 9 statement pairs |
| `migration_report.md` | This migration report |

---

## 5. SQL Statement Conversion Details

### 5.1 GetAllProductsAsync (Statement 1)
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Changes**: All schema objects lowercased
- **PostgreSQL Compatibility**: Fully compatible - CTEs, window functions, CASE, ROUND all supported in PostgreSQL

### 5.2 GetProductByIdAsync (Statement 2)
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, CASE, ROUND
- **Changes**: All schema objects lowercased
- **PostgreSQL Compatibility**: Fully compatible - LAG window function supported in PostgreSQL

### 5.3 InsertProductAsync (Statement 3)
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Changes**:
  - `SCOPE_IDENTITY()` → `INSERT ... RETURNING productid`
  - `GETDATE()` → `NOW()`
  - `DECLARE @var` / `SET @var` → Handled in C# application layer
  - `BEGIN TRANSACTION` / `COMMIT` → Managed via NpgsqlTransaction in C# code
  - Transaction restructured into separate SQL commands within C# transaction scope

### 5.4 UpdateProductAsync (Statement 4)
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE()
- **Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice` / `SELECT @OldPrice = Price` → C# variables via separate SELECT query
  - Transaction restructured into separate SQL commands within C# transaction scope

### 5.5 DeleteProductAsync (Statement 5)
- **Type**: Transaction block with DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE with CASE
- **Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice` / `SELECT @OldPrice = Price` → C# variables via separate SELECT query
  - Transaction restructured into separate SQL commands within C# transaction scope

### 5.6 GetProductsByPriceRangeAsync (Statement 6)
- **Type**: SELECT with CTE, RANK and PERCENT_RANK window functions, CASE
- **Changes**: All schema objects lowercased
- **PostgreSQL Compatibility**: Fully compatible - RANK and PERCENT_RANK supported in PostgreSQL

### 5.7 GetLowStockProductsAsync (Statement 7)
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Changes**: All schema objects lowercased, added `::numeric` cast for integer division in ROUND
- **PostgreSQL Compatibility**: Required `::numeric` cast because PostgreSQL integer division truncates

---

## 6. Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.1` |

### Type Mappings Applied
| SQL Server Type | Npgsql Type |
|----------------|-------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlTransaction` | `NpgsqlTransaction` |
| `SqlParameter` | `NpgsqlParameter` |

---

## 7. Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database name | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| Certificate | `TrustServerCertificate=True` | Removed |

---

## 8. SQL Script Conversion Details

### 8.1 Data Type Mappings
| SQL Server | PostgreSQL |
|-----------|------------|
| `INT IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `DATETIME` | `TIMESTAMP` |
| `BIT` | `BOOLEAN` |
| `DECIMAL(p,s)` | `DECIMAL(p,s)` |

### 8.2 Syntax Conversions
| SQL Server | PostgreSQL |
|-----------|------------|
| `GETDATE()` | `NOW()` |
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION ... RETURNS ... AS $$ ... $$ LANGUAGE plpgsql` |
| `GO` batch separator | Removed |
| `USE database` | Removed (connection-level) |
| `IF NOT EXISTS (SELECT * FROM sys.objects...)` | `CREATE TABLE IF NOT EXISTS` / `DROP ... IF EXISTS` |
| `[dbo].[tablename]` | `tablename` (lowercase) |
| `SYSTEM_USER` | `CURRENT_USER` |
| SQL Server trigger syntax | PostgreSQL trigger function + CREATE TRIGGER |
| `DEFAULT 1` (bit) | `DEFAULT TRUE` (boolean) |
| `DEFAULT 0` (bit) | `DEFAULT FALSE` (boolean) |

---

## 9. Build Verification

All steps passed the build verification:
- Step 1: Build succeeded after SQL statement conversion and re-integration
- Step 2: Build succeeded after package dependency replacement (Microsoft.Data.SqlClient → Npgsql)
- Step 3: Build succeeded after connection string update
- Step 4: Build succeeded after SQL script conversion

---

## 10. Known Issues and Recommendations

### 10.1 DMS Tool Unavailability
The DMS MCP tool was unavailable during this migration (consistent metadata model creation failure). All conversions were performed manually with lowercase schema naming. **Recommendation**: Re-run DMS conversion when the tool is available to verify manual conversions.

### 10.2 SQL Equivalency Tool Unavailability
The SQL Equivalency tool returned ERROR for all statement pairs. **Recommendation**: Re-validate all statement pairs when the tool is operational.

### 10.3 Transaction Handling Changes
The transaction-based SQL statements (Insert, Update, Delete) were restructured from single multi-statement SQL strings to multiple separate commands within C# transaction scope. This maintains the same transactional atomicity but uses a different execution pattern. **Recommendation**: Thoroughly test all CRUD operations against a live PostgreSQL database.

### 10.4 MapProductFromReader Column Names
Column name references in `MapProductFromReader` were updated to lowercase to match PostgreSQL column naming. Ensure the PostgreSQL database schema uses lowercase column names.

### 10.5 Connection String Security
Connection strings in `appsettings.json` contain placeholder credentials. **Recommendation**: Use environment variables or secure configuration management for production deployments.

---

## 11. Complete Statement Equivalency Summary

See `sql_equivalency_validation_report.json` for the complete detailed report of all 9 statement pairs with their:
- Original MS SQL statement
- Converted PostgreSQL statement
- Conversion method (all: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- Equivalency status (all: ERROR due to tool unavailability)
- DMS failure reason
- Source file and method information
