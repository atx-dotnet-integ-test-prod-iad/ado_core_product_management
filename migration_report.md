# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Statements Converted by DMS Tool** | 0 |
| **Statements Requiring Manual Conversion** | 7 |
| **DMS Failure Reason** | Metadata model creation failed: Unknown metadata model creation status: RECEIVED |
| **Manual Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Validation Error** | 7 |
| **Equivalency Error Reason** | Tool returned 'uniqueID' error for all statements |

## DMS Tool Attempts

All 7 SQL statements were passed through the DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) with:
- **Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Schema**: `dbo`
- **Region**: `us-east-1`

**All 7 attempts failed** with the error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Statement 1 (GetAllProductsAsync) was attempted 3 times with different polling configurations, all producing the same error.

## SQL Equivalency Validation

All 7 statement pairs (original MS SQL + converted PostgreSQL) were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 validations returned ERROR** with the error:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a tool infrastructure issue, not a statement-level problem, as even a trivial `SELECT` statement returned the same error.

## SQL Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
- **Changes**: Lowercase schema objects (Products→products, ProductId→productid, etc.)
- **PostgreSQL Compatibility**: Window functions (AVG OVER, COUNT OVER) are natively supported

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, LEFT JOIN, CASE, ROUND
- **Parameters**: @ProductId
- **Changes**: Lowercase schema objects
- **PostgreSQL Compatibility**: LAG window function natively supported

### Statement 3: InsertProductAsync
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Parameters**: @Name, @Description, @Price, @StockQuantity
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - Removed `DECLARE @NewProductId` and `BEGIN TRANSACTION/COMMIT` (handled in C# code)
  - Sequential statements with `lastval()` for identity retrieval

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT into variables, UPDATE
- **Parameters**: @ProductId, @Name, @Description, @Price, @StockQuantity
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice/DECLARE @OldStock` → Captured via separate SELECT in C# code
  - Old values passed as @OldPrice, @OldStock parameters
  - Removed `BEGIN TRANSACTION/COMMIT` (handled in C# code)

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT, DELETE, CASE
- **Parameters**: @ProductId
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice/DECLARE @OldStock` → Captured via separate SELECT in C# code
  - Old values passed as @OldPrice, @OldStock parameters
  - Removed `BEGIN TRANSACTION/COMMIT` (handled in C# code)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK, PERCENT_RANK, CASE, BETWEEN
- **Parameters**: @MinPrice, @MaxPrice
- **Changes**: Lowercase schema objects
- **PostgreSQL Compatibility**: RANK, PERCENT_RANK, BETWEEN natively supported

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG, MIN, MAX window functions, CASE, ROUND
- **Parameters**: @Threshold
- **Key Changes**:
  - Lowercase schema objects
  - `ROUND((StockQuantity / AvgStock) * 100, 2)` → `ROUND(CAST(stockquantity AS NUMERIC) / CAST(avgstock AS NUMERIC) * 100, 2)` (explicit CAST for integer division)

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `AdoCore.csproj` | Modified | Replaced `Microsoft.Data.SqlClient 5.1.4` with `Npgsql 8.0.9` |
| `DataAccess/ProductRepository.cs` | Modified | All 7 SQL statements converted; all SqlClient classes replaced with Npgsql equivalents |
| `appsettings.json` | Modified | Connection strings updated from SQL Server to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL DDL syntax |
| `Database/Scripts/01_InitialSetup.sql` | Modified | Converted to PostgreSQL DDL syntax (comprehensive) |
| `extracted_statements.sql` | New | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | New | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | New | Equivalency validation report |
| `migration_report.md` | New | This report |

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.9` |

> Note: Initially planned Npgsql 8.0.0 per plan, upgraded to 8.0.9 to address known high severity vulnerability (NU1903, GHSA-x9vc-6hfv-hg8c).

## Class Replacements

| SQL Server Class | Npgsql Equivalent |
|------------------|-------------------|
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `using Microsoft.Data.SqlClient` | `using Npgsql` |

## Connection String Changes

**Before (SQL Server)**:
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

**After (PostgreSQL)**:
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres
```

Removed SQL Server-specific parameters: `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`

## Build Status

- **Final Build**: ✅ Succeeded with 0 errors
- **Warnings**: 10 (pre-existing nullable reference warnings from CS8601, CS8603, CS8618, CS8625, CS8600)

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | All 7 original MS SQL statements with metadata |
| `converted_statements.sql` | Project root | All 7 converted PostgreSQL statements with metadata |
| `sql_equivalency_validation_report.json` | Project root | Full equivalency report with all 7 statement pairs |
| `migration_report.md` | Project root | This comprehensive migration report |

## Statements Requiring Manual Review

All 7 statements should be manually reviewed because:
1. DMS tool was unavailable (metadata model creation error)
2. SQL Equivalency tool returned errors for all validations
3. Manual conversion was applied based on known SQL Server → PostgreSQL migration rules
4. Particular attention should be given to:
   - Statement 3 (InsertProductAsync): `lastval()` usage for identity retrieval
   - Statement 4 (UpdateProductAsync): Old value capture restructuring
   - Statement 5 (DeleteProductAsync): Old value capture restructuring
   - Statement 7 (GetLowStockProductsAsync): Integer division CAST handling
