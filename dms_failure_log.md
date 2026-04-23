# DMS Conversion Failure Log
# All 7 statements failed DMS conversion with the same error.
# Manual conversion was applied with lowercase schema object names.

## Common DMS Error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Schema**: dbo
- **Region**: us-east-1

## Statement 1: GetAllProductsAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects lowercased, ROUND argument cast to numeric for PostgreSQL

## Statement 2: GetProductByIdAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects lowercased, ROUND argument cast to numeric for PostgreSQL

## Statement 3: InsertProductAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: SCOPE_IDENTITY() -> lastval(), GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, DECLARE removed, schema objects lowercased

## Statement 4: UpdateProductAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE/SELECT INTO variables -> @params kept for C# ADO param binding, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, schema objects lowercased

## Statement 5: DeleteProductAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE/SELECT INTO variables -> @params kept for C# ADO param binding, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, schema objects lowercased

## Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects lowercased

## Statement 7: GetLowStockProductsAsync
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects lowercased, ROUND argument cast to numeric for PostgreSQL
