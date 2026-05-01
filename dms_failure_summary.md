# DMS Conversion Failure Summary
## Date: 2026-05-01
## Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}

All 7 SQL statements from ProductRepository.cs were submitted to the DMS MCP tool (dms-mcp___statement_conversion_tool) 
and all returned the same error. Manual conversion was applied with lowercase schema object names as per schema mapping tool results.

### Schema Mapping Tool Results (Successful):
- Products -> productmanagement_dbo.products (all lowercase columns)
- ProductHistory -> productmanagement_dbo.producthistory (all lowercase columns) 
- ProductStats -> productmanagement_dbo.productstats (all lowercase columns)

### Statements with DMS Failures:

1. **GetAllProductsAsync** - CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
   - DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
   - Manual Conversion: Lowercase all schema objects, CTE name changed to avoid conflict with table name

2. **GetProductByIdAsync** - CTE with LAG window function, LEFT JOIN, CASE, ROUND
   - DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
   - Manual Conversion: Lowercase all schema objects

3. **InsertProductAsync** - Transaction with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
   - DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
   - Manual Conversion: Replaced SCOPE_IDENTITY() with INSERT...RETURNING, GETDATE() with NOW(), used writable CTE pattern

4. **UpdateProductAsync** - Transaction with DECLARE, SELECT INTO vars, UPDATE, GETDATE()
   - DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
   - Manual Conversion: Replaced DECLARE/SET with CTE subquery, GETDATE() with NOW(), used writable CTE pattern

5. **DeleteProductAsync** - Transaction with DECLARE, SELECT INTO vars, DELETE, CASE, GETDATE()
   - DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
   - Manual Conversion: Replaced DECLARE/SET with CTE subquery, GETDATE() with NOW(), used writable CTE pattern

6. **GetProductsByPriceRangeAsync** - CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
   - DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
   - Manual Conversion: Lowercase all schema objects, window functions compatible

7. **GetLowStockProductsAsync** - CTE with AVG/MIN/MAX window functions, CASE, ROUND
   - DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
   - Manual Conversion: Lowercase all schema objects, added ::numeric cast for integer division in ROUND
