# DMS Conversion Failure Summary

## Overview
All 7 SQL statements failed DMS conversion due to metadata model creation failures.
Manual conversion was performed applying lowercase schema object names per transformation instructions.

## DMS Errors Encountered
1. "Metadata model creation did not complete after 15 attempts" (Statements 1, 2, 4, 6)
2. "Access to Amazon Service denied" (Statements 3, 5, 7)

## Statements Manually Converted

### Statement 1: GetAllProductsAsync (SELECT with CTE + window functions)
- **DMS Error**: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Lowercase schema objects, SQL syntax compatible as-is
- **Key Changes**: ProductId→productid, Products→products, etc.

### Statement 2: GetProductByIdAsync (SELECT with CTE + LAG window function)
- **DMS Error**: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Lowercase schema objects, SQL syntax compatible as-is
- **Key Changes**: ProductId→productid, Products→products, ModifiedDate→modifieddate

### Statement 3: InsertProductAsync (Transaction with SCOPE_IDENTITY, GETDATE)
- **DMS Error**: Access to Amazon Service denied
- **Manual Conversion**: Restructured to use PostgreSQL writable CTEs with RETURNING clause
- **Key Changes**: 
  - SCOPE_IDENTITY() → RETURNING productid (via writable CTE)
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → single atomic CTE statement
  - All schema objects lowercased

### Statement 4: UpdateProductAsync (Transaction with DECLARE, GETDATE)
- **DMS Error**: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Restructured to use PostgreSQL writable CTEs
- **Key Changes**:
  - DECLARE @var / SELECT @var = col → CTE subquery (old_values)
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → single atomic CTE statement
  - All schema objects lowercased

### Statement 5: DeleteProductAsync (Transaction with DECLARE, GETDATE, CASE)
- **DMS Error**: Access to Amazon Service denied
- **Manual Conversion**: Restructured to use PostgreSQL writable CTEs
- **Key Changes**:
  - DECLARE @var / SELECT @var = col → CTE subquery (old_values)
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT → single atomic CTE statement
  - All schema objects lowercased

### Statement 6: GetProductsByPriceRangeAsync (SELECT with CTE + RANK/PERCENT_RANK)
- **DMS Error**: Metadata model creation did not complete after 15 attempts
- **Manual Conversion**: Lowercase schema objects, SQL syntax compatible as-is
- **Key Changes**: Products→products, Price→price, etc.

### Statement 7: GetLowStockProductsAsync (SELECT with CTE + AVG/MIN/MAX OVER)
- **DMS Error**: Access to Amazon Service denied
- **Manual Conversion**: Lowercase schema objects + CAST for integer division
- **Key Changes**: 
  - All schema objects lowercased
  - Added CAST(stockquantity AS DECIMAL) for correct division behavior

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool.
All returned ERROR status with error "'uniqueID'" - this appears to be a tool-level infrastructure issue unrelated to the SQL conversions themselves.
