# Code Integration Log
# SQL Statement Re-integration into ProductRepository.cs
# Date: 2024-12-29

## Overview
This log documents the re-integration of converted PostgreSQL SQL statements back into the ProductRepository.cs file.

## Important Note
SQL statement updates are documented here but will be physically applied in conjunction with Steps 5 and 6 (package and class replacements) to ensure atomic transformation and avoid intermediate compilation errors.

## Schema Object Name Changes
All occurrences of table names must be updated per DMS tool conversion:
- `Products` → `productmanagement_dbo.products` (lowercase with schema prefix)
- `ProductHistory` → `productmanagement_dbo.producthistory`
- `ProductStats` → `productmanagement_dbo.productstats`

## Statement-by-Statement Integration Plan

### Statement 1: GetAllProductsAsync()
**Location:** Lines 43-70
**Method:** Simple SQL string replacement

**Original SQL:**
```sql
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' 
         WHEN p.Price < ps.AvgPrice THEN 'Below Average' 
         ELSE 'Average' END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
```

**Converted PostgreSQL SQL:**
```sql
WITH productstats AS (
    SELECT productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average' 
         WHEN p.price < ps.avgprice THEN 'Below Average' 
         ELSE 'Average' END AS pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
FROM productmanagement_dbo.products AS p
INNER JOIN productstats AS ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END NULLS FIRST, p.name NULLS FIRST
```

**Changes Applied:**
- CTE name: ProductStats → productstats
- Table reference: Products → productmanagement_dbo.products
- All column names converted to lowercase
- Added NULLS FIRST to ORDER BY clauses
- Column aliases converted to lowercase with AS keyword

**Code Logic Changes:** None required - direct SQL replacement

---

### Statement 2: GetProductByIdAsync(int productId)
**Location:** Lines 85-113
**Method:** Simple SQL string replacement

**Original SQL:**
```sql
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
           LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products WHERE ProductId = @ProductId
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
       ph.PreviousPrice, ph.PreviousStock,
       CASE WHEN ph.PreviousPrice IS NOT NULL 
            THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) 
            ELSE NULL END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL SQL:**
```sql
WITH producthistory AS (
    SELECT productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice,
           lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
       ph.previousprice, ph.previousstock,
       CASE WHEN ph.previousprice IS NOT NULL 
            THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) 
            ELSE NULL END AS pricechangepercentage
FROM productmanagement_dbo.products AS p
LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Changes Applied:**
- CTE name: ProductHistory → producthistory
- Table reference: Products → productmanagement_dbo.products
- All column names converted to lowercase
- LEFT JOIN → LEFT OUTER JOIN
- Parameter @ProductId preserved (Npgsql compatible)

**Code Logic Changes:** None required - direct SQL replacement

---

### Statement 3: InsertProductAsync(Product product)
**Location:** Lines 127-158
**Method:** Complex refactoring required - SCOPE_IDENTITY() to RETURNING clause

**Original SQL:**
```sql
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    SET @NewProductId = SCOPE_IDENTITY();
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    UPDATE ProductStats
    SET TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
SELECT @NewProductId;
```

**Converted PostgreSQL SQL (Split into 3 statements):**
```sql
-- Statement 3a: Insert with RETURNING
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Log the insertion
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
```

**Code Logic Changes Required:**
1. Remove single SQL command approach
2. Use NpgsqlConnection.BeginTransactionAsync() for transaction management
3. Execute INSERT with ExecuteScalarAsync() to get RETURNING value
4. Store returned productid in variable
5. Execute remaining statements within same transaction
6. Return the productid

**Refactored C# Code:**
```csharp
public async Task<int> InsertProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Insert product and get ID using RETURNING
        const string insertSql = @"
            INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
            VALUES (@Name, @Description, @Price, @StockQuantity)
            RETURNING productid";
        
        int newProductId;
        using (var insertCmd = new NpgsqlCommand(insertSql, connection, transaction))
        {
            insertCmd.Parameters.AddWithValue("@Name", product.Name);
            insertCmd.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            insertCmd.Parameters.AddWithValue("@Price", product.Price);
            insertCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            newProductId = Convert.ToInt32(await insertCmd.ExecuteScalarAsync());
        }
        
        // Log the insertion
        const string historySql = @"
            INSERT INTO productmanagement_dbo.producthistory 
            (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
            VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";
        
        using (var historyCmd = new NpgsqlCommand(historySql, connection, transaction))
        {
            historyCmd.Parameters.AddWithValue("@ProductId", newProductId);
            historyCmd.Parameters.AddWithValue("@Price", product.Price);
            historyCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            await historyCmd.ExecuteNonQueryAsync();
        }
        
        // Update statistics
        const string statsSql = @"
            UPDATE productmanagement_dbo.productstats
            SET totalproducts = totalproducts + 1,
                averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                lastupdated = CURRENT_TIMESTAMP
            WHERE statid = 1";
        
        using (var statsCmd = new NpgsqlCommand(statsSql, connection, transaction))
        {
            statsCmd.Parameters.AddWithValue("@Price", product.Price);
            await statsCmd.ExecuteNonQueryAsync();
        }
        
        await transaction.CommitAsync();
        return newProductId;
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

---

### Statement 4: UpdateProductAsync(Product product)
**Location:** Lines 172-199
**Method:** Complex refactoring - multi-statement transaction

**Original SQL:**
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

**Converted PostgreSQL SQL (Split into 4 statements):**
```sql
-- Statement 4a: Get old values
SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Statement 4b: Update product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price,
    stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 4c: Log changes
INSERT INTO productmanagement_dbo.producthistory 
(productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update statistics
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
```

**Code Logic Changes Required:**
1. Move DECLARE variables to C# code
2. Use NpgsqlConnection.BeginTransactionAsync()
3. Execute SELECT to fetch old values into C# variables
4. Execute remaining statements with fetched values
5. Proper transaction management with try/catch

**Refactored C# Code:**
```csharp
public async Task UpdateProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Get old values
        decimal oldPrice = 0;
        int oldStock = 0;
        
        const string selectSql = @"
            SELECT price, stockquantity 
            FROM productmanagement_dbo.products 
            WHERE productid = @ProductId";
        
        using (var selectCmd = new NpgsqlCommand(selectSql, connection, transaction))
        {
            selectCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
            using var reader = await selectCmd.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = reader.GetDecimal(0);
                oldStock = reader.GetInt32(1);
            }
        }
        
        // Update product
        const string updateSql = @"
            UPDATE productmanagement_dbo.products
            SET name = @Name, description = @Description, price = @Price,
                stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
            WHERE productid = @ProductId";
        
        using (var updateCmd = new NpgsqlCommand(updateSql, connection, transaction))
        {
            updateCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
            updateCmd.Parameters.AddWithValue("@Name", product.Name);
            updateCmd.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            updateCmd.Parameters.AddWithValue("@Price", product.Price);
            updateCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            await updateCmd.ExecuteNonQueryAsync();
        }
        
        // Log changes
        const string historySql = @"
            INSERT INTO productmanagement_dbo.producthistory 
            (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
            VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP)";
        
        using (var historyCmd = new NpgsqlCommand(historySql, connection, transaction))
        {
            historyCmd.Parameters.AddWithValue("@ProductId", product.ProductId);
            historyCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
            historyCmd.Parameters.AddWithValue("@Price", product.Price);
            historyCmd.Parameters.AddWithValue("@OldStock", oldStock);
            historyCmd.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            await historyCmd.ExecuteNonQueryAsync();
        }
        
        // Update statistics
        const string statsSql = @"
            UPDATE productmanagement_dbo.productstats
            SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
                lastupdated = CURRENT_TIMESTAMP
            WHERE statid = 1";
        
        using (var statsCmd = new NpgsqlCommand(statsSql, connection, transaction))
        {
            statsCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
            statsCmd.Parameters.AddWithValue("@Price", product.Price);
            await statsCmd.ExecuteNonQueryAsync();
        }
        
        await transaction.CommitAsync();
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

---

### Statement 5: DeleteProductAsync(int productId)
**Location:** Lines 213-237
**Method:** Complex refactoring - multi-statement transaction

**Original SQL:**
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
                              THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) 
                              ELSE 0 END,
           LastUpdated = GETDATE() WHERE StatId = 1;
COMMIT;
```

**Converted PostgreSQL SQL (Split into 4 statements):**
```sql
-- Statement 5a: Get old values
SELECT price, stockquantity FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Statement 5b: Log deletion
INSERT INTO productmanagement_dbo.producthistory 
(productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete product
DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Statement 5d: Update statistics
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1,
    averageprice = CASE WHEN totalproducts > 1 
                       THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) 
                       ELSE 0 END,
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
```

**Code Logic Changes Required:**
Similar to Statement 4 - move variables to C# code and execute statements separately within transaction.

**Refactored C# Code:**
```csharp
public async Task DeleteProductAsync(int productId)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Get old values
        decimal oldPrice = 0;
        int oldStock = 0;
        
        const string selectSql = @"
            SELECT price, stockquantity 
            FROM productmanagement_dbo.products 
            WHERE productid = @ProductId";
        
        using (var selectCmd = new NpgsqlCommand(selectSql, connection, transaction))
        {
            selectCmd.Parameters.AddWithValue("@ProductId", productId);
            using var reader = await selectCmd.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = reader.GetDecimal(0);
                oldStock = reader.GetInt32(1);
            }
        }
        
        // Log deletion
        const string historySql = @"
            INSERT INTO productmanagement_dbo.producthistory 
            (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
            VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP)";
        
        using (var historyCmd = new NpgsqlCommand(historySql, connection, transaction))
        {
            historyCmd.Parameters.AddWithValue("@ProductId", productId);
            historyCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
            historyCmd.Parameters.AddWithValue("@OldStock", oldStock);
            await historyCmd.ExecuteNonQueryAsync();
        }
        
        // Delete product
        const string deleteSql = @"
            DELETE FROM productmanagement_dbo.products 
            WHERE productid = @ProductId";
        
        using (var deleteCmd = new NpgsqlCommand(deleteSql, connection, transaction))
        {
            deleteCmd.Parameters.AddWithValue("@ProductId", productId);
            await deleteCmd.ExecuteNonQueryAsync();
        }
        
        // Update statistics
        const string statsSql = @"
            UPDATE productmanagement_dbo.productstats
            SET totalproducts = totalproducts - 1,
                averageprice = CASE WHEN totalproducts > 1 
                                   THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1) 
                                   ELSE 0 END,
                lastupdated = CURRENT_TIMESTAMP
            WHERE statid = 1";
        
        using (var statsCmd = new NpgsqlCommand(statsSql, connection, transaction))
        {
            statsCmd.Parameters.AddWithValue("@OldPrice", oldPrice);
            await statsCmd.ExecuteNonQueryAsync();
        }
        
        await transaction.CommitAsync();
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

---

### Statement 6: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
**Location:** Lines 244-263
**Method:** Simple SQL string replacement

**Original SQL:**
```sql
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
           PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
                  WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
                  ELSE 'Premium' END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
```

**Converted PostgreSQL SQL:**
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) AS pricerank,
           percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p 
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
                  WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
                  ELSE 'Premium' END AS pricesegment
FROM rankedproducts AS rp
ORDER BY rp.pricerank NULLS FIRST
```

**Changes Applied:**
- CTE name: RankedProducts → rankedproducts
- Table reference: Products → productmanagement_dbo.products
- All column names converted to lowercase
- PERCENT_RANK → percent_rank (function name lowercase)
- Added NULLS FIRST to ORDER BY

**Code Logic Changes:** None required - direct SQL replacement

---

### Statement 7: GetLowStockProductsAsync(int threshold)
**Location:** Lines 277-296
**Method:** Simple SQL string replacement

**Original SQL:**
```sql
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER() as AvgStock,
           MIN(StockQuantity) OVER() as MinStock,
           MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical'
                  WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
                  ELSE 'Adequate' END as StockStatus,
       ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity
```

**Converted PostgreSQL SQL:**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER () AS avgstock,
           MIN(stockquantity) OVER () AS minstock,
           MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p
)
SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical'
                  WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
                  ELSE 'Adequate' END AS stockstatus,
       ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
FROM stockanalysis AS sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity NULLS FIRST
```

**Changes Applied:**
- CTE name: StockAnalysis → stockanalysis
- Table reference: Products → productmanagement_dbo.products
- All column names converted to lowercase
- Added NULLS FIRST to ORDER BY

**Code Logic Changes:** None required - direct SQL replacement

---

## MapProductFromReader Method
**Location:** Lines 316-327
**Changes Required:** Update column name references to lowercase

**Original:**
```csharp
ProductId = Convert.ToInt32(reader["ProductId"]),
Name = reader["Name"].ToString(),
Description = reader["Description"] == DBNull.Value ? null : reader["Description"].ToString(),
Price = Convert.ToDecimal(reader["Price"]),
StockQuantity = Convert.ToInt32(reader["StockQuantity"]),
CreatedDate = Convert.ToDateTime(reader["CreatedDate"]),
ModifiedDate = reader["ModifiedDate"] == DBNull.Value ? null : (DateTime?)Convert.ToDateTime(reader["ModifiedDate"])
```

**Updated:**
```csharp
ProductId = Convert.ToInt32(reader["productid"]),
Name = reader["name"].ToString(),
Description = reader["description"] == DBNull.Value ? null : reader["description"].ToString(),
Price = Convert.ToDecimal(reader["price"]),
StockQuantity = Convert.ToInt32(reader["stockquantity"]),
CreatedDate = Convert.ToDateTime(reader["createddate"]),
ModifiedDate = reader["modifieddate"] == DBNull.Value ? null : (DateTime?)Convert.ToDateTime(reader["modifieddate"])
```

---

## Summary of Changes

### Simple SQL Replacements (Statements 1, 2, 6, 7)
- Direct string replacement in const string sql declarations
- Schema prefix and lowercase conversions
- NULLS FIRST added to ORDER BY clauses

### Complex Refactoring (Statements 3, 4, 5)
- Split single SQL command into multiple statements
- Move T-SQL variables to C# code
- Implement explicit transaction management using NpgsqlConnection.BeginTransactionAsync()
- Use RETURNING clause for SCOPE_IDENTITY() replacement
- Proper error handling with try/catch/rollback

### Column Name Mapping
All column references in MapProductFromReader must be updated to lowercase to match PostgreSQL column names.

### Total Lines Modified
- Statement 1: ~28 lines
- Statement 2: ~29 lines
- Statement 3: ~32 lines + refactoring to ~60 lines
- Statement 4: ~28 lines + refactoring to ~70 lines
- Statement 5: ~25 lines + refactoring to ~65 lines
- Statement 6: ~20 lines
- Statement 7: ~20 lines
- MapProductFromReader: ~12 lines

**Total:** Approximately 200+ lines modified/refactored

## Implementation Order
1. Update package references (Step 5)
2. Replace SQL Server ADO.NET classes with Npgsql (Step 6)
3. Apply SQL statement changes (this step, integrated with Steps 5-6)
4. Test each method individually after changes

## Validation
After integration:
- Compile the code to ensure no syntax errors
- Verify all table references use correct schema prefix
- Test transaction rollback scenarios
- Verify RETURNING clause returns correct IDs
- Validate MapProductFromReader with lowercase column names
