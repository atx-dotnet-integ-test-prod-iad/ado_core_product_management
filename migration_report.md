# Migration Report: MS SQL Server to PostgreSQL

## Overview
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

**Migration Date:** 2026-03-24
**Source Database:** Microsoft SQL Server 2019 (ProductManagement)
**Target Database:** PostgreSQL 13 (postgres)
**Application Framework:** .NET 9.0, ADO.NET

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent (SQL Equivalency tool) | 0 |
| With equivalency validation errors | 7 |

### DMS Tool Status
- **Tool:** dms-mcp___statement_conversion_tool
- **Migration Project ARN:** arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Status:** ALL 7 statements failed with error: "Metadata model creation failed: Metadata model creation did not complete after 15 attempts"
- **Fallback:** Manual conversion applied with lowercase schema object names per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA guidelines

### SQL Equivalency Tool Status
- **Tool:** sql-equivalency___validate_sql_equivalence
- **Status:** ALL 7 statement pairs returned ERROR with 'uniqueID' infrastructure error
- **Note:** This is an infrastructure-level error in the equivalency tool, not a statement-level issue

---

## Statement Details

### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, INNER JOIN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase table/column names
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG window function, CASE, LEFT JOIN, parameterized
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase table/column names
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 3: InsertProductAsync
- **Type:** Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - SCOPE_IDENTITY() → RETURNING clause
  - GETDATE() → now()
  - BEGIN TRANSACTION/COMMIT → C# transaction management (BeginTransactionAsync/CommitAsync)
  - DECLARE @var → C# variables
  - Restructured from single batch to multiple separate commands within C# transaction
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT history
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - DECLARE @OldPrice/@OldStock → C# variables (decimal oldPrice, int oldStock)
  - GETDATE() → now()
  - BEGIN TRANSACTION/COMMIT → C# transaction management
  - SELECT @var = column → C# SELECT with reader
  - Restructured from single batch to multiple separate commands
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO vars, INSERT history, DELETE, UPDATE stats
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:**
  - Same restructuring as UpdateProductAsync
  - CASE expression in UPDATE preserved (PostgreSQL compatible)
  - GETDATE() → now()
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase table/column names
- **Equivalency Status:** ERROR (tool infrastructure error)

### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX OVER(), CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Lowercase table/column names, added ::numeric cast for integer division in ROUND
- **Equivalency Status:** ERROR (tool infrastructure error)

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL; ADO.NET classes replaced with Npgsql equivalents; transaction handling restructured for INSERT/UPDATE/DELETE operations; column name references updated to lowercase |
| `AdoCore.csproj` | Package reference changed from Microsoft.Data.SqlClient 5.1.4 to Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server format to PostgreSQL format |

---

## Package Dependency Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|-------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

---

## Class Replacements

| Original (Microsoft.Data.SqlClient) | Replacement (Npgsql) | Occurrences |
|--------------------------------------|----------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `SqlTransaction` | `NpgsqlTransaction` | 11 |

---

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| Server=localhost | Host=localhost |
| Database=ProductManagement | Database=postgres |
| Trusted_Connection=True | Removed (N/A) |
| MultipleActiveResultSets=true | Removed (N/A) |
| TrustServerCertificate=True | Removed (N/A) |
| N/A | Port=5432 |
| N/A | Username=postgres |
| N/A | Password=postgres |

---

## SQL Syntax Conversion Rules Applied

| MS SQL Server | PostgreSQL | Applied To |
|---------------|-----------|------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` | InsertProductAsync |
| `GETDATE()` | `now()` | Insert, Update, Delete operations |
| `BEGIN TRANSACTION/COMMIT` | C# `BeginTransactionAsync()/CommitAsync()` | Insert, Update, Delete operations |
| `DECLARE @var TYPE` | C# variable declarations | Update, Delete operations |
| `SELECT @var = column` | C# `ExecuteReaderAsync()` with variable assignment | Update, Delete operations |
| Mixed case identifiers (e.g., `Products`) | Lowercase (e.g., `products`) | All statements |
| `ROUND(int/int)` | `ROUND(int::numeric / int)` | GetLowStockProductsAsync |

---

## Artifacts Generated

| Artifact | Location | Contents |
|----------|----------|----------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Complete equivalency report for all 7 statement pairs |
| migration_report.md | sourceCode/ | This report |

---

## Build Verification

- **Final Build Status:** ✅ SUCCESS
- **Errors:** 0
- **Warnings:** 10 (all pre-existing nullable reference warnings, not introduced by migration)
- **Output:** AdoCore.dll successfully compiled to bin/Debug/net9.0/

---

## Recommendations for Manual Review

1. **SQL Equivalency Validation:** All 7 statement pairs returned ERROR from the equivalency tool due to infrastructure issues ('uniqueID' error). Manual review of the converted SQL statements is recommended.

2. **Transaction Restructuring:** Statements 3, 4, and 5 were restructured from single SQL batches to multiple C#-managed commands. The functional behavior should be equivalent, but integration testing is recommended.

3. **Integer Division:** The `GetLowStockProductsAsync` statement uses `::numeric` cast to ensure proper decimal division in PostgreSQL. This should be verified with actual data.

4. **Connection Credentials:** The connection strings use placeholder credentials (postgres/postgres). These should be updated with actual credentials before deployment.
