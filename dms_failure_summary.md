# DMS Conversion Failure Summary
## Date: 2026-03-26

## DMS Tool Error
All 7 SQL statements failed DMS conversion with the same error:
- **Error**: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
- **Status**: error
- **Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Multiple attempts made**: Including simple SELECT statements, all failed with the same metadata model creation timeout

## SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency tool (sql-equivalency___validate_sql_equivalence).
All returned ERROR with: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`
This appears to be a backend infrastructure issue affecting all validations.

## Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied with:
- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- All schema object names converted to lowercase
- SQL Server functions converted to PostgreSQL equivalents:
  - SCOPE_IDENTITY() -> RETURNING clause with CTE
  - GETDATE() -> NOW()
  - DECLARE @var / SET @var -> CTE-based approach for Npgsql parameter compatibility
  - BEGIN TRANSACTION/COMMIT -> Managed via C# transaction (Npgsql)
  - Integer division -> ::numeric cast for proper decimal division

## Statement Details

### Statement 1: GetAllProductsAsync
- **Source**: ProductRepository.cs lines ~44-69
- **DMS Output**: Error - Metadata model creation failed
- **Manual Changes**: Lowercase schema objects, no functional SQL changes needed (CTE with window functions compatible)

### Statement 2: GetProductByIdAsync
- **Source**: ProductRepository.cs lines ~77-101
- **DMS Output**: Error - Metadata model creation failed
- **Manual Changes**: Lowercase schema objects, no functional SQL changes needed (CTE with LAG() compatible)

### Statement 3: InsertProductAsync
- **Source**: ProductRepository.cs lines ~109-134
- **DMS Output**: Error - Metadata model creation failed
- **Manual Changes**: 
  - SCOPE_IDENTITY() replaced with CTE using INSERT...RETURNING
  - GETDATE() replaced with NOW()
  - Transaction block removed (managed by C# code)
  - DECLARE/SET variable pattern replaced with CTE chaining

### Statement 4: UpdateProductAsync
- **Source**: ProductRepository.cs lines ~147-175
- **DMS Output**: Error - Metadata model creation failed
- **Manual Changes**:
  - DECLARE @OldPrice/@OldStock replaced with CTE subquery
  - GETDATE() replaced with NOW()
  - Transaction block removed (managed by C# code)
  - Variable references replaced with CTE references

### Statement 5: DeleteProductAsync
- **Source**: ProductRepository.cs lines ~183-214
- **DMS Output**: Error - Metadata model creation failed
- **Manual Changes**:
  - DECLARE @OldPrice/@OldStock replaced with CTE subquery
  - GETDATE() replaced with NOW()
  - Transaction block removed (managed by C# code)
  - Variable references replaced with CTE references

### Statement 6: GetProductsByPriceRangeAsync
- **Source**: ProductRepository.cs lines ~222-243
- **DMS Output**: Error - Metadata model creation failed
- **Manual Changes**: Lowercase schema objects, no functional SQL changes needed (RANK/PERCENT_RANK compatible)

### Statement 7: GetLowStockProductsAsync
- **Source**: ProductRepository.cs lines ~258-280
- **DMS Output**: Error - Metadata model creation failed
- **Manual Changes**: 
  - Lowercase schema objects
  - Added ::numeric cast for integer division in ROUND function
