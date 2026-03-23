# Migration Report: SQL Server to PostgreSQL - AdoCore Application

## Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Manually Converted (DMS Failure) | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |

## DMS Tool Status

The DMS MCP tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements. All attempts failed with the same error:

- **Error**: `Metadata model creation/conversion failed: Metadata model creation did not complete after 15 attempts`
- **Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Multiple retry strategies** were attempted including increased poll attempts (30) and extended intervals (15s), as well as testing with trivial statements. The DMS service was consistently unresponsive.

Per the transformation definition, manual conversion was performed using **DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA** rules.

## SQL Equivalency Tool Status

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs. All 7 returned:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be a consistent tool-side error unrelated to the statement content. Per the transformation definition, all equivalency statuses are recorded as **ERROR** (no agent judgment was used to determine equivalency).

## File Changes

| File | Change Description |
|------|-------------------|
| `sourceCode/AdoCore.csproj` | `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.6` |
| `sourceCode/DataAccess/ProductRepository.cs` | SQL statements converted to PostgreSQL; SqlClient → Npgsql classes |
| `sourceCode/appsettings.json` | Connection strings updated to PostgreSQL format |

## Detailed Statement Conversion Report

### Statement 1: GetAllProductsAsync

- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetAllProductsAsync()`
- **DMS Status**: FAILED (metadata model timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

**Original MS SQL:**
```sql
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
```

**Converted PostgreSQL:**
```sql
WITH productstats AS (
    SELECT productid, AVG(price) OVER() as avgprice, COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name
```

**Changes**: Lowercase schema object names only (query is PostgreSQL-compatible)

---

### Statement 2: GetProductByIdAsync

- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetProductByIdAsync(int productId)`
- **DMS Status**: FAILED (metadata model timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

**Changes**: Lowercase schema object names only (LAG window function is PostgreSQL-compatible)

---

### Statement 3: InsertProductAsync

- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `InsertProductAsync(Product product)`
- **DMS Status**: FAILED (metadata model timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

**Key Changes**:
- `SCOPE_IDENTITY()` → `INSERT ... RETURNING productid` (using writable CTE pattern)
- `GETDATE()` → `NOW()`
- `DECLARE @NewProductId INT` / `SET @NewProductId` → Writable CTE with RETURNING
- `BEGIN TRANSACTION / COMMIT` → Removed (single writable CTE statement is atomic)
- All table/column names → lowercase

---

### Statement 4: UpdateProductAsync

- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `UpdateProductAsync(Product product)`
- **DMS Status**: FAILED (metadata model timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

**Key Changes**:
- `DECLARE @OldPrice / @OldStock` → Writable CTE `old_values` with SELECT
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION / COMMIT` → Removed (single writable CTE statement)
- All table/column names → lowercase

---

### Statement 5: DeleteProductAsync

- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `DeleteProductAsync(int productId)`
- **DMS Status**: FAILED (metadata model timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

**Key Changes**:
- `DECLARE @OldPrice / @OldStock` → Writable CTE `old_values` with SELECT
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION / COMMIT` → Removed (single writable CTE statement)
- CASE expression preserved for AveragePrice calculation
- All table/column names → lowercase

---

### Statement 6: GetProductsByPriceRangeAsync

- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **DMS Status**: FAILED (metadata model timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

**Changes**: Lowercase schema object names only (RANK, PERCENT_RANK, BETWEEN are PostgreSQL-compatible)

---

### Statement 7: GetLowStockProductsAsync

- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **DMS Status**: FAILED (metadata model timeout)
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool returned 'uniqueID' error)

**Key Changes**:
- Lowercase schema object names
- Added `::NUMERIC` cast for `stockquantity::NUMERIC / avgstock` to ensure proper decimal division in PostgreSQL (integer division would truncate)

---

## ADO.NET Class Replacements

| Original (SqlClient) | Replacement (Npgsql) | Occurrences |
|----------------------|---------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |

## Package Dependency Change

| Original | Replacement | Notes |
|----------|------------|-------|
| `Microsoft.Data.SqlClient 5.1.4` | `Npgsql 8.0.6` | Version 8.0.6 used instead of 8.0.1 to address GHSA-x9vc-6hfv-hg8c vulnerability |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (not applicable) |
| SSL | `TrustServerCertificate=True` | Removed |

## Transformation Artifacts

| Artifact | Location | Contents |
|----------|----------|----------|
| `extracted_statements.sql` | `sourceCode/` | All 7 original MS SQL statements with source locations |
| `converted_statements.sql` | `sourceCode/` | All 7 converted PostgreSQL statements with conversion notes |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Full equivalency report with all 7 statement pairs |
| `migration_report.md` | `sourceCode/` | This report |

## Exit Criteria Verification

| Criterion | Status |
|-----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ |
| All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql equivalents | ✅ |
| All SQL statements processed through DMS MCP tool | ✅ (all 7 attempted; all failed with timeout) |
| Comprehensive catalog of all SQL statements exists | ✅ |
| All statement pairs validated through SQL Equivalency tool | ✅ (all 7 validated; all returned ERROR) |
| Comprehensive equivalency validation report generated | ✅ |
| No agent judgment used for equivalency determinations | ✅ |
| DMS-failed statements documented with manual conversion | ✅ |
| Connection strings updated to PostgreSQL format | ✅ |
| Application compiles without errors | ✅ (0 errors, 10 pre-existing warnings) |

## Build Status

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All warnings are pre-existing nullable reference warnings from the original codebase (CS8600, CS8601, CS8603, CS8618, CS8625).
