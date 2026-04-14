# Migration Log: SQL Server to PostgreSQL

## Migration Overview
- **Source Database**: Microsoft SQL Server 2019
- **Target Database**: PostgreSQL 13
- **Application Framework**: .NET 9.0 with ADO.NET
- **Migration Date**: 2026-04-14

---

## Files Modified

### 1. sourceCode/DataAccess/ProductRepository.cs
**Changes:**
- Replaced `using Microsoft.Data.SqlClient;` with `using Npgsql;`
- Replaced all SQL Server ADO.NET class references:
  - `SqlConnection` → `NpgsqlConnection` (3 occurrences)
  - `SqlCommand` → `NpgsqlCommand` (15 occurrences)
  - `SqlDataReader` → `NpgsqlDataReader` (1 occurrence)
  - `SqlTransaction` → `NpgsqlTransaction` (11 occurrences)
- Replaced all 7 SQL statements with PostgreSQL equivalents (see SQL Statement Details below)
- Restructured transaction-based methods (Insert, Update, Delete) from single SQL batch to C#-managed transactions with separate commands
- Updated column name references in `MapProductFromReader` to lowercase (e.g., `reader["ProductId"]` → `reader["productid"]`)

### 2. sourceCode/AdoCore.csproj
**Changes:**
- Removed: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- Added: `<PackageReference Include="Npgsql" Version="8.0.0" />`

### 3. sourceCode/appsettings.json
**Changes:**
- DevConnection: `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- ProdConnection: Same conversion applied
- Removed SQL Server-specific parameters: Trusted_Connection, MultipleActiveResultSets, TrustServerCertificate
- Added PostgreSQL-specific parameters: Host, Username, Password

### 4. sourceCode/Database/Scripts/01_InitialSetup.sql
**Changes:**
- Full conversion from SQL Server to PostgreSQL syntax
- `[dbo].[TableName]` → `tablename` (lowercase, no brackets)
- `IDENTITY(1,1)` → `SERIAL`
- `nvarchar` → `varchar`
- `bit` → `boolean`
- `GETDATE()` → `NOW()`
- `CREATE OR ALTER PROCEDURE` → `CREATE OR REPLACE FUNCTION`
- `GO` statements → removed
- `SYSTEM_USER` → `CURRENT_USER`
- Trigger syntax converted to PostgreSQL trigger function pattern
- `IF EXISTS/IF NOT EXISTS` patterns converted to PostgreSQL equivalents

### 5. sourceCode/Scripts/01_InitialSetup.sql
**Changes:**
- Same SQL Server to PostgreSQL conversions as Database/Scripts/01_InitialSetup.sql
- `IF NOT EXISTS` patterns → `CREATE TABLE IF NOT EXISTS` and `DO $$ ... END $$` blocks
- Stored procedures → PostgreSQL functions

### 6. sourceCode/README.md
**Changes:**
- Updated prerequisites from SQL Server to PostgreSQL
- Updated connection string examples to PostgreSQL format
- Updated NuGet packages section (Microsoft.Data.SqlClient → Npgsql)
- Updated troubleshooting section for PostgreSQL
- Updated deployment instructions

---

## SQL Statement Conversion Details

All 7 SQL statements were extracted from `DataAccess/ProductRepository.cs`.

### DMS Tool Conversion Results
All 7 statements were passed to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with:
- `migration_project_identifier`: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- `schema_name`: `dbo`
- `database_name`: `ProductManagement`

**Result**: ALL 7 statements FAILED with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

### Manual Conversion Applied
Per the transformation rules, all statements were manually converted with lowercase schema object names, documented with reason: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`

---

### Statement 1: GetAllProductsAsync (Line ~42)
**Source File**: DataAccess/ProductRepository.cs
**Method**: GetAllProductsAsync

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

**DMS Output**: ERROR - Metadata model creation failed
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

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

---

### Statement 2: GetProductByIdAsync (Line ~76)
**Source File**: DataAccess/ProductRepository.cs
**Method**: GetProductByIdAsync

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
FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**DMS Output**: ERROR - Metadata model creation failed
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

**Converted PostgreSQL:**
```sql
WITH producthistory AS (
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
FROM products p LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

---

### Statement 3: InsertProductAsync (Line ~107)
**Source File**: DataAccess/ProductRepository.cs
**Method**: InsertProductAsync

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

**DMS Output**: ERROR - Metadata model creation failed
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention**: Restructured from single SQL batch to 3 separate commands within C#-managed transaction. SCOPE_IDENTITY() replaced with RETURNING clause. GETDATE() replaced with NOW().

**Converted PostgreSQL (3 separate statements):**
```sql
-- Statement 3a: Insert
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Stats update
UPDATE productstats SET totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW() WHERE statid = 1;
```

---

### Statement 4: UpdateProductAsync (Line ~138)
**Source File**: DataAccess/ProductRepository.cs
**Method**: UpdateProductAsync

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

**DMS Output**: ERROR - Metadata model creation failed
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention**: Restructured from single SQL batch to 4 separate commands within C#-managed transaction. DECLARE variables replaced with C# variables. GETDATE() replaced with NOW().

**Converted PostgreSQL (4 separate statements):**
```sql
-- Statement 4a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 4b: Update
UPDATE products SET name = @Name, description = @Description, price = @Price,
    stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId;

-- Statement 4c: Log
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Stats update
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW() WHERE statid = 1;
```

---

### Statement 5: DeleteProductAsync (Line ~177)
**Source File**: DataAccess/ProductRepository.cs
**Method**: DeleteProductAsync

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (...) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**DMS Output**: ERROR - Metadata model creation failed
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention**: Same restructuring as Statement 4. DECLARE variables replaced with C# variables.

**Converted PostgreSQL (4 separate statements):**
```sql
-- Statement 5a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 5b: Log
INSERT INTO producthistory (...) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete
DELETE FROM products WHERE productid = @ProductId;

-- Statement 5d: Stats update
UPDATE productstats SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END,
    lastupdated = NOW() WHERE statid = 1;
```

---

### Statement 6: GetProductsByPriceRangeAsync (Line ~212)
**Source File**: DataAccess/ProductRepository.cs
**Method**: GetProductsByPriceRangeAsync

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

**DMS Output**: ERROR - Metadata model creation failed
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

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

---

### Statement 7: GetLowStockProductsAsync (Line ~241)
**Source File**: DataAccess/ProductRepository.cs
**Method**: GetLowStockProductsAsync

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

**DMS Output**: ERROR - Metadata model creation failed
**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Additional Change**: Added `CAST(stockquantity AS NUMERIC)` for proper decimal division (PostgreSQL integer division behavior)

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

---

## SQL Equivalency Validation Results
All 7 statement pairs were validated via the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).
**Result**: ALL 7 returned `ERROR` with error message `'uniqueID'`.
No agent judgment was used for equivalency determination - all results are directly from the tool.

---

## Package Dependency Changes
| Original Package | Version | Replacement Package | Version |
|---|---|---|---|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.0 |

No other package dependencies were changed.

---

## Connection String Changes
| Parameter | SQL Server | PostgreSQL |
|---|---|---|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed - not applicable) |
| TrustServerCertificate | True | (removed - not applicable) |
