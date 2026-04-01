# DMS Conversion Failure Summary

## Overview
All 7 SQL statements from ProductRepository.cs were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion from MS SQL Server to PostgreSQL. All 7 statements failed with the same error.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
- **Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Schema**: dbo
- **Region**: us-east-1

## Statements and DMS Attempt Timestamps

### Statement 1: GetAllProductsAsync CTE
- **Attempt 1**: 2026-03-31T23:17:49 - Error: Metadata model conversion did not complete after 15 attempts
- **Attempt 2**: Timed out after 300 seconds (with max_poll_attempts=30)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync CTE
- **Attempt**: 2026-03-31T23:28:47 - Error: Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync Transaction Block
- **Attempt**: 2026-03-31T23:31:34 - Error: Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Changes**: SCOPE_IDENTITY() -> currval('products_productid_seq'), GETDATE() -> now(), DECLARE removed

### Statement 4: UpdateProductAsync Transaction Block
- **Attempt**: 2026-03-31T23:34:20 - Error: Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Changes**: GETDATE() -> now(), DECLARE removed, reordered to use INSERT...SELECT for old values

### Statement 5: DeleteProductAsync Transaction Block
- **Attempt**: 2026-03-31T23:37:06 - Error: Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Manual Changes**: GETDATE() -> now(), DECLARE removed, reordered to use INSERT...SELECT for old values

### Statement 6: GetProductsByPriceRangeAsync CTE
- **Attempt**: 2026-03-31T23:39:52 - Error: Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync CTE
- **Attempt**: 2026-03-31T23:42:39 - Error: Metadata model creation did not complete after 15 attempts
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Additional DMS Test
- A simple test query `SELECT ProductId, Name FROM Products WHERE ProductId = @ProductId` was also attempted and failed with the same error (2026-03-31T23:25:57)

## Manual Conversion Rules Applied
1. All schema object names converted to lowercase (tables, columns, aliases)
2. SCOPE_IDENTITY() -> currval('products_productid_seq')
3. GETDATE() -> now()
4. BEGIN TRANSACTION -> BEGIN
5. DECLARE @var / SET @var removed, replaced with subquery/INSERT...SELECT patterns
6. Integer division for ROUND() corrected with CAST to NUMERIC where needed
7. CTE syntax, window functions (LAG, RANK, PERCENT_RANK, AVG OVER, COUNT OVER) preserved (compatible)
8. CASE expressions, BETWEEN, JOIN syntax preserved (compatible)
