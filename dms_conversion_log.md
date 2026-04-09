# DMS Conversion Log

## Summary
All 7 SQL statements were submitted to the DMS MCP tool for conversion. All 7 failed with the same error.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Region**: us-east-1
- **Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Database**: ProductManagement
- **Schema**: dbo

## Fallback Applied
Since DMS failed for ALL statements, manual conversion was applied with lowercase schema object names per the transformation definition:
- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Statement-by-Statement DMS Results

### Statement 1: GetAllProductsAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-04-09T19:17:49.803482
- **Manual Conversion Applied**: Yes
- **Key Changes**: Lowercase schema names, ROUND compatible

### Statement 2: GetProductByIdAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-04-09T19:18:06.197666
- **Manual Conversion Applied**: Yes
- **Key Changes**: Lowercase schema names, LAG window function compatible

### Statement 3: InsertProductAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-04-09T19:18:40.810225
- **Manual Conversion Applied**: Yes
- **Key Changes**: Lowercase schema names, SCOPE_IDENTITY() -> RETURNING clause, GETDATE() -> NOW(), DECLARE/SET removed, transaction restructured

### Statement 4: UpdateProductAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-04-09T19:18:57.945267
- **Manual Conversion Applied**: Yes
- **Key Changes**: Lowercase schema names, DECLARE/SET -> separate queries, GETDATE() -> NOW(), transaction restructured

### Statement 5: DeleteProductAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-04-09T19:19:13.356452
- **Manual Conversion Applied**: Yes
- **Key Changes**: Lowercase schema names, DECLARE/SET -> separate queries, GETDATE() -> NOW(), transaction restructured

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-04-09T19:19:28.226401
- **Manual Conversion Applied**: Yes
- **Key Changes**: Lowercase schema names, RANK/PERCENT_RANK compatible

### Statement 7: GetLowStockProductsAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-04-09T19:19:42.647184
- **Manual Conversion Applied**: Yes
- **Key Changes**: Lowercase schema names, AVG/MIN/MAX OVER compatible, ROUND with cast
