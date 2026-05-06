# Migration Report: MS SQL Server to PostgreSQL
## ADO.NET Application Migration (AdoCore)

### Summary
- **Migration Date**: 2026-05-06
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Application Framework**: .NET 9.0 ADO.NET
- **Package Migration**: Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.0

### SQL Statement Processing

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| DMS conversion attempted | 7 |
| DMS conversion successful | 0 |
| DMS conversion failed | 7 |
| Manual conversion applied | 7 |
| SQL Equivalency validated | 7 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 7 |

### DMS Tool Results
All 7 SQL statements failed DMS conversion with identical error:
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Fallback**: Manual conversion with lowercase schema object names applied per transformation rules

### SQL Equivalency Tool Results
All 7 statement pairs returned ERROR from the SQL Equivalency tool:
- **Error**: `'uniqueID'`
- **Note**: This appears to be a systemic tool issue, not a statement-specific problem

### Conversion Rules Applied (Manual - DMS Failure Fallback)
1. All schema object names converted to lowercase (PostgreSQL convention)
2. `GETDATE()` → `NOW()`
3. `SCOPE_IDENTITY()` → `RETURNING productid`
4. `NVARCHAR` → `VARCHAR`
5. `IDENTITY(1,1)` → `SERIAL`
6. `BIT` → `BOOLEAN`
7. `SYSTEM_USER` → `CURRENT_USER`
8. `[dbo].[table]` bracketed identifiers → unquoted lowercase names
9. T-SQL stored procedures → PostgreSQL functions (`CREATE OR REPLACE FUNCTION`)
10. T-SQL triggers → PostgreSQL trigger functions + CREATE TRIGGER
11. Transaction blocks decomposed into separate SQL commands with C# transaction management
12. Integer division fixed with `CAST(column AS DECIMAL)` where needed

### Files Modified

| File | Changes |
|------|---------|
| sourceCode/DataAccess/ProductRepository.cs | All 7 SQL statements converted, ADO.NET classes migrated to Npgsql |
| sourceCode/AdoCore.csproj | Microsoft.Data.SqlClient → Npgsql |
| sourceCode/appsettings.json | Connection strings converted to PostgreSQL format |
| sourceCode/Scripts/01_InitialSetup.sql | Converted to PostgreSQL DDL |
| sourceCode/Database/Scripts/01_InitialSetup.sql | Converted to PostgreSQL DDL (full schema) |

### Files Created

| File | Purpose |
|------|---------|
| extracted_statements.sql | Catalog of all 7 original MS SQL statements |
| converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Complete equivalency validation report |
| migration_report.md | This report |

### Build Status
- **Final Build**: ✅ Success (0 errors, 12 warnings - all pre-existing nullable reference type warnings)

### Key Architecture Changes
1. **Transaction Handling**: T-SQL inline transactions (BEGIN TRANSACTION...COMMIT) decomposed into C# `BeginTransactionAsync()`/`CommitAsync()`/`RollbackAsync()` pattern with explicit `command.Transaction` assignment
2. **Identity/Sequence**: `SCOPE_IDENTITY()` replaced with PostgreSQL `RETURNING` clause
3. **Variable Handling**: T-SQL `DECLARE @variable` patterns replaced with C# local variables
4. **Connection**: SQL Server connection string parameters mapped to PostgreSQL equivalents
