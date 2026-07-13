# SQL Server to PostgreSQL Migration Report

## Summary
- **Total SQL statements processed**: 7
- **Successfully converted by DMS**: 0
- **Manual conversion (DMS failure)**: 7
- **Equivalency validated as EQUIVALENT**: 0
- **Equivalency validated as NOT_EQUIVALENT**: 0
- **Equivalency validation ERROR**: 7

## DMS Tool Failure Details
All 7 statements failed DMS conversion due to infrastructure issues:
- Error Type 1: "Metadata model creation did not complete after 15 attempts" (5 statements)
- Error Type 2: "DMS Schema Conversion can't access the S3 resource" (2 statements)

## Manual Conversion Approach
Since DMS failed for all statements, manual conversion was applied with the following rules:
- All schema object names converted to lowercase (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
- SCOPE_IDENTITY() replaced with RETURNING clause
- GETDATE() replaced with NOW()
- Transaction blocks using DECLARE converted to DO $$ blocks with PL/pgSQL
- Integer division in ROUND() converted with ::numeric cast where needed
- SQL Server-specific syntax (SET NOCOUNT ON, GO, IF EXISTS sys.objects) replaced with PostgreSQL equivalents

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency validation tool.
All returned ERROR status with error: "'uniqueID'" - indicating a tool-side issue unrelated to statement quality.

## Files Modified
1. **DataAccess/ProductRepository.cs** - Replaced Microsoft.Data.SqlClient with Npgsql, converted all SQL statements
2. **AdoCore.csproj** - Replaced Microsoft.Data.SqlClient v5.1.4 with Npgsql v8.0.3
3. **appsettings.json** - Updated connection strings from SQL Server to PostgreSQL format
4. **Database/Scripts/01_InitialSetup.sql** - Converted full schema DDL to PostgreSQL
5. **Scripts/01_InitialSetup.sql** - Converted simple schema DDL to PostgreSQL

## Conversion Details per Statement

### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG OVER, COUNT OVER)
- **Changes**: Lowercase schema objects, compatible syntax preserved
- **DMS Error**: Metadata model creation timeout

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function
- **Changes**: Lowercase schema objects, compatible syntax preserved
- **DMS Error**: Metadata model creation timeout

### Statement 3: InsertProductAsync
- **Type**: Transaction block with SCOPE_IDENTITY()
- **Changes**: Replaced with CTE + RETURNING pattern, GETDATE() → NOW()
- **DMS Error**: S3 access failure

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with variables
- **Changes**: Converted to DO $$ block with PL/pgSQL, GETDATE() → NOW()
- **DMS Error**: Metadata model creation timeout

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with variables and CASE expression
- **Changes**: Converted to DO $$ block with PL/pgSQL, GETDATE() → NOW()
- **DMS Error**: Metadata model creation timeout

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK and PERCENT_RANK window functions
- **Changes**: Lowercase schema objects, compatible syntax preserved
- **DMS Error**: S3 access failure

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX OVER window functions
- **Changes**: Lowercase schema objects, added ::numeric cast for integer division
- **DMS Error**: Metadata model creation timeout
