# Migration Report: SQL Server to PostgreSQL - AdoCore Application
## Generated: 2026-04-12

---

## Executive Summary

The AdoCore .NET application has been migrated from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET data access types, updating package dependencies, and modifying connection strings and database setup scripts.

---

## 1. SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL statements extracted | 7 |
| DMS MCP conversion attempts | 7 |
| DMS MCP conversion successes | 0 |
| DMS MCP conversion failures | 7 |
| Manual conversions (with lowercase schema) | 7 |
| SQL Equivalency validations performed | 7 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 7 |

### DMS Tool Status
- **DMS statement_conversion_tool**: FAILED for all statements
  - Error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
  - All 7 statements attempted; all returned the same error
- **DMS schema_mapping_tool**: SUCCEEDED
  - Successfully retrieved schema mappings for Products, ProductHistory, ProductStats tables
  - Provided target PostgreSQL schema structure used for manual conversions

### SQL Equivalency Tool Status
- All 7 statement pairs returned ERROR status with error: `'uniqueID'`
- Per transformation definition: errors marked as ERROR (not agent-judged)

---

## 2. Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased (Products→products, ProductId→productid, etc.)
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - SCOPE_IDENTITY() → RETURNING productid
  - GETDATE() → clock_timestamp()
  - DECLARE @var / single SQL transaction → separate ADO.NET commands with C# managed transaction
  - All table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - DECLARE @var with SELECT INTO → separate SELECT command with C# reader
  - GETDATE() → clock_timestamp()
  - Single SQL transaction → separate ADO.NET commands with C# managed transaction
  - All table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**:
  - DECLARE @var with SELECT INTO → separate SELECT command with C# reader
  - GETDATE() → clock_timestamp()
  - Single SQL transaction → separate ADO.NET commands with C# managed transaction
  - All table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK() and PERCENT_RANK() window functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes**: Table/column names lowercased
- **Equivalency Status**: ERROR

---

## 3. Files Modified

### Source Code Changes
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements converted to PostgreSQL; transaction methods restructured; ADO.NET types changed from SqlClient to Npgsql |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server to PostgreSQL format |

### Database Scripts
| File | Changes |
|------|---------|
| `Scripts/01_InitialSetup.sql` | Converted from SQL Server DDL to PostgreSQL (IDENTITY→GENERATED ALWAYS AS IDENTITY, NVARCHAR→VARCHAR, DATETIME→TIMESTAMP, stored procedures→functions) |
| `Database/Scripts/01_InitialSetup.sql` | Full conversion including tables, indexes, triggers, stored procedures→functions, sample data |

### Artifacts Created
| File | Description |
|------|-------------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive JSON report with all equivalency results |

---

## 4. ADO.NET Type Replacements

| SQL Server Type | Npgsql Equivalent | Occurrences |
|----------------|-------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, return type, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader param) |
| `SqlTransaction` cast | `NpgsqlTransaction` cast | 3 |

---

## 5. Connection String Changes

| Setting | SQL Server | PostgreSQL |
|---------|-----------|------------|
| DevConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=postgres;Username=postgres;Password=postgres;` |
| ProdConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=postgres;Username=postgres;Password=postgres;` |

### Connection Parameter Mappings
- `Server=` → `Host=`
- `Database=ProductManagement` → `Database=postgres` (target DB name from transformation-preferences.json)
- `Trusted_Connection=True` → `Username=postgres;Password=postgres;` (PostgreSQL doesn't support Windows Auth)
- `MultipleActiveResultSets=true` → Removed (PostgreSQL-unsupported)
- `TrustServerCertificate=True` → Removed (SQL Server-specific)

---

## 6. Schema Mapping (from DMS schema_mapping_tool)

| SQL Server Object | PostgreSQL Object |
|-------------------|-------------------|
| `[dbo].[Products]` | `products` |
| `[dbo].[ProductHistory]` | `producthistory` |
| `[dbo].[ProductStats]` | `productstats` |
| `[dbo].[Categories]` | `categories` |
| `[dbo].[Suppliers]` | `suppliers` |

### Column Name Mappings (all lowercased)
- `ProductId` → `productid`
- `Name` → `name`
- `Description` → `description`
- `Price` → `price`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`
- (All other columns follow the same lowercase pattern)

### Type Mappings
- `int IDENTITY(1,1)` → `INTEGER GENERATED ALWAYS AS IDENTITY`
- `nvarchar(n)` → `VARCHAR(n)`
- `decimal(18,2)` → `NUMERIC(18,2)`
- `datetime` → `TIMESTAMP WITHOUT TIME ZONE`
- `bit` → `BOOLEAN`
- `GETDATE()` → `clock_timestamp()`

---

## 7. Build Status

- **Final Build**: SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference type warnings, no new warnings introduced)

---

## 8. Statements Requiring Manual Review

All 7 SQL statements require manual review because:
1. DMS statement_conversion_tool was unavailable (consistent metadata model creation failure)
2. SQL Equivalency tool returned ERROR for all 7 pairs (error: 'uniqueID')
3. Manual conversions applied lowercase schema mapping rules per DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA guidelines
4. Transaction blocks (statements 3, 4, 5) were restructured from single SQL blocks to multiple ADO.NET commands - this changes the execution model

Refer to `sql_equivalency_validation_report.json` for the complete detailed report of each statement pair.
