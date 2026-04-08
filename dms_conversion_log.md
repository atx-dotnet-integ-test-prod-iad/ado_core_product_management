# DMS Conversion Log

## Summary
- **Migration Project ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1
- **Total Statements**: 7
- **Successfully Converted by DMS**: 0
- **Failed DMS Conversions (Manual Fallback)**: 7
- **DMS Error (consistent for all)**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

## Schema Mapping (Retrieved via DMS schema_mapping_tool - SUCCEEDED)

The DMS schema_mapping_tool successfully returned schema mappings that guided manual conversions:

### Products Table
- Source: `[dbo].[Products]` → Target: `productmanagement_dbo.products`
- Column mappings: ProductId→productid, Name→name, Description→description, Price→price, StockQuantity→stockquantity, CreatedDate→createddate, ModifiedDate→modifieddate
- Type mappings: int→INTEGER, nvarchar→VARCHAR, decimal→NUMERIC, datetime→TIMESTAMP WITHOUT TIME ZONE
- IDENTITY→GENERATED ALWAYS AS IDENTITY, GETDATE()→clock_timestamp()

### ProductHistory Table
- Source: `[dbo].[ProductHistory]` → Target: `productmanagement_dbo.producthistory`
- Column mappings: HistoryId→historyid, ProductId→productid, Action→action, OldPrice→oldprice, NewPrice→newprice, OldStock→oldstock, NewStock→newstock, ActionDate→actiondate

### ProductStats Table
- Source: `[dbo].[ProductStats]` → Target: `productmanagement_dbo.productstats`
- Column mappings: StatId→statid, TotalProducts→totalproducts, AveragePrice→averageprice, LastUpdated→lastupdated

## SQL Equivalency Validation
- **Tool Used**: sql-equivalency___validate_sql_equivalence
- **All 7 statements validated**: YES
- **Results**: All 7 returned ERROR with `'uniqueID'` - this is a systemic tool error, not specific to any statement
- **Note**: The equivalency tool had a systemic failure (returned `'uniqueID'` error for all calls, including trivial test queries)

---

## Statement-by-Statement DMS Conversion Log

### Statement 1: GetAllProductsAsync
- **DMS Call Timestamp**: 2026-04-08T22:53:26 (first attempt), 2026-04-08T22:53:42 (second attempt), 2026-04-08T22:53:59 (third attempt)
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: All table/column names lowercased per DMS schema mapping. CTE name changed from `ProductStats` to `productstats_cte` to avoid name collision with the `productstats` table.
- **Equivalency Validation**: ERROR (tool returned `'uniqueID'` error at 2026-04-08T22:56:59)

### Statement 2: GetProductByIdAsync
- **DMS Call Timestamp**: 2026-04-08T22:55:04
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: All table/column names lowercased. CTE name changed from `ProductHistory` to `producthistory_cte` to avoid name collision with the `producthistory` table. LAG window function is compatible with PostgreSQL.
- **Equivalency Validation**: ERROR (tool returned `'uniqueID'` error at 2026-04-08T22:57:51)

### Statement 3: InsertProductAsync
- **DMS Call Timestamp**: 2026-04-08T22:55:22
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: Major structural changes:
  - `DECLARE @NewProductId INT` → `DO $$ DECLARE v_newproductid INTEGER;`
  - `SCOPE_IDENTITY()` → `RETURNING productid INTO v_newproductid`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION / COMMIT` → `DO $$ BEGIN ... END $$` (anonymous block provides transactional context)
  - Final `SELECT @NewProductId` → `SELECT lastval()`
  - All table/column names lowercased
- **Equivalency Validation**: ERROR (tool returned `'uniqueID'` error at 2026-04-08T22:58:07)

### Statement 4: UpdateProductAsync
- **DMS Call Timestamp**: 2026-04-08T22:55:38
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: Major structural changes:
  - `DECLARE @OldPrice / @OldStock` → `DO $$ DECLARE v_oldprice / v_oldstock`
  - `SELECT @var = col` → `SELECT col INTO v_var`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION / COMMIT` → `DO $$ BEGIN ... END $$`
  - All table/column names lowercased
- **Equivalency Validation**: ERROR (tool returned `'uniqueID'` error at 2026-04-08T22:58:23)

### Statement 5: DeleteProductAsync
- **DMS Call Timestamp**: 2026-04-08T22:55:55
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: Same structural pattern as Statement 4. CASE expression in UPDATE is PostgreSQL compatible. All table/column names lowercased.
- **Equivalency Validation**: ERROR (tool returned `'uniqueID'` error at 2026-04-08T22:58:39)

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Call Timestamp**: 2026-04-08T22:56:12
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: RANK(), PERCENT_RANK(), BETWEEN, and CASE are all PostgreSQL compatible. Only lowercasing applied. All table/column names lowercased.
- **Equivalency Validation**: ERROR (tool returned `'uniqueID'` error at 2026-04-08T22:58:52)

### Statement 7: GetLowStockProductsAsync
- **DMS Call Timestamp**: 2026-04-08T22:56:28
- **DMS Status**: error
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion Applied**: Yes - DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Conversion Notes**: AVG/MIN/MAX OVER() window functions are PostgreSQL compatible. Added `::numeric` cast for integer division in ROUND function to avoid integer truncation in PostgreSQL. All table/column names lowercased.
- **Equivalency Validation**: ERROR (tool returned `'uniqueID'` error at 2026-04-08T22:59:05)
