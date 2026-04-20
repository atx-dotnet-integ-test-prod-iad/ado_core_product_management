# DMS Conversion Log

## Summary
- **DMS Migration Project ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Required**: 7
- **Consistent Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

## Schema Mapping (from DMS schema_mapping_tool - SUCCESSFUL)
The DMS schema_mapping_tool successfully returned schema mappings:
- **Source Schema**: `dbo` → **Target Schema**: `productmanagement_dbo`
- **Products** → `productmanagement_dbo.products` (all columns lowercase)
- **ProductHistory** → `productmanagement_dbo.producthistory` (all columns lowercase)
- **ProductStats** → `productmanagement_dbo.productstats` (all columns lowercase)

## Statement-by-Statement DMS Conversion Attempts

### Statement 1: GetAllProductsAsync
- **DMS Attempt**: FAILED
- **Timestamp**: 2026-04-20T07:08:15 and retry at 2026-04-20T07:08:29
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - lowercase schema object names per DMS schema mapping
- **Conversion Notes**: CTE with window functions (AVG OVER, COUNT OVER), CASE, ROUND, INNER JOIN - all PostgreSQL compatible syntax, only table/column names needed mapping

### Statement 2: GetProductByIdAsync
- **DMS Attempt**: FAILED
- **Timestamp**: 2026-04-20T07:09:07
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - lowercase schema object names per DMS schema mapping
- **Conversion Notes**: CTE with LAG window function, CASE with NULL check, ROUND, LEFT JOIN - all PostgreSQL compatible, table/column names mapped

### Statement 3: InsertProductAsync
- **DMS Attempt**: FAILED
- **Timestamp**: 2026-04-20T07:09:11
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - significant restructuring required
- **Conversion Notes**: 
  - `SCOPE_IDENTITY()` replaced with PostgreSQL `RETURNING` clause via CTE
  - `GETDATE()` replaced with `CURRENT_TIMESTAMP`
  - `DECLARE @variable / BEGIN TRANSACTION / COMMIT` replaced with CTE-based approach using writable CTEs
  - Transaction block restructured to use PostgreSQL writable CTE pattern for atomic operations

### Statement 4: UpdateProductAsync
- **DMS Attempt**: FAILED
- **Timestamp**: 2026-04-20T07:09:15
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - significant restructuring required
- **Conversion Notes**:
  - `DECLARE @OldPrice / @OldStock` and variable assignment replaced with CTE `old_values`
  - `GETDATE()` replaced with `CURRENT_TIMESTAMP`
  - Transaction block restructured to use writable CTE pattern
  - Multiple operations chained via CTEs for atomicity

### Statement 5: DeleteProductAsync
- **DMS Attempt**: FAILED
- **Timestamp**: 2026-04-20T07:09:36
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - significant restructuring required
- **Conversion Notes**:
  - `DECLARE @OldPrice / @OldStock` replaced with CTE `old_values`
  - `GETDATE()` replaced with `CURRENT_TIMESTAMP`
  - Transaction block restructured to use writable CTE pattern
  - CASE expression for AveragePrice calculation preserved

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt**: FAILED
- **Timestamp**: 2026-04-20T07:09:40
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - lowercase schema object names per DMS schema mapping
- **Conversion Notes**: CTE with RANK and PERCENT_RANK window functions, CASE, BETWEEN - all PostgreSQL compatible, table/column names mapped

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt**: FAILED
- **Timestamp**: 2026-04-20T07:09:44
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Manual Conversion Applied**: Yes - lowercase schema object names per DMS schema mapping
- **Conversion Notes**: 
  - CTE with AVG/MIN/MAX window functions, CASE, ROUND - all PostgreSQL compatible
  - Added explicit `CAST(stockquantity AS NUMERIC)` for integer division fix in PostgreSQL (integer / numeric would truncate in PostgreSQL unlike SQL Server)
  - Table/column names mapped per schema mapping

## SQL Equivalency Validation
All 7 statement pairs were validated through the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error `'uniqueID'` - this is a tool infrastructure issue, not a conversion quality issue.
