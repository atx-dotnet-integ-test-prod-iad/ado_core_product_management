# DMS Conversion Log

## Summary
- **Total Statements**: 7
- **DMS Successful Conversions**: 0
- **DMS Failed Conversions**: 7
- **Manual Conversions (DMS Failure)**: 7
- **DMS Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

## Statement 1: GetAllProductsAsync

**DMS Call Timestamp**: 2026-03-21T07:36:35.852473
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Manual Conversion Notes**:
- CTE and window functions (AVG OVER, COUNT OVER) are compatible with PostgreSQL
- CASE and ROUND syntax are compatible with PostgreSQL
- Applied lowercase to all schema object names (Products→products, ProductId→productid, etc.)

---

## Statement 2: GetProductByIdAsync

**DMS Call Timestamp**: 2026-03-21T07:47:17.585529
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Manual Conversion Notes**:
- LAG window function is compatible with PostgreSQL
- CASE with NULL handling and ROUND are compatible
- Applied lowercase to all schema object names

---

## Statement 3: InsertProductAsync

**DMS Call Timestamp**: 2026-03-21T07:50:02.170087
**DMS Status**: error
**DMS Error**: Metadata model creation failed: {'error': "Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}"}
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Manual Conversion Notes**:
- SCOPE_IDENTITY() replaced with INSERT...RETURNING clause (PostgreSQL idiom)
- GETDATE() replaced with NOW()
- DECLARE @variable pattern replaced with PostgreSQL variable handling
- Transaction block restructured for C# ADO.NET execution (individual statements with RETURNING)
- Applied lowercase to all schema object names

---

## Statement 4: UpdateProductAsync

**DMS Call Timestamp**: 2026-03-21T07:52:14.053723
**DMS Status**: error
**DMS Error**: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Manual Conversion Notes**:
- DECLARE @variable pattern replaced with PostgreSQL variable handling
- GETDATE() replaced with NOW()
- SELECT INTO variable syntax adapted for PostgreSQL
- Transaction managed at C# ADO.NET level
- Applied lowercase to all schema object names

---

## Statement 5: DeleteProductAsync

**DMS Call Timestamp**: 2026-03-21T07:56:05.811369
**DMS Status**: error
**DMS Error**: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Manual Conversion Notes**:
- DECLARE @variable pattern replaced with PostgreSQL variable handling
- GETDATE() replaced with NOW()
- CASE WHEN compatible with PostgreSQL
- Transaction managed at C# ADO.NET level
- Applied lowercase to all schema object names

---

## Statement 6: GetProductsByPriceRangeAsync

**DMS Call Timestamp**: 2026-03-21T08:01:04.314470
**DMS Status**: error
**DMS Error**: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Manual Conversion Notes**:
- RANK() and PERCENT_RANK() window functions are compatible with PostgreSQL
- BETWEEN and CASE syntax are compatible
- Applied lowercase to all schema object names

---

## Statement 7: GetLowStockProductsAsync

**DMS Call Timestamp**: 2026-03-21T08:06:00.347746
**DMS Status**: error
**DMS Error**: Metadata model conversion failed: {'error': 'Metadata model conversion did not complete after 15 attempts'}
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Manual Conversion Notes**:
- AVG/MIN/MAX OVER() window functions are compatible with PostgreSQL
- CASE and ROUND syntax are compatible
- Added CAST for integer division in ROUND to avoid PostgreSQL integer division truncation
- Applied lowercase to all schema object names
