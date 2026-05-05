# DMS Conversion Failure Summary
## Date: 2026-05-05
## Migration Project: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

## Summary
All 7 SQL statements failed DMS conversion with the same error:
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Root Cause**: DMS metadata model creation service returned unexpected 'RECEIVED' status
- **Impact**: All 7 statements required manual conversion

## Manual Conversion Approach
Per transformation definition instructions, when DMS fails:
- All schema object names (tables, columns, views) converted to lowercase
- SQL Server specific functions converted to PostgreSQL equivalents:
  - SCOPE_IDENTITY() → lastval()
  - GETDATE() → NOW()
  - BEGIN TRANSACTION → BEGIN
  - DECLARE @var pattern → removed (restructured queries to use subqueries)
  - Integer division → explicit cast to numeric for ROUND operations

## Statement Details

### Statement 1: GetAllProductsAsync
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, window functions compatible
- **Key Changes**: Products→products, ProductId→productid, Price→price, etc.

### Statement 2: GetProductByIdAsync
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, LAG window function compatible
- **Key Changes**: Products→products, ModifiedDate→modifieddate, etc.

### Statement 3: InsertProductAsync
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: SCOPE_IDENTITY()→lastval(), GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN
- **Key Changes**: Transaction restructured, DECLARE removed

### Statement 4: UpdateProductAsync
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: GETDATE()→NOW(), DECLARE @var→subquery, BEGIN TRANSACTION→BEGIN
- **Key Changes**: Variable assignments replaced with subquery approach

### Statement 5: DeleteProductAsync
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: GETDATE()→NOW(), DECLARE @var→subquery, BEGIN TRANSACTION→BEGIN
- **Key Changes**: Variable assignments replaced with subquery, CASE preserved

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, RANK/PERCENT_RANK compatible
- **Key Changes**: Products→products, Price→price, etc.

### Statement 7: GetLowStockProductsAsync
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, integer division cast to numeric
- **Key Changes**: StockQuantity→stockquantity, explicit ::numeric cast for ROUND
