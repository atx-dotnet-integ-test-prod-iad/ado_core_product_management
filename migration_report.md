# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 7 |

## Migration Details

### Source Application
- **Application**: AdoCore (.NET 9.0)
- **Original Database**: Microsoft SQL Server
- **Original Package**: Microsoft.Data.SqlClient 5.1.4
- **Target Database**: PostgreSQL
- **Target Package**: Npgsql 8.0.6

### Migration Date
- **Date**: 2026-05-07

## DMS MCP Tool Results

All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed with the same error:

- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Migration Project**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Region**: us-east-1

### Manual Conversion Applied
Since DMS failed, manual conversion was applied following the rule: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

Key conversion rules applied:
1. All schema object names converted to lowercase (e.g., `Products` → `products`, `ProductHistory` → `producthistory`)
2. `SCOPE_IDENTITY()` → `INSERT...RETURNING productid`
3. `GETDATE()` → `NOW()`
4. `BEGIN TRANSACTION` → C# managed transaction with `NpgsqlTransaction`
5. T-SQL variable declarations → Restructured using C# variables
6. Window functions (AVG OVER, LAG, RANK, PERCENT_RANK) → Preserved (compatible)
7. CTE syntax → Preserved (compatible)
8. `ROUND` function → Preserved (with CAST for integer division)

## SQL Equivalency Validation Results

All 7 statement pairs were submitted to the SQL Equivalency MCP tool. All returned ERROR:

- **Error**: `'uniqueID'`
- **Note**: Per transformation definition, equivalency errors are recorded as-is from the tool output. Agent judgment was NOT used to determine equivalency.

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE and window functions
- **DMS Result**: FAILED - Metadata model creation error
- **Manual Conversion**: Applied lowercase schema naming
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE and LAG window function
- **DMS Result**: FAILED - Metadata model creation error
- **Manual Conversion**: Applied lowercase schema naming
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY, UPDATE
- **DMS Result**: FAILED - Metadata model creation error
- **Manual Conversion**: Restructured to INSERT...RETURNING with C# managed transaction
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT
- **DMS Result**: FAILED - Metadata model creation error
- **Manual Conversion**: Restructured to separate SQL commands in C# managed transaction
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE
- **DMS Result**: FAILED - Metadata model creation error
- **Manual Conversion**: Restructured to separate SQL commands in C# managed transaction
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK, PERCENT_RANK
- **DMS Result**: FAILED - Metadata model creation error
- **Manual Conversion**: Applied lowercase schema naming
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions
- **DMS Result**: FAILED - Metadata model creation error
- **Manual Conversion**: Applied lowercase schema naming, added CAST for integer division
- **Equivalency Status**: ERROR

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; SqlClient → Npgsql classes |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings converted to PostgreSQL format |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion |
| `Scripts/01_InitialSetup.sql` | Full PostgreSQL conversion |

## Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | Complete catalog of original MS SQL statements |
| `converted_statements.sql` | Project root | Complete catalog of converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency validation report |
| `dms_failure_summary.md` | Project root | Detailed DMS failure documentation |
| `migration_report.md` | Project root | This report |

## Build Status
- **Final Build**: ✅ SUCCESS (0 errors, warnings only for nullable reference types)

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS conversion tool was unavailable (metadata model creation failure)
2. SQL Equivalency tool returned errors for all pairs

Manual review should verify that the PostgreSQL conversions are functionally equivalent to the original MS SQL statements, particularly for:
- Transaction block restructuring (Statements 3, 4, 5)
- Window function compatibility (Statements 1, 2, 6, 7)
- Integer division handling in ROUND expressions (Statement 7)
