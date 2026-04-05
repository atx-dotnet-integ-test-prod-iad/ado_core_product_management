# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| Migration Date | 2026-04-05 |
| Source Database | Microsoft SQL Server 2019 (ProductManagement) |
| Target Database | PostgreSQL 13 |
| Application Framework | .NET 9.0 / ADO.NET |
| Total SQL Statements | 7 |
| Files Modified | 3 |

---

## SQL Statement Conversion

### DMS Tool Conversion Results

| Metric | Count |
|--------|-------|
| Total Statements Processed | 7 |
| DMS Tool Successful | 0 |
| DMS Tool Failed | 7 |
| Manual Conversion (with lowercase schema) | 7 |

**DMS Failure Reason:** The DMS statement_conversion_tool consistently failed with "Metadata model creation/conversion did not complete after 15 attempts" (timeout). Multiple retries were attempted with varying poll configurations (default, 25 attempts/12s interval, 30 attempts/15s interval). Both complex and simple queries failed.

**DMS Schema Mapping:** The DMS schema_mapping_tool worked successfully and was used to obtain the exact target schema/table/column names for manual conversion.

### Schema Mapping (from DMS schema_mapping_tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |
| `ProductId` (column) | `productid` |
| `Name` (column) | `name` |
| `Description` (column) | `description` |
| `Price` (column) | `price` |
| `StockQuantity` (column) | `stockquantity` |
| `CreatedDate` (column) | `createddate` |
| `ModifiedDate` (column) | `modifieddate` |
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `RETURNING` clause |
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| `decimal(18,2)` | `NUMERIC(18,2)` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `nvarchar(N)` | `VARCHAR(N)` |

### SQL Statement Details

#### Statement 1: GetAllProductsAsync
- **Type:** SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, schema prefix `productmanagement_dbo` added, CTE renamed from `ProductStats` to `productstats_cte` to avoid table name conflict

#### Statement 2: GetProductByIdAsync
- **Type:** SELECT with CTE, LAG Window Function, LEFT JOIN, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, schema prefix added, CTE renamed from `ProductHistory` to `producthistory_cte`

#### Statement 3: InsertProductAsync
- **Type:** Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), UPDATE, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Restructured to writable CTE with RETURNING clause; SCOPE_IDENTITY() eliminated; GETDATE() → clock_timestamp(); Transaction management moved to C# level

#### Statement 4: UpdateProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** DECLARE/SET variables replaced with CTE (old_values); GETDATE() → clock_timestamp(); Transaction management moved to C# level

#### Statement 5: DeleteProductAsync
- **Type:** Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** DECLARE/SET variables replaced with CTE (old_values); GETDATE() → clock_timestamp(); Transaction management moved to C# level

#### Statement 6: GetProductsByPriceRangeAsync
- **Type:** SELECT with CTE, RANK(), PERCENT_RANK() Window Functions, BETWEEN, CASE
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, schema prefix added

#### Statement 7: GetLowStockProductsAsync
- **Type:** SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Key Changes:** Table/column names lowercased, schema prefix added, added CAST(stockquantity AS NUMERIC) for integer division fix

---

## SQL Equivalency Validation Results

| Metric | Count |
|--------|-------|
| Total Statement Pairs Validated | 7 |
| Equivalent | 0 |
| Not Equivalent | 0 |
| Error | 7 |

**Note:** The SQL Equivalency validation tool (sql-equivalency___validate_sql_equivalence) returned a systemic ERROR with message `'uniqueID'` for all 7 statement pairs. This appears to be a tool-level infrastructure issue, not related to the SQL statements themselves. All 7 statements were submitted as required by the transformation definition.

**Full equivalency report:** See `sql_equivalency_validation_report.json` for detailed results.

---

## Files Modified

### 1. DataAccess/ProductRepository.cs
- **All 7 SQL statements** replaced with PostgreSQL equivalents
- **ADO.NET class replacements:**
  - `using Microsoft.Data.SqlClient` → `using Npgsql`
  - `SqlConnection` → `NpgsqlConnection`
  - `SqlCommand` → `NpgsqlCommand`
  - `SqlDataReader` → `NpgsqlDataReader`
- **Transaction handling:** InsertProductAsync, UpdateProductAsync, and DeleteProductAsync now use C#-level transactions (BeginTransactionAsync/CommitAsync/RollbackAsync) instead of SQL-level BEGIN TRANSACTION/COMMIT
- **Column name references:** MapProductFromReader updated to use lowercase column names matching PostgreSQL schema

### 2. AdoCore.csproj
- `Microsoft.Data.SqlClient` Version 5.1.4 → `Npgsql` Version 8.0.6

### 3. appsettings.json
- **DevConnection:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection:** Same transformation as DevConnection

---

## Artifacts Generated

| File | Description |
|------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements with context |
| `converted_statements.sql` | All 7 converted PostgreSQL statements with notes |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency report in JSON format |
| `migration_report.md` | This report |

---

## Build Verification

- **Build Command:** `dotnet build`
- **Result:** ✅ Build succeeded
- **Errors:** 0
- **Warnings:** 10 (all pre-existing nullable reference warnings, not introduced by migration)

---

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS statement conversion tool failure (manual conversion applied)
2. SQL equivalency tool returning systemic errors

**Priority review items:**
- **Statements 3, 4, 5 (Insert, Update, Delete):** These were significantly restructured from SQL Server DECLARE/SET/BEGIN TRANSACTION patterns to PostgreSQL writable CTEs. The transaction semantics should be verified in integration testing.
- **Statement 7 (GetLowStockProducts):** Added CAST(stockquantity AS NUMERIC) to prevent integer division truncation in PostgreSQL.

---

## Recommendations

1. **Integration Testing:** Run full integration tests against a PostgreSQL database to verify all 7 SQL statements execute correctly
2. **Transaction Testing:** Specifically test the Insert, Update, and Delete operations to ensure writable CTEs behave atomically within the C#-level transactions
3. **Performance Testing:** The writable CTE approach may have different performance characteristics than the original SQL Server DECLARE/SET approach
4. **Connection String Security:** Update the PostgreSQL connection strings with actual production credentials (current values are placeholders)
5. **Schema Verification:** Confirm that the `productmanagement_dbo` schema exists in the target PostgreSQL database with the expected table structures
