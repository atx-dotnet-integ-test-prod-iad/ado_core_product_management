# DMS Conversion Failure Summary

## Overview
All 7 SQL statements failed DMS conversion with the same error.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Region**: us-east-1
- **Server**: 172.31.94.132
- **Database**: ProductManagement
- **Schema**: dbo

## Conversion Approach
Since DMS was unavailable, all statements were manually converted following the DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA rules:
- All schema object names (tables, columns, views) converted to lowercase
- `SCOPE_IDENTITY()` replaced with `lastval()`
- `GETDATE()` replaced with `NOW()`
- `BEGIN TRANSACTION / COMMIT` replaced with `BEGIN / COMMIT` or `DO $$ ... END $$` blocks
- `DECLARE @var TYPE` replaced with PL/pgSQL `DECLARE v_var TYPE` in DO blocks
- `SET @var = expr` replaced with `SELECT ... INTO v_var`
- Integer division handled with `::numeric` cast where needed

## Statements Processed

| # | Method | Location | Description |
|---|--------|----------|-------------|
| 1 | GetAllProductsAsync | ProductRepository.cs:39 | CTE with AVG/COUNT window functions |
| 2 | GetProductByIdAsync | ProductRepository.cs:79 | CTE with LAG window function |
| 3 | InsertProductAsync | ProductRepository.cs:113 | Transaction with SCOPE_IDENTITY → lastval() |
| 4 | UpdateProductAsync | ProductRepository.cs:142 | Transaction with variable declarations |
| 5 | DeleteProductAsync | ProductRepository.cs:177 | Transaction with CASE expression |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs:213 | CTE with RANK/PERCENT_RANK |
| 7 | GetLowStockProductsAsync | ProductRepository.cs:243 | CTE with AVG/MIN/MAX window functions |

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool.
All 7 returned ERROR status with error: "'uniqueID'"
This is a tool-level issue, not a statement-level issue.
