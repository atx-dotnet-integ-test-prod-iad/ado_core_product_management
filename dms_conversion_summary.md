# DMS Conversion Failure Summary

## Overview
- **Total Statements Attempted**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Applied**: 7
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## DMS Tool Configuration
- Migration Project: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- Database: ProductManagement
- Schema: dbo
- Region: us-east-1
- Server: 172.31.94.132

## Statement Details

### Statement 1: GetAllProductsAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-05-07T12:07:47.717420
- **Manual Conversion Applied**: Yes
- **Conversion Notes**: CTE with window functions (AVG, COUNT) - compatible with PostgreSQL. Applied lowercase schema names.

### Statement 2: GetProductByIdAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-05-07T12:08:24.901645
- **Manual Conversion Applied**: Yes
- **Conversion Notes**: CTE with LAG window functions - compatible with PostgreSQL. Applied lowercase schema names.

### Statement 3: InsertProductAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-05-07T12:08:41.316867
- **Manual Conversion Applied**: Yes
- **Conversion Notes**: 
  - SCOPE_IDENTITY() → INSERT...RETURNING + currval(pg_get_serial_sequence())
  - GETDATE() → NOW()
  - DECLARE @variable / BEGIN TRANSACTION / COMMIT → restructured as CTE with RETURNING clause
  - Transaction management moved to application code (Npgsql BeginTransaction)

### Statement 4: UpdateProductAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-05-07T12:08:56.827265
- **Manual Conversion Applied**: Yes
- **Conversion Notes**: 
  - DECLARE @OldPrice/@OldStock → CTE with subquery
  - GETDATE() → NOW()
  - BEGIN TRANSACTION / COMMIT → managed by application code (Npgsql BeginTransaction)

### Statement 5: DeleteProductAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-05-07T12:09:11.633386
- **Manual Conversion Applied**: Yes
- **Conversion Notes**: 
  - DECLARE @OldPrice/@OldStock → CTE with subquery
  - GETDATE() → NOW()
  - BEGIN TRANSACTION / COMMIT → managed by application code (Npgsql BeginTransaction)

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-05-07T12:09:27.898481
- **Manual Conversion Applied**: Yes
- **Conversion Notes**: CTE with RANK/PERCENT_RANK window functions - compatible with PostgreSQL. Applied lowercase schema names.

### Statement 7: GetLowStockProductsAsync
- **DMS Status**: ERROR
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **DMS Timestamp**: 2026-05-07T12:09:42.338600
- **Manual Conversion Applied**: Yes
- **Conversion Notes**: 
  - CTE with AVG/MIN/MAX window functions - compatible with PostgreSQL
  - Added CAST(stockquantity AS NUMERIC) to avoid integer division
  - Applied lowercase schema names
