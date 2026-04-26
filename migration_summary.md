# Migration Summary: Microsoft SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore - .NET ADO Product Management Application
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-04-26
- **Migration Method**: Manual conversion with lowercase schema object names (DMS tool unavailable)

## SQL Statement Migration Summary

### Statistics
| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS Tool | 0 |
| Statements Requiring Manual Intervention (DMS Failure) | 7 |
| Statements Validated as Equivalent (by SQL Equivalency Tool) | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Error | 7 |

### DMS Tool Status
- **Status**: All 7 conversion attempts FAILED
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Fallback**: Manual conversion applied with lowercase schema object names per transformation definition rules
- **Conversion Reason Code**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

### SQL Equivalency Tool Status
- **Status**: All 7 equivalency validations returned ERROR
- **Error**: `'uniqueID'` (service-level error)
- **Note**: All equivalency statuses are from the tool output, NOT agent judgment

### Statement-by-Statement Summary

| # | Method | Type | Key Conversions |
|---|--------|------|-----------------|
| 1 | `GetAllProductsAsync` | SELECT with CTE, Window Functions | Lowercase schema objects |
| 2 | `GetProductByIdAsync` | SELECT with CTE, LAG | Lowercase schema objects |
| 3 | `InsertProductAsync` | Transaction (INSERT) | SCOPE_IDENTITY() → RETURNING, GETDATE() → NOW(), Split to multi-command |
| 4 | `UpdateProductAsync` | Transaction (UPDATE) | GETDATE() → NOW(), DECLARE → C# variables, Split to multi-command |
| 5 | `DeleteProductAsync` | Transaction (DELETE) | GETDATE() → NOW(), DECLARE → C# variables, Split to multi-command |
| 6 | `GetProductsByPriceRangeAsync` | SELECT with CTE, RANK | Lowercase schema objects |
| 7 | `GetLowStockProductsAsync` | SELECT with CTE, AVG/MIN/MAX | Lowercase schema objects, ::numeric cast |

## Package Dependency Changes

| Action | Package | Old Version | New Version |
|--------|---------|-------------|-------------|
| Removed | Microsoft.Data.SqlClient | 5.1.4 | - |
| Added | Npgsql | - | 8.0.6 |
| Unchanged | Microsoft.Extensions.Configuration | 8.0.0 | 8.0.0 |
| Unchanged | Microsoft.Extensions.Configuration.Json | 8.0.0 | 8.0.0 |
| Unchanged | Microsoft.Extensions.DependencyInjection | 8.0.0 | 8.0.0 |

**Note**: Npgsql 8.0.6 was used instead of 8.0.0 to avoid known high severity vulnerability GHSA-x9vc-6hfv-hg8c.

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|--------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 4 (field, constructor, method return, instantiation) |
| `SqlCommand` | `NpgsqlCommand` | 15+ (all query/command methods) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |
| `SqlParameter` | `NpgsqlParameter` | N/A (using AddWithValue pattern) |

### Using Directive Change
```csharp
// Before
using Microsoft.Data.SqlClient;

// After
using Npgsql;
```

## SQL Syntax Conversions Applied

| SQL Server Syntax | PostgreSQL Syntax | Statements Affected |
|------------------|-------------------|---------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` clause | Statement 3 |
| `GETDATE()` | `NOW()` | Statements 3, 4, 5 |
| `BEGIN TRANSACTION / COMMIT` | Npgsql managed `BeginTransactionAsync()` | Statements 3, 4, 5 |
| `DECLARE @var` | C# variables with separate queries | Statements 3, 4, 5 |
| `SET @var = SCOPE_IDENTITY()` | `RETURNING productid` captured by `ExecuteScalarAsync()` | Statement 3 |
| `SELECT @var = Column FROM Table` | `SELECT column FROM table` + C# DataReader | Statements 4, 5 |
| `StockQuantity / AvgStock` (integer division) | `stockquantity::numeric / avgstock` | Statement 7 |
| PascalCase table/column names | lowercase table/column names | All 7 statements |

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `DataAccess/ProductRepository.cs` | Modified | SQL statements, ADO.NET classes, using directive |
| `AdoCore.csproj` | Modified | Package reference replacement |
| `appsettings.json` | Modified | Connection string format |

## Files Created (Artifacts)

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Detailed equivalency validation results for all 7 statement pairs |
| `migration_summary.md` | This report |

## Build Status
- **Final Build**: ✅ Succeeded (0 errors, 10 warnings)
- **Warnings**: Pre-existing nullable reference type warnings (CS8601, CS8618, CS8600, CS8603, CS8625) - not introduced by migration

## Known Issues and Limitations
1. **DMS Tool Unavailable**: All 7 DMS conversion attempts failed with metadata model creation error. Manual conversions were applied.
2. **Equivalency Validation Unavailable**: All 7 equivalency checks returned ERROR from the SQL Equivalency tool. Manual review recommended.
3. **Transaction Restructuring**: Transaction-based SQL (statements 3, 4, 5) was restructured from single T-SQL blocks to multiple Npgsql commands within managed transactions. This maintains the same transactional semantics.
4. **Column Name Case Sensitivity**: PostgreSQL is case-sensitive for quoted identifiers. The converted queries use lowercase unquoted identifiers which PostgreSQL normalizes to lowercase.
