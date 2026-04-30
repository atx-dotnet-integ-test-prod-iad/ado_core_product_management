# Migration Report: SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-04-30  
**Source Database:** SQL Server 2019 (ProductManagement)  
**Target Database:** PostgreSQL 13 (postgres)  
**Application Framework:** .NET 9.0 with ADO.NET

---

## 1. SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool failure | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) using migration project ARN `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU` with `schema_name='dbo'`.

**All 7 calls failed** with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

### Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` rule:
- All schema object names (tables, columns, aliases) converted to lowercase
- SQL Server-specific functions converted to PostgreSQL equivalents
- Transaction blocks restructured using writable CTEs

### SQL Equivalency Validation Status
All 7 statement pairs were validated using the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 calls returned ERROR** with:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

The equivalency tool encountered an internal error for all statement pairs. These results are recorded exactly as returned by the tool with no agent judgment applied.

---

## 2. Detailed SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase identifiers
- **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG() Window Function, LEFT JOIN, parameterized query
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase identifiers
- **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `RETURNING productid` with writable CTE
  - `GETDATE()` → `NOW()`
  - `DECLARE @var / SET @var` → Writable CTEs
  - `BEGIN TRANSACTION / COMMIT` → Writable CTEs (atomic operation)
  - Lowercase identifiers
- **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE variables, SELECT into variables, UPDATE, INSERT
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `DECLARE @var` → Writable CTE (`WITH old_values AS ...`)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION / COMMIT` → Writable CTEs (atomic operation)
  - Lowercase identifiers
- **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE variables, INSERT history, DELETE, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `DECLARE @var` → Writable CTE (`WITH old_values AS ...`)
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION / COMMIT` → Writable CTEs (atomic operation)
  - Lowercase identifiers
- **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase identifiers
- **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER(), CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - `CAST(stockquantity AS DECIMAL)` for integer division in ROUND
  - Lowercase identifiers
- **Equivalency Status:** ERROR

---

## 3. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, ADO.NET classes replaced with Npgsql equivalents |
| `AdoCore.csproj` | Package reference updated from Microsoft.Data.SqlClient to Npgsql |
| `appsettings.json` | Connection strings converted from SQL Server to PostgreSQL format |

---

## 4. Package Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

**Note:** Npgsql version 8.0.6 was selected instead of 8.0.1 (specified in plan) to address a known high severity vulnerability ([GHSA-x9vc-6hfv-hg8c](https://github.com/advisories/GHSA-x9vc-6hfv-hg8c)).

---

## 5. Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### Using Directive Change
```csharp
// Before
using Microsoft.Data.SqlClient;

// After
using Npgsql;
```

---

## 6. Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Equivalent |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=postgres` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |
| N/A | `Port=5432` (added) |

---

## 7. Build Verification

### Final Build Result
- **Status:** SUCCESS
- **Errors:** 0
- **Warnings:** 0

### Previous Build Warnings (resolved)
The initial build with Npgsql 8.0.1 had a security vulnerability warning (NU1903). This was resolved by upgrading to Npgsql 8.0.6.

---

## 8. Statements Requiring Manual Review

**All 7 statements** require manual review due to:
1. **DMS conversion failure** - All statements were manually converted since the DMS MCP tool failed for all statements
2. **Equivalency validation error** - The SQL Equivalency tool returned ERROR for all pairs, making automated equivalency verification unavailable

### Recommended Manual Review Actions
1. Verify each converted PostgreSQL statement produces equivalent results to the original SQL Server statement
2. Pay special attention to:
   - Writable CTE conversions (Statements 3, 4, 5) - ensure atomicity and correctness
   - Window function compatibility (Statements 1, 2, 6, 7)
   - Integer vs decimal division in ROUND expressions (Statement 7)
   - Parameter binding behavior with Npgsql vs SqlClient

---

## 9. Artifacts Generated

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Complete equivalency validation report for all 7 pairs |
| `migration_report.md` | `sourceCode/` | This comprehensive migration report |

---

## 10. Summary

The migration from SQL Server to PostgreSQL has been completed for all code-level changes:
- ✅ All 7 SQL statements processed through DMS tool (all failed, manual conversion applied)
- ✅ All 7 statement pairs validated through SQL Equivalency tool (all returned ERROR)
- ✅ All ADO.NET classes replaced with Npgsql equivalents
- ✅ All connection strings converted to PostgreSQL format
- ✅ Package references updated (Microsoft.Data.SqlClient → Npgsql)
- ✅ Application compiles successfully with 0 errors
- ⚠️ Manual review recommended for all converted SQL statements due to tool-level failures
