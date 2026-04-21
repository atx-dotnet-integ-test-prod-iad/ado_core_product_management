# DMS Conversion Failure Summary

## DMS Tool Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Status**: error
- **Affected Statements**: ALL 7 statements
- **DMS ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Database**: ProductManagement
- **Schema**: dbo
- **Attempts**: Multiple attempts per statement with varying poll_interval_seconds (10, 15, 20, 30) and max_poll_attempts (15, 25, 30, 40)

## Statement-by-Statement DMS Attempts

### Statement 1: GetAllProductsAsync (CTE with window functions)
- **DMS Attempt Timestamp**: 2026-04-21T15:44:30 and 2026-04-21T15:44:46
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Applied lowercase schema object names, SQL syntax is already PostgreSQL-compatible

### Statement 2: GetProductByIdAsync (CTE with LAG window function)
- **DMS Attempt Timestamp**: 2026-04-21T15:45:48
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Applied lowercase schema object names, SQL syntax is already PostgreSQL-compatible

### Statement 3: InsertProductAsync (Transaction with SCOPE_IDENTITY, GETDATE)
- **DMS Attempt Timestamp**: 2026-04-21T15:46:03
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: SCOPE_IDENTITY() -> LASTVAL(), GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, DECLARE @var removed, applied lowercase schema

### Statement 4: UpdateProductAsync (Transaction with DECLARE vars, GETDATE)
- **DMS Attempt Timestamp**: 2026-04-21T15:46:18
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: DECLARE @var -> subquery approach, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, reordered operations to capture old values before update, applied lowercase schema

### Statement 5: DeleteProductAsync (Transaction with DECLARE vars, GETDATE)
- **DMS Attempt Timestamp**: 2026-04-21T15:46:32
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: DECLARE @var -> subquery approach, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN, reordered operations to capture old values before delete, applied lowercase schema

### Statement 6: GetProductsByPriceRangeAsync (CTE with RANK, PERCENT_RANK)
- **DMS Attempt Timestamp**: 2026-04-21T15:46:46
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Applied lowercase schema object names, SQL syntax is already PostgreSQL-compatible

### Statement 7: GetLowStockProductsAsync (CTE with AVG/MIN/MAX OVER)
- **DMS Attempt Timestamp**: 2026-04-21T15:47:01
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Applied lowercase schema object names, added CAST for integer division, SQL syntax is already PostgreSQL-compatible
