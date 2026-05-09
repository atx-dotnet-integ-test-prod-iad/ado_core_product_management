# DMS Conversion Summary

## Overview
All 7 SQL statements were submitted to the DMS MCP tool for conversion from MS SQL Server to PostgreSQL.
All 7 statements failed with the same error. Manual conversion was performed with lowercase schema mapping.

## DMS Error Details
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Timestamps**: 2026-05-09T22:40:33 through 2026-05-09T22:41:06
- **Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

## Statements Processed

| # | Method | Source Location | Description |
|---|--------|----------------|-------------|
| 1 | GetAllProductsAsync | ProductRepository.cs | CTE with AVG/COUNT OVER, CASE, ROUND, JOIN |
| 2 | GetProductByIdAsync | ProductRepository.cs | CTE with LAG window function, LEFT JOIN |
| 3 | InsertProductAsync | ProductRepository.cs | Transaction with INSERT, SCOPE_IDENTITY, UPDATE |
| 4 | UpdateProductAsync | ProductRepository.cs | Transaction with SELECT, UPDATE, INSERT |
| 5 | DeleteProductAsync | ProductRepository.cs | Transaction with SELECT, INSERT, DELETE, UPDATE |
| 6 | GetProductsByPriceRangeAsync | ProductRepository.cs | CTE with RANK, PERCENT_RANK, BETWEEN |
| 7 | GetLowStockProductsAsync | ProductRepository.cs | CTE with AVG/MIN/MAX OVER, ROUND |

## Manual Conversion Applied (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

### Key Transformations:
1. **Schema object names**: All converted to lowercase (Products -> products, ProductId -> productid, etc.)
2. **SCOPE_IDENTITY()**: Replaced with `RETURNING productid` clause
3. **GETDATE()**: Replaced with `NOW()`
4. **BEGIN TRANSACTION/COMMIT**: Replaced with application-level transaction management via `BeginTransactionAsync()`/`CommitAsync()`
5. **DECLARE @variable / SET @variable**: Replaced with application-level C# variables
6. **Integer division**: Added `::numeric` cast where needed for proper ROUND behavior
7. **NVARCHAR**: Mapped to VARCHAR in PostgreSQL
8. **DATETIME**: Mapped to TIMESTAMP in PostgreSQL
9. **INT IDENTITY(1,1)**: Mapped to SERIAL in PostgreSQL

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool for validation.
All 7 returned ERROR status with error: "'uniqueID'" - this appears to be a systemic issue with the tool.
No statements could be validated as EQUIVALENT or NOT_EQUIVALENT due to this tool error.
