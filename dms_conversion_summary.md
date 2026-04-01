# DMS Conversion Failure Summary
## All 7 SQL Statements Failed DMS Conversion

### DMS Configuration
- Migration Project ARN: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- Database: ProductManagement
- Schema: dbo
- Region: us-east-1
- Server: 172.31.94.132

### Common Error
All 7 statements failed with the same error:
- **Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Status**: error
- **Root Cause**: The DMS metadata model creation process timed out for all attempts

### Statements and Manual Conversions

#### Statement 1: GetAllProductsAsync
- **DMS Attempt Time**: 2026-04-01T15:20:34 (first attempt), then retried
- **DMS Error**: Metadata model conversion failed after 15 attempts
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names to lowercase, SQL syntax PostgreSQL compatible as-is

#### Statement 2: GetProductByIdAsync
- **DMS Attempt Time**: 2026-04-01T15:36:46
- **DMS Error**: Metadata model creation failed after 15 attempts
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names to lowercase, LAG window function compatible

#### Statement 3: InsertProductAsync
- **DMS Attempt Time**: 2026-04-01T15:39:37
- **DMS Error**: Metadata model creation failed after 15 attempts
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: SCOPE_IDENTITY() -> RETURNING + lastval(), GETDATE() -> NOW(), DECLARE/BEGIN TRANSACTION -> DO block

#### Statement 4: UpdateProductAsync
- **DMS Attempt Time**: 2026-04-01T15:42:24
- **DMS Error**: Metadata model creation failed after 15 attempts
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE -> DO block, GETDATE() -> NOW(), SELECT INTO variable syntax updated

#### Statement 5: DeleteProductAsync
- **DMS Attempt Time**: 2026-04-01T15:45:13
- **DMS Error**: Metadata model creation failed after 15 attempts
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: DECLARE -> DO block, GETDATE() -> NOW(), SELECT INTO variable syntax updated

#### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt Time**: 2026-04-01T15:48:00
- **DMS Error**: Metadata model creation failed after 15 attempts
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names to lowercase, RANK/PERCENT_RANK compatible

#### Statement 7: GetLowStockProductsAsync
- **DMS Attempt Time**: 2026-04-01T15:50:49
- **DMS Error**: Metadata model creation failed after 15 attempts
- **Manual Conversion Applied**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Table/column names to lowercase, added CAST for integer division
