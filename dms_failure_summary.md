# DMS Conversion Failure Summary

## Overview
All 7 SQL statements from ProductRepository.cs were submitted to the DMS MCP tool for conversion.
All 7 failed with the same error.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Region**: us-east-1
- **Server**: 172.31.94.132

## Statements Attempted

### Statement 1: GetAllProductsAsync
- **Timestamp**: 2026-05-07T18:51:09 (first attempt), 2026-05-07T18:51:26 (retry)
- **DMS Status**: error
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **Timestamp**: 2026-05-07T18:51:45
- **DMS Status**: error
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **Timestamp**: 2026-05-07T18:52:00
- **DMS Status**: error
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **Timestamp**: 2026-05-07T18:52:14
- **DMS Status**: error
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **Timestamp**: 2026-05-07T18:52:30
- **DMS Status**: error
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **Timestamp**: 2026-05-07T18:52:44
- **DMS Status**: error
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **Timestamp**: 2026-05-07T18:52:59
- **DMS Status**: error
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Manual Conversion Rules Applied
Per the transformation definition, when DMS fails:
1. All schema object names (tables, columns, views) converted to lowercase
2. SCOPE_IDENTITY() replaced with RETURNING clause
3. GETDATE() replaced with NOW()
4. BEGIN TRANSACTION replaced with BEGIN (or managed by C# transaction)
5. Variable declarations restructured for PostgreSQL compatibility
6. ROUND function preserved (compatible with PostgreSQL)
7. Window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK) preserved (compatible)
8. CTE syntax preserved (compatible with PostgreSQL)
