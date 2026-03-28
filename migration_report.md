# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary
Migration of ADO.NET application from Microsoft SQL Server to PostgreSQL completed successfully.

**Date:** 2026-03-28  
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13 (postgres)  
**Application Framework:** .NET 9.0 ADO.NET  

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Converted by DMS Tool | 0 |
| Statements Requiring Manual Intervention | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Errors | 7 |

### DMS Tool Status
The DMS MCP Statement Conversion Tool was called for all 7 statements but consistently failed with:
- **Error:** "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- Multiple retry attempts were made (3 separate calls with different queries) - all failed
- As per transformation rules, manual conversion was performed applying lowercase schema object names

### SQL Equivalency Tool Status
The SQL Equivalency Validation Tool was called for all 7 statement pairs but returned errors for all:
- **Error:** "'uniqueID'" for all 7 pairs
- Each pair was submitted independently as required
- Results were recorded exactly as returned by the tool

---

## SQL Statements Detail

### Statement 1: GetAllProductsAsync
- **Type:** CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **Key Conversions:** Schema objects lowercased, ROUND with ::numeric casting
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window function, CASE with NULL handling, ROUND
- **Key Conversions:** Schema objects lowercased, ROUND with ::numeric casting
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Key Conversions:** SCOPE_IDENTITY() → RETURNING productid, GETDATE() → NOW(), Transaction restructured for C# managed transactions
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT
- **Key Conversions:** DECLARE @var → C# variables with SELECT query, GETDATE() → NOW(), Transaction restructured
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, DELETE, CASE WHEN for zero-division protection
- **Key Conversions:** DECLARE @var → C# variables with SELECT query, GETDATE() → NOW(), Transaction restructured
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Key Conversions:** Schema objects lowercased
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX OVER(), CASE, ROUND
- **Key Conversions:** Schema objects lowercased, ROUND with ::numeric casting for integer division
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR

---

## Files Modified

| File | Changes |
|------|---------|
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.0` |
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET classes replaced, using statement updated |
| `appsettings.json` | Connection strings converted from SQL Server to PostgreSQL format |

### Detailed Changes per File

#### AdoCore.csproj
- Removed: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- Added: `<PackageReference Include="Npgsql" Version="8.0.0" />`

#### DataAccess/ProductRepository.cs
- **Using statement:** `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **Class replacements:**
  - `SqlConnection` → `NpgsqlConnection` (3 occurrences)
  - `SqlCommand` → `NpgsqlCommand` (15 occurrences)
  - `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
  - `SqlTransaction` casts → `NpgsqlTransaction` (11 occurrences)
- **SQL statements:** All 7 statements converted to PostgreSQL syntax
- **Reader column names:** Updated to lowercase for PostgreSQL compatibility
- **Transaction handling:** Restructured for InsertProductAsync, UpdateProductAsync, DeleteProductAsync

#### appsettings.json
- **DevConnection:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres;`
- **ProdConnection:** Same transformation as DevConnection

---

## Transformation Artifacts

| Artifact | Status |
|----------|--------|
| `extracted_statements.sql` | ✅ Created (233 lines) |
| `converted_statements.sql` | ✅ Created (313 lines) |
| `sql_equivalency_validation_report.json` | ✅ Created (7 statements, all with ERROR status) |
| `migration_report.md` | ✅ This document |

---

## Build Verification
- **Final build status:** SUCCESS (0 errors, 12 warnings - all pre-existing nullable reference warnings)
- **No remaining SQL Server references:** Verified via grep

---

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS tool was unable to convert any statements (metadata model creation timeout)
2. SQL Equivalency tool returned ERROR for all statement pairs
3. Manual conversion was performed applying lowercase schema object naming convention

**Recommendation:** Perform integration testing against a PostgreSQL database to validate all converted SQL statements execute correctly and produce expected results.
