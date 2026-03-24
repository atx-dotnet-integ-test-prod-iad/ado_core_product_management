# Migration Report: MS SQL Server to PostgreSQL

## Project: AdoCore
## Date: 2026-03-24
## Migration Type: ADO.NET Application Database Provider Migration

---

## Executive Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration covered all in-code SQL statements, database setup scripts, ADO.NET class replacements, package dependencies, and connection string configurations.

---

## Migration Statistics

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 20 |
| **In-Code Statements (ProductRepository.cs)** | 7 |
| **Script Statements (Setup SQL Scripts)** | 13 |
| **Successfully Converted by DMS** | 0 |
| **Manually Converted (DMS Failure)** | 20 |
| **Equivalency Validated as EQUIVALENT** | 0 |
| **Equivalency Validated as NOT_EQUIVALENT** | 0 |
| **Equivalency Validation ERROR** | 20 |

---

## DMS Tool Status

The DMS MCP tool (dms-mcp___statement_conversion_tool) was attempted for all 20 statements but consistently failed with:
```
Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
```

All statements were therefore manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` method, applying lowercase schema object names for PostgreSQL compatibility.

---

## SQL Equivalency Tool Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) was called for all 20 statement pairs but consistently returned:
```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a systemic tool-level issue unrelated to the quality of conversions. All equivalency statuses are recorded as ERROR per the requirement that tool failures must be marked as ERROR without agent judgment substitution.

---

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statements, updated ADO.NET classes (Sql* → Npgsql*), updated using directive |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| `appsettings.json` | Converted connection strings from SQL Server to PostgreSQL format |
| `Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax (tables, functions, sample data) |
| `Database/Scripts/01_InitialSetup.sql` | Converted to PostgreSQL syntax (tables, functions, triggers, indexes, sample data) |

---

## Detailed Conversion Summary

### In-Code Statements (DataAccess/ProductRepository.cs)

| # | Method | Key Conversions | Status |
|---|--------|----------------|--------|
| 1 | GetAllProductsAsync | CTE, AVG/COUNT OVER(), CASE, ROUND, INNER JOIN → lowercase schema | Converted |
| 2 | GetProductByIdAsync | CTE, LAG OVER(), LEFT JOIN, CASE → lowercase schema | Converted |
| 3 | InsertProductAsync | SCOPE_IDENTITY() → RETURNING + CTE, GETDATE() → NOW(), DECLARE → CTE | Converted |
| 4 | UpdateProductAsync | DECLARE/SET → CTE, GETDATE() → NOW(), BEGIN TRANSACTION → CTE atomicity | Converted |
| 5 | DeleteProductAsync | DECLARE/SET → CTE, GETDATE() → NOW(), CASE preserved, BEGIN TRANSACTION → CTE | Converted |
| 6 | GetProductsByPriceRangeAsync | RANK, PERCENT_RANK, BETWEEN, CASE → lowercase schema | Converted |
| 7 | GetLowStockProductsAsync | AVG/MIN/MAX OVER(), CASE, ROUND with ::numeric cast | Converted |

### ADO.NET Class Replacements

| Original | Replacement |
|----------|------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (not used directly; AddWithValue compatible) |

### Script Statement Conversions

| # | Source | Statement Type | Key Conversions |
|---|--------|---------------|----------------|
| 8 | Scripts/01_InitialSetup.sql | CREATE TABLE Products | IDENTITY → SERIAL, nvarchar → VARCHAR, datetime → TIMESTAMP, GETDATE() → NOW() |
| 9 | Scripts/01_InitialSetup.sql | sp_GetAllProducts | CREATE OR ALTER PROCEDURE → CREATE OR REPLACE FUNCTION, SET NOCOUNT ON removed |
| 10 | Scripts/01_InitialSetup.sql | sp_GetProductById | Procedure → Function with parameter, RETURNS TABLE |
| 11 | Scripts/01_InitialSetup.sql | sp_InsertProduct | SCOPE_IDENTITY() → RETURNING INTO, Procedure → Function |
| 12 | Scripts/01_InitialSetup.sql | sp_UpdateProduct | GETDATE() → NOW(), Procedure → Function |
| 13 | Scripts/01_InitialSetup.sql | sp_DeleteProduct | Procedure → Function RETURNS VOID |
| 14 | Database/Scripts/01_InitialSetup.sql | CREATE TABLE Categories | IDENTITY → SERIAL, nvarchar → VARCHAR, [dbo] brackets removed |
| 15 | Database/Scripts/01_InitialSetup.sql | CREATE TABLE Suppliers | bit → BOOLEAN, DEFAULT 1 → DEFAULT TRUE |
| 16 | Database/Scripts/01_InitialSetup.sql | CREATE TABLE Products (full) | Full table with FKs, bit → BOOLEAN, IDENTITY → SERIAL |
| 17 | Database/Scripts/01_InitialSetup.sql | CREATE TABLE ProductHistory | IDENTITY → SERIAL, datetime → TIMESTAMP |
| 18 | Database/Scripts/01_InitialSetup.sql | CREATE TABLE ProductStats | datetime → TIMESTAMP, GETDATE() → NOW() |
| 19 | Database/Scripts/01_InitialSetup.sql | Trigger trg_Products_History | inserted/deleted → NEW/OLD, SYSTEM_USER → current_user, FOR EACH ROW trigger function |
| 20 | Database/Scripts/01_InitialSetup.sql | UPDATE ProductStats | IsDiscontinued = 1 → isdiscontinued = TRUE, GETDATE() → NOW() |

### Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TLS | `TrustServerCertificate=True` | Removed (not applicable) |

### Package Dependency Changes

| Package | Before | After |
|---------|--------|-------|
| Microsoft.Data.SqlClient | 5.1.4 | Removed |
| Npgsql | N/A | 8.0.6 |
| Microsoft.Extensions.Configuration | 8.0.0 | Unchanged |
| Microsoft.Extensions.Configuration.Json | 8.0.0 | Unchanged |
| Microsoft.Extensions.DependencyInjection | 8.0.0 | Unchanged |

**Note**: Npgsql 8.0.1 was initially specified but upgraded to 8.0.6 to resolve known high severity vulnerability GHSA-x9vc-6hfv-hg8c.

---

## Build Status

**Build Result: SUCCESS** (0 errors, 10 warnings)

Warnings are pre-existing nullable reference warnings (CS8601, CS8603, CS8618, CS8600, CS8625) that existed in the original codebase and are not related to the migration.

---

## Statements Requiring Manual Review

All 20 statements were manually converted due to DMS tool failure and all equivalency validations returned ERROR. The following statements have the most significant structural changes and should be prioritized for manual review:

1. **InsertProductAsync** - SCOPE_IDENTITY() pattern replaced with CTE + RETURNING
2. **UpdateProductAsync** - DECLARE/SET variable pattern replaced with CTE
3. **DeleteProductAsync** - DECLARE/SET variable pattern replaced with CTE
4. **trg_Products_History trigger** - SQL Server inserted/deleted virtual tables replaced with PostgreSQL NEW/OLD trigger syntax
5. **sp_InsertProduct function** - SCOPE_IDENTITY() replaced with RETURNING INTO

---

## Artifact Catalog

| Artifact | Path | Description |
|----------|------|-------------|
| Extracted Statements | `extracted_statements.sql` | Original 7 MS SQL statements from ProductRepository.cs |
| Converted Statements | `converted_statements.sql` | 7 PostgreSQL-converted statements for ProductRepository.cs |
| Equivalency Report | `sql_equivalency_validation_report.json` | Complete validation report for all 20 statement pairs |
| Migration Report | `migration_report.md` | This document |

---

## Recommendations

1. **Manual Testing**: All converted SQL statements should be tested against a running PostgreSQL database to verify correctness
2. **CTE with DML**: The PostgreSQL writeable CTE pattern (used for Insert/Update/Delete methods) requires PostgreSQL 9.1+ and should be verified with the target version
3. **Trigger Behavior**: The converted trigger function uses FOR EACH ROW instead of SQL Server's statement-level trigger with virtual tables
4. **Connection Pooling**: Consider adding connection pooling parameters to the PostgreSQL connection string for production use
5. **Npgsql Version**: Monitor Npgsql for security patches and keep updated
