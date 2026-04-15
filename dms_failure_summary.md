# DMS Conversion Failure Summary
# Date: 2026-04-15
# Migration Project ARN: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

## DMS Statement Conversion Tool Failure
All 7 SQL statements failed DMS conversion with the same error:
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Step Failed At**: create_metadata_model
- **Attempts**: Multiple attempts per statement with varying poll intervals (10s, 30s) and max attempts (15, 20)

## DMS Schema Mapping Tool (Success)
The DMS Schema Mapping Tool (dms-mcp___schema_mapping_tool) was successful and provided:
- Products -> productmanagement_dbo.products
- ProductHistory -> productmanagement_dbo.producthistory
- ProductStats -> productmanagement_dbo.productstats

## Manual Conversion Approach
Since DMS statement conversion failed, all 7 statements were manually converted using:
1. Schema mappings from DMS Schema Mapping Tool
2. Lowercase schema object naming convention per PostgreSQL standards
3. SQL Server to PostgreSQL syntax translations:
   - SCOPE_IDENTITY() -> RETURNING clause
   - GETDATE() -> NOW()
   - DECLARE @var / SET @var -> Restructured to separate queries
   - BEGIN TRANSACTION / COMMIT -> Managed via C# transaction API
   - ROUND with decimal -> ROUND with CAST to NUMERIC for PostgreSQL compatibility
   - Column/table names -> lowercase per DMS schema mapping

## SQL Equivalency Tool Results
All 7 statement pairs returned ERROR from the equivalency tool:
- **Error**: 'uniqueID'
- **Note**: This appears to be a tool-side error, not a statement-level issue
- **All statuses marked as**: ERROR (per transformation definition requirements)

## Statements Processed

### Statement 1: GetAllProductsAsync
- **DMS Input**: CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, ROUND with CAST

### Statement 2: GetProductByIdAsync
- **DMS Input**: CTE with LAG window functions, CASE, ROUND, LEFT JOIN, parameterized
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, ROUND with CAST

### Statement 3: InsertProductAsync
- **DMS Input**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: RETURNING clause, NOW(), separate commands in C# transaction

### Statement 4: UpdateProductAsync
- **DMS Input**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE()
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: SELECT INTO, NOW(), separate commands in C# transaction

### Statement 5: DeleteProductAsync
- **DMS Input**: Transaction block with DECLARE, SELECT INTO, INSERT, DELETE, UPDATE, CASE
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: SELECT INTO, NOW(), separate commands in C# transaction

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Input**: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects

### Statement 7: GetLowStockProductsAsync
- **DMS Input**: CTE with AVG/MIN/MAX window functions, CASE, ROUND, parameterized
- **DMS Output**: Error - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, ROUND with CAST
