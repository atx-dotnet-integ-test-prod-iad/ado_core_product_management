# DMS Conversion Log

## Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions Required**: 7
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

All 7 statements were passed to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with `schema_name='dbo'`. All failed with the same systemic error. Manual conversion was applied with lowercase schema object names per the transformation plan's fallback instructions.

---

## Statement 1: GetAllProductsAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-22T11:32:45.502649
- **Manual Conversion**: Applied lowercase schema objects
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All table/column/alias names lowercased

## Statement 2: GetProductByIdAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-22T11:33:22.676099
- **Manual Conversion**: Applied lowercase schema objects
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All table/column/alias names lowercased

## Statement 3: InsertProductAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-22T11:33:37.691672
- **Manual Conversion**: Applied lowercase schema objects + SQL syntax changes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause on INSERT
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION`/`COMMIT` → handled at application level (Npgsql transaction)
  - `DECLARE @NewProductId INT` → variable captured via RETURNING in C# code
  - All table/column names lowercased

## Statement 4: UpdateProductAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-22T11:33:52.559198
- **Manual Conversion**: Applied lowercase schema objects + SQL syntax changes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice`/`@OldStock` + `SELECT INTO` → separate SELECT query in C# code
  - `BEGIN TRANSACTION`/`COMMIT` → handled at application level (Npgsql transaction)
  - All table/column names lowercased

## Statement 5: DeleteProductAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-22T11:34:07.114096
- **Manual Conversion**: Applied lowercase schema objects + SQL syntax changes
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - `GETDATE()` → `NOW()`
  - `DECLARE @OldPrice`/`@OldStock` + `SELECT INTO` → separate SELECT query in C# code
  - `BEGIN TRANSACTION`/`COMMIT` → handled at application level (Npgsql transaction)
  - `CASE` expression in UPDATE preserved (PostgreSQL compatible)
  - All table/column names lowercased

## Statement 6: GetProductsByPriceRangeAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-22T11:34:22.515424
- **Manual Conversion**: Applied lowercase schema objects
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: All table/column/alias names lowercased. RANK(), PERCENT_RANK(), BETWEEN are PostgreSQL compatible.

## Statement 7: GetLowStockProductsAsync
- **DMS Status**: FAILED
- **DMS Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Timestamp**: 2026-04-22T11:34:37.481000
- **Manual Conversion**: Applied lowercase schema objects + CAST for integer division
- **Conversion Reason**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - All table/column/alias names lowercased
  - Added `CAST(stockquantity AS DECIMAL)` to prevent integer division in `ROUND((stockquantity / avgstock) * 100, 2)`
  - AVG/MIN/MAX OVER() window functions are PostgreSQL compatible

---

## SQL Equivalency Validation Summary
All 7 statement pairs were validated through the `sql-equivalency___validate_sql_equivalence` tool.
All returned: `{"equivalence_status": "ERROR", "error": "'uniqueID'"}`

This appears to be a systemic issue with the SQL Equivalency tool, not related to the quality of conversion.
Per plan instructions: equivalency status marked as ERROR for all statements (tool output used, not agent judgment).
