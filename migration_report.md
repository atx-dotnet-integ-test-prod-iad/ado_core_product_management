# Migration Report: MS SQL Server to PostgreSQL

## Executive Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating database access code, and replacing all SQL Server-specific dependencies with PostgreSQL equivalents.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS MCP Tool | 0 |
| Statements Requiring Manual Intervention (DMS Failure) | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |

## DMS Tool Results

All 7 SQL statements were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion. All 7 calls failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN:** `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

Due to the DMS tool failure, all statements were manually converted following the rule: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

## SQL Equivalency Validation Results

All 7 statement pairs were validated through the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence). All 7 validations returned ERROR with the error `'uniqueID'`.

**Note:** Per transformation rules, equivalency status comes exclusively from the tool output - no agent judgment was applied.

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool failure (unable to automatically verify conversion correctness)
2. SQL Equivalency tool returning ERROR for all pairs

### Statement Details

| # | Method | Type | Conversion Notes |
|---|--------|------|------------------|
| 1 | GetAllProductsAsync | SELECT with CTE/Window Functions | Direct translation - lowercase names |
| 2 | GetProductByIdAsync | SELECT with CTE/LAG | Direct translation - lowercase names |
| 3 | InsertProductAsync | Transaction Block | SCOPE_IDENTITY() → RETURNING clause, GETDATE() → NOW() |
| 4 | UpdateProductAsync | Transaction Block | DECLARE variables → CTE approach, GETDATE() → NOW() |
| 5 | DeleteProductAsync | Transaction Block | DECLARE variables → CTE approach, GETDATE() → NOW() |
| 6 | GetProductsByPriceRangeAsync | SELECT with CTE/RANK | Direct translation - lowercase names |
| 7 | GetLowStockProductsAsync | SELECT with CTE/AVG OVER | Added ::numeric cast for integer division |

## Key SQL Conversion Patterns Applied

| MS SQL Server | PostgreSQL | Notes |
|---------------|-----------|-------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (via CTE) | Used writable CTE pattern |
| `GETDATE()` | `NOW()` | Equivalent functionality |
| `DECLARE @var; SET @var = ...` | CTE with subquery | PostgreSQL writable CTE |
| `BEGIN TRANSACTION/COMMIT` | Application-managed transaction | Via NpgsqlTransaction |
| `ROUND(int/int, 2)` | `ROUND(int::numeric / int, 2)` | Explicit cast for precision |
| Table/Column names (PascalCase) | Table/column names (lowercase) | PostgreSQL convention |

## File Changes Summary

### Modified Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL, SqlClient → Npgsql classes |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

### New Files (Artifacts)
| File | Description |
|------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Complete equivalency validation report |
| `migration_report.md` | This report |

## Package Dependencies

### Before
```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />
```

### After
```xml
<PackageReference Include="Npgsql" Version="8.0.6" />
```

**Note:** Version 8.0.6 was used instead of 8.0.0 to address a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Database=postgres;Username=postgres;Password=postgres
```

## ADO.NET Class Replacements

| SQL Server | PostgreSQL |
|-----------|-----------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Build Status

**Final Build: ✅ SUCCESS**

- 0 Errors
- 10 Warnings (pre-existing nullable reference warnings, not introduced by migration)

## Recommendations

1. **Manual Testing Required:** Since both the DMS conversion tool and SQL equivalency validation tool encountered errors, thorough manual testing of all 7 SQL statements against the PostgreSQL database is strongly recommended.

2. **Transaction Block Validation:** The conversion of transaction blocks (Statements 3, 4, 5) from procedural SQL (DECLARE/SET) to CTE-based writable queries is a significant structural change that should be carefully validated.

3. **Integer Division:** Statement 7 uses `::numeric` cast to ensure correct decimal division. Verify all division operations produce expected precision.

4. **Parameter Compatibility:** Npgsql supports @ParameterName syntax, but AddWithValue may infer types differently than SqlClient. Consider using explicit NpgsqlDbType for critical operations.
