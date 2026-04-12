# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS Tool | 0 |
| Statements Requiring Manual Intervention (DMS Failed) | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Validation Errors | 7 |

## Migration Overview

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved:

1. **SQL Statement Conversion**: All 7 SQL statements in `DataAccess/ProductRepository.cs` were extracted, converted to PostgreSQL syntax, and re-integrated.
2. **ADO.NET Class Migration**: All SQL Server ADO.NET classes (`SqlConnection`, `SqlCommand`, `SqlDataReader`) were replaced with Npgsql equivalents (`NpgsqlConnection`, `NpgsqlCommand`, `NpgsqlDataReader`).
3. **Package Reference Update**: `Microsoft.Data.SqlClient` 5.1.4 replaced with `Npgsql` 8.0.1.
4. **Connection String Update**: SQL Server connection strings converted to PostgreSQL format.

## DMS Tool Status

All 7 statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following parameters:
- `migration_project_identifier`: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- `database_name`: `ProductManagement`
- `schema_name`: `dbo`

**All 7 statements failed** with error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

Manual conversion was applied with lowercase schema object names per the transformation definition rule: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Equivalency Validation Status

All 7 statement pairs were validated using the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 validations returned ERROR** with error: `'uniqueID'`

Per the transformation definition, these are marked as ERROR (tool failures are never substituted with agent judgment).

## Detailed Statement Breakdown

### Statement 1: GetAllProductsAsync

| Property | Value |
|----------|-------|
| Source File | `DataAccess/ProductRepository.cs` |
| Method | `GetAllProductsAsync()` |
| DMS Status | FAILED |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR |

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
WITH productstats AS (
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
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END,
    p.name
```

**Conversion Notes:** Schema objects converted to lowercase. CTE and window functions syntax identical in PostgreSQL.

---

### Statement 2: GetProductByIdAsync

| Property | Value |
|----------|-------|
| Source File | `DataAccess/ProductRepository.cs` |
| Method | `GetProductByIdAsync(int productId)` |
| DMS Status | FAILED |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR |

**Original MS SQL:**
```sql
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity,
    p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL:**
```sql
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT 
    p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Conversion Notes:** Schema objects converted to lowercase. LAG window function syntax identical in PostgreSQL.

---

### Statement 3: InsertProductAsync

| Property | Value |
|----------|-------|
| Source File | `DataAccess/ProductRepository.cs` |
| Method | `InsertProductAsync(Product product)` |
| DMS Status | FAILED |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR |

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

**Converted PostgreSQL:**
```sql
WITH new_product AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
log_insertion AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM new_product
),
update_stats AS (
    UPDATE productstats SET totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW() WHERE statid = 1
)
SELECT productid FROM new_product;
```

**Conversion Notes:** SCOPE_IDENTITY() replaced with INSERT...RETURNING pattern using writable CTEs. GETDATE() replaced with NOW(). DECLARE/SET variables eliminated. Transaction managed by single writable CTE statement.

---

### Statement 4: UpdateProductAsync

| Property | Value |
|----------|-------|
| Source File | `DataAccess/ProductRepository.cs` |
| Method | `UpdateProductAsync(Product product)` |
| DMS Status | FAILED |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR |

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

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock FROM products WHERE productid = @ProductId
),
do_update AS (
    UPDATE products SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId
),
log_changes AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, NOW() FROM old_values
)
UPDATE productstats SET averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW() WHERE statid = 1;
```

**Conversion Notes:** DECLARE/SET variables replaced with CTE subquery. GETDATE() replaced with NOW(). Transaction managed by single writable CTE statement.

---

### Statement 5: DeleteProductAsync

| Property | Value |
|----------|-------|
| Source File | `DataAccess/ProductRepository.cs` |
| Method | `DeleteProductAsync(int productId)` |
| DMS Status | FAILED |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR |

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

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock FROM products WHERE productid = @ProductId
),
log_deletion AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, NOW() FROM old_values
),
do_delete AS (
    DELETE FROM products WHERE productid = @ProductId
)
UPDATE productstats SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1) ELSE 0 END,
    lastupdated = NOW() WHERE statid = 1;
```

**Conversion Notes:** DECLARE/SET variables replaced with CTE subquery. GETDATE() replaced with NOW(). CASE expression preserved. Transaction managed by single writable CTE statement.

---

### Statement 6: GetProductsByPriceRangeAsync

| Property | Value |
|----------|-------|
| Source File | `DataAccess/ProductRepository.cs` |
| Method | `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)` |
| DMS Status | FAILED |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR |

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

**Conversion Notes:** Schema objects converted to lowercase. RANK() and PERCENT_RANK() window functions syntax identical in PostgreSQL.

---

### Statement 7: GetLowStockProductsAsync

| Property | Value |
|----------|-------|
| Source File | `DataAccess/ProductRepository.cs` |
| Method | `GetLowStockProductsAsync(int threshold)` |
| DMS Status | FAILED |
| Conversion Method | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| Equivalency Status | ERROR |

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
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Conversion Notes:** Schema objects converted to lowercase. Added `::numeric` cast for integer division in ROUND to ensure correct PostgreSQL behavior.

---

## Code Changes Summary

### Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced all 7 SQL statements, updated all ADO.NET classes to Npgsql, updated using directive |
| `AdoCore.csproj` | Replaced `Microsoft.Data.SqlClient` 5.1.4 with `Npgsql` 8.0.1 |
| `appsettings.json` | Updated connection strings from SQL Server to PostgreSQL format |

### Files Verified (No Changes Needed)

| File | Reason |
|------|--------|
| `Program.cs` | No SQL Server references |
| `Business/ProductService.cs` | No SQL Server references |
| `CLI/CommandLineInterface.cs` | No SQL Server references |
| `CLI/InteractiveMenu.cs` | No SQL Server references |
| `Models/Product.cs` | Pure POCO model |

### ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|-------------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |

### Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | Removed (not applicable) |
| TrustServerCertificate | `TrustServerCertificate=True` | Removed (not applicable) |

## Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | `sourceCode/` | All 7 original MS SQL statements |
| `converted_statements.sql` | `sourceCode/` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | `sourceCode/` | Comprehensive equivalency validation report |
| `migration_report.md` | `sourceCode/` | This report |

## Build Verification

Final build result: **Build succeeded** with 0 errors and 12 warnings (pre-existing nullable reference type warnings).

```
Build succeeded.
    12 Warning(s)
    0 Error(s)
```
