-- ============================================================
-- DMS CONVERSION SUMMARY FILE
-- ============================================================
-- All 7 SQL statements were passed to the DMS MCP tool 
-- (dms-mcp___statement_conversion_tool) for conversion.
-- Migration Project ARN: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
-- Database: ProductManagement, Schema: dbo, Region: us-east-1
--
-- ALL 7 statements FAILED with the same error:
-- Error: "Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}"
--
-- Per transformation plan instructions, manual conversion was applied with:
-- - Lowercase schema object names for PostgreSQL compatibility
-- - SCOPE_IDENTITY() -> INSERT...RETURNING
-- - GETDATE() -> NOW()
-- - DECLARE/@variable patterns -> separate C# commands within transaction
-- - Integer division -> explicit ::numeric cast for ROUND
-- - Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================

-- Statement 1: GetAllProductsAsync
-- DMS Call Timestamp: 2026-03-28T23:01:54.773383
-- DMS Status: error
-- DMS Error: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
-- Manual Conversion Applied: Yes - lowercase schema, syntax preserved (PostgreSQL-compatible window functions)

-- Statement 2: GetProductByIdAsync  
-- DMS Call Timestamp: 2026-03-28T23:18:01.451282
-- DMS Status: error
-- DMS Error: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
-- Manual Conversion Applied: Yes - lowercase schema, syntax preserved

-- Statement 3: InsertProductAsync
-- DMS Call Timestamp: 2026-03-28T23:20:48.388237
-- DMS Status: error
-- DMS Error: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
-- Manual Conversion Applied: Yes - SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(), split into multi-command C# transaction

-- Statement 4: UpdateProductAsync
-- DMS Call Timestamp: 2026-03-28T23:23:34.198944
-- DMS Status: error
-- DMS Error: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
-- Manual Conversion Applied: Yes - DECLARE/@variable -> separate SELECT + C# vars, GETDATE() -> NOW()

-- Statement 5: DeleteProductAsync
-- DMS Call Timestamp: 2026-03-28T23:26:19.574244
-- DMS Status: error
-- DMS Error: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
-- Manual Conversion Applied: Yes - DECLARE/@variable -> separate SELECT + C# vars, GETDATE() -> NOW()

-- Statement 6: GetProductsByPriceRangeAsync
-- DMS Call Timestamp: 2026-03-28T23:29:06.400604
-- DMS Status: error
-- DMS Error: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
-- Manual Conversion Applied: Yes - lowercase schema, syntax preserved (PostgreSQL-compatible window functions)

-- Statement 7: GetLowStockProductsAsync
-- DMS Call Timestamp: 2026-03-28T23:31:53.508333
-- DMS Status: error
-- DMS Error: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
-- Manual Conversion Applied: Yes - lowercase schema, integer division fix (::numeric cast)
