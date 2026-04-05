===============================================================
FINAL MIGRATION REPORT
SQL Server to PostgreSQL Migration for ADO.NET Core Application
===============================================================
Date: 2026-04-05
Source Database: Microsoft SQL Server 2019
Target Database: PostgreSQL 13
Application: AdoCore (.NET 9.0)
===============================================================

1. SUMMARY
===============================================================
Total SQL statements processed: 7
Statements successfully converted by DMS MCP tool: 0
Statements requiring manual intervention (DMS failure): 7
Statements validated as equivalent by SQL Equivalency tool: 0
Statements validated as non-equivalent: 0
Statements with equivalency validation errors: 7

2. DMS CONVERSION RESULTS
===============================================================
DMS Migration Project ARN: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
DMS Status: ALL FAILED - Metadata model creation/conversion timed out

All 7 statements were attempted through the DMS MCP tool first (as required).
DMS consistently failed due to metadata model creation/conversion timeouts.
Manual conversion was applied with lowercase schema object names per
DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA rule.

3. SQL EQUIVALENCY VALIDATION RESULTS
===============================================================
Tool: sql-equivalency___validate_sql_equivalence
Status: ALL ERROR - Tool returned "'uniqueID'" service error for all 7 statements

Each statement pair was submitted to the equivalency tool independently.
All 7 returned the same ERROR status. This appears to be a service-side issue.
Per the transformation definition, errors are marked as ERROR in the report.

4. STATEMENT-BY-STATEMENT DETAILS
===============================================================

Statement 1: GetAllProductsAsync
- Source: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
- Changes: Lowercase schema objects only
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Equivalency: ERROR

Statement 2: GetProductByIdAsync  
- Source: CTE with LAG window function, LEFT JOIN, CASE, ROUND
- Changes: Lowercase schema objects only
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Equivalency: ERROR

Statement 3: InsertProductAsync
- Source: DECLARE/SCOPE_IDENTITY()/BEGIN TRANSACTION/GETDATE()
- Changes: Writable CTE with INSERT...RETURNING, NOW() for GETDATE()
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Equivalency: ERROR

Statement 4: UpdateProductAsync
- Source: BEGIN TRANSACTION/DECLARE @var/SELECT INTO @var/GETDATE()
- Changes: Writable CTE capturing old values, NOW() for GETDATE()
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Equivalency: ERROR

Statement 5: DeleteProductAsync
- Source: BEGIN TRANSACTION/DECLARE @var/SELECT INTO @var/GETDATE()/CASE
- Changes: Writable CTE, DELETE...RETURNING, NOW() for GETDATE()
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Equivalency: ERROR

Statement 6: GetProductsByPriceRangeAsync
- Source: CTE with RANK/PERCENT_RANK, BETWEEN, CASE
- Changes: Lowercase schema objects only
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Equivalency: ERROR

Statement 7: GetLowStockProductsAsync
- Source: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- Changes: Lowercase + CAST(stockquantity AS DECIMAL) for integer division
- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- Equivalency: ERROR

5. FILE CHANGES MADE
===============================================================

Modified files:
- sourceCode/DataAccess/ProductRepository.cs
  * 7 SQL string literals replaced with PostgreSQL equivalents
  * `using Microsoft.Data.SqlClient` → `using Npgsql`
  * `SqlConnection` → `NpgsqlConnection` (3 occurrences)
  * `SqlCommand` → `NpgsqlCommand` (7 occurrences)
  * `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)

- sourceCode/AdoCore.csproj
  * `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6`
  * (8.0.0 had known vulnerability GHSA-x9vc-6hfv-hg8c, upgraded to 8.0.6)

- sourceCode/appsettings.json
  * `Server=localhost` → `Host=localhost`
  * Removed: `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
  * Added: `Username=postgres;Password=postgres`

- sourceCode/README.md
  * Updated all references from SQL Server to PostgreSQL
  * Updated prerequisites, setup instructions, connection strings
  * Updated deployment and troubleshooting sections

Created files:
- sourceCode/extracted_statements.sql (7 original MS SQL statements)
- sourceCode/converted_statements.sql (7 converted PostgreSQL statements)
- sourceCode/sql_equivalency_validation_report.json (comprehensive report)
- sourceCode/dms_failure_summary.log (DMS failure details)

6. KEY CONVERSION PATTERNS APPLIED
===============================================================
| MS SQL Pattern           | PostgreSQL Equivalent              |
|-------------------------|------------------------------------|
| SCOPE_IDENTITY()        | INSERT...RETURNING productid       |
| GETDATE()               | NOW()                              |
| DECLARE @var / SET @var | Writable CTEs / subqueries         |
| BEGIN TRANSACTION/COMMIT| Managed by Npgsql (C# layer)      |
| INT division            | CAST(int AS DECIMAL) / int         |
| SqlConnection           | NpgsqlConnection                   |
| SqlCommand              | NpgsqlCommand                      |
| SqlDataReader           | NpgsqlDataReader                   |
| Server=                 | Host=                              |
| Trusted_Connection      | Username/Password auth             |

7. BUILD STATUS
===============================================================
Final build: SUCCEEDED
Errors: 0
Warnings: 10 (all pre-existing nullable reference warnings, not migration-related)

8. MANUAL INTERVENTIONS REQUIRED
===============================================================
- All 7 SQL statements required manual conversion due to DMS tool failure
- All 7 statement pair validations returned ERROR from the equivalency tool
- Transaction blocks (statements 3, 4, 5) required structural refactoring
  from MS SQL batch patterns to PostgreSQL writable CTEs
- Npgsql 8.0.0 upgraded to 8.0.6 due to known security vulnerability

9. ARTIFACTS
===============================================================
- extracted_statements.sql: Complete catalog of all 7 original MS SQL statements
- converted_statements.sql: Complete catalog of all 7 converted PostgreSQL statements
- sql_equivalency_validation_report.json: Comprehensive equivalency report (JSON)
- dms_failure_summary.log: Detailed DMS failure documentation
- This report (migration_report.md): Final migration summary

===============================================================
END OF MIGRATION REPORT
===============================================================
