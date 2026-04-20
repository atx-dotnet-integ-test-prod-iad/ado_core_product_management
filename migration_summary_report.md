# Migration Summary Report

## Microsoft SQL Server to PostgreSQL Migration for ADO.NET Application

**Project:** AdoCore  
**Date:** 2026-04-20  
**Migration Type:** SQL Server → PostgreSQL (ADO.NET with Npgsql)

---

## 1. SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 7 |

### DMS Tool Status
- **Statement Conversion Tool:** FAILED for all 7 statements
  - Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
  - Multiple retry attempts with different polling parameters all failed
- **Schema Mapping Tool:** SUCCEEDED for all 3 tables
  - Schema mappings obtained and used to guide manual conversion

### SQL Equivalency Tool Status
- **All 7 statement pairs returned ERROR** with `'uniqueID'` error
  - This appears to be a service-side issue affecting all requests
  - All results are recorded exactly as returned by the tool

### Conversion Method
All statements were converted using: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

The DMS Schema Mapping Tool provided the target schema (`productmanagement_dbo`) and all column name mappings (lowercase), which were applied during manual conversion.

---

## 2. Statement Details

### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Key Changes:** Schema/column lowercase, CTE renamed to avoid table name conflict

### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG() window function, LEFT JOIN, CASE, parameterized
- **Key Changes:** Schema/column lowercase, CTE renamed to avoid table name conflict

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), INSERT history, UPDATE stats
- **Key Changes:** SCOPE_IDENTITY() → CTE with INSERT...RETURNING + lastval(), GETDATE() → clock_timestamp(), BEGIN TRANSACTION → BEGIN, DECLARE removed (restructured with CTE)

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT history, UPDATE stats
- **Key Changes:** DECLARE/SET variables → subqueries, GETDATE() → clock_timestamp(), reordered operations (history INSERT before product UPDATE to capture old values)

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO vars, INSERT history, DELETE, UPDATE stats
- **Key Changes:** DECLARE/SET variables → subqueries, GETDATE() → clock_timestamp(), reordered operations

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Key Changes:** Schema/column lowercase

### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER(), CASE, ROUND
- **Key Changes:** Schema/column lowercase, added CAST(stockquantity AS NUMERIC) for integer division

---

## 3. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted; SqlConnection→NpgsqlConnection; SqlCommand→NpgsqlCommand; SqlDataReader→NpgsqlDataReader; using directive updated |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings converted to PostgreSQL format |

---

## 4. Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

Other packages remain unchanged:
- Microsoft.Extensions.Configuration v8.0.0
- Microsoft.Extensions.Configuration.Json v8.0.0
- Microsoft.Extensions.DependencyInjection v8.0.0

---

## 5. Class Replacements

| SQL Server (Before) | PostgreSQL (After) | Occurrences |
|---------------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader method) |
| `Microsoft.Data.SqlClient` | `Npgsql` | 1 (using directive) |

---

## 6. Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | Removed (replaced with Username/Password) |
| `MultipleActiveResultSets=true` | Removed (SQL Server specific) |
| `TrustServerCertificate=True` | Removed (SQL Server specific) |
| N/A | `Port=5432` (added) |
| N/A | `Username=postgres` (added) |
| N/A | `Password=postgres` (added) |

---

## 7. Schema Mapping (from DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

All column names are mapped to lowercase in the target schema.

---

## 8. Statements Requiring Manual Review

**All 7 statements require manual review** because:
1. DMS statement conversion tool failed for all statements (metadata model creation error)
2. SQL Equivalency tool returned ERROR for all statement pairs (service-side issue)
3. Manual conversion was applied using DMS schema mappings

**Specific areas of concern for review:**
- **Statement 3 (InsertProductAsync):** Significant restructuring from SCOPE_IDENTITY() to CTE with INSERT...RETURNING + lastval()
- **Statement 4 (UpdateProductAsync):** Reordered operations to use subqueries for old value capture
- **Statement 5 (DeleteProductAsync):** Reordered operations to use subqueries for old value capture
- **Integer division in Statement 7:** Added explicit CAST(stockquantity AS NUMERIC) to prevent integer division

---

## 9. Build Verification

- **Final build status:** ✅ SUCCESS (0 errors)
- **Warnings:** 10 (all pre-existing nullable reference warnings, not related to migration)

---

## 10. Artifact Checklist

- [x] `extracted_statements.sql` - Complete catalog of 7 original MS SQL statements
- [x] `converted_statements.sql` - Complete catalog of 7 converted PostgreSQL statements
- [x] `sql_equivalency_validation_report.json` - Comprehensive report with all 7 statement pairs
- [x] `dms_conversion_log.txt` - Detailed DMS tool output log
- [x] `migration_summary_report.md` - This report
- [x] All SQL Server references removed from code
- [x] Build succeeds with 0 errors
