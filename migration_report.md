# Migration Report: SQL Server to PostgreSQL

## Summary
- **Application**: AdoCore (.NET 9.0 ADO.NET Console Application)
- **Migration**: Microsoft SQL Server → PostgreSQL
- **Date**: 2026-04-19
- **Database**: ProductManagement

## SQL Statement Processing

### Overview
| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements converted by DMS tool | 0 |
| Statements manually converted (DMS failure) | 7 |
| Equivalency validated as EQUIVALENT | 0 |
| Equivalency validated as NOT_EQUIVALENT | 0 |
| Equivalency with ERROR | 7 |

### DMS Conversion Tool Results
- **Tool**: `dms-mcp___statement_conversion_tool`
- **Migration Project**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **All 7 statements submitted** to the DMS tool for conversion
- **All 7 failed** with error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS Schema Mapping Tool** (`dms-mcp___schema_mapping_tool`) was used successfully to obtain authoritative schema mappings for all 3 tables

### Schema Mappings from DMS
| Source Table (SQL Server) | Target Table (PostgreSQL) | Target Schema |
|---------------------------|---------------------------|---------------|
| `dbo.Products` | `products` | `productmanagement_dbo` |
| `dbo.ProductHistory` | `producthistory` | `productmanagement_dbo` |
| `dbo.ProductStats` | `productstats` | `productmanagement_dbo` |

### SQL Equivalency Validation Results
- **Tool**: `sql-equivalency___validate_sql_equivalence`
- **All 7 statement pairs submitted** to the equivalency tool
- **All 7 returned ERROR** with: `{'equivalence_status': 'ERROR', 'error': "'uniqueID'"}`
- **Note**: Per transformation rules, all equivalency statuses are marked as ERROR based solely on tool output (no agent judgment applied)

---

## Detailed Statement Conversion

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **DMS Status**: Failed
- **Conversion Method**: Manual with lowercase schema
- **Equivalency**: ERROR (tool error)
- **Key Changes**: Lowercase table/column names, CTE renamed to `productstats_cte`

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
- **Method**: `GetProductByIdAsync(int productId)`
- **DMS Status**: Failed
- **Conversion Method**: Manual with lowercase schema
- **Equivalency**: ERROR (tool error)
- **Key Changes**: Lowercase table/column names, CTE renamed to `producthistory_cte`

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **DMS Status**: Failed
- **Conversion Method**: Manual with lowercase schema
- **Equivalency**: ERROR (tool error)
- **Key Changes**:
  - `SCOPE_IDENTITY()` → `INSERT ... RETURNING productid` with CTE
  - `GETDATE()` → `clock_timestamp()`
  - `DECLARE @NewProductId` → eliminated via CTE approach
  - `BEGIN TRANSACTION/COMMIT` → single atomic CTE statement

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **DMS Status**: Failed
- **Conversion Method**: Manual with lowercase schema
- **Equivalency**: ERROR (tool error)
- **Key Changes**:
  - `DECLARE @OldPrice, @OldStock` → CTE `old_values`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → single atomic CTE statement

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **DMS Status**: Failed
- **Conversion Method**: Manual with lowercase schema
- **Equivalency**: ERROR (tool error)
- **Key Changes**:
  - `DECLARE @OldPrice, @OldStock` → CTE `old_values`
  - `GETDATE()` → `clock_timestamp()`
  - `BEGIN TRANSACTION/COMMIT` → single atomic CTE statement

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **DMS Status**: Failed
- **Conversion Method**: Manual with lowercase schema
- **Equivalency**: ERROR (tool error)
- **Key Changes**: Lowercase table/column names only

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **DMS Status**: Failed
- **Conversion Method**: Manual with lowercase schema
- **Equivalency**: ERROR (tool error)
- **Key Changes**: Lowercase table/column names, added `::NUMERIC` cast for integer division

---

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |
| `Microsoft.Extensions.Configuration` v8.0.0 | `Microsoft.Extensions.Configuration` v8.0.0 (unchanged) |
| `Microsoft.Extensions.Configuration.Json` v8.0.0 | `Microsoft.Extensions.Configuration.Json` v8.0.0 (unchanged) |
| `Microsoft.Extensions.DependencyInjection` v8.0.0 | `Microsoft.Extensions.DependencyInjection` v8.0.0 (unchanged) |

**Note**: Npgsql v8.0.6 was selected instead of v8.0.0 to address known high-severity vulnerability GHSA-x9vc-6hfv-hg8c.

## Class Replacements

| SQL Server (Before) | PostgreSQL (After) |
|---------------------|--------------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

## Connection String Changes

### DevConnection
| Before | After |
|--------|-------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=ProductManagement` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| `MultipleActiveResultSets=true` | (removed - not applicable) |
| `TrustServerCertificate=True` | (removed) |
| N/A | `Port=5432` |

### ProdConnection
Same changes as DevConnection.

## Column Name Mapping (MapProductFromReader)

| Before (SQL Server) | After (PostgreSQL) |
|---------------------|--------------------|
| `reader["ProductId"]` | `reader["productid"]` |
| `reader["Name"]` | `reader["name"]` |
| `reader["Description"]` | `reader["description"]` |
| `reader["Price"]` | `reader["price"]` |
| `reader["StockQuantity"]` | `reader["stockquantity"]` |
| `reader["CreatedDate"]` | `reader["createddate"]` |
| `reader["ModifiedDate"]` | `reader["modifieddate"]` |

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | Project root | All 7 original MS SQL statements |
| `converted_statements.sql` | Project root | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Project root | Complete equivalency validation report |
| `migration_report.md` | Project root | This report |

## Build Status

- **Final build**: ✅ SUCCESS (0 errors, 10 warnings)
- **Warnings**: All pre-existing nullable reference type warnings (CS8601, CS8618, CS8600, CS8603, CS8625)
- **Vulnerable packages**: None
- **Remaining SQL Server references**: None

## Statements Flagged for Manual Review

All 7 statements should be reviewed manually because:
1. DMS conversion tool was unavailable (all conversions were manual)
2. SQL equivalency tool returned ERROR for all pairs (service-side issue)
3. Complex transaction statements (3, 4, 5) were restructured from DECLARE/BEGIN TRANSACTION to PostgreSQL CTEs with data-modifying statements
4. The CTE data-modifying approach ensures atomicity but differs structurally from the original
