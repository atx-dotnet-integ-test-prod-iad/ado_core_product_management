# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS | 0 |
| Requiring Manual Intervention | 7 |
| Validated as Equivalent | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Errors | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following parameters:
- `migration_project_identifier`: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- `database_name`: `ProductManagement`
- `schema_name`: `dbo`

**All 7 DMS conversion attempts failed** with error: "Metadata model creation failed: Metadata model creation did not complete after 15 attempts"

Manual conversion was applied with lowercase schema object naming convention for PostgreSQL compatibility (documented as `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`).

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 equivalency checks returned ERROR** with error: `'uniqueID'`

---

## Detailed Statement Log

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetAllProductsAsync()`
- **Type**: SELECT with CTE and Window Functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND

**Original SQL (MS SQL Server):**
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

**DMS Output**: ERROR - Metadata model conversion did not complete after 15 attempts

**Converted SQL (PostgreSQL):**
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

**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Result**: ERROR ('uniqueID')
**Changes Applied**: Lowercase table/column/alias names

---

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductByIdAsync(int productId)`
- **Type**: SELECT with CTE and LAG Window Function, LEFT JOIN, CASE, ROUND

**Original SQL (MS SQL Server):**
```sql
WITH ProductHistory AS (
    SELECT ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
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

**DMS Output**: ERROR - Metadata model creation did not complete after 15 attempts

**Converted SQL (PostgreSQL):**
```sql
WITH producthistory AS (
    SELECT productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM products
    WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity,
    p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN 
        ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
    ELSE NULL END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Result**: ERROR ('uniqueID')
**Changes Applied**: Lowercase table/column/alias names

---

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `InsertProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, BEGIN TRANSACTION, INSERT, SCOPE_IDENTITY(), GETDATE()

**Original SQL (MS SQL Server):**
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

**DMS Output**: ERROR - Metadata model creation did not complete after 15 attempts

**Converted SQL (PostgreSQL):** Split into 3 separate statements within C# ADO.NET transaction:
```sql
-- Statement 3a: Insert product and get new ID
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update product statistics
UPDATE productstats SET totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW() WHERE statid = 1;
```

**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Result**: ERROR ('uniqueID')
**Changes Applied**: SCOPE_IDENTITY() → RETURNING productid, GETDATE() → NOW(), DECLARE/SET removed (handled in C# code), lowercase names, transaction managed by C# ADO.NET BeginTransactionAsync

---

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `UpdateProductAsync(Product product)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, UPDATE, INSERT, GETDATE()

**Original SQL (MS SQL Server):**
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

**DMS Output**: ERROR - Metadata model creation did not complete after 15 attempts

**Converted SQL (PostgreSQL):** Split into 4 separate statements within C# ADO.NET transaction:
```sql
-- Statement 4a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 4b: Update product
UPDATE products SET name = @Name, description = @Description, price = @Price,
    stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId;

-- Statement 4c: Log changes
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update statistics
UPDATE productstats SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW() WHERE statid = 1;
```

**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Result**: ERROR ('uniqueID')
**Changes Applied**: GETDATE() → NOW(), DECLARE removed (handled in C# code), lowercase names, transaction managed by C# ADO.NET

---

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `DeleteProductAsync(int productId)`
- **Type**: Transaction block with DECLARE, SELECT INTO variables, INSERT, DELETE, UPDATE with CASE, GETDATE()

**Original SQL (MS SQL Server):**
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

**DMS Output**: ERROR - Metadata model creation did not complete after 15 attempts

**Converted SQL (PostgreSQL):** Split into 4 separate statements within C# ADO.NET transaction:
```sql
-- Statement 5a: Get old values
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- Statement 5b: Log deletion
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete product
DELETE FROM products WHERE productid = @ProductId;

-- Statement 5d: Update statistics
UPDATE productstats SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) ELSE 0 END,
    lastupdated = NOW() WHERE statid = 1;
```

**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Result**: ERROR ('uniqueID')
**Changes Applied**: GETDATE() → NOW(), DECLARE removed, lowercase names, transaction managed by C# ADO.NET

---

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Type**: SELECT with CTE, RANK, PERCENT_RANK Window Functions, BETWEEN, CASE

**Original SQL (MS SQL Server):**
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

**DMS Output**: ERROR - Metadata model creation did not complete after 15 attempts

**Converted SQL (PostgreSQL):**
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

**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Result**: ERROR ('uniqueID')
**Changes Applied**: Lowercase table/column/alias names

---

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND

**Original SQL (MS SQL Server):**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*,
    CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
         WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
         ELSE 'Adequate' END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**DMS Output**: ERROR - Metadata model creation did not complete after 15 attempts

**Converted SQL (PostgreSQL):**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock, MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT sa.*,
    CASE WHEN stockquantity <= @Threshold THEN 'Critical'
         WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
         ELSE 'Adequate' END as stockstatus,
    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Equivalency Result**: ERROR ('uniqueID')
**Changes Applied**: Lowercase names, added CAST(stockquantity AS NUMERIC) for integer division in ROUND()

---

## Code Changes Summary

### Files Modified

| File | Changes |
|------|---------|
| DataAccess/ProductRepository.cs | Replaced all 7 SQL statements, replaced all ADO.NET classes |
| AdoCore.csproj | Replaced package reference |
| appsettings.json | Updated connection strings |

### Package Changes

| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |

Note: Npgsql 8.0.6 was used instead of 8.0.0 (specified in plan) due to known high severity vulnerability (GHSA-x9vc-6hfv-hg8c) in version 8.0.0.

### ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent |
|-----------------|-------------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `SqlParameter` | `NpgsqlParameter` (via AddWithValue) |

### Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | Removed (native in PostgreSQL) |
| SSL | `TrustServerCertificate=True` | Removed |

### SQL Syntax Changes Applied

| SQL Server Syntax | PostgreSQL Equivalent |
|------------------|----------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE` | Handled in C# code |
| `SET @var = expr` | Handled in C# code |
| `BEGIN TRANSACTION`/`COMMIT` | C# `BeginTransactionAsync()`/`CommitAsync()` |
| Integer division in `ROUND()` | `CAST(col AS NUMERIC)` |
| Mixed-case identifiers | Lowercase identifiers |

---

## Verification

### Build Status
- **Final Build**: ✅ **SUCCESS** (0 errors, 0 vulnerability warnings)
- Build command: `dotnet build AdoCore.sln`

### Artifacts Checklist
- [x] `extracted_statements.sql` - Complete catalog of all 7 original SQL statements
- [x] `converted_statements.sql` - Complete catalog of all 7 converted PostgreSQL statements
- [x] `sql_equivalency_validation_report.json` - Comprehensive report with all 7 statement pairs
- [x] `migration_report.md` - This report

### Notes for Manual Review
1. **DMS Tool Failures**: All 7 DMS conversion attempts failed due to metadata model creation timeouts. Manual conversion was applied following the documented lowercase schema naming convention.
2. **Equivalency Tool Errors**: All 7 equivalency checks returned ERROR with `'uniqueID'` error. These errors came from the tool itself, not from the SQL statements. Manual review of the conversions is recommended.
3. **Transaction Restructuring**: Statements 3, 4, and 5 (InsertProductAsync, UpdateProductAsync, DeleteProductAsync) were restructured from single SQL strings with SQL-level transactions to multiple C# commands within ADO.NET transactions. This maintains the same atomicity guarantees while being compatible with PostgreSQL.
4. **Npgsql Version**: Used 8.0.6 instead of 8.0.0 to address known vulnerability.
