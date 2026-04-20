# DMS Conversion Failure Summary

## DMS Tool Error
All 7 SQL statements failed to convert through the DMS MCP tool (dms-mcp___statement_conversion_tool).

**Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**DMS Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

**Region**: us-east-1

**Attempts**: Each statement was attempted at least once with various configurations including:
- Default poll settings (15 attempts, 10s interval)
- Extended poll settings (30-40 attempts, 15-30s interval)
- Explicit database_name and server_name parameters

## Manual Conversion Applied
Per transformation definition guidelines, all 7 statements were manually converted with the following approach:
- **Conversion method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- All schema object names (tables, columns, aliases) converted to lowercase
- SQL Server functions converted to PostgreSQL equivalents:
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @var` → removed (PostgreSQL doesn't support inline DECLARE in plain SQL)
  - Variable assignments replaced with subqueries
- Window functions (AVG OVER, COUNT OVER, LAG, RANK, PERCENT_RANK) preserved (compatible)
- CASE expressions preserved (compatible)
- ROUND function preserved with CAST for integer division where needed

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All 7 returned ERROR status with error: `'uniqueID'`

## Statements Converted

| # | Method | Source Location | DMS Error | Equivalency Status |
|---|--------|----------------|-----------|-------------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | Metadata model creation failed | ERROR |
| 2 | GetProductByIdAsync | ProductRepository.cs | Metadata model creation failed | ERROR |
| 3 | InsertProductAsync | ProductRepository.cs | Metadata model creation failed | ERROR |
| 4 | UpdateProductAsync | ProductRepository.cs | Metadata model creation failed | ERROR |
| 5 | DeleteProductAsync | ProductRepository.cs | Metadata model creation failed | ERROR |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | Metadata model creation failed | ERROR |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | Metadata model creation failed | ERROR |
