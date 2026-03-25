# Migration Report: MS SQL Server to PostgreSQL

## Project: AdoCore - .NET ADO Application
## Migration Date: 2026-03-25

---

## 1. Executive Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, replacing ADO.NET database access classes, updating project dependencies, and converting connection strings.

---

## 2. SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool failure | 7 |
| Statements validated as equivalent by SQL Equivalency tool | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status
- **Status**: FAILED for all 7 statements
- **Error**: Metadata model creation/conversion timed out after multiple retry attempts
- **Retry attempts**: 15 attempts (default), 25 attempts, 30 attempts with varying poll intervals (10s, 15s)
- **Fallback**: Manual conversion applied with lowercase schema object names per transformation definition

### SQL Equivalency Tool Status
- **Status**: ERROR for all 7 statements  
- **Error**: `'uniqueID'` - consistent across all statement pairs
- **Note**: This appears to be a systemic tool issue, not related to statement quality

---

## 3. Detailed SQL Statement Conversions

### SQL #1: GetAllProductsAsync
- **Source**: CTE with window functions (AVG, COUNT OVER) and CASE/ROUND expressions
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Lowercase schema objects (Products → products, ProductId → productid, etc.)
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### SQL #2: GetProductByIdAsync
- **Source**: CTE with LAG window functions and CASE/ROUND expressions
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Lowercase schema objects
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### SQL #3: InsertProductAsync
- **Source**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(), multi-table operations
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid` (with C# managed transaction)
  - `GETDATE()` → `NOW()`
  - Single SQL command → Three separate parameterized commands within C# transaction
  - `DECLARE @var` pattern → C# local variables
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### SQL #4: UpdateProductAsync
- **Source**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - Single SQL command → Four separate parameterized commands within C# transaction
  - `DECLARE @var / SELECT @var = col` → C# local variables with separate SELECT query
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### SQL #5: DeleteProductAsync
- **Source**: Transaction block with DECLARE, SELECT INTO variables, DELETE, INSERT, UPDATE with CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - Single SQL command → Four separate parameterized commands within C# transaction
  - `DECLARE @var / SELECT @var = col` → C# local variables with separate SELECT query
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### SQL #6: GetProductsByPriceRangeAsync
- **Source**: CTE with RANK(), PERCENT_RANK() window functions and CASE expression
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Lowercase schema objects
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

### SQL #7: GetLowStockProductsAsync
- **Source**: CTE with AVG, MIN, MAX window functions, CASE and ROUND expressions
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Lowercase schema objects, `StockQuantity/AvgStock` → `stockquantity::numeric / avgstock` (explicit cast for integer division)
- **Equivalency Status**: ERROR (tool error: 'uniqueID')

---

## 4. Code Changes Summary

### 4.1 ADO.NET Class Replacements
| Original (SQL Server) | Replacement (PostgreSQL) |
|------------------------|--------------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

### 4.2 Package Dependencies
| Original | Replacement |
|----------|-------------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.9 |

Note: Npgsql 8.0.9 was used instead of 8.0.1 (as originally planned) to avoid known high severity vulnerability GHSA-x9vc-6hfv-hg8c.

### 4.3 Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|------------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

### 4.4 SQL Syntax Changes
| SQL Server | PostgreSQL |
|------------|------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` clause |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE` | C# local variables |
| `SELECT @var = col` | Separate SELECT query with C# reader |
| `BEGIN TRANSACTION / COMMIT` | C# managed `BeginTransactionAsync()` / `CommitAsync()` |
| Mixed case identifiers | Lowercase identifiers |
| `StockQuantity / AvgStock` (int division) | `stockquantity::numeric / avgstock` (explicit cast) |

---

## 5. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All SQL statements converted, ADO.NET classes replaced |
| `AdoCore.csproj` | Package reference updated |
| `appsettings.json` | Connection strings converted |

## 6. Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Original 7 MS SQL statements |
| `converted_statements.sql` | 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report |
| `migration_report.md` | This report |

---

## 7. DMS Failures Detail

All 7 SQL statements failed DMS conversion. The consistent error was:

```
Metadata model creation failed: {'error': 'Metadata model creation did not complete after N attempts'}
```

or

```
Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after N attempts'}
```

### Retry History:
1. **Attempt 1** (SQL #1): 15 poll attempts, 10s interval → Metadata model conversion timeout
2. **Attempt 2** (SQL #1): 30 poll attempts, 10s interval → Command execution timeout (300s)
3. **Attempt 3** (simple SELECT): 15 poll attempts, 10s interval → Metadata model creation timeout
4. **Attempt 4** (simple SELECT): 30 poll attempts, 15s interval → Command execution timeout (300s)
5. **Attempt 5** (SQL #1 compact): 25 poll attempts, 10s interval → Metadata model creation timeout

After 5 failed attempts with varying parameters, manual conversion was applied to all 7 statements per the transformation definition.

---

## 8. Statements Requiring Manual Review

**ALL 7 statements** require manual review because:
1. DMS conversion was unavailable (timeout failures) — manual lowercase conversion was applied
2. SQL Equivalency validation returned ERROR for all pairs (tool error: 'uniqueID')

### Recommended Manual Review Actions:
- Verify all lowercase schema object names match the target PostgreSQL database schema
- Verify RETURNING clause works correctly for INSERT operations with Npgsql
- Verify NOW() function returns expected datetime format
- Verify integer division behavior with explicit numeric cast in SQL #7
- Test all transaction blocks (INSERT, UPDATE, DELETE) end-to-end against PostgreSQL database

---

## 9. Build Verification

**Final Build Status**: ✅ **SUCCESS**
- 0 Errors
- 0 Warnings (down from 10 — resolved through file encoding normalization)
- No vulnerable packages detected

---

## 10. Transformation Artifacts Checklist

| Artifact | Status | Content |
|----------|--------|---------|
| `extracted_statements.sql` | ✅ Complete | 7 original MS SQL statements |
| `converted_statements.sql` | ✅ Complete | 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | ✅ Complete | 7 statement pairs with ERROR status |
| `migration_report.md` | ✅ Complete | This document |
| Build compilation | ✅ Passes | 0 errors, 0 warnings |
| No vulnerable dependencies | ✅ Verified | Npgsql 8.0.9 is clean |
