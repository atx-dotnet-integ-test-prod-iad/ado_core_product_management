# DMS Conversion Log

## Summary
- **Total SQL Statements**: 7
- **DMS Statement Conversion Tool Results**: 0 successful, 7 failed
- **DMS Schema Mapping Tool Results**: 3 successful (Products, ProductHistory, ProductStats)
- **Manual Conversions Required**: 7 (all statements)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## DMS Statement Conversion Tool Error
All 7 SQL statements failed with the same error when passed to the DMS statement conversion tool:
```
{
  "status": "error",
  "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}",
  "workflow_steps": [{"step": "create_metadata_model", "status": "started"}]
}
```

The DMS tool was attempted with multiple configurations:
- With/without database_name parameter
- With/without explicit server_name parameter  
- With increased poll_attempts (15, 30, 45, 60)
- With increased poll_interval_seconds (10, 15, 20, 30)
- With simple and complex SQL statements

The metadata model creation consistently stalled at "RECEIVED" status.

## DMS Schema Mapping Tool Results (Successful)
Schema mappings were successfully retrieved using the DMS schema mapping tool:

### Products Table
- Source: `[dbo].[Products]` → Target: `productmanagement_dbo.products`
- Column mappings: All lowercase (ProductId→productid, Name→name, etc.)
- Type mappings: datetime→TIMESTAMP WITHOUT TIME ZONE, IDENTITY→GENERATED ALWAYS AS IDENTITY

### ProductHistory Table  
- Source: `[dbo].[ProductHistory]` → Target: `productmanagement_dbo.producthistory`
- Column mappings: All lowercase
- Type mappings: Same as Products

### ProductStats Table
- Source: `[dbo].[ProductStats]` → Target: `productmanagement_dbo.productstats`
- Column mappings: All lowercase
- Type mappings: Same patterns

## Statement-by-Statement Conversion Details

### SQL #1: GetAllProductsAsync
- **DMS Tool Attempt**: Failed (Metadata model creation error)
- **DMS Tool Timestamp**: 2026-04-18T10:36:00
- **Manual Conversion**: Applied lowercase schema mapping from DMS schema_mapping_tool
- **Key Changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo`

### SQL #2: GetProductByIdAsync
- **DMS Tool Attempt**: Failed (Metadata model creation error)
- **Manual Conversion**: Applied lowercase schema mapping
- **Key Changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo`

### SQL #3: InsertProductAsync
- **DMS Tool Attempt**: Failed (Metadata model creation error)
- **Manual Conversion**: Applied lowercase schema mapping
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @NewProductId INT` → Removed (using lastval() directly)
  - `BEGIN TRANSACTION` → `BEGIN`
  - Schema prefix `productmanagement_dbo`

### SQL #4: UpdateProductAsync
- **DMS Tool Attempt**: Failed (Metadata model creation error)
- **Manual Conversion**: Applied lowercase schema mapping + PL/pgSQL DO block
- **Key Changes**:
  - `DECLARE @OldPrice` → PL/pgSQL `DECLARE v_oldprice`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → `DO $$ ... END $$`
  - Schema prefix `productmanagement_dbo`

### SQL #5: DeleteProductAsync
- **DMS Tool Attempt**: Failed (Metadata model creation error)
- **Manual Conversion**: Applied lowercase schema mapping + PL/pgSQL DO block
- **Key Changes**:
  - `DECLARE @OldPrice` → PL/pgSQL `DECLARE v_oldprice`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → `DO $$ ... END $$`
  - Schema prefix `productmanagement_dbo`

### SQL #6: GetProductsByPriceRangeAsync
- **DMS Tool Attempt**: Failed (Metadata model creation error)
- **Manual Conversion**: Applied lowercase schema mapping
- **Key Changes**: Table/column names to lowercase, schema prefix `productmanagement_dbo`

### SQL #7: GetLowStockProductsAsync
- **DMS Tool Attempt**: Failed (Metadata model creation error)
- **Manual Conversion**: Applied lowercase schema mapping
- **Key Changes**: 
  - Table/column names to lowercase
  - Schema prefix `productmanagement_dbo`
  - Added `CAST(stockquantity AS NUMERIC)` for proper decimal division in PostgreSQL
