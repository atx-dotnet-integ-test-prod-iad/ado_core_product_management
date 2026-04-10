# DMS Conversion Log

## Summary
- **Total Statements:** 7
- **DMS Successful Conversions:** 0
- **DMS Failures:** 7
- **Manual Conversions Required:** 7
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Migration Project ARN:** arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

## Schema Mappings (from DMS schema_mapping_tool - SUCCESSFUL)
The DMS schema_mapping_tool successfully returned schema mappings:
- `dbo.Products` → `productmanagement_dbo.products`
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory`
- `dbo.ProductStats` → `productmanagement_dbo.productstats`

All column names are mapped to lowercase in the target PostgreSQL schema.

## DMS Statement Conversion Attempts

### Statement 1: GetAllProductsAsync
- **DMS Timestamp:** 2026-04-10T15:18:31.115256
- **DMS Status:** error
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied:** Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes:**
  - Table `Products` → `productmanagement_dbo.products`
  - All column references lowercased (ProductId→productid, Name→name, etc.)
  - CTE alias `ProductStats` → `productstats`
  - SQL logic and window functions preserved (AVG OVER, COUNT OVER, CASE)

### Statement 2: GetProductByIdAsync
- **DMS Timestamp:** 2026-04-10T15:18:36.028469
- **DMS Status:** error
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied:** Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes:**
  - Table `Products` → `productmanagement_dbo.products`
  - All column references lowercased
  - CTE alias `ProductHistory` → `producthistory`
  - LAG window functions preserved
  - Parameter @ProductId retained (Npgsql handles @ parameters)

### Statement 3: InsertProductAsync
- **DMS Timestamp:** 2026-04-10T15:19:19.452088
- **DMS Status:** error
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied:** Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `INSERT ... RETURNING productid` with writable CTE
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @NewProductId` → writable CTE pattern (no DECLARE needed)
  - `BEGIN TRANSACTION`/`COMMIT` → removed (writable CTE is atomic)
  - Tables/columns lowercased with schema prefix
  - Used writable CTE to chain INSERT operations and return the new ID

### Statement 4: UpdateProductAsync
- **DMS Timestamp:** 2026-04-10T15:19:24.560157
- **DMS Status:** error
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied:** Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes:**
  - `DECLARE @OldPrice`/`@OldStock` → `DO $$ DECLARE var_oldprice/var_oldstock`
  - `SELECT @OldPrice = ...` → `SELECT ... INTO var_oldprice, var_oldstock`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION`/`COMMIT` → `DO $$ ... END $$` (anonymous block)
  - Tables/columns lowercased with schema prefix

### Statement 5: DeleteProductAsync
- **DMS Timestamp:** 2026-04-10T15:19:29.367680
- **DMS Status:** error
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied:** Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes:**
  - Same pattern as Statement 4 (DO block with DECLARE)
  - `GETDATE()` → `clock_timestamp()`
  - CASE expression preserved for AveragePrice calculation
  - Tables/columns lowercased with schema prefix

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Timestamp:** 2026-04-10T15:19:52.340388
- **DMS Status:** error
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied:** Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes:**
  - Table `Products` → `productmanagement_dbo.products`
  - CTE alias `RankedProducts` → `rankedproducts`
  - All column references lowercased
  - RANK() and PERCENT_RANK() window functions preserved (PostgreSQL compatible)
  - BETWEEN clause preserved

### Statement 7: GetLowStockProductsAsync
- **DMS Timestamp:** 2026-04-10T15:19:57.112437
- **DMS Status:** error
- **DMS Error:** Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied:** Yes (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- **Key Changes:**
  - Table `Products` → `productmanagement_dbo.products`
  - CTE alias `StockAnalysis` → `stockanalysis`
  - All column references lowercased
  - Added `CAST(stockquantity AS NUMERIC)` for integer division issue in PostgreSQL
  - AVG/MIN/MAX window functions preserved
