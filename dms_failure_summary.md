# DMS Conversion Failure Summary
## Date: 2026-04-08

All 7 SQL statements from ProductRepository.cs were submitted to the DMS MCP statement_conversion_tool.
All 7 attempts failed with metadata model creation/conversion timeout errors.

Manual conversion was applied with lowercase schema object names per transformation rules.
Reason code: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

## Statement 1: GetAllProductsAsync
- **DMS Error**: "Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}"
- **Manual Conversion**: Applied lowercase schema object names. CTE window functions (AVG OVER, COUNT OVER) are PostgreSQL compatible.

## Statement 2: GetProductByIdAsync
- **DMS Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Manual Conversion**: Applied lowercase schema object names. LAG() window function is PostgreSQL compatible.

## Statement 3: InsertProductAsync
- **DMS Error**: "Command execution timed out after 300 seconds"
- **Manual Conversion**: SCOPE_IDENTITY() replaced with INSERT...RETURNING. GETDATE() replaced with NOW(). Applied lowercase schema object names. Restructured from single batch to separate statements for C# ADO.NET execution.

## Statement 4: UpdateProductAsync
- **DMS Error**: "Command execution timed out after 300 seconds"
- **Manual Conversion**: DECLARE/SET variable pattern restructured for PostgreSQL. GETDATE() replaced with NOW(). Applied lowercase schema object names.

## Statement 5: DeleteProductAsync
- **DMS Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Manual Conversion**: DECLARE/SET variable pattern restructured for PostgreSQL. GETDATE() replaced with NOW(). Applied lowercase schema object names. CASE expression in UPDATE preserved (PostgreSQL compatible).

## Statement 6: GetProductsByPriceRangeAsync
- **DMS Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Manual Conversion**: Applied lowercase schema object names. RANK(), PERCENT_RANK(), BETWEEN are PostgreSQL compatible.

## Statement 7: GetLowStockProductsAsync
- **DMS Error**: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
- **Manual Conversion**: Applied lowercase schema object names. AVG/MIN/MAX OVER() are PostgreSQL compatible. Added CAST for integer division in ROUND().
