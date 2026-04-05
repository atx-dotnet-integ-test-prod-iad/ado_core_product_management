# Migration Report: Microsoft SQL Server to PostgreSQL

## Overview

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The application uses ADO.NET for database access and has been migrated from `Microsoft.Data.SqlClient` to `Npgsql`.

## Migration Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements converted by DMS MCP tool | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated as equivalent (SQL Equivalency tool) | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

### DMS Tool Status
The DMS MCP statement conversion tool (dms-mcp___statement_conversion_tool) failed consistently for all 7 statements with the error: "Metadata model creation/conversion did not complete after 15 attempts". Multiple retry attempts were made with varying poll intervals and max attempts. The DMS schema_mapping_tool was successfully used to obtain accurate schema mappings for manual conversion.

### SQL Equivalency Tool Status
The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) returned ERROR with `'uniqueID'` error for all 7 statement pairs. This appears to be a systemic issue with the tool's backend. All statements are marked as ERROR per the requirement that agent judgment must NOT be used for equivalency determination.

## Schema Mapping (from DMS schema_mapping_tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

All column names converted to lowercase in PostgreSQL (e.g., `ProductId` → `productid`, `StockQuantity` → `stockquantity`).

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source Location:** `DataAccess/ProductRepository.cs`, lines ~42-65
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** CTE name changed from `ProductStats` to `productstats_cte` (to avoid conflict with the `productstats` table), all table/column names lowercased

**Original (MS SQL):**
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

**Converted (PostgreSQL):**
```sql
WITH productstats_cte AS (
    SELECT productid, AVG(price) OVER() as avgprice, COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name
```

### Statement 2: GetProductByIdAsync
- **Source Location:** `DataAccess/ProductRepository.cs`, lines ~74-96
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** CTE name changed to `producthistory_cte`, all table/column names lowercased

### Statement 3: InsertProductAsync
- **Source Location:** `DataAccess/ProductRepository.cs`, lines ~108-129
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `SCOPE_IDENTITY()` → `INSERT...RETURNING` with CTE pattern
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION`/`COMMIT` → Replaced with CTE-based single statement
  - `DECLARE @var` → Replaced with CTE subqueries

### Statement 4: UpdateProductAsync
- **Source Location:** `DataAccess/ProductRepository.cs`, lines ~142-168
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION`/`COMMIT` → Replaced with CTE-based single statement
  - `DECLARE @OldPrice`/`@OldStock` → Replaced with CTE `old_values`

### Statement 5: DeleteProductAsync
- **Source Location:** `DataAccess/ProductRepository.cs`, lines ~180-209
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:**
  - `GETDATE()` → `NOW()`
  - `BEGIN TRANSACTION`/`COMMIT` → Replaced with CTE-based single statement
  - `DECLARE @OldPrice`/`@OldStock` → Replaced with CTE `old_values`

### Statement 6: GetProductsByPriceRangeAsync
- **Source Location:** `DataAccess/ProductRepository.cs`, lines ~221-239
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** All table/column names lowercased, CTE name lowercased

### Statement 7: GetLowStockProductsAsync
- **Source Location:** `DataAccess/ProductRepository.cs`, lines ~253-270
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR
- **Key Changes:** All table/column names lowercased, added `CAST(stockquantity AS NUMERIC)` to prevent integer division

## Files Modified

### 1. DataAccess/ProductRepository.cs
- **Using directive:** `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **ADO.NET class replacements:**
  - `SqlConnection` → `NpgsqlConnection` (3 references: field, return type, constructor)
  - `SqlCommand` → `NpgsqlCommand` (7 references: one per query method)
  - `SqlDataReader` → `NpgsqlDataReader` (1 reference: MapProductFromReader)
- **SQL statements:** All 7 replaced with PostgreSQL equivalents
- **Column references in MapProductFromReader:** Updated to lowercase (`"productid"`, `"name"`, etc.)
- **Parameter syntax:** `@param` preserved (compatible with Npgsql)
- **Transaction handling:** `BeginTransactionAsync`/`CommitAsync`/`RollbackAsync` preserved (compatible with Npgsql)

### 2. AdoCore.csproj
- **Removed:** `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- **Added:** `<PackageReference Include="Npgsql" Version="8.0.6" />`
  - Note: Plan specified 8.0.1 but upgraded to 8.0.6 to address known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)

### 3. appsettings.json
- **DevConnection:** `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- **ProdConnection:** Same transformation as DevConnection
- **Removed SQL Server parameters:** `Trusted_Connection`, `MultipleActiveResultSets`, `TrustServerCertificate`

## Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| Extracted SQL statements | `sourceCode/extracted_statements.sql` | Complete (7 statements) |
| Converted SQL statements | `sourceCode/converted_statements.sql` | Complete (7 statements) |
| SQL Equivalency Report | `sourceCode/sql_equivalency_validation_report.json` | Complete (7 entries) |
| Migration Report | `sourceCode/migration_report.md` | Complete |

## Build Status

The application compiles successfully with 0 errors after migration:
```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```
All warnings are pre-existing nullable reference type warnings unrelated to the migration.

## Exit Criteria Checklist

| # | Criterion | Status |
|---|-----------|--------|
| 1 | All SQL Server packages replaced with PostgreSQL equivalents | ✅ |
| 2 | All SqlConnection/SqlCommand/SqlDataReader/SqlParameter replaced with Npgsql | ✅ |
| 3 | ALL SQL statements processed through DMS MCP tool | ✅ (all attempted, all failed, manual conversion applied) |
| 4 | Comprehensive catalog of all SQL statements exists | ✅ |
| 5 | ALL statement pairs validated through SQL Equivalency tool | ✅ (all returned ERROR) |
| 6 | Comprehensive equivalency report generated | ✅ |
| 7 | No agent judgment used for equivalency | ✅ |
| 8 | DMS failures documented with manual conversions | ✅ |
| 9 | Connection strings updated to PostgreSQL format | ✅ |
| 10 | Transaction handling updated | ✅ |
| 11 | Application compiles without errors | ✅ |
