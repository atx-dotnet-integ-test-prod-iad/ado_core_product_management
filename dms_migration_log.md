# DMS Migration Log
## DMS Tool Failures and Manual Conversions

All 7 SQL statements were passed through the DMS MCP tool (dms-mcp___statement_conversion_tool) 
and ALL failed with the same error.

### DMS Error Details
- **Migration Project ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Schema**: dbo
- **Database**: ProductManagement

### Statement-by-Statement DMS Attempts

| Statement # | Method | DMS Timestamp | DMS Status | Error |
|-------------|--------|---------------|------------|-------|
| 1 (GetAllProductsAsync) | DMS attempted, failed | 2026-05-03T14:37:03 | error | Metadata model creation failed |
| 2 (GetProductByIdAsync) | DMS attempted, failed | 2026-05-03T14:37:34 | error | Metadata model creation failed |
| 3 (InsertProductAsync) | DMS attempted, failed | 2026-05-03T14:37:49 | error | Metadata model creation failed |
| 4 (UpdateProductAsync) | DMS attempted, failed | 2026-05-03T14:38:03 | error | Metadata model creation failed |
| 5 (DeleteProductAsync) | DMS attempted, failed | 2026-05-03T14:38:17 | error | Metadata model creation failed |
| 6 (GetProductsByPriceRangeAsync) | DMS attempted, failed | 2026-05-03T14:38:31 | error | Metadata model creation failed |
| 7 (GetLowStockProductsAsync) | DMS attempted, failed | 2026-05-03T14:38:45 | error | Metadata model creation failed |

### Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied with the following rules:
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names (tables, columns, aliases) converted to lowercase
- SCOPE_IDENTITY() → lastval()
- GETDATE() → NOW()
- DECLARE @var / SET @var patterns restructured using subqueries (PostgreSQL plain SQL doesn't support variables)
- Integer division in ROUND() → CAST to NUMERIC for proper decimal results
- Transaction blocks (BEGIN TRANSACTION/COMMIT) preserved as compatible
- Window functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX with OVER) preserved as compatible
- CTE syntax preserved as compatible
- CASE expressions preserved as compatible
