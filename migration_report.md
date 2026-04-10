# Migration Report: SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Statements Converted by DMS Tool** | 0 |
| **Statements Requiring Manual Intervention** | 7 |
| **Statements Validated as EQUIVALENT** | 0 |
| **Statements Validated as NOT_EQUIVALENT** | 0 |
| **Statements with Equivalency ERROR** | 7 |

## Migration Overview

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL using Npgsql as the ADO.NET data provider.

### Migration Scope
- **Source Database:** Microsoft SQL Server (ProductManagement)
- **Target Database:** PostgreSQL 13 (postgres)
- **DMS Migration Project:** arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Application Framework:** .NET 9.0 with ADO.NET

## SQL Statement Conversions

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool for conversion. All failed with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Manual conversion was applied using lowercase schema mapping rules (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA), using schema mappings successfully obtained from the DMS schema_mapping_tool.

### Schema Mappings Applied (from DMS schema_mapping_tool)
| Source (SQL Server) | Target (PostgreSQL) |
|---|---|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

### SQL Equivalency Validation Status
All 7 statement pairs were submitted to the SQL Equivalency tool for validation. All returned ERROR with:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
This appears to be a systemic issue with the equivalency tool, not an indication of incorrect conversions.

### Statement-by-Statement Details

#### Statement 1: GetAllProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetAllProductsAsync()
- **Type:** SELECT with CTE, AVG/COUNT window functions, INNER JOIN, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error, not conversion error)
- **Key Changes:** Table/column names lowercased, schema prefix added

#### Statement 2: GetProductByIdAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductByIdAsync()
- **Type:** SELECT with CTE, LAG window functions, LEFT JOIN, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error, not conversion error)
- **Key Changes:** Table/column names lowercased, schema prefix added

#### Statement 3: InsertProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** InsertProductAsync()
- **Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error, not conversion error)
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `INSERT ... RETURNING` with writable CTE
  - `GETDATE()` → `clock_timestamp()`
  - Transaction block restructured as atomic writable CTE

#### Statement 4: UpdateProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** UpdateProductAsync()
- **Type:** Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error, not conversion error)
- **Key Changes:**
  - DECLARE/variable assignments replaced with writable CTE
  - `GETDATE()` → `clock_timestamp()`
  - Transaction block restructured as atomic writable CTE

#### Statement 5: DeleteProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** DeleteProductAsync()
- **Type:** Transaction block with DECLARE, SELECT INTO vars, DELETE, INSERT, UPDATE with CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error, not conversion error)
- **Key Changes:**
  - DECLARE/variable assignments replaced with writable CTE
  - `GETDATE()` → `clock_timestamp()`
  - Transaction block restructured as atomic writable CTE

#### Statement 6: GetProductsByPriceRangeAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductsByPriceRangeAsync()
- **Type:** SELECT with CTE, RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error, not conversion error)
- **Key Changes:** Table/column names lowercased, schema prefix added

#### Statement 7: GetLowStockProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetLowStockProductsAsync()
- **Type:** SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool error, not conversion error)
- **Key Changes:**
  - Table/column names lowercased, schema prefix added
  - Added `CAST(stockquantity AS NUMERIC)` for integer division compatibility

## Package Dependency Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.3` |

## ADO.NET Class Mapping Changes

| SQL Server (Before) | PostgreSQL/Npgsql (After) |
|---|---|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `new SqlConnection(...)` | `new NpgsqlConnection(...)` |
| `new SqlCommand(...)` | `new NpgsqlCommand(...)` |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|---|---|---|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed - not applicable) |
| TLS | `TrustServerCertificate=True` | (removed - not applicable) |

## SQL Function Mappings Applied

| SQL Server | PostgreSQL |
|---|---|
| `SCOPE_IDENTITY()` | `INSERT ... RETURNING` with writable CTE |
| `GETDATE()` | `clock_timestamp()` |
| `DECLARE @var / SET @var` | Writable CTE pattern |
| `BEGIN TRANSACTION / COMMIT` | Writable CTE (atomic) |
| `SELECT @var = col FROM table` | CTE subquery pattern |

## Column Name Mappings in Code

The `MapProductFromReader` method was updated to use lowercase column names matching the PostgreSQL schema:
| SQL Server | PostgreSQL |
|---|---|
| `reader["ProductId"]` | `reader["productid"]` |
| `reader["Name"]` | `reader["name"]` |
| `reader["Description"]` | `reader["description"]` |
| `reader["Price"]` | `reader["price"]` |
| `reader["StockQuantity"]` | `reader["stockquantity"]` |
| `reader["CreatedDate"]` | `reader["createddate"]` |
| `reader["ModifiedDate"]` | `reader["modifieddate"]` |

## Files Modified

1. **sourceCode/DataAccess/ProductRepository.cs** - SQL statements, ADO.NET classes, using statements, column references
2. **sourceCode/AdoCore.csproj** - Package reference (Microsoft.Data.SqlClient → Npgsql)
3. **sourceCode/appsettings.json** - Connection strings (SQL Server → PostgreSQL format)

## Artifacts Generated

1. **extracted_statements.sql** - Catalog of all 7 original MS SQL statements
2. **converted_statements.sql** - Catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency report (all 7 pairs, all ERROR status due to tool issue)
4. **dms_conversion_log.md** - Detailed log of all DMS conversion attempts and manual interventions
5. **migration_report.md** - This report

## Build Status

**Final Build: SUCCESS** (0 errors, 10 warnings)

All warnings are pre-existing nullable reference type warnings, not introduced by the migration.

## Manual Review Recommended

Due to the systemic failures of both the DMS conversion tool and the SQL Equivalency validation tool, the following items should be manually reviewed:

1. **All 7 SQL statement conversions** - While the conversions follow standard SQL Server → PostgreSQL mapping rules and use schema mappings from the DMS schema_mapping_tool, they could not be machine-validated for equivalency.
2. **Writable CTE patterns** (Statements 3, 4, 5) - The transaction blocks with DECLARE/SET were restructured as writable CTEs. These should be tested against the actual PostgreSQL database to verify correct behavior.
3. **Integer division** (Statement 7) - Added explicit `CAST(stockquantity AS NUMERIC)` to prevent integer division truncation in PostgreSQL.
