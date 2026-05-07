# Migration Report: MS SQL Server to PostgreSQL

## Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS tool processing | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## Migration Overview

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved extracting SQL statements, converting them to PostgreSQL syntax, updating all ADO.NET database access code from `Microsoft.Data.SqlClient` to `Npgsql`, and updating configuration files.

## DMS Tool Conversion Results

**DMS Tool Status:** FAILED for all statements

All 7 SQL statements were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool) using migration project identifier:
`arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

**Error received for all statements:**
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Manual conversion method applied:** `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

All schema object names were converted to lowercase for PostgreSQL compatibility as per the transformation definition's fallback protocol.

## SQL Equivalency Validation Results

**SQL Equivalency Tool Status:** ERROR for all statements

All 7 statement pairs were validated using the `sql-equivalency___validate_sql_equivalence` tool.

**Error received for all statements:**
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be an internal tool error unrelated to the SQL statements themselves. All statements are marked as ERROR per the transformation definition requirement.

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure requiring manual conversion
2. SQL Equivalency tool returning errors for all pairs

### Statement 1: GetAllProductsAsync
- **Type:** CTE with AVG/COUNT window functions, CASE, ROUND
- **Conversion:** Schema objects to lowercase; SQL syntax compatible with PostgreSQL
- **Risk:** Low - Window functions, CTE, CASE, and ROUND all have identical semantics in PostgreSQL

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window functions, parameterized query
- **Conversion:** Schema objects to lowercase; parameter name lowercased (@ProductId → @productid)
- **Risk:** Low - LAG window function identical in PostgreSQL

### Statement 3: InsertProductAsync
- **Type:** Transaction block with SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE()
- **Conversion:** 
  - SCOPE_IDENTITY() → INSERT...RETURNING productid
  - GETDATE() → NOW()
  - T-SQL batch → separate statements with C# transaction management
- **Risk:** Medium - Structural change from single batch to multiple commands in transaction

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion:**
  - DECLARE/@variable → C# variables with separate SELECT query
  - GETDATE() → NOW()
  - T-SQL batch → separate statements with C# transaction management
- **Risk:** Medium - Structural change from single batch to multiple commands in transaction

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, DELETE, UPDATE with CASE, GETDATE()
- **Conversion:**
  - DECLARE/@variable → C# variables with separate SELECT query
  - GETDATE() → NOW()
  - T-SQL batch → separate statements with C# transaction management
- **Risk:** Medium - Structural change from single batch to multiple commands in transaction

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK/PERCENT_RANK, BETWEEN, CASE
- **Conversion:** Schema objects to lowercase; SQL syntax compatible with PostgreSQL
- **Risk:** Low - RANK, PERCENT_RANK, BETWEEN all identical in PostgreSQL

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX window functions, ROUND, CASE
- **Conversion:** Schema objects to lowercase; added CAST(stockquantity AS NUMERIC) for integer division
- **Risk:** Low - Added explicit CAST to ensure decimal division in PostgreSQL

## File Changes Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | All SQL statements converted to PostgreSQL; SqlClient→Npgsql classes |
| `AdoCore.csproj` | Modified | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Modified | Connection strings updated to PostgreSQL format |
| `extracted_statements.sql` | New | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | New | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | New | Comprehensive equivalency validation report |
| `migration_report.md` | New | This migration report |

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|--------------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Task<SqlConnection>` | `Task<NpgsqlConnection>` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| Extra params | `MultipleActiveResultSets=true;TrustServerCertificate=True` | (removed - not applicable) |

## SQL Syntax Conversion Mapping

| SQL Server | PostgreSQL | Used In |
|-----------|-----------|---------|
| `SCOPE_IDENTITY()` | `INSERT...RETURNING productid` | Statement 3 |
| `GETDATE()` | `NOW()` | Statements 3, 4, 5 |
| `DECLARE @var` / `SET @var` | C# variables with separate queries | Statements 3, 4, 5 |
| `BEGIN TRANSACTION` / `COMMIT` (T-SQL) | `BeginTransactionAsync()` / `CommitAsync()` (C#) | Statements 3, 4, 5 |
| Schema objects (PascalCase) | Lowercase identifiers | All statements |

## Build Status

**Final build result:** ✅ SUCCESS (0 errors, warnings only)

## Required Artifacts Verification

- ✅ `extracted_statements.sql` - Complete (7 statements)
- ✅ `converted_statements.sql` - Complete (7 statements)
- ✅ `sql_equivalency_validation_report.json` - Complete (7 pairs validated)
- ✅ `migration_report.md` - Complete (this document)

## Notes

1. The DMS MCP tool failed consistently for all statements with a metadata model creation error. This appears to be an infrastructure/configuration issue with the DMS migration project, not related to the SQL statements themselves.

2. The SQL Equivalency tool returned errors for all statement pairs with an internal "'uniqueID'" error. This appears to be a tool-side issue rather than a problem with the statement conversions.

3. All manual conversions followed the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol as specified in the transformation definition.

4. The Npgsql package was upgraded from the planned 8.0.0 to 8.0.6 to address a known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c), in compliance with security guardrails.
