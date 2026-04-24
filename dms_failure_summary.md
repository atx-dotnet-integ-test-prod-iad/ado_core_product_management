# DMS Conversion Failure Summary

## Overview
All 7 SQL statements were passed to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion from MS SQL Server to PostgreSQL. All 7 statements failed with the same error.

## DMS Configuration Used
- **Migration Project ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Schema Name**: dbo
- **Database Name**: ProductManagement
- **Region**: us-east-1

## Error Details
All 7 statements returned the same error:
```
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied following the rule: **DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA**

### Key Conversion Rules Applied:
1. **Lowercase Schema Objects**: All table names, column names, aliases converted to lowercase
   - Products → products, ProductHistory → producthistory, ProductStats → productstats
   - ProductId → productid, StockQuantity → stockquantity, CreatedDate → createddate, etc.
2. **SCOPE_IDENTITY()** → INSERT...RETURNING + currval('products_productid_seq')
3. **GETDATE()** → NOW()
4. **DECLARE @variable** → SELECT INTO TEMPORARY or inline subqueries
5. **BEGIN TRANSACTION / COMMIT** → BEGIN / COMMIT
6. **ROUND()** function preserved (compatible), with ::numeric cast where integer division occurs
7. **Window functions** (LAG, RANK, PERCENT_RANK, AVG/COUNT/MIN/MAX OVER) preserved (compatible with PostgreSQL)
8. **CTE syntax** preserved (compatible with PostgreSQL)

## Statement-by-Statement Conversion Summary

| # | Method | Source | DMS Status | Manual Conversion Applied |
|---|--------|--------|------------|--------------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | FAILED | Yes - lowercase schema |
| 2 | GetProductByIdAsync | ProductRepository.cs | FAILED | Yes - lowercase schema |
| 3 | InsertProductAsync | ProductRepository.cs | FAILED | Yes - lowercase schema + SCOPE_IDENTITY→RETURNING + GETDATE→NOW |
| 4 | UpdateProductAsync | ProductRepository.cs | FAILED | Yes - lowercase schema + DECLARE→SELECT INTO + GETDATE→NOW |
| 5 | DeleteProductAsync | ProductRepository.cs | FAILED | Yes - lowercase schema + DECLARE→SELECT INTO + GETDATE→NOW |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | FAILED | Yes - lowercase schema |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | FAILED | Yes - lowercase schema + ::numeric cast |
