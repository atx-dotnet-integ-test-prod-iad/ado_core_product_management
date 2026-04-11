# DMS Conversion Failure Summary
## Date: 2026-04-11

## DMS Tool Error
All 7 SQL statements failed DMS conversion with the same error:
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Region**: us-east-1
- **Schema**: dbo

## Retry Attempts
- Each statement was attempted at least once with DMS
- Multiple retry strategies were used: default polling, increased poll attempts (30, 45, 60), increased poll intervals (15s, 20s, 30s)
- All attempts failed with the same metadata model creation error
- Simple SELECT statements also failed, confirming this is a DMS infrastructure issue, not a SQL complexity issue

## Manual Conversion Applied
Per the transformation definition, when DMS fails:
- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names (tables, columns, views, aliases) converted to lowercase
- MS SQL specific functions converted to PostgreSQL equivalents:
  - SCOPE_IDENTITY() -> lastval()
  - GETDATE() -> NOW()
  - BEGIN TRANSACTION -> BEGIN
  - DECLARE @var -> Eliminated using subquery approach or lastval()
  - Integer division in ROUND() -> CAST to NUMERIC for proper decimal division

## Statements Summary

| # | Method | DMS Status | Manual Conversion Applied |
|---|--------|------------|--------------------------|
| 1 | GetAllProductsAsync | FAILED | Yes - lowercase schema |
| 2 | GetProductByIdAsync | FAILED | Yes - lowercase schema |
| 3 | InsertProductAsync | FAILED | Yes - lowercase schema, SCOPE_IDENTITY->lastval(), GETDATE->NOW() |
| 4 | UpdateProductAsync | FAILED | Yes - lowercase schema, DECLARE->subquery, GETDATE->NOW() |
| 5 | DeleteProductAsync | FAILED | Yes - lowercase schema, DECLARE->subquery, GETDATE->NOW() |
| 6 | GetProductsByPriceRangeAsync | FAILED | Yes - lowercase schema |
| 7 | GetLowStockProductsAsync | FAILED | Yes - lowercase schema, CAST for integer division |
