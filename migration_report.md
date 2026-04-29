# Migration Report: SQL Server to PostgreSQL

## Summary

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all SQL statements, updating ADO.NET database access classes from `Microsoft.Data.SqlClient` to `Npgsql`, and updating connection strings and configuration.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention after DMS failure | 7 |
| Statements validated as equivalent by SQL Equivalency tool | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Status

The DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) was called for all 7 SQL statements. All calls failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple retry attempts with varying poll settings (15/30/40 max_poll_attempts, 10/15/20/30 poll_interval_seconds) all produced the same error.

**Note:** The DMS schema mapping tool (`dms-mcp___schema_mapping_tool`) succeeded and provided accurate schema mappings used for manual conversion:
- `dbo.Products` → `productmanagement_dbo.products` (all columns lowercase)
- `dbo.ProductHistory` → `productmanagement_dbo.producthistory` (all columns lowercase)
- `dbo.ProductStats` → `productmanagement_dbo.productstats` (all columns lowercase)
- `GETDATE()` → `clock_timestamp()`
- `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`

## SQL Equivalency Tool Status

The SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`) was called for all 7 statement pairs. All calls returned ERROR:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This was a consistent system-level error across all calls, not related to individual statement content.

## Detailed Statement Migration

### Statement 1: GetAllProductsAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `GetAllProductsAsync()`
**DMS Conversion Status:** FAILED
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Status:** ERROR (tool error: 'uniqueID')

**Original MS SQL:**
```sql
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END,
    p.Name
```

**Converted PostgreSQL:**
```sql
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END,
    p.name
```

**Changes:** All identifiers lowercased. CTE renamed from `ProductStats` to `productstats_cte` to avoid conflict with table name.

---

### Statement 2: GetProductByIdAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `GetProductByIdAsync(int productId)`
**DMS Conversion Status:** FAILED
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Status:** ERROR (tool error: 'uniqueID')

**Original MS SQL:**
```sql
WITH ProductHistory AS (
    SELECT ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE WHEN ph.PreviousPrice IS NOT NULL THEN 
        ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
    ELSE NULL END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL:**
```sql
WITH producthistory_cte AS (
    SELECT productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN 
        ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
    ELSE NULL END as pricechangepercentage
FROM products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Changes:** All identifiers lowercased. CTE renamed to avoid table name conflict.

---

### Statement 3: InsertProductAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `InsertProductAsync(Product product)`
**DMS Conversion Status:** FAILED
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Status:** ERROR (tool error: 'uniqueID')

**Original MS SQL:**
```sql
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    UPDATE ProductStats SET TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
SELECT @NewProductId;
```

**Converted PostgreSQL (3 separate statements in app-level transaction):**
```sql
-- Statement 3a
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid;

-- Statement 3b
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Statement 3c
UPDATE productstats SET totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = clock_timestamp() WHERE statid = 1;
```

**Changes:** `SCOPE_IDENTITY()` → `RETURNING productid`, `GETDATE()` → `clock_timestamp()`, `DECLARE`/`SET` removed and restructured to C# code, transaction managed at application level.

---

### Statement 4: UpdateProductAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `UpdateProductAsync(Product product)`
**DMS Conversion Status:** FAILED
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Status:** ERROR (tool error: 'uniqueID')

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    UPDATE Products SET Name = @Name, Description = @Description, Price = @Price,
        StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL (4 separate statements in app-level transaction):**
```sql
-- 4a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- 4b: Update product
UPDATE products SET name = @Name, description = @Description, price = @Price,
    stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId;
-- 4c: Log changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
-- 4d: Update stats
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = clock_timestamp() WHERE statid = 1;
```

**Changes:** `DECLARE` variables → C# variables, `GETDATE()` → `clock_timestamp()`, transaction managed at app level.

---

### Statement 5: DeleteProductAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `DeleteProductAsync(int productId)`
**DMS Conversion Status:** FAILED
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Status:** ERROR (tool error: 'uniqueID')

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL (4 separate statements in app-level transaction):**
```sql
-- 5a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;
-- 5b: Log deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
-- 5c: Delete product
DELETE FROM products WHERE productid = @ProductId;
-- 5d: Update stats
UPDATE productstats SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END,
    lastupdated = clock_timestamp() WHERE statid = 1;
```

**Changes:** Same pattern as Statement 4.

---

### Statement 6: GetProductsByPriceRangeAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
**DMS Conversion Status:** FAILED
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Status:** ERROR (tool error: 'uniqueID')

**Original MS SQL:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE 
    WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
    WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
    ELSE 'Premium' END as PriceSegment
FROM RankedProducts rp ORDER BY rp.PriceRank
```

**Converted PostgreSQL:**
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE 
    WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
    WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
    ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank
```

**Changes:** All identifiers lowercased.

---

### Statement 7: GetLowStockProductsAsync

**Source File:** `DataAccess/ProductRepository.cs`
**Method:** `GetLowStockProductsAsync(int threshold)`
**DMS Conversion Status:** FAILED
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Status:** ERROR (tool error: 'uniqueID')

**Original MS SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*, CASE 
    WHEN StockQuantity <= @Threshold THEN 'Critical'
    WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
    ELSE 'Adequate' END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**Converted PostgreSQL:**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock, MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT sa.*, CASE 
    WHEN stockquantity <= @Threshold THEN 'Critical'
    WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
    ELSE 'Adequate' END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Changes:** All identifiers lowercased. Added `CAST(stockquantity AS NUMERIC)` for PostgreSQL integer division.

---

## Package Changes

| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` 5.1.4 | `Npgsql` 8.0.6 |
| `Microsoft.Extensions.Configuration` 8.0.0 | (unchanged) |
| `Microsoft.Extensions.Configuration.Json` 8.0.0 | (unchanged) |
| `Microsoft.Extensions.DependencyInjection` 8.0.0 | (unchanged) |

## ADO.NET Class Changes

| SQL Server Class | PostgreSQL Equivalent |
|-----------------|----------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` |

## Connection String Changes

| Setting | Before | After |
|---------|--------|-------|
| DevConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres` |
| ProdConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres` |

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS statement conversion tool was unavailable (metadata model creation failed)
2. SQL Equivalency tool returned ERROR for all validation attempts
3. Manual conversion was applied using schema mappings from the DMS schema mapping tool

The manual conversions follow these rules:
- All schema object names (tables, columns) converted to lowercase per DMS schema mapping
- SQL Server functions converted: `SCOPE_IDENTITY()` → `RETURNING`, `GETDATE()` → `clock_timestamp()`
- T-SQL transaction blocks restructured to use application-level transaction management
- T-SQL variable declarations (`DECLARE @var`) replaced with C# variables

## Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| `extracted_statements.sql` | `sourceCode/extracted_statements.sql` | Complete - 7 statements |
| `converted_statements.sql` | `sourceCode/converted_statements.sql` | Complete - 7 statements |
| `sql_equivalency_validation_report.json` | `sourceCode/sql_equivalency_validation_report.json` | Complete - 7 pairs |
| `migration_report.md` | `sourceCode/migration_report.md` | This file |

## Build Status

**Final Build: SUCCESS** (0 errors, warnings are pre-existing nullable reference warnings)
