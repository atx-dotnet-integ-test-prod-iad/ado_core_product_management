# DMS Conversion Failure Summary

## DMS Tool Error
All 7 SQL statements failed conversion through the DMS MCP tool with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Migration Project Details
- ARN: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- Region: us-east-1
- Source Database: ProductManagement (SQL Server 2019)
- Target Database: postgres (PostgreSQL 13)
- Schema: dbo

## Attempts Made
Each statement was attempted at least once through the DMS tool. Statement 1 (GetAllProductsAsync) was attempted 3 times with increasing poll intervals (10s, 15s, 30s). All attempts failed with the same metadata model creation error.

## Manual Conversion Approach
Per transformation definition: "ONLY IF DMS FAILS: Use your own judgment to convert the statement, applying lowercase schema object names"

### Conversion Rules Applied:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. SCOPE_IDENTITY() → lastval()
3. GETDATE() → NOW()
4. BEGIN TRANSACTION → BEGIN
5. DECLARE @variable approach → subquery approach (PostgreSQL doesn't support T-SQL DECLARE in plain SQL batches)
6. ROUND function → ROUND with numeric cast where needed for integer division
7. CTE, Window Functions (AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX) → kept as-is (PostgreSQL compatible)
8. CASE expressions → kept as-is (PostgreSQL compatible)
9. Parameter syntax (@ParameterName) → kept as-is (Npgsql supports @param syntax)

## Statement Conversion Details

| # | Method | Statement | DMS Error | Manual Conversion Notes |
|---|--------|-----------|-----------|------------------------|
| 1 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | GetAllProductsAsync | Metadata model creation failed | Lowercase schema, no functional changes needed |
| 2 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | GetProductByIdAsync | Metadata model creation failed | Lowercase schema, no functional changes needed |
| 3 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | InsertProductAsync | Metadata model creation failed | SCOPE_IDENTITY()→lastval(), GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN |
| 4 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | UpdateProductAsync | Metadata model creation failed | DECLARE/@var→subquery, GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN |
| 5 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | DeleteProductAsync | Metadata model creation failed | DECLARE/@var→subquery, GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN, reordered to capture values before delete |
| 6 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | GetProductsByPriceRangeAsync | Metadata model creation failed | Lowercase schema, no functional changes needed |
| 7 | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA | GetLowStockProductsAsync | Metadata model creation failed | Lowercase schema, added ::numeric cast for integer division in ROUND |
