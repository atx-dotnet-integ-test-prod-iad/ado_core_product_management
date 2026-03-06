# Migration Report: MS SQL Server to PostgreSQL

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS** | 6 |
| **Manual Conversion Required** | 1 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **Equivalency Validation Errors** | 7 |
| **Build Status** | ✅ SUCCESS |

## Migration Overview

This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved:

1. **SQL Statement Extraction**: All 7 SQL statements extracted from `ProductRepository.cs`
2. **DMS Conversion**: 6 of 7 statements successfully converted via AWS DMS MCP Tool
3. **Manual Conversion**: 1 statement (InsertProductAsync) required manual conversion due to DMS failure
4. **SQL Equivalency Validation**: All 7 pairs validated through the SQL Equivalency MCP Tool (all returned ERROR due to systematic tool issue)
5. **Static Code Migration**: Verified Npgsql packages, connection strings, and class replacements

---

## DMS Conversion Details

### Statement 1: GetAllProductsAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetAllProductsAsync()`
- **SQL Type**: CTE with AVG/COUNT window functions
- **Conversion Method**: `DMS_TOOL`
- **DMS Status**: ✅ SUCCESS

**Original MS SQL:**
```sql
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts
    FROM dbo.Products
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average'
         WHEN p.Price < ps.AvgPrice THEN 'Below Average'
         ELSE 'Average'
    END AS PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage
FROM dbo.Products AS p
INNER JOIN ProductStats AS ps ON p.ProductId = ps.ProductId
ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
```

**Converted PostgreSQL (DMS):**
```sql
WITH productstats
AS (SELECT productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average'
         WHEN p.price < ps.avgprice THEN 'Below Average'
         ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps ON p.productid = ps.productid
    ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END NULLS FIRST, p.name NULLS FIRST;
```

**Equivalency Status**: ERROR (Tool error: 'uniqueID')

---

### Statement 2: GetProductByIdAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetProductByIdAsync(int productId)`
- **SQL Type**: CTE with LAG window function
- **Conversion Method**: `DMS_TOOL`
- **DMS Status**: ✅ SUCCESS

**Original MS SQL:**
```sql
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice,
           LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
    FROM dbo.Products WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
    CASE WHEN ph.PreviousPrice IS NOT NULL
         THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
         ELSE NULL
    END AS PriceChangePercentage
FROM dbo.Products AS p
LEFT OUTER JOIN ProductHistory AS ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL (DMS):**
```sql
WITH producthistory
AS (SELECT productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice,
           lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products WHERE productid = @ProductId)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL
         THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
         ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid
    WHERE p.productid = @ProductId;
```

**Equivalency Status**: ERROR (Tool error: 'uniqueID')

---

### Statement 3: InsertProductAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `InsertProductAsync(Product product)`
- **SQL Type**: BEGIN/END block with SCOPE_IDENTITY(), multi-table INSERT/UPDATE
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **DMS Status**: ❌ FAILED
- **DMS Error**: `Metadata model creation failed: Statement definition is not valid.`

**Original MS SQL:**
```sql
DECLARE @NewProductId INT;
BEGIN
    INSERT INTO dbo.Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    UPDATE dbo.ProductStats SET TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE() WHERE StatId = 1;
END;
```

**Converted PostgreSQL (Manual):**
```sql
DO $$
DECLARE
    var_newproductid INTEGER;
BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO var_newproductid;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (var_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    UPDATE productmanagement_dbo.productstats SET
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp() WHERE statid = 1;
END $$;
```

**Manual Conversion Notes:**
- `SCOPE_IDENTITY()` → `RETURNING productid INTO var_newproductid`
- `GETDATE()` → `clock_timestamp()`
- `dbo.*` → `productmanagement_dbo.*` (lowercase)
- `BEGIN/END` → `DO $$ ... END $$`
- All schema object names converted to lowercase

**Equivalency Status**: ERROR (Tool error: 'uniqueID')

---

### Statement 4: UpdateProductAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `UpdateProductAsync(Product product)`
- **SQL Type**: BEGIN/END block with SELECT INTO, UPDATE, INSERT
- **Conversion Method**: `DMS_TOOL`
- **DMS Status**: ✅ SUCCESS

**Original MS SQL:**
```sql
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;
BEGIN
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId;
    UPDATE dbo.Products SET Name = @Name, Description = @Description, Price = @Price,
        StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
    INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    UPDATE dbo.ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE() WHERE StatId = 1;
END;
```

**Converted PostgreSQL (DMS):**
```sql
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts,
        lastupdated = clock_timestamp() WHERE statid = 1;
END $$;
```

**Equivalency Status**: ERROR (Tool error: 'uniqueID')

---

### Statement 5: DeleteProductAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `DeleteProductAsync(int productId)`
- **SQL Type**: BEGIN/END block with SELECT INTO, INSERT, DELETE, UPDATE with CASE
- **Conversion Method**: `DMS_TOOL`
- **DMS Status**: ✅ SUCCESS

**Original MS SQL:**
```sql
DECLARE @OldPrice DECIMAL(18, 2);
DECLARE @OldStock INT;
BEGIN
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId;
    INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM dbo.Products WHERE ProductId = @ProductId;
    UPDATE dbo.ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
END;
```

**Converted PostgreSQL (DMS):**
```sql
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    SELECT price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());
    DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
        CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1) ELSE 0 END,
        lastupdated = clock_timestamp() WHERE statid = 1;
END $$;
```

**Equivalency Status**: ERROR (Tool error: 'uniqueID')

---

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **SQL Type**: CTE with RANK, PERCENT_RANK
- **Conversion Method**: `DMS_TOOL`
- **DMS Status**: ✅ SUCCESS

**Original MS SQL:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank,
           PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM dbo.Products AS p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
    WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS PriceSegment
FROM RankedProducts AS rp ORDER BY rp.PriceRank
```

**Converted PostgreSQL (DMS):**
```sql
WITH rankedproducts
AS (SELECT p.*, RANK() OVER (ORDER BY p.price) AS pricerank,
           percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
    WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS pricesegment
    FROM rankedproducts AS rp ORDER BY rp.pricerank NULLS FIRST;
```

**Equivalency Status**: ERROR (Tool error: 'uniqueID')

---

### Statement 7: GetLowStockProductsAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **SQL Type**: CTE with AVG, MIN, MAX window functions
- **Conversion Method**: `DMS_TOOL`
- **DMS Status**: ✅ SUCCESS

**Original MS SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER () AS AvgStock,
           MIN(StockQuantity) OVER () AS MinStock, MAX(StockQuantity) OVER () AS MaxStock
    FROM dbo.Products AS p
)
SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
    WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END AS StockStatus,
    ROUND((CAST(StockQuantity AS DECIMAL(18, 0)) / AvgStock) * 100, 2) AS StockPercentageOfAverage
FROM StockAnalysis AS sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**Converted PostgreSQL (DMS):**
```sql
WITH stockanalysis
AS (SELECT p.*, AVG(stockquantity) OVER () AS avgstock,
           MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical'
    WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END AS stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC(18, 0)) / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa WHERE stockquantity <= @Threshold ORDER BY stockquantity NULLS FIRST;
```

**Equivalency Status**: ERROR (Tool error: 'uniqueID')

---

## SQL Equivalency Validation Summary

All 7 statement pairs were individually validated through the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All returned an ERROR status with error `'uniqueID'`, which indicates a systematic tool-side issue rather than actual equivalency problems. Per the transformation definition, these are marked as ERROR without agent judgment substitution.

The full equivalency validation report is available in `sql_equivalency_validation_report.json`.

---

## Static Code Changes Summary

### Package References (AdoCore.csproj)
| Package | Status |
|---------|--------|
| `Microsoft.Data.SqlClient` | ❌ NOT present (removed) |
| `Npgsql` Version 8.0.6 | ✅ Present |
| `Microsoft.Extensions.Configuration` Version 8.0.0 | ✅ Unchanged |
| `Microsoft.Extensions.Configuration.Json` Version 8.0.0 | ✅ Unchanged |
| `Microsoft.Extensions.DependencyInjection` Version 8.0.0 | ✅ Unchanged |

### Class Replacements (ProductRepository.cs)
| SQL Server Class | Npgsql Equivalent | Status |
|-----------------|-------------------|--------|
| `SqlConnection` | `NpgsqlConnection` | ✅ Replaced |
| `SqlCommand` | `NpgsqlCommand` | ✅ Replaced |
| `SqlDataReader` | `NpgsqlDataReader` | ✅ Replaced |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | ✅ Replaced |

### Connection String (appsettings.json)
| Parameter | SQL Server | PostgreSQL | Status |
|-----------|-----------|------------|--------|
| Server | `Server=` | `Host=localhost` | ✅ Updated |
| Port | N/A | `Port=5432` | ✅ Added |
| Database | `Database=` | `Database=ProductManagement` | ✅ Maintained |
| Auth | `Integrated Security` | `Username=;Password=` | ✅ Updated |

### Schema Mapping (DMS)
| SQL Server Schema | PostgreSQL Schema |
|-------------------|-------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

### Column Name Mapping
All column names converted from PascalCase to lowercase per DMS conversion:
- `ProductId` → `productid`
- `Name` → `name`
- `Description` → `description`
- `Price` → `price`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`

---

## Statements Requiring Manual Review

1. **InsertProductAsync** (Statement 3): DMS conversion failed. Manual conversion applied with lowercase schema mapping. Should be reviewed for correctness.

2. **All 7 Statements**: Equivalency validation returned ERROR for all statements due to systematic tool error ('uniqueID'). Manual review recommended to verify equivalency.

---

## Transformation Artifacts

| Artifact | Location | Status |
|----------|----------|--------|
| `extracted_statements.sql` | `sourceCode/` | ✅ Complete (7 original MS SQL statements) |
| `converted_statements.sql` | `sourceCode/` | ✅ Complete (7 converted PostgreSQL statements) |
| `sql_equivalency_validation_report.json` | `sourceCode/` | ✅ Complete (all 7 pairs with tool results) |
| `migration_report.md` | `sourceCode/` | ✅ Complete (this file) |

---

## Build Verification

**Final Build Status**: ✅ SUCCESS
- 0 Errors
- 10 Warnings (pre-existing nullable reference type warnings, not related to migration)
- Framework: .NET 9.0
- Output: `AdoCore.dll`
