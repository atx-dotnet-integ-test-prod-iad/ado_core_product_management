# DMS Conversion Summary Report

## Tool Status
- **DMS Tool**: dms-mcp___statement_conversion_tool
- **Status**: FAILED for all 7 statements
- **Error**: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
- **Date**: 2026-05-05

## DMS Attempts

All 7 SQL statements were passed through the DMS MCP tool. Each attempt failed with the same error.

### Statement 1: GetAllProductsAsync
- **DMS Status**: ERROR
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Timestamp**: 2026-05-05T19:11:39.427347
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **DMS Status**: ERROR
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Timestamp**: 2026-05-05T19:12:17.797832
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **DMS Status**: ERROR
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Timestamp**: 2026-05-05T19:12:22.601601
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **DMS Status**: ERROR
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Timestamp**: 2026-05-05T19:12:27.434757
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **DMS Status**: ERROR
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Timestamp**: 2026-05-05T19:12:48.436218
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: ERROR
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Timestamp**: 2026-05-05T19:12:53.201097
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **DMS Status**: ERROR
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Timestamp**: 2026-05-05T19:12:58.402336
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Manual Conversion Rules Applied
Since DMS failed for all statements, the following manual conversion rules were applied per the transformation definition:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. `GETDATE()` → `NOW()`
3. `SCOPE_IDENTITY()` → `RETURNING productid` clause
4. `BEGIN TRANSACTION` → `BEGIN`
5. `COMMIT` remains the same
6. `DECLARE @var TYPE` / `SET @var = value` → handled at application level or with DO blocks
7. Window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK) → same syntax in PostgreSQL
8. `ROUND()` → same syntax, with `::numeric` cast where integer division could occur
9. `BETWEEN`, `CASE`, `LEFT JOIN`, `INNER JOIN` → same syntax in PostgreSQL
