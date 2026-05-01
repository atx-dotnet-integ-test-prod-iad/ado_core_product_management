-- ============================================================
-- DMS FAILURE SUMMARY
-- All 7 SQL statements were submitted to DMS MCP tool for conversion
-- All 7 statements failed with the same error
-- Manual conversion applied with lowercase schema object names
-- ============================================================

-- DMS Error (consistent across all 7 statements):
-- Status: error
-- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Reason: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

-- Statement 1 (GetAllProductsAsync):
--   DMS Timestamp: 2026-05-01T22:40:32
--   DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--   Manual Conversion: Applied lowercase schema names, SQL syntax compatible with PostgreSQL

-- Statement 2 (GetProductByIdAsync):
--   DMS Timestamp: 2026-05-01T22:40:35
--   DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--   Manual Conversion: Applied lowercase schema names, SQL syntax compatible with PostgreSQL

-- Statement 3 (InsertProductAsync):
--   DMS Timestamp: 2026-05-01T22:40:38
--   DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--   Manual Conversion: SCOPE_IDENTITY() replaced with INSERT...RETURNING, GETDATE() -> NOW(),
--   Transaction restructured: split into multiple statements with C# transaction management

-- Statement 4 (UpdateProductAsync):
--   DMS Timestamp: 2026-05-01T22:40:59
--   DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--   Manual Conversion: DECLARE variables replaced with subqueries/CTE approach,
--   GETDATE() -> NOW(), transaction managed in C# code

-- Statement 5 (DeleteProductAsync):
--   DMS Timestamp: 2026-05-01T22:41:02
--   DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--   Manual Conversion: DECLARE variables replaced with subqueries/CTE approach,
--   GETDATE() -> NOW(), transaction managed in C# code

-- Statement 6 (GetProductsByPriceRangeAsync):
--   DMS Timestamp: 2026-05-01T22:41:05
--   DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--   Manual Conversion: Applied lowercase schema names, SQL syntax compatible with PostgreSQL

-- Statement 7 (GetLowStockProductsAsync):
--   DMS Timestamp: 2026-05-01T22:41:09
--   DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
--   Manual Conversion: Applied lowercase schema names, added CAST for integer division,
--   SQL syntax compatible with PostgreSQL
