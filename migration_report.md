# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Application**: AdoCore (.NET ADO.NET Application)
- **Source Database**: Microsoft SQL Server (ProductManagement)
- **Target Database**: PostgreSQL
- **Migration Date**: 2026-04-29
- **Migration Method**: DMS MCP Tool (attempted) + Manual Conversion (fallback)

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS Tool** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`). All 7 failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

The DMS Schema Mapping Tool (`dms-mcp___schema_mapping_tool`) was operational and successfully returned PostgreSQL table DDL for all 3 tables (Products, ProductHistory, ProductStats).

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All 7 returned ERROR status:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
All equivalency results come directly from the tool output. No agent judgment was used.

---

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE, INNER JOIN
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema object names
- **Key Changes**: Table/column names to lowercase; SQL syntax compatible as-is
- **Equivalency**: ERROR (tool returned error)

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE, LAG Window Functions, LEFT JOIN, ROUND, Parameterized (@ProductId)
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema object names
- **Key Changes**: Table/column names to lowercase; LAG/ROUND compatible
- **Equivalency**: ERROR (tool returned error)

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), INSERT, UPDATE, GETDATE()
- **DMS Status**: FAILED
- **Manual Conversion**: Major restructuring required
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION / COMMIT` → C# managed `BeginTransactionAsync() / CommitAsync()`
  - `DECLARE @var / SET @var` → C# variables with separate SQL queries
  - Single monolithic SQL block → 3 separate `NpgsqlCommand` calls within C# transaction
- **Equivalency**: ERROR (tool returned error)

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **DMS Status**: FAILED
- **Manual Conversion**: Major restructuring required
- **Key Changes**:
  - `DECLARE @OldPrice / @OldStock` → C# `decimal oldPrice` / `int oldStock` with SELECT query
  - `GETDATE()` → `NOW()`
  - Single SQL block → 4 separate `NpgsqlCommand` calls within C# transaction
- **Equivalency**: ERROR (tool returned error)

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **DMS Status**: FAILED
- **Manual Conversion**: Major restructuring required
- **Key Changes**:
  - Same patterns as Statement 4 (DECLARE → C# variables, GETDATE → NOW)
  - Single SQL block → 4 separate `NpgsqlCommand` calls within C# transaction
  - CASE expression in UPDATE preserved (compatible)
- **Equivalency**: ERROR (tool returned error)

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN, CASE
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema object names
- **Key Changes**: Table/column names to lowercase; Window functions compatible
- **Equivalency**: ERROR (tool returned error)

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND, Parameterized (@Threshold)
- **DMS Status**: FAILED
- **Manual Conversion**: Applied lowercase schema object names
- **Key Changes**: Table/column names to lowercase; Window functions compatible
- **Equivalency**: ERROR (tool returned error)

---

## File Changes Summary

### Modified Files
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; Transaction blocks restructured; ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader); using directive updated; MapProductFromReader column references lowercased |
| `AdoCore.csproj` | `Microsoft.Data.SqlClient` 5.1.4 → `Npgsql` 8.0.3 |
| `appsettings.json` | Connection strings converted from SQL Server to PostgreSQL format |

### New Files (Artifacts)
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `migration_report.md` | This report |

---

## Schema Mapping (from DMS Schema Mapping Tool)

| SQL Server Table | PostgreSQL Table | Schema |
|-----------------|------------------|--------|
| `[dbo].[Products]` | `products` | `productmanagement_dbo` |
| `[dbo].[ProductHistory]` | `producthistory` | `productmanagement_dbo` |
| `[dbo].[ProductStats]` | `productstats` | `productmanagement_dbo` |

### Key Type Mappings
| SQL Server Type | PostgreSQL Type |
|----------------|-----------------|
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| `nvarchar(N)` | `VARCHAR(N)` |
| `decimal(P,S)` | `NUMERIC(P,S)` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `bit` | `NUMERIC(1,0)` |
| `getdate()` | `clock_timestamp()` |

---

## Build Status
- **Final Build**: ✅ SUCCESS (0 errors)
- **Warnings**: Pre-existing nullable reference warnings only (CS8601, CS8618, CS8600, CS8603, CS8625)

---

## Statements Requiring Manual Review
All 7 statements should be manually reviewed due to:
1. DMS conversion tool failure (metadata model creation error)
2. SQL equivalency validation errors (tool returned ERROR for all pairs)
3. Transaction blocks (statements 3, 4, 5) were significantly restructured from single SQL blocks to multiple C# commands

### Priority Review Items
- **High**: InsertProductAsync (Statement 3) - SCOPE_IDENTITY() → RETURNING conversion + transaction restructuring
- **High**: UpdateProductAsync (Statement 4) - DECLARE/SET → C# variables + transaction restructuring
- **High**: DeleteProductAsync (Statement 5) - DECLARE/SET → C# variables + transaction restructuring
- **Medium**: All SELECT statements (1, 2, 6, 7) - Verify lowercase schema compatibility with target PostgreSQL database

---

## Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Auth | `Trusted_Connection=True` | `Username=postgres;Password=<password>` |
| MARS | `MultipleActiveResultSets=true` | (removed - not applicable) |
| SSL | `TrustServerCertificate=True` | (removed - not applicable) |
