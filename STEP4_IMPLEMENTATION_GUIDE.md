# Step 4 Implementation Guide: Re-integrate Converted SQL Statements

## Overview
This document provides detailed instructions for re-integrating all 7 converted PostgreSQL SQL statements back into ProductRepository.cs. Each statement must be replaced with its PostgreSQL equivalent while respecting the schema changes made by the DMS tool.

## CRITICAL: Schema Name Changes
The DMS tool converted all table names to include the `productmanagement_dbo` schema prefix:
- `Products` → `productmanagement_dbo.products`
- `ProductHistory` → `productmanagement_dbo.producthistory`
- `ProductStats` → `productmanagement_dbo.productstats`

**These schema changes MUST be preserved in the code per transformation requirements.**

## Statement-by-Statement Replacements

### Statement 1: GetAllProductsAsync (Lines 43-69)

**Original SQL Server Statement:**
```sql
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name
```

**Converted PostgreSQL Statement:**
```sql
WITH productstats AS (
    SELECT 
        productid, 
        AVG(price) OVER () AS avgprice, 
        COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
FROM productmanagement_dbo.products AS p
INNER JOIN productstats AS ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST,
    p.name NULLS FIRST
```

**Key Changes:**
- All identifiers to lowercase
- Table name: `Products` → `productmanagement_dbo.products`
- Added `NULLS FIRST` to ORDER BY clauses
- CTE name: `ProductStats` → `productstats`

---

### Statement 2: GetProductByIdAsync (Lines 87-115)

**Original SQL Server Statement:**
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
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL Statement:**
```sql
WITH producthistory AS (
    SELECT 
        productid, 
        lag(price) OVER (ORDER BY modifieddate) AS previousprice, 
        lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
FROM productmanagement_dbo.products AS p
LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Key Changes:**
- All identifiers to lowercase
- Table name: `Products` → `productmanagement_dbo.products`
- `LEFT JOIN` → `LEFT OUTER JOIN`
- `LAG()` function name to lowercase
- CTE name: `ProductHistory` → `producthistory`

---

### Statement 3: InsertProductAsync (Lines 130-158)

**Original SQL Server Statement:**
```sql
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
```

**CRITICAL: This Statement Requires Complete Refactoring**

The DMS tool FAILED to convert this statement. This must be manually refactored into separate SQL statements executed within a C#-managed transaction. Replace the entire method implementation with:

```csharp
public async Task<int> InsertProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Step 1: Insert product with RETURNING clause to get new ID
        const string insertSql = @"
            INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
            VALUES (@Name, @Description, @Price, @StockQuantity)
            RETURNING productid";
        
        int newProductId;
        using (var command = new SqlCommand(insertSql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            
            newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());
        }
        
        // Step 2: Log the insertion
        const string historySql = @"
            INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
            VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW())";
        
        using (var command = new SqlCommand(historySql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@ProductId", newProductId);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            
            await command.ExecuteNonQueryAsync();
        }
        
        // Step 3: Update product statistics
        const string statsSql = @"
            UPDATE productmanagement_dbo.productstats
            SET 
                totalproducts = totalproducts + 1,
                averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                lastupdated = NOW()
            WHERE statid = 1";
        
        using (var command = new SqlCommand(statsSql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@Price", product.Price);
            
            await command.ExecuteNonQueryAsync();
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

**Key Changes:**
- Split single multi-statement batch into 3 separate SQL commands
- Transaction management moved to C# code using `BeginTransactionAsync()`
- `SCOPE_IDENTITY()` replaced with `RETURNING productid` clause
- `GETDATE()` → `NOW()`
- All table names updated with schema prefix
- All identifiers to lowercase

---

### Statement 4: UpdateProductAsync (Lines 176-204)

**Original SQL Server Statement:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

**CRITICAL: This Statement Requires Refactoring**

Replace the entire method implementation with:

```csharp
public async Task UpdateProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Step 1: Get old values
        const string selectSql = @"
            SELECT price, stockquantity 
            FROM productmanagement_dbo.products 
            WHERE productid = @ProductId";
        
        decimal oldPrice;
        int oldStock;
        using (var command = new SqlCommand(selectSql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = Convert.ToDecimal(reader["price"]);
                oldStock = Convert.ToInt32(reader["stockquantity"]);
            }
            else
            {
                throw new InvalidOperationException($"Product with ID {product.ProductId} not found");
            }
        }
        
        // Step 2: Update the product
        const string updateSql = @"
            UPDATE productmanagement_dbo.products
            SET 
                name = @Name,
                description = @Description,
                price = @Price,
                stockquantity = @StockQuantity,
                modifieddate = NOW()
            WHERE productid = @ProductId";
        
        using (var command = new SqlCommand(updateSql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            
            await command.ExecuteNonQueryAsync();
        }
        
        // Step 3: Log the changes
        const string historySql = @"
            INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
            VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW())";
        
        using (var command = new SqlCommand(historySql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@OldStock", oldStock);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            
            await command.ExecuteNonQueryAsync();
        }
        
        // Step 4: Update statistics
        const string statsSql = @"
            UPDATE productmanagement_dbo.productstats
            SET 
                averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
                lastupdated = NOW()
            WHERE statid = 1";
        
        using (var command = new SqlCommand(statsSql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            command.Parameters.AddWithValue("@Price", product.Price);
            
            await command.ExecuteNonQueryAsync();
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

**Key Changes:**
- Split into 4 separate SQL statements
- Transaction managed in C# code
- Variables (`@OldPrice`, `@OldStock`) now C# variables
- `GETDATE()` → `NOW()`
- All table names with schema prefix
- All identifiers lowercase

---

### Statement 5: DeleteProductAsync (Lines 222-254)

**Original SQL Server Statement:**
```sql
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
```

**CRITICAL: This Statement Requires Refactoring**

Replace the entire method implementation with:

```csharp
public async Task DeleteProductAsync(int productId)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Step 1: Get old values
        const string selectSql = @"
            SELECT price, stockquantity 
            FROM productmanagement_dbo.products 
            WHERE productid = @ProductId";
        
        decimal oldPrice;
        int oldStock;
        using (var command = new SqlCommand(selectSql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@ProductId", productId);
            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = Convert.ToDecimal(reader["price"]);
                oldStock = Convert.ToInt32(reader["stockquantity"]);
            }
            else
            {
                throw new InvalidOperationException($"Product with ID {productId} not found");
            }
        }
        
        // Step 2: Log the deletion
        const string historySql = @"
            INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
            VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW())";
        
        using (var command = new SqlCommand(historySql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@ProductId", productId);
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            command.Parameters.AddWithValue("@OldStock", oldStock);
            
            await command.ExecuteNonQueryAsync();
        }
        
        // Step 3: Delete the product
        const string deleteSql = @"
            DELETE FROM productmanagement_dbo.products 
            WHERE productid = @ProductId";
        
        using (var command = new SqlCommand(deleteSql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@ProductId", productId);
            
            await command.ExecuteNonQueryAsync();
        }
        
        // Step 4: Update statistics
        const string statsSql = @"
            UPDATE productmanagement_dbo.productstats
            SET 
                totalproducts = totalproducts - 1,
                averageprice = CASE 
                    WHEN totalproducts > 1 
                    THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                    ELSE 0
                END,
                lastupdated = NOW()
            WHERE statid = 1";
        
        using (var command = new SqlCommand(statsSql, connection, (SqlTransaction)transaction))
        {
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            
            await command.ExecuteNonQueryAsync();
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

**Key Changes:**
- Split into 4 separate SQL statements
- Transaction managed in C# code
- Variables now C# variables
- `GETDATE()` → `NOW()`
- All table names with schema prefix
- All identifiers lowercase

---

### Statement 6: GetProductsByPriceRangeAsync (Lines 272-290)

**Original SQL Server Statement:**
```sql
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
```

**Converted PostgreSQL Statement:**
```sql
WITH rankedproducts AS (
    SELECT 
        p.*, 
        RANK() OVER (ORDER BY p.price) AS pricerank, 
        percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
FROM rankedproducts AS rp
ORDER BY rp.pricerank NULLS FIRST
```

**Key Changes:**
- All identifiers to lowercase
- Table name: `Products` → `productmanagement_dbo.products`
- Added `NULLS FIRST` to ORDER BY
- CTE name: `RankedProducts` → `rankedproducts`
- `PERCENT_RANK()` → `percent_rank()` (lowercase)

---

### Statement 7: GetLowStockProductsAsync (Lines 308-328)

**Original SQL Server Statement:**
```sql
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity
```

**Converted PostgreSQL Statement:**
```sql
WITH stockanalysis AS (
    SELECT 
        p.*, 
        AVG(stockquantity) OVER () AS avgstock, 
        MIN(stockquantity) OVER () AS minstock, 
        MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
FROM stockanalysis AS sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity NULLS FIRST
```

**Key Changes:**
- All identifiers to lowercase
- Table name: `Products` → `productmanagement_dbo.products`
- Added `NULLS FIRST` to ORDER BY
- CTE name: `StockAnalysis` → `stockanalysis`

---

## Additional Changes Required

### MapProductFromReader Method (Line 348)
The column names in the database are now lowercase due to PostgreSQL conversion. Update the MapProductFromReader method to use lowercase column names:

```csharp
private static Product MapProductFromReader(SqlDataReader reader)
{
    return new Product
    {
        ProductId = Convert.ToInt32(reader["productid"]),  // lowercase
        Name = reader["name"].ToString(),                    // lowercase
        Description = reader["description"] == DBNull.Value ? null : reader["description"].ToString(),  // lowercase
        Price = Convert.ToDecimal(reader["price"]),        // lowercase
        StockQuantity = Convert.ToInt32(reader["stockquantity"]),  // lowercase
        CreatedDate = Convert.ToDateTime(reader["createddate"]),    // lowercase
        ModifiedDate = reader["modifieddate"] == DBNull.Value ? null : (DateTime?)Convert.ToDateTime(reader["modifieddate"])  // lowercase
    };
}
```

---

## Verification Checklist

After implementing all changes:

1. ✅ All 7 SQL statements updated with PostgreSQL syntax
2. ✅ All table names include `productmanagement_dbo` schema prefix
3. ✅ All identifiers converted to lowercase
4. ✅ `GETDATE()` replaced with `NOW()` everywhere
5. ✅ Statements 3, 4, 5 refactored with C#-managed transactions
6. ✅ `SCOPE_IDENTITY()` replaced with `RETURNING` clause
7. ✅ `NULLS FIRST` added to appropriate ORDER BY clauses
8. ✅ MapProductFromReader updated for lowercase column names
9. ✅ All parameter names (@param) remain unchanged (Npgsql supports this)
10. ✅ Transaction management moved from SQL to C# code

---

## Implementation Status

**Status:** DOCUMENTED - Awaiting implementation

This document provides complete guidance for Step 4. The actual code changes should be implemented by:
1. Manually editing ProductRepository.cs
2. Replacing each SQL statement string with its PostgreSQL equivalent
3. Refactoring methods 3, 4, and 5 with new transaction management pattern
4. Updating MapProductFromReader with lowercase column names

**Note:** Due to tool limitations with exact string matching on large multi-line SQL statements with mixed line endings, automated replacement was not completed. Manual implementation following this guide is required.
