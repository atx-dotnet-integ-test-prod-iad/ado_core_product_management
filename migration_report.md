# Migration Report: SQL Server to PostgreSQL

## Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS MCP tool | 0 |
| Requiring manual intervention (DMS failure) | 7 |
| Validated as equivalent (SQL Equivalency tool) | 0 |
| Validated as non-equivalent (SQL Equivalency tool) | 0 |
| Equivalency validation errors | 7 |

### DMS Tool Status
The DMS MCP statement conversion tool (`dms-mcp___statement_conversion_tool`) failed for all 7 statements with the following error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```
All 7 statements were attempted through DMS before falling back to manual conversion.

The DMS schema mapping tool (`dms-mcp___schema_mapping_tool`) was successful and provided the target schema mappings used for manual conversion.

### SQL Equivalency Tool Status
The SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`) returned ERROR for all 7 statement pairs with:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```
Per the transformation definition, these are marked as ERROR (not agent-judged equivalency).

---

## DMS Schema Mappings (from schema_mapping_tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `dbo.Products` | `productmanagement_dbo.products` |
| `dbo.ProductHistory` | `productmanagement_dbo.producthistory` |
| `dbo.ProductStats` | `productmanagement_dbo.productstats` |

### Column Mappings
All column names were lowercased by DMS:
- `ProductId` → `productid`
- `Name` → `name`
- `Description` → `description`
- `Price` → `price`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- `ModifiedDate` → `modifieddate`
- `HistoryId` → `historyid`
- `Action` → `action`
- `OldPrice` → `oldprice`
- `NewPrice` → `newprice`
- `OldStock` → `oldstock`
- `NewStock` → `newstock`
- `ActionDate` → `actiondate`
- `StatId` → `statid`
- `TotalProducts` → `totalproducts`
- `AveragePrice` → `averageprice`
- `LastUpdated` → `lastupdated`

---

## Statement-by-Statement Migration Log

### Statement 1: GetAllProductsAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetAllProductsAsync()`
- **DMS Tool Output**: ERROR - Metadata model creation failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (from tool: `'uniqueID'`)

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

**Manual Conversion Notes**: Lowercase table/column names per DMS schema mapping. CTE, window functions, CASE, ROUND, JOIN all compatible with PostgreSQL.

---

### Statement 2: GetProductByIdAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetProductByIdAsync(int productId)`
- **DMS Tool Output**: ERROR - Metadata model creation failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (from tool: `'uniqueID'`)

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
    p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
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
    p.createddate, p.modifieddate,
    ph.previousprice, ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Manual Conversion Notes**: Lowercase names. LAG window function compatible with PostgreSQL.

---

### Statement 3: InsertProductAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `InsertProductAsync(Product product)`
- **DMS Tool Output**: ERROR - Metadata model creation failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (from tool: `'uniqueID'`)

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
-- Restructured to use multiple ADO.NET commands within a C# transaction
-- INSERT with RETURNING replaces SCOPE_IDENTITY()
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid;

-- History insert (separate command)
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Stats update (separate command)
UPDATE productstats SET totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW() WHERE statid = 1;
```

**Manual Conversion Notes**: 
- `SCOPE_IDENTITY()` → `RETURNING productid` clause
- `GETDATE()` → `NOW()`
- `DECLARE @variable` → removed; handled in C# application code
- `BEGIN TRANSACTION` → managed by ADO.NET `BeginTransactionAsync()`
- Transaction block restructured into separate commands within C# transaction

---

### Statement 4: UpdateProductAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `UpdateProductAsync(Product product)`
- **DMS Tool Output**: ERROR - Metadata model creation failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (from tool: `'uniqueID'`)

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
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
-- Separate SELECT to get old values (C# variable capture)
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Update product
UPDATE products SET name = @Name, description = @Description, price = @Price,
    stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId;

-- Log changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Update stats
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW() WHERE statid = 1;
```

**Manual Conversion Notes**: `DECLARE @variable` → C# variables. `GETDATE()` → `NOW()`. Transaction via ADO.NET.

---

### Statement 5: DeleteProductAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `DeleteProductAsync(int productId)`
- **DMS Tool Output**: ERROR - Metadata model creation failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (from tool: `'uniqueID'`)

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
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
-- Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Log deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Delete product
DELETE FROM products WHERE productid = @ProductId;

-- Update stats
UPDATE productstats SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END,
    lastupdated = NOW() WHERE statid = 1;
```

**Manual Conversion Notes**: Same pattern as UpdateProductAsync. `DECLARE @variable` → C# variables.

---

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **DMS Tool Output**: ERROR - Metadata model creation failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (from tool: `'uniqueID'`)

**Original MS SQL:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
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
SELECT rp.*,
    CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank
```

**Manual Conversion Notes**: Lowercase names. RANK(), PERCENT_RANK(), BETWEEN all compatible with PostgreSQL.

---

### Statement 7: GetLowStockProductsAsync
- **Source File**: `DataAccess/ProductRepository.cs`
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **DMS Tool Output**: ERROR - Metadata model creation failed
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- **Equivalency Status**: ERROR (from tool: `'uniqueID'`)

**Original MS SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock FROM Products p
)
SELECT sa.*,
    CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate' END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**Converted PostgreSQL:**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock FROM products p
)
SELECT sa.*,
    CASE WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate' END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Manual Conversion Notes**: Lowercase names. Added `CAST(stockquantity AS NUMERIC)` to avoid integer division in PostgreSQL (SQL Server performs implicit conversion for ROUND).

---

## Static Code Changes Summary

### Package Reference Changes
| Before | After |
|--------|-------|
| `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

### Import Changes
| Before | After |
|--------|-------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### Class Type Changes
| SQL Server Type | Npgsql Type | Occurrences |
|-----------------|-------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 15 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `SqlTransaction` | `NpgsqlTransaction` | 11 |

### Connection String Changes
| Parameter | Before | After |
|-----------|--------|-------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (not specified) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed) |
| Certificate | `TrustServerCertificate=True` | (removed) |

---

## Artifacts Checklist

| Artifact | Status |
|----------|--------|
| `extracted_statements.sql` | ✅ Complete (7 statements) |
| `converted_statements.sql` | ✅ Complete (7 statements) |
| `sql_equivalency_validation_report.json` | ✅ Complete (7 entries) |
| `migration_report.md` | ✅ This file |

---

## Additional Fix: MapProductFromReader Column Name Casing

During post-migration validation, a runtime-critical bug was identified in the `MapProductFromReader` method. The method used PascalCase column names (e.g., `reader["ProductId"]`) when accessing the data reader, but the SQL queries now return lowercase column names from PostgreSQL (e.g., `productid`). The Npgsql data reader is case-sensitive, which would cause `IndexOutOfRangeException` at runtime.

**Fix applied**: Updated all column name references in `MapProductFromReader` to lowercase:
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`

Note: The `reader["price"]` and `reader["stockquantity"]` references in `UpdateProductAsync` and `DeleteProductAsync` were already using lowercase.

## Build Verification

Final build status: **SUCCESS** (0 errors, warnings only)

```
Build succeeded.
    0 Error(s)
```
