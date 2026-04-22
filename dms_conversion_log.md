# DMS Conversion Log

## Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions**: 7 (all due to DMS failure)
- **Conversion Method for all**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## DMS Tool Configuration
- **Migration Project ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Database Name**: ProductManagement
- **Schema Name**: dbo
- **Region**: us-east-1
- **Server Name**: 172.31.94.132 (auto-detected by DMS tool)

## DMS Error Details
All 7 statements failed with the same error:
```
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
Workflow Step: create_metadata_model (started but failed)
```

## DMS Conversion Attempts

### Attempt 1: Statement 1 (GetAllProductsAsync)
- **Timestamp**: 2026-04-22T02:44:56.386350
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - lowercase schema object names

### Attempt 2: Statement 2 (GetProductByIdAsync)  
- **Timestamp**: 2026-04-22T02:45:00.104427
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - lowercase schema object names

### Attempt 3: Statement 1 (GetAllProductsAsync) - RETRY with increased polling
- **Timestamp**: 2026-04-22T02:45:15.091423
- **Status**: error
- **Error**: Same as above (retry with max_poll_attempts=30, poll_interval_seconds=15)
- **Notes**: Retry confirmed DMS service-level issue

### Attempt 4: Statement 3 (InsertProductAsync)
- **Timestamp**: 2026-04-22T02:45:48.176191
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - SCOPE_IDENTITY() → lastval(), GETDATE() → NOW(), DECLARE/SET removed, lowercase schema

### Attempt 5: Statement 4 (UpdateProductAsync)
- **Timestamp**: 2026-04-22T02:45:51.824083
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DECLARE removed, GETDATE() → NOW(), subquery pattern, lowercase schema

### Attempt 6: Statement 5 (DeleteProductAsync)
- **Timestamp**: 2026-04-22T02:45:55.316611
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DECLARE removed, GETDATE() → NOW(), subquery pattern, lowercase schema

### Attempt 7: Statement 6 (GetProductsByPriceRangeAsync)
- **Timestamp**: 2026-04-22T02:45:58.925401
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - lowercase schema object names

### Attempt 8: Statement 7 (GetLowStockProductsAsync)
- **Timestamp**: 2026-04-22T02:46:02.622481
- **Status**: error
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - lowercase schema, added ::numeric cast for integer division

## Manual Conversion Rules Applied
Since DMS failed for all statements, the following conversion rules were applied:
1. **Lowercase Schema Objects**: All table names, column names, aliases converted to lowercase
2. **SCOPE_IDENTITY()** → `lastval()` (PostgreSQL sequence function)
3. **GETDATE()** → `NOW()` (PostgreSQL current timestamp)
4. **BEGIN TRANSACTION/COMMIT** → Removed (handled by ADO.NET transaction management)
5. **DECLARE @variable / SET @variable** → Removed (use subquery patterns or lastval())
6. **Integer Division** → Added `::numeric` cast where needed (Statement 7)
7. **Window Functions** (LAG, RANK, PERCENT_RANK, AVG OVER, etc.) → Compatible, only lowercase applied
8. **ROUND()** → Compatible
9. **BETWEEN** → Compatible
10. **CASE expressions** → Compatible

## SQL Equivalency Validation Results
All 7 statement pairs were validated through the SQL Equivalency tool.
All 7 returned ERROR with: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`
This appears to be a service-level issue with the SQL Equivalency tool, not related to the statement conversions themselves.
Per transformation definition requirements, all are marked as ERROR status.
