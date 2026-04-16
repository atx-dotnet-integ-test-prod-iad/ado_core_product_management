# Migration Report: SQL Server to PostgreSQL
## ADO.NET Application Migration

### Summary
- **Project**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-04-16

---

### SQL Statement Processing

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Conversion Successes | 0 |
| DMS Conversion Failures | 7 |
| Manual Conversions (Lowercase Schema) | 7 |
| Equivalency Validated as EQUIVALENT | 0 |
| Equivalency Validated as NOT_EQUIVALENT | 0 |
| Equivalency Validation ERRORs | 7 |

### DMS Tool Status
All 7 DMS MCP tool calls failed with: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

All statements were manually converted applying lowercase schema object names per `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` rules.

### SQL Equivalency Tool Status
All 7 equivalency validations returned ERROR with: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`

Per transformation definition, all pairs are marked as ERROR in the report.

---

### Statement Conversion Summary

| # | Method | Statement | Key Conversions |
|---|--------|-----------|-----------------|
| 1 | GetAllProductsAsync | CTE + Window Functions + CASE + ROUND + JOIN | Lowercase schema objects |
| 2 | GetProductByIdAsync | CTE + LAG Window Function + ROUND + LEFT JOIN | Lowercase schema objects |
| 3 | InsertProductAsync | Transaction with INSERT + SCOPE_IDENTITY + GETDATE | SCOPE_IDENTITY()→lastval(), GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN, DECLARE/SET eliminated |
| 4 | UpdateProductAsync | Transaction with DECLARE + UPDATE + INSERT | DECLARE/SET eliminated via subqueries, GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN |
| 5 | DeleteProductAsync | Transaction with DECLARE + INSERT + DELETE + CASE | DECLARE/SET eliminated via subqueries, GETDATE()→NOW(), BEGIN TRANSACTION→BEGIN |
| 6 | GetProductsByPriceRangeAsync | CTE + RANK/PERCENT_RANK + BETWEEN + CASE | Lowercase schema objects |
| 7 | GetLowStockProductsAsync | CTE + AVG/MIN/MAX Window Functions + CASE + ROUND | Lowercase schema objects, CAST(int AS numeric) for ROUND division |

---

### Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; using Microsoft.Data.SqlClient → using Npgsql; SqlConnection→NpgsqlConnection; SqlCommand→NpgsqlCommand; SqlDataReader→NpgsqlDataReader |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.0 |
| `appsettings.json` | Connection strings converted to PostgreSQL format (Host, Username, Password) |
| `Database/Scripts/01_InitialSetup.sql` | Full PostgreSQL DDL conversion (IDENTITY→SERIAL, NVARCHAR→VARCHAR, BIT→BOOLEAN, GETDATE()→CURRENT_TIMESTAMP, triggers, stored procedures→functions) |
| `Scripts/01_InitialSetup.sql` | PostgreSQL DDL conversion |

### New Files Created

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report with all 7 statement pairs |

---

### Build Status
- **Final Build**: SUCCESS (0 errors, 12 warnings - all pre-existing nullable reference type warnings)

### Manual Interventions Required
1. All 7 SQL statements required manual conversion due to DMS tool failure
2. All 7 equivalency validations returned ERROR - manual review recommended
3. Connection string credentials (Username/Password) in appsettings.json should be updated with actual PostgreSQL credentials before deployment
