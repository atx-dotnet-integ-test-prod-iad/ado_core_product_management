# Migration Report: MS SQL Server to PostgreSQL

## 1. Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements converted by DMS tool | 0 |
| Statements requiring manual intervention | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency errors | 7 |

**DMS Tool Status:** All 7 statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`). All failed with the same error: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`. Manual conversion was applied with lowercase schema object names per the `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` protocol.

**SQL Equivalency Tool Status:** All 7 statement pairs were validated through the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status with error `'uniqueID'`.

---

## 2. Detailed Statement Log

### Statement 1: GetAllProductsAsync()
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetAllProductsAsync()`

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

**DMS Tool Output:** FAILED - `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

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

**Equivalency Tool Result:** ERROR (`'uniqueID'`)
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention:** Converted all schema objects to lowercase. SQL syntax is identical between MS SQL and PostgreSQL for CTEs and window functions.

---

### Statement 2: GetProductByIdAsync()
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetProductByIdAsync(int productId)`

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

**DMS Tool Output:** FAILED - `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

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
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Equivalency Tool Result:** ERROR (`'uniqueID'`)
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention:** Converted all schema objects to lowercase. LAG window function syntax is identical.

---

### Statement 3: InsertProductAsync()
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `InsertProductAsync(Product product)`

**Original MS SQL:**
```sql
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    UPDATE ProductStats SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
SELECT @NewProductId;
```

**DMS Tool Output:** FAILED - `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**Converted PostgreSQL:**
```sql
WITH inserted AS (
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid
),
history_insert AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW()
    FROM inserted
    RETURNING productid
),
stats_update AS (
    UPDATE productstats SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = NOW()
    WHERE statid = 1
    RETURNING statid
)
SELECT productid FROM inserted
```

**Equivalency Tool Result:** ERROR (`'uniqueID'`)
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention:** Major restructuring required:
- `SCOPE_IDENTITY()` → PostgreSQL `RETURNING` clause in writable CTE
- `GETDATE()` → `NOW()`
- `DECLARE`/`SET` variables → writable CTE pattern (WITH ... INSERT ... RETURNING)
- `BEGIN TRANSACTION`/`COMMIT` → single atomic writable CTE (PostgreSQL executes CTEs atomically)
- All schema objects converted to lowercase

---

### Statement 4: UpdateProductAsync()
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `UpdateProductAsync(Product product)`

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
    UPDATE ProductStats SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**DMS Tool Output:** FAILED - `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock FROM products WHERE productid = @ProductId
),
update_product AS (
    UPDATE products SET name = @Name, description = @Description, price = @Price,
        stockquantity = @StockQuantity, modifieddate = NOW() WHERE productid = @ProductId
    RETURNING productid
),
log_changes AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, NOW()
    FROM old_values ov RETURNING productid
)
UPDATE productstats SET 
    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
    lastupdated = NOW() WHERE statid = 1
```

**Equivalency Tool Result:** ERROR (`'uniqueID'`)
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention:** `DECLARE`/`SET` variables replaced with writable CTE using `old_values` subquery. `GETDATE()` → `NOW()`. All schema objects lowercase.

---

### Statement 5: DeleteProductAsync()
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `DeleteProductAsync(int productId)`

**Original MS SQL:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    DELETE FROM Products WHERE ProductId = @ProductId;
    UPDATE ProductStats SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END,
        LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**DMS Tool Output:** FAILED - `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**Converted PostgreSQL:**
```sql
WITH old_values AS (
    SELECT price as oldprice, stockquantity as oldstock FROM products WHERE productid = @ProductId
),
log_deletion AS (
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, NOW()
    FROM old_values ov RETURNING productid
),
delete_product AS (
    DELETE FROM products WHERE productid = @ProductId RETURNING productid
)
UPDATE productstats SET 
    totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 
        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1) ELSE 0 END,
    lastupdated = NOW() WHERE statid = 1
```

**Equivalency Tool Result:** ERROR (`'uniqueID'`)
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention:** Same pattern as Statement 4. `DECLARE`/`SET` → writable CTE. `GETDATE()` → `NOW()`. All schema objects lowercase.

---

### Statement 6: GetProductsByPriceRangeAsync()
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`

**Original MS SQL:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as PriceSegment
FROM RankedProducts rp ORDER BY rp.PriceRank
```

**DMS Tool Output:** FAILED - `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**Converted PostgreSQL:**
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END as pricesegment
FROM rankedproducts rp ORDER BY rp.pricerank
```

**Equivalency Tool Result:** ERROR (`'uniqueID'`)
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention:** Converted all schema objects to lowercase. RANK/PERCENT_RANK syntax is identical.

---

### Statement 7: GetLowStockProductsAsync()
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** `GetLowStockProductsAsync(int threshold)`

**Original MS SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock, MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*,
    CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**DMS Tool Output:** FAILED - `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`

**Converted PostgreSQL:**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock, MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT sa.*,
    CASE WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END as stockstatus,
    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa WHERE stockquantity <= @Threshold ORDER BY stockquantity
```

**Equivalency Tool Result:** ERROR (`'uniqueID'`)
**Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
**Manual Intervention:** Converted all schema objects to lowercase. Added `::numeric` cast for `StockQuantity / AvgStock` to avoid integer division in PostgreSQL (MS SQL performs decimal division when one operand comes from AVG, but PostgreSQL integer/integer = integer).

---

## 3. Code Changes Summary

### Package Reference Changes
| File | Before | After |
|------|--------|-------|
| AdoCore.csproj | `Microsoft.Data.SqlClient` v5.1.4 | `Npgsql` v8.0.6 |

### Using Directive Changes
| File | Before | After |
|------|--------|-------|
| DataAccess/ProductRepository.cs | `using Microsoft.Data.SqlClient;` | `using Npgsql;` |

### ADO.NET Class Replacements
| Original Class | Replacement Class | Occurrences |
|---------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

### Connection String Changes
| Setting | Before | After |
|---------|--------|-------|
| DevConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres` |
| ProdConnection | `Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` | `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres` |

### Column Name Reference Changes
The `MapProductFromReader` method was updated to use lowercase column names for PostgreSQL compatibility:
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`

### Files Modified
1. **AdoCore.csproj** - Package reference change
2. **DataAccess/ProductRepository.cs** - SQL statements, ADO.NET classes, using directives, column references
3. **appsettings.json** - Connection strings

### Files Unchanged
1. **Program.cs** - No SQL Server references
2. **Business/ProductService.cs** - No SQL Server references
3. **CLI/CommandLineInterface.cs** - No SQL Server references
4. **CLI/InteractiveMenu.cs** - No SQL Server references
5. **Models/Product.cs** - No SQL Server references

---

## 4. Transformation Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/extracted_statements.sql | Complete catalog of all 7 original MS SQL statements |
| converted_statements.sql | sourceCode/converted_statements.sql | Complete catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/sql_equivalency_validation_report.json | JSON report with all 7 statement validation results |
| migration_report.md | sourceCode/migration_report.md | This comprehensive migration report |

---

## 5. Build Verification

Final build status: **SUCCESS**
- 0 Errors
- 10 Warnings (all pre-existing nullable reference warnings, not related to migration)
- Build command: `dotnet build AdoCore.sln`
- Output: `AdoCore.dll` compiled successfully

---

## 6. Key Conversion Patterns Applied

| MS SQL Pattern | PostgreSQL Equivalent |
|---------------|----------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` (in writable CTE) |
| `GETDATE()` | `NOW()` |
| `DECLARE @var TYPE; SET @var = ...` | Writable CTE with `old_values` subquery |
| `BEGIN TRANSACTION ... COMMIT` | Single atomic writable CTE |
| `ROUND(int/int * 100, 2)` | `ROUND(int::numeric / int * 100, 2)` |
| `Microsoft.Data.SqlClient` | `Npgsql` |
| `SqlConnection` | `NpgsqlConnection` |
| `SqlCommand` | `NpgsqlCommand` |
| `SqlDataReader` | `NpgsqlDataReader` |
| `Server=` (connection string) | `Host=` |
| `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| PascalCase table/column names | lowercase table/column names |
