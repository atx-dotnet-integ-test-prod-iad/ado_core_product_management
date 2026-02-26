# Migration Report: MS SQL Server to PostgreSQL

## Summary

| Metric | Value |
|---|---|
| Total SQL Statements Processed | 7 |
| DMS Tool Conversion Successes | 0 |
| DMS Tool Conversion Failures | 7 |
| Manual Conversions (DMS Failure) | 7 |
| Equivalency Validations: EQUIVALENT | 0 |
| Equivalency Validations: NOT_EQUIVALENT | 0 |
| Equivalency Validations: ERROR | 7 |
| Source File | DataAccess/ProductRepository.cs |
| Package Change | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.8 |

## DMS Tool Status

All 7 SQL statements were submitted to the AWS DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion. All 7 failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

DMS Parameters:
- database_name: ProductManagement
- schema_name: dbo
- server_name: ProductManagement
- region: us-east-1
- migration_project_identifier: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

Per transformation definition, manual conversion was applied with lowercase schema object names (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Tool Status

All 7 statement pairs were submitted to the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence). All 7 returned ERROR:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This appears to be an infrastructure issue with the tool itself, confirmed by testing with a trivial SELECT query.

## Statement Details

### Statement 1: GetAllProductsAsync()
- **Source**: DataAccess/ProductRepository.cs, GetAllProductsAsync() method
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Original MS SQL**:
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
- **Converted PostgreSQL**:
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
- **Changes**: All schema objects converted to lowercase

### Statement 2: GetProductByIdAsync()
- **Source**: DataAccess/ProductRepository.cs, GetProductByIdAsync() method
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Changes**: All schema objects converted to lowercase. LAG window function is PostgreSQL-compatible.

### Statement 3: InsertProductAsync()
- **Source**: DataAccess/ProductRepository.cs, InsertProductAsync() method
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `lastval()`
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @NewProductId INT` → removed (using lastval() directly)
  - All schema objects converted to lowercase

### Statement 4: UpdateProductAsync()
- **Source**: DataAccess/ProductRepository.cs, UpdateProductAsync() method
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**:
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @OldPrice/@OldStock` → replaced with subquery approach
  - All schema objects converted to lowercase

### Statement 5: DeleteProductAsync()
- **Source**: DataAccess/ProductRepository.cs, DeleteProductAsync() method
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**:
  - `GETDATE()` → `CURRENT_TIMESTAMP`
  - `BEGIN TRANSACTION` → `BEGIN`
  - `DECLARE @OldPrice/@OldStock` → replaced with subquery approach
  - All schema objects converted to lowercase

### Statement 6: GetProductsByPriceRangeAsync()
- **Source**: DataAccess/ProductRepository.cs, GetProductsByPriceRangeAsync() method
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Changes**: All schema objects converted to lowercase. RANK/PERCENT_RANK are PostgreSQL-compatible.

### Statement 7: GetLowStockProductsAsync()
- **Source**: DataAccess/ProductRepository.cs, GetLowStockProductsAsync() method
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool infrastructure issue)
- **Key Changes**:
  - All schema objects converted to lowercase
  - Added `CAST(stockquantity AS NUMERIC)` for integer division in ROUND function

## Code Changes

### Package Dependencies
| Original | Replacement |
|---|---|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.8 |

### ADO.NET Class Replacements
| Original | Replacement |
|---|---|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `new SqlConnection(...)` | `new NpgsqlConnection(...)` |
| `new SqlCommand(...)` | `new NpgsqlCommand(...)` |

### Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|---|---|---|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | *(removed - not applicable)* |
| TLS | `TrustServerCertificate=True` | *(removed - not applicable)* |

## Files Modified
1. **sourceCode/DataAccess/ProductRepository.cs** - SQL statements, ADO.NET classes, using statements
2. **sourceCode/AdoCore.csproj** - Package references
3. **sourceCode/appsettings.json** - Connection strings

## Transformation Artifacts
1. **sourceCode/extracted_statements.sql** - All 7 original MS SQL statements
2. **sourceCode/converted_statements.sql** - All 7 converted PostgreSQL statements
3. **sourceCode/sql_equivalency_validation_report.json** - Equivalency validation report for all 7 pairs
4. **sourceCode/migration_report.md** - This report

## Known Limitations
1. **SQL Script Files**: Scripts/01_InitialSetup.sql and Database/Scripts/01_InitialSetup.sql contain SQL Server DDL (CREATE TABLE, stored procedures) that need separate database migration. These are not used by the application at runtime.
2. **Stored Procedures**: The stored procedures in the script files (sp_GetAllProducts, sp_GetProductById, etc.) are not directly referenced by the application code.
3. **Transaction Handling**: The PostgreSQL transaction blocks (BEGIN/COMMIT) may behave differently from SQL Server's BEGIN TRANSACTION/COMMIT in error scenarios. Runtime testing against an actual PostgreSQL database is recommended.
4. **DMS Tool**: All 7 statements failed DMS conversion due to metadata model creation issues. Manual conversion was applied following the lowercase schema object naming convention.
5. **SQL Equivalency**: All 7 statement pairs returned ERROR from the equivalency tool due to infrastructure issues. Manual review of the conversions is recommended.
6. **Parameter Syntax**: Npgsql supports the `@ParameterName` syntax used in the code, so no changes were needed for parameter placeholders.

## Build Status
- **Final Build**: SUCCESS (0 errors, 10 warnings - all pre-existing nullable reference warnings)
