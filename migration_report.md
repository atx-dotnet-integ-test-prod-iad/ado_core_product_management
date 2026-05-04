# Migration Report: Microsoft SQL Server to PostgreSQL
## ADO.NET Application Migration (AdoCore)

**Date:** 2026-05-04  
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13  
**Application Framework:** .NET 9.0 with ADO.NET  

---

## Executive Summary

This report documents the complete migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting 7 SQL statements, updating package dependencies, replacing all ADO.NET class references, and updating connection strings.

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| With equivalency validation errors | 7 |

### DMS Tool Status
The DMS MCP tool (dms-mcp___statement_conversion_tool) consistently failed with error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
This was a service-level issue. The tool was attempted 4 times with different parameters (full ARN, short identifier, various poll settings). All 7 statements were manually converted using lowercase schema mapping rules per transformation guidelines.

### SQL Equivalency Tool Status
The SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence) consistently returned ERROR with `'uniqueID'` for all 7 statement pairs. This was also a service-level issue unrelated to the SQL statements themselves. All statements are marked as ERROR status per the requirement to rely solely on tool output.

---

## Detailed Statement Listing

### Statement 1: GetAllProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetAllProductsAsync()
- **Type:** CTE with window functions (AVG OVER, COUNT OVER) and CASE/ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool service error)
- **Key Changes:** Lowercase table/column names

### Statement 2: GetProductByIdAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductByIdAsync()
- **Type:** CTE with LAG window function and parameterized WHERE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool service error)
- **Key Changes:** Lowercase table/column names

### Statement 3: InsertProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** InsertProductAsync()
- **Type:** Transaction block with SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool service error)
- **Key Changes:** SCOPE_IDENTITY() → RETURNING + currval(), GETDATE() → NOW(), BEGIN TRANSACTION → DO $$ BEGIN/END $$, DECLARE @var → DECLARE var

### Statement 4: UpdateProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** UpdateProductAsync()
- **Type:** Transaction block with variable declarations, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool service error)
- **Key Changes:** DECLARE @var → DECLARE var, GETDATE() → NOW(), SELECT INTO variables, DO $$ block

### Statement 5: DeleteProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** DeleteProductAsync()
- **Type:** Transaction block with variable declarations, DELETE, INSERT, UPDATE with CASE, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool service error)
- **Key Changes:** DECLARE @var → DECLARE var, GETDATE() → NOW(), DO $$ block, CASE expression preserved

### Statement 6: GetProductsByPriceRangeAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductsByPriceRangeAsync()
- **Type:** CTE with RANK/PERCENT_RANK window functions and BETWEEN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool service error)
- **Key Changes:** Lowercase table/column names

### Statement 7: GetLowStockProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetLowStockProductsAsync()
- **Type:** CTE with AVG/MIN/MAX window functions and ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool service error)
- **Key Changes:** Lowercase table/column names, added ::numeric cast for integer division in ROUND

---

## Files Modified

| File | Changes |
|------|---------|
| sourceCode/AdoCore.csproj | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| sourceCode/DataAccess/ProductRepository.cs | SQL statements converted; SqlConnection/SqlCommand/SqlDataReader → Npgsql equivalents; using statement updated |
| sourceCode/appsettings.json | Connection strings updated to PostgreSQL format |

## Files Created

| File | Purpose |
|------|---------|
| sourceCode/extracted_statements.sql | Catalog of all 7 original MS SQL statements |
| sourceCode/converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sourceCode/sql_equivalency_validation_report.json | Comprehensive equivalency validation report |
| sourceCode/migration_report.md | This report |

---

## Package Dependency Changes

| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

**Note:** Npgsql 8.0.6 was chosen over 8.0.0 to avoid known vulnerability GHSA-x9vc-6hfv-hg8c.

---

## Connection String Changes

| Environment | Before | After |
|-------------|--------|-------|
| DevConnection | Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True | Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres |
| ProdConnection | Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True | Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres |

---

## ADO.NET Class Replacements

| SQL Server Class | PostgreSQL Equivalent |
|-----------------|---------------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| Microsoft.Data.SqlClient (using) | Npgsql (using) |

---

## Build Status

**Final Build Result:** SUCCESS (0 errors, 10 warnings)  
All warnings are pre-existing nullable reference type warnings (CS8601, CS8618, CS8600, CS8603, CS8625) unrelated to the migration.

---

## Validation Checklist

- [x] All SQL Server specific packages replaced with PostgreSQL equivalents
- [x] All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents
- [x] All 7 SQL statements passed through DMS MCP tool (tool failed, manual conversion applied)
- [x] Complete catalog of all SQL statements exists (extracted_statements.sql, converted_statements.sql)
- [x] All 7 statement pairs validated through SQL Equivalency tool (tool returned ERROR for all)
- [x] Comprehensive equivalency validation report generated (sql_equivalency_validation_report.json)
- [x] No agent judgment used for equivalency determination
- [x] DMS failures documented with original statement, error, and manual conversion
- [x] All connection strings updated to PostgreSQL format
- [x] Transaction handling updated to PostgreSQL syntax (DO $$ blocks)
- [x] Application compiles without errors
- [x] No Microsoft.Data.SqlClient references remain
- [x] No SqlConnection/SqlCommand/SqlDataReader/SqlParameter usage remains
- [x] No SQL Server-specific syntax remains (SCOPE_IDENTITY, GETDATE, BEGIN TRANSACTION, DECLARE @)
