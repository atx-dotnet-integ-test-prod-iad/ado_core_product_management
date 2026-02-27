# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Project**: AdoCore - .NET ADO Application
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Migration Date**: 2026-02-27
- **Framework**: .NET 9.0

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed (code) | 7 |
| Total SQL statements processed (scripts) | 5 |
| **Total SQL statements processed** | **12** |
| DMS conversion successes | 0 |
| DMS conversion failures | 12 |
| Manual conversions (DMS failure fallback) | 12 |
| SQL Equivalency validations performed | 12 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 12 |
| Files modified | 5 |
| Files created (artifacts) | 5 |

---

## DMS Tool Status

**Tool**: dms-mcp____statement_conversion_tool  
**Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`

All 12 SQL statements were passed to the DMS MCP tool for conversion. **All 12 failed** with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple retries were attempted with varying parameters:
- Default: 15 poll attempts, 10s interval
- Increased: 30 poll attempts, 15-20s interval
- Explicit database_name parameter
- Simple test queries

The error persisted across all attempts, indicating an infrastructure-level issue with the DMS service rather than a statement-specific problem.

Per the transformation definition's fallback rules, all statements were manually converted with **lowercase schema object names** for PostgreSQL compatibility.

---

## SQL Equivalency Tool Status

**Tool**: sql-equivalency___validate_sql_equivalence

All 12 statement pairs were passed to the SQL Equivalency tool. **All 12 returned ERROR** with:
```
{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}
```

This appears to be an infrastructure-level error with the equivalency service. Even the simplest test queries (e.g., `SELECT ProductId, Name, Price FROM Products`) returned the same error.

Per the transformation definition: errors are marked as ERROR status, and agent judgment is never used for equivalency determination.

---

## Files Modified

### 1. sourceCode/DataAccess/ProductRepository.cs
- **Using statement**: `Microsoft.Data.SqlClient` → `Npgsql`
- **Connection class**: `SqlConnection` → `NpgsqlConnection`
- **Command class**: `SqlCommand` → `NpgsqlCommand`
- **Reader class**: `SqlDataReader` → `NpgsqlDataReader`
- **7 SQL statements**: Converted to PostgreSQL (lowercase schema, NOW(), RETURNING, etc.)
- **Transaction handling**: Moved from SQL-level (BEGIN TRANSACTION/COMMIT in SQL) to application-level (NpgsqlTransaction)

### 2. sourceCode/AdoCore.csproj
- **Removed**: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added**: `<PackageReference Include="Npgsql" Version="8.0.1" />`

### 3. sourceCode/appsettings.json
- **Connection strings**: Converted from SQL Server format to PostgreSQL format
  - `Server=` → `Host=`
  - Removed: `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`
  - Added: `Username`, `Password`

### 4. sourceCode/Scripts/01_InitialSetup.sql
- Complete conversion from MS SQL Server to PostgreSQL syntax
- Stored procedures → PostgreSQL functions (plpgsql)
- IDENTITY → SERIAL
- GETDATE() → NOW()
- NVARCHAR → VARCHAR
- IF NOT EXISTS patterns → CREATE TABLE IF NOT EXISTS / DO $$ blocks

### 5. sourceCode/Database/Scripts/01_InitialSetup.sql
- Complete conversion from MS SQL Server to PostgreSQL syntax
- All tables: lowercase names, SERIAL, TIMESTAMP, BOOLEAN, VARCHAR
- Trigger: MS SQL trigger → PostgreSQL trigger function + trigger
- Stored procedures → PostgreSQL functions
- Indexes: lowercase names
- GO batch separators removed
- sys.objects checks → DROP IF EXISTS
- SYSTEM_USER → current_user
- BIT → BOOLEAN
- SET NOCOUNT ON → removed

---

## SQL Conversion Details

### Code SQL Statements (ProductRepository.cs)

| # | Method | Key MS SQL Features | Key PostgreSQL Changes |
|---|--------|-------------------|----------------------|
| 1 | GetAllProductsAsync | CTE, AVG/COUNT OVER(), CASE, ROUND | Lowercase schema names |
| 2 | GetProductByIdAsync | CTE, LAG OVER(), CASE, ROUND | Lowercase schema names |
| 3 | InsertProductAsync | SCOPE_IDENTITY(), GETDATE(), DECLARE, transaction | RETURNING, NOW(), app-level transaction |
| 4 | UpdateProductAsync | DECLARE, SELECT INTO var, GETDATE(), transaction | App-level variable fetch, NOW(), app-level transaction |
| 5 | DeleteProductAsync | DECLARE, SELECT INTO var, GETDATE(), CASE, transaction | App-level variable fetch, NOW(), app-level transaction |
| 6 | GetProductsByPriceRangeAsync | CTE, RANK(), PERCENT_RANK(), BETWEEN | Lowercase schema names |
| 7 | GetLowStockProductsAsync | CTE, AVG/MIN/MAX OVER(), ROUND | CAST to NUMERIC for integer division, lowercase |

### Script SQL Statements (01_InitialSetup.sql files)

| # | Object | Key MS SQL Features | Key PostgreSQL Changes |
|---|--------|-------------------|----------------------|
| 8 | CREATE TABLE Products | IDENTITY, NVARCHAR, BIT, GETDATE() | SERIAL, VARCHAR, BOOLEAN, NOW() |
| 9 | sp_GetAllProducts | CREATE OR ALTER PROCEDURE, SET NOCOUNT ON | CREATE OR REPLACE FUNCTION, RETURNS TABLE |
| 10 | sp_InsertProduct | SCOPE_IDENTITY() | RETURNING INTO |
| 11 | UPDATE ProductStats | GETDATE(), IsDiscontinued = 1 | NOW(), isdiscontinued = TRUE |
| 12 | trg_Products_History | MS SQL trigger with inserted/deleted tables, SYSTEM_USER | PostgreSQL trigger function, TG_OP, NEW/OLD, current_user |

---

## Manual Interventions Required

All 12 statements required manual conversion due to DMS tool failures. The conversions followed these rules:
1. **Schema objects** → lowercase (Products → products, ProductId → productid, etc.)
2. **GETDATE()** → NOW()
3. **SCOPE_IDENTITY()** → RETURNING clause
4. **IDENTITY(1,1)** → SERIAL
5. **NVARCHAR** → VARCHAR
6. **BIT** → BOOLEAN
7. **DATETIME** → TIMESTAMP
8. **MS SQL Trigger** → PostgreSQL trigger function + trigger
9. **Stored Procedures** → PostgreSQL functions (plpgsql)
10. **SYSTEM_USER** → current_user
11. **Transaction handling** → Moved to application level for C# code

---

## Known Issues and Limitations

1. **DMS Tool Unavailable**: All DMS conversion attempts failed. Manual conversions were applied per fallback rules.
2. **SQL Equivalency Tool Unavailable**: All equivalency validations returned ERROR. Manual review is recommended for production deployment.
3. **Connection String Credentials**: appsettings.json contains placeholder credentials (postgres/postgres) that must be updated for production.
4. **Transaction Semantics**: Insert/Update/Delete methods were restructured from single-batch SQL transactions to application-level NpgsqlTransaction management. The functional behavior is preserved but the execution pattern differs.
5. **Integer Division**: The GetLowStockProductsAsync query adds explicit CAST to NUMERIC for the StockQuantity/AvgStock division to avoid PostgreSQL integer division behavior.

---

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | All 7 original MS SQL statements from code |
| converted_statements.sql | sourceCode/ | All 7 converted PostgreSQL statements for code |
| dms_conversion_summary.log | sourceCode/ | Detailed DMS failure documentation |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency report (12 pairs) |
| migration_report.md | sourceCode/ | This report |

---

## Verification Files Not Modified

The following files were confirmed to contain no SQL Server references and required no changes:
- `Program.cs`
- `Business/ProductService.cs`
- `Models/Product.cs`
- `CLI/CommandLineInterface.cs`
- `CLI/InteractiveMenu.cs`

---

*Report generated: 2026-02-27*
