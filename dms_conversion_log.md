# DMS Conversion Failure Log

## Summary
All 7 SQL statements failed DMS conversion due to infrastructure issues (metadata model creation failures and S3 access errors).
Manual conversion was applied using lowercase schema object naming for PostgreSQL compatibility.

## DMS Error Details

### Statements 1, 2, 4, 5, 7:
- Error: "Metadata model creation failed: Metadata model creation did not complete after 15 attempts"

### Statements 3, 6:
- Error: "Metadata model creation failed: DMS Schema Conversion can't access the S3 resource 'atx-db-modernization-789616364195-us-east-1'. Verify that the IAM role has permission to access this S3 resource."

## Manual Conversion Approach
Since DMS failed for all statements, manual conversion was applied with:
1. All schema object names (tables, columns, aliases) converted to lowercase
2. SCOPE_IDENTITY() replaced with INSERT...RETURNING pattern using writable CTEs
3. GETDATE() replaced with NOW()
4. DECLARE/@variable transaction blocks restructured as writable CTEs
5. BEGIN TRANSACTION/COMMIT removed (writable CTEs are atomic; C# transaction handling preserved)
6. Integer division cast to numeric where needed (::numeric)
7. CAST(x AS DECIMAL) replaced with x::numeric

## SQL Equivalency Validation
All 7 statement pairs were submitted to the SQL Equivalency tool.
All 7 returned ERROR status with error: "'uniqueID'" (tool-side error, not related to SQL quality).
Per transformation instructions, these are marked as ERROR in the equivalency report.

## Migration Report Summary
- Total SQL statements processed: 7
- Statements successfully converted by DMS: 0
- Statements requiring manual intervention: 7
- Statements validated as equivalent: 0
- Statements validated as non-equivalent: 0
- Statements with equivalency validation errors: 7
