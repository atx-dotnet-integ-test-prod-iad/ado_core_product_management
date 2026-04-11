# DMS Conversion Failure Summary

## DMS Tool Error
All 7 SQL statements failed with the same error when passed to `dms-mcp___statement_conversion_tool`:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## DMS Schema Mapping Success
The `dms-mcp___schema_mapping_tool` worked correctly and provided the following schema mappings:

### Products Table
- Source: `[dbo].[Products]` → Target: `productmanagement_dbo.products`
- Columns: ProductId→productid, Name→name, Description→description, Price→price, StockQuantity→stockquantity, CreatedDate→createddate, ModifiedDate→modifieddate
- GETDATE() → clock_timestamp()
- IDENTITY → GENERATED ALWAYS AS IDENTITY

### ProductHistory Table
- Source: `[dbo].[ProductHistory]` → Target: `productmanagement_dbo.producthistory`
- Columns: HistoryId→historyid, ProductId→productid, Action→action, OldPrice→oldprice, NewPrice→newprice, OldStock→oldstock, NewStock→newstock, ActionDate→actiondate

### ProductStats Table
- Source: `[dbo].[ProductStats]` → Target: `productmanagement_dbo.productstats`
- Columns: StatId→statid, TotalProducts→totalproducts, AveragePrice→averageprice, LastUpdated→lastupdated

## Manual Conversion Applied
Since DMS statement_conversion_tool failed, manual conversion was applied with:
- All schema object names (tables, columns) converted to lowercase per DMS schema mapping
- SCOPE_IDENTITY() → RETURNING clause
- GETDATE() → clock_timestamp()
- DECLARE @var TYPE → PostgreSQL DO block with DECLARE
- ROUND(expr, 2) → ROUND(expr::numeric, 2) where needed for division results
- BEGIN TRANSACTION/COMMIT → DO block (for statements with DECLARE)

## Statement-by-Statement DMS Attempts

### Statement 1: GetAllProductsAsync
- DMS Attempt: FAILED - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 2: GetProductByIdAsync
- DMS Attempt: FAILED - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 3: InsertProductAsync
- DMS Attempt: FAILED - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 4: UpdateProductAsync
- DMS Attempt: FAILED - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 5: DeleteProductAsync
- DMS Attempt: FAILED - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 6: GetProductsByPriceRangeAsync
- DMS Attempt: FAILED - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

### Statement 7: GetLowStockProductsAsync
- DMS Attempt: FAILED - Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
