# Migration Report: SQL Server to PostgreSQL
## Project: AdoCore - Product Management Application
## Date: 2026-05-05

---

## Executive Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET data access code, modifying connection strings, and converting database setup scripts.

---

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS | 0 |
| Statements Requiring Manual Intervention | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |
| Database Setup Scripts Converted | 2 |
| C# Source Files Modified | 1 |
| Configuration Files Modified | 1 |
| Package References Updated | 1 |

---

## DMS Tool Status

**Status: ALL FAILED**

All 7 SQL statement conversions attempted through the DMS MCP tool failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project:** arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

As per the transformation definition, all statements were manually converted applying lowercase schema object names for PostgreSQL compatibility, with conversion method documented as "DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA".

---

## SQL Equivalency Validation Status

**Status: ALL ERRORS**

All 7 SQL statement pairs validated through the SQL Equivalency tool returned ERROR:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

Per the transformation definition, these are marked as ERROR status. No agent judgment was used to determine equivalency.

---

## Conversion Details

### Statement 1: GetAllProductsAsync
- **Type:** CTE with window functions (AVG OVER, COUNT OVER, CASE, ROUND)
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** Schema objects converted to lowercase
- **Equivalency Status:** ERROR

### Statement 2: GetProductByIdAsync
- **Type:** CTE with LAG window functions, parameterized query
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** Schema objects converted to lowercase
- **Equivalency Status:** ERROR

### Statement 3: InsertProductAsync
- **Type:** Transaction block with SCOPE_IDENTITY(), GETDATE(), multi-table operations
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** SCOPE_IDENTITY() → RETURNING + lastval(), GETDATE() → NOW(), schema lowercase
- **Equivalency Status:** ERROR

### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE variables, SELECT INTO, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** T-SQL DECLARE → PostgreSQL DO $$ block, GETDATE() → NOW(), schema lowercase
- **Equivalency Status:** ERROR

### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE variables, DELETE, CASE expression
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** T-SQL DECLARE → PostgreSQL DO $$ block, GETDATE() → NOW(), schema lowercase
- **Equivalency Status:** ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type:** CTE with RANK(), PERCENT_RANK() window functions, BETWEEN
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** Schema objects converted to lowercase
- **Equivalency Status:** ERROR

### Statement 7: GetLowStockProductsAsync
- **Type:** CTE with AVG/MIN/MAX OVER(), ROUND, parameterized threshold
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes:** Schema objects to lowercase, added CAST for integer division
- **Equivalency Status:** ERROR

---

## Code Changes Summary

### DataAccess/ProductRepository.cs
- Replaced `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- Replaced `SqlConnection` → `NpgsqlConnection`
- Replaced `SqlCommand` → `NpgsqlCommand`
- Replaced `SqlDataReader` → `NpgsqlDataReader`
- All 7 SQL statements replaced with PostgreSQL equivalents

### AdoCore.csproj
- Removed: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- Added: `<PackageReference Include="Npgsql" Version="8.0.1" />`

### appsettings.json
- Connection strings updated from SQL Server format to PostgreSQL format
- Server= → Host=
- Removed Trusted_Connection, MultipleActiveResultSets, TrustServerCertificate
- Added Username and Password parameters

### Database/Scripts/01_InitialSetup.sql
- Converted all T-SQL syntax to PostgreSQL
- IDENTITY(1,1) → GENERATED ALWAYS AS IDENTITY
- nvarchar → varchar, bit → boolean, datetime → timestamp
- GO statements removed
- Stored procedures → PostgreSQL functions (CREATE OR REPLACE FUNCTION)
- Triggers converted to PostgreSQL trigger function + trigger syntax
- sys.objects checks → DROP IF EXISTS
- SYSTEM_USER → CURRENT_USER

### Scripts/01_InitialSetup.sql
- Same conversions as above (simplified version)
- IF NOT EXISTS pattern converted to PostgreSQL DO $$ block

---

## Build Status

**Final Build: SUCCESS**
- 0 Errors
- 12 Warnings (pre-existing nullable reference type warnings)

---

## Artifacts Produced

1. **extracted_statements.sql** - Complete catalog of all 7 original MS SQL statements
2. **converted_statements.sql** - Complete catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency report with all 7 pairs
4. **migration_report.md** - This report

---

## Statements Flagged for Manual Review

All 7 statements should be reviewed manually due to:
1. DMS tool was unable to convert (metadata model creation failure)
2. SQL Equivalency tool was unable to validate (uniqueID error)
3. Manual conversion was applied based on documented rules

**Priority Review Items:**
- Statement 3 (InsertProductAsync): Complex SCOPE_IDENTITY() → RETURNING pattern change
- Statement 4 (UpdateProductAsync): T-SQL variable pattern → DO $$ block
- Statement 5 (DeleteProductAsync): T-SQL variable pattern → DO $$ block

---

## Recommendations

1. **Test all SQL statements** against a real PostgreSQL database to verify functional correctness
2. **Validate the DO $$ blocks** for statements 4 and 5 - ensure Npgsql properly handles parameter passing to anonymous code blocks
3. **Consider refactoring** statements 3-5 to use individual parameterized queries with ADO.NET transactions instead of server-side anonymous blocks, for better parameter handling
4. **Verify RETURNING clause** behavior with Npgsql's ExecuteScalarAsync()
5. **Test connection** with updated connection string format
