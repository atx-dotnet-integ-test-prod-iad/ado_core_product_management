# Migration Report: SQL Server to PostgreSQL - AdoCore Application

## Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-04 |
| **Application** | AdoCore - .NET ADO.NET Product Management |
| **Source Database** | Microsoft SQL Server |
| **Target Database** | PostgreSQL |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |
| **Total SQL Statements Processed** | 7 |
| **Statements Successfully Converted by DMS MCP Tool** | 0 |
| **Statements Requiring Manual Intervention** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Validation Errors** | 7 |
| **Build Status** | ✅ SUCCESS (0 errors, 10 pre-existing warnings) |

---

## 1. SQL Statement Conversion

### DMS MCP Tool Results

All 7 SQL statements were passed to the DMS MCP `statement_conversion_tool` with the following parameters:
- **Migration Project**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Database**: `ProductManagement`
- **Schema**: `dbo`
- **Region**: `us-east-1`

**All 7 statements failed** with the same error:
> `Metadata model creation failed: Metadata model creation did not complete after 15 attempts`

Per the transformation plan's fallback policy, all statements were manually converted using the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` approach.

### Statement Conversion Details

#### Statement 1: GetAllProductsAsync
- **Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **DMS Error**: Metadata model creation timeout
- **Changes**: Table/column names lowercased (Products→products, ProductId→productid, etc.)
- **Original**: CTE with AVG/COUNT OVER(), CASE, ROUND, INNER JOIN, ORDER BY with CASE
- **Converted**: Identical structure with lowercase identifiers

#### Statement 2: GetProductByIdAsync
- **Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **DMS Error**: Metadata model creation timeout
- **Changes**: Table/column names lowercased
- **Original**: CTE with LAG window function, LEFT JOIN, ROUND, CASE with NULL handling
- **Converted**: Identical structure with lowercase identifiers

#### Statement 3: InsertProductAsync
- **Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **DMS Error**: Metadata model creation timeout
- **Changes**:
  - `SCOPE_IDENTITY()` → `RETURNING productid` clause with writable CTEs
  - `GETDATE()` → `NOW()`
  - `DECLARE/SET @NewProductId` → CTE chain with `ins`, `hist`, `stats`
  - `BEGIN TRANSACTION/COMMIT` → Writable CTEs (atomic single statement)
  - Table/column names lowercased

#### Statement 4: UpdateProductAsync
- **Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **DMS Error**: Metadata model creation timeout
- **Changes**:
  - `DECLARE @OldPrice/@OldStock` + `SELECT INTO` → `old_values` CTE
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Writable CTEs
  - Table/column names lowercased

#### Statement 5: DeleteProductAsync
- **Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **DMS Error**: Metadata model creation timeout
- **Changes**:
  - `DECLARE @OldPrice/@OldStock` + `SELECT INTO` → `old_values` CTE
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION/COMMIT` → Writable CTEs
  - Table/column names lowercased

#### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **DMS Error**: Metadata model creation timeout
- **Changes**: Table/column names lowercased
- **Original**: CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Converted**: Identical structure with lowercase identifiers

#### Statement 7: GetLowStockProductsAsync
- **Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **DMS Error**: Metadata model creation timeout
- **Changes**:
  - Table/column names lowercased
  - Added `::numeric` cast for integer division in ROUND function
- **Original**: CTE with AVG/MIN/MAX OVER(), CASE, ROUND
- **Converted**: Lowercase identifiers + numeric cast

---

## 2. SQL Equivalency Validation

All 7 statement pairs were validated using the `sql-equivalency___validate_sql_equivalence` tool.

| # | Statement | Equivalency Status | Tool Output |
|---|-----------|-------------------|-------------|
| 1 | GetAllProductsAsync | ERROR | `'uniqueID'` |
| 2 | GetProductByIdAsync | ERROR | `'uniqueID'` |
| 3 | InsertProductAsync | ERROR | `'uniqueID'` |
| 4 | UpdateProductAsync | ERROR | `'uniqueID'` |
| 5 | DeleteProductAsync | ERROR | `'uniqueID'` |
| 6 | GetProductsByPriceRangeAsync | ERROR | `'uniqueID'` |
| 7 | GetLowStockProductsAsync | ERROR | `'uniqueID'` |

All equivalency checks returned ERROR from the tool. Per the transformation plan: "If sql-equivalency___validate_sql_equivalence returns an error, mark the equivalency status as ERROR." No agent judgment was used.

The comprehensive report is available in `sql_equivalency_validation_report.json`.

---

## 3. Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET classes replaced |
| `AdoCore.csproj` | Package reference updated |
| `appsettings.json` | Connection strings updated |

### Files NOT Modified (confirmed unchanged):
- `Models/Product.cs` - No database code
- `Business/ProductService.cs` - No database code
- `CLI/CommandLineInterface.cs` - No database code
- `CLI/InteractiveMenu.cs` - No database code
- `Program.cs` - No database code (DI configuration only)
- `Database/Scripts/01_InitialSetup.sql` - Reference SQL scripts
- `Scripts/01_InitialSetup.sql` - Reference SQL scripts

---

## 4. ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) | Occurrences |
|----------------------|------------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, return type, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader) |

---

## 5. Connection String Changes

### Before (SQL Server):
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL):
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping:
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | *(removed - not applicable)* |
| `TrustServerCertificate=True` | *(removed - not applicable)* |

---

## 6. Package Dependency Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|-------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

Unchanged packages:
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

---

## 7. Verification Checklist

| # | Check | Status |
|---|-------|--------|
| 1 | All SQL Server packages replaced with PostgreSQL equivalents | ✅ PASS |
| 2 | All SqlConnection → NpgsqlConnection, SqlCommand → NpgsqlCommand, SqlDataReader → NpgsqlDataReader | ✅ PASS |
| 3 | ALL 7 SQL statements processed through DMS MCP tool | ✅ PASS (all attempted, all failed with timeout) |
| 4 | ALL 7 SQL statement pairs validated through SQL Equivalency tool | ✅ PASS (all returned ERROR from tool) |
| 5 | sql_equivalency_validation_report.json contains all 7 entries | ✅ PASS |
| 6 | Connection strings updated to PostgreSQL format | ✅ PASS |
| 7 | Application compiles without errors | ✅ PASS (0 errors, 10 pre-existing warnings) |
| 8 | No remaining references to Microsoft.Data.SqlClient or Sql* ADO.NET classes | ✅ PASS |

---

## 8. Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | All 7 original MS SQL statements |
| `converted_statements.sql` | Project root | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Comprehensive equivalency validation report |
| `migration_report.md` | Project root | This report |

---

## 9. Known Issues and Recommendations

1. **DMS Tool Unavailability**: All DMS conversions timed out. Manual conversions were applied following the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` policy. It is recommended to re-validate these conversions when DMS becomes available.

2. **SQL Equivalency Tool Errors**: All equivalency checks returned ERROR with `'uniqueID'` message. This appears to be a tool-side issue. Manual review of the statement pairs is recommended.

3. **Writable CTEs**: The transaction-based statements (Insert, Update, Delete) were restructured from T-SQL procedural patterns (DECLARE/SET/BEGIN TRANSACTION) to PostgreSQL writable CTEs for Npgsql compatibility. These should be tested against the actual PostgreSQL database.

4. **Integer Division**: Statement 7 (GetLowStockProductsAsync) required a `::numeric` cast for the `stockquantity / avgstock` division to avoid integer truncation in PostgreSQL.
