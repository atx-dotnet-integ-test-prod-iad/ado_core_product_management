# Migration Report: MS SQL Server to PostgreSQL
## ADO.NET Application (AdoCore)

**Migration Date:** 2026-04-08  
**Source Database:** Microsoft SQL Server (ProductManagement)  
**Target Database:** PostgreSQL (postgres)  
**Migration Project ARN:** arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

---

## Executive Summary

This migration converted an ADO.NET application from Microsoft SQL Server to PostgreSQL. All 7 SQL statements were extracted, converted, and re-integrated. Package dependencies and connection strings were updated. The application compiles successfully with 0 errors.

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL statements processed** | 7 |
| **Successfully converted by DMS MCP Tool** | 0 |
| **Requiring manual intervention (DMS failure)** | 7 |
| **Validated as equivalent (SQL Equivalency Tool)** | 0 |
| **Validated as non-equivalent** | 0 |
| **Equivalency validation errors** | 7 |

### DMS Tool Status
The DMS MCP statement conversion tool consistently failed for all 7 statements with the error:
> "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"

Multiple retry strategies were attempted (default settings, increased poll attempts to 20/25/30, various poll intervals). All attempts failed.

**Note:** The DMS Schema Mapping Tool was successfully used to obtain target schema mappings, which guided the manual conversion:
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`

### SQL Equivalency Tool Status
The SQL Equivalency tool returned ERROR for all 7 statement pairs with the error:
> "'uniqueID'"

All equivalency status values are recorded as-is from the tool output (no agent judgment applied).

---

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Source:** DataAccess/ProductRepository.cs
- **DMS Status:** FAILED (Metadata model creation timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Table/column names lowercased, CTE name changed from ProductStats to productstats_cte

### Statement 2: GetProductByIdAsync
- **Source:** DataAccess/ProductRepository.cs
- **DMS Status:** FAILED (Metadata model creation timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Table/column names lowercased, CTE name changed from ProductHistory to producthistory_cte

### Statement 3: InsertProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **DMS Status:** FAILED (Metadata model creation timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** 
  - `SCOPE_IDENTITY()` → `RETURNING productid` with CTE pattern
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @variable` / `SET @variable` → CTE-based approach
  - `BEGIN TRANSACTION`/`COMMIT` → Removed (managed at C# level)

### Statement 4: UpdateProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **DMS Status:** FAILED (Metadata model creation timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `DECLARE @OldPrice`/`@OldStock` → `old_values` CTE
  - `GETDATE()` → `clock_timestamp()`
  - Multi-statement transaction → CTE with writable sub-queries

### Statement 5: DeleteProductAsync
- **Source:** DataAccess/ProductRepository.cs
- **DMS Status:** FAILED (Metadata model creation timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `DECLARE @OldPrice`/`@OldStock` → `old_values` CTE
  - `GETDATE()` → `clock_timestamp()`
  - Multi-statement transaction → CTE with writable sub-queries

### Statement 6: GetProductsByPriceRangeAsync
- **Source:** DataAccess/ProductRepository.cs
- **DMS Status:** FAILED (Metadata model creation timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Table/column names lowercased, RANK()/PERCENT_RANK() preserved (PostgreSQL compatible)

### Statement 7: GetLowStockProductsAsync
- **Source:** DataAccess/ProductRepository.cs
- **DMS Status:** FAILED (Metadata model creation timeout)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** Table/column names lowercased, `CAST(stockquantity AS NUMERIC)` added for integer division in ROUND

---

## Code Changes Summary

### Package Dependencies (AdoCore.csproj)
| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

### ADO.NET Type Replacements (ProductRepository.cs)
| SQL Server Type | PostgreSQL Type | Count |
|-----------------|-----------------|-------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

### Connection String Updates (appsettings.json)
| Parameter | Before | After |
|-----------|--------|-------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (none) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=password` |
| MultipleActiveResultSets | `true` | (removed) |
| TrustServerCertificate | `True` | (removed) |

---

## Build Validation

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All warnings are pre-existing nullable reference warnings (CS8601, CS8603, CS8618, CS8625, CS8600) - not introduced by the migration.

---

## Migration Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Extracted SQL Statements | `sourceCode/extracted_statements.sql` | All 7 original MS SQL statements |
| Converted SQL Statements | `sourceCode/converted_statements.sql` | All 7 PostgreSQL converted statements |
| Equivalency Report | `sourceCode/sql_equivalency_validation_report.json` | Complete validation report for all 7 pairs |
| Migration Report | `sourceCode/migration_report.md` | This document |

---

## Statements Requiring Manual Review

**All 7 statements** require manual review because:
1. DMS conversion tool was unavailable (metadata model creation timeout)
2. SQL Equivalency tool returned ERROR for all validations

Manual conversions were performed using:
- DMS Schema Mapping Tool output (for target table/column names)
- PostgreSQL syntax rules (GETDATE→clock_timestamp, SCOPE_IDENTITY→RETURNING, etc.)
- Lowercase naming convention per DMS schema mapping

---

## Recommendations

1. **Manual Testing:** Thoroughly test all 7 converted SQL queries against the target PostgreSQL database
2. **Integration Testing:** Run the full application against PostgreSQL and verify all CRUD operations
3. **Performance Testing:** CTE-based writable queries (Statements 3, 4, 5) may have different performance characteristics
4. **Connection String Security:** Update placeholder credentials with actual PostgreSQL credentials via environment variables
5. **Schema Verification:** Verify the target PostgreSQL schema matches the DMS schema mapping (productmanagement_dbo schema)
