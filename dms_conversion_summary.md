# DMS Conversion Failure Summary

## Overview
All 7 SQL statements were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool) and all 7 failed with the same error.

## DMS Configuration Used
- migration_project_identifier: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- database_name: ProductManagement
- schema_name: dbo
- region: us-east-1
- server_name (auto-detected): 172.31.94.132

## Error Details
All 7 statements received the same error:
```
status: error
error: "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"
```

The error occurred at the "create_metadata_model" workflow step, indicating the DMS service could not create the metadata model needed for SQL conversion.

## Statements Attempted and Manual Conversions Applied

### Statement 1: GetAllProductsAsync
- **DMS Attempt**: Failed
- **Manual Conversion**: Lowercase schema objects (Products→products, ProductId→productid, etc.)
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- **DMS Attempt**: Failed
- **Manual Conversion**: Lowercase schema objects
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- **DMS Attempt**: Failed
- **Manual Conversion**: Lowercase schema objects + SCOPE_IDENTITY()→lastval() + GETDATE()→NOW() + BEGIN TRANSACTION→BEGIN + restructured with CTE+RETURNING
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- **DMS Attempt**: Failed
- **Manual Conversion**: Lowercase schema objects + GETDATE()→NOW() + BEGIN TRANSACTION→BEGIN + replaced DECLARE variables with subqueries
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- **DMS Attempt**: Failed
- **Manual Conversion**: Lowercase schema objects + GETDATE()→NOW() + BEGIN TRANSACTION→BEGIN + replaced DECLARE variables with subqueries
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt**: Failed
- **Manual Conversion**: Lowercase schema objects
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt**: Failed
- **Manual Conversion**: Lowercase schema objects + added CAST for integer division in ROUND
- **Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
