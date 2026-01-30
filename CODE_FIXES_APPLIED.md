# Code Fixes Applied - SQL Server to PostgreSQL Migration

## Summary
This document details all code fixes applied to complete the SQL Server to PostgreSQL migration for the AdoCore application.

---

## Fix 1: InsertProductAsync Method

### Issue
- SQL Server syntax: `DECLARE @NewProductId INT;`, `SCOPE_IDENTITY()`, `GETDATE()`
- Transaction using SQL strings: `BEGIN TRANSACTION;...COMMIT;`
- Would fail at runtime with PostgreSQL

### Fix Applied
- Converted to use PostgreSQL `RETURNING` clause instead of `SCOPE_IDENTITY()`
- Replaced `GETDATE()` with `CURRENT_TIMESTAMP`
- Split transaction into 3 separate SQL commands
- Moved transaction handling to ADO.NET level with `NpgsqlTransaction`
- Added proper try/catch with commit/rollback

### Before (SQL Server):
```csharp
public async Task<int> InsertProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    
    const string sql = @"
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
        
        SELECT @NewProductId;";
    
    using var command = new NpgsqlCommand(sql, connection);
    command.Parameters.AddWithValue("@Name", product.Name);
    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
    command.Parameters.AddWithValue("@Price", product.Price);
    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
    
    return Convert.ToInt32(await command.ExecuteScalarAsync());
}
```

### After (PostgreSQL):
```csharp
public async Task<int> InsertProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();

    try
    {
        // Insert the new product with RETURNING clause
        const string insertProductSql = @"
            INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
            VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
            RETURNING ProductId";

        int newProductId;
        using (var command = new NpgsqlCommand(insertProductSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());
        }

        // Log the insertion
        const string insertHistorySql = @"
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";

        using (var command = new NpgsqlCommand(insertHistorySql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", newProductId);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            await command.ExecuteNonQueryAsync();
        }

        // Update product statistics
        const string updateStatsSql = @"
            UPDATE ProductStats
            SET 
                TotalProducts = TotalProducts + 1,
                AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1";

        using (var command = new NpgsqlCommand(updateStatsSql, connection, transaction))
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

---

## Fix 2: UpdateProductAsync Method

### Issue
- SQL Server syntax: `DECLARE @OldPrice`, `DECLARE @OldStock`, `GETDATE()`
- Transaction using SQL strings: `BEGIN TRANSACTION;...COMMIT;`
- DECLARE variables not supported in PostgreSQL inline SQL

### Fix Applied
- Replaced `DECLARE` statements with separate SELECT query to fetch old values
- Split transaction into 4 separate SQL commands
- Moved transaction handling to ADO.NET level with `NpgsqlTransaction`
- Replaced `GETDATE()` with `CURRENT_TIMESTAMP`
- Added proper error handling for non-existent products

### Before (SQL Server):
```csharp
public async Task UpdateProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    
    const string sql = @"
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
        COMMIT;";
    
    using var command = new NpgsqlCommand(sql, connection);
    command.Parameters.AddWithValue("@ProductId", product.ProductId);
    command.Parameters.AddWithValue("@Name", product.Name);
    command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
    command.Parameters.AddWithValue("@Price", product.Price);
    command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
    
    await command.ExecuteNonQueryAsync();
}
```

### After (PostgreSQL):
```csharp
public async Task UpdateProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();

    try
    {
        // Fetch old values for history
        const string fetchOldValuesSql = @"
            SELECT Price, StockQuantity
            FROM Products
            WHERE ProductId = @ProductId";

        decimal oldPrice;
        int oldStock;
        using (var command = new NpgsqlCommand(fetchOldValuesSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = Convert.ToDecimal(reader["Price"]);
                oldStock = Convert.ToInt32(reader["StockQuantity"]);
            }
            else
            {
                throw new InvalidOperationException($"Product with ID {product.ProductId} not found.");
            }
        }

        // Update the product
        const string updateProductSql = @"
            UPDATE Products
            SET 
                Name = @Name,
                Description = @Description,
                Price = @Price,
                StockQuantity = @StockQuantity,
                ModifiedDate = CURRENT_TIMESTAMP
            WHERE ProductId = @ProductId";

        using (var command = new NpgsqlCommand(updateProductSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);

            await command.ExecuteNonQueryAsync();
        }

        // Log the changes
        const string insertHistorySql = @"
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@ProductId, 'UPDATE', @OldPrice, @NewPrice, @OldStock, @NewStock, CURRENT_TIMESTAMP)";

        using (var command = new NpgsqlCommand(insertHistorySql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            command.Parameters.AddWithValue("@NewPrice", product.Price);
            command.Parameters.AddWithValue("@OldStock", oldStock);
            command.Parameters.AddWithValue("@NewStock", product.StockQuantity);

            await command.ExecuteNonQueryAsync();
        }

        // Update product statistics
        const string updateStatsSql = @"
            UPDATE ProductStats
            SET 
                AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @NewPrice) / TotalProducts,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1";

        using (var command = new NpgsqlCommand(updateStatsSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            command.Parameters.AddWithValue("@NewPrice", product.Price);

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

---

## Fix 3: DeleteProductAsync Method

### Issue
- SQL Server syntax: `DECLARE @OldPrice`, `DECLARE @OldStock`, `GETDATE()`
- Transaction using SQL strings: `BEGIN TRANSACTION;...COMMIT;`
- DECLARE variables not supported in PostgreSQL inline SQL

### Fix Applied
- Replaced `DECLARE` statements with separate SELECT query to fetch old values
- Split transaction into 4 separate SQL commands
- Moved transaction handling to ADO.NET level with `NpgsqlTransaction`
- Replaced `GETDATE()` with `CURRENT_TIMESTAMP`
- Added proper error handling for non-existent products

### Before (SQL Server):
```csharp
public async Task DeleteProductAsync(int productId)
{
    var connection = await GetConnectionAsync();
    
    const string sql = @"
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
        COMMIT;";
    
    using var command = new NpgsqlCommand(sql, connection);
    command.Parameters.AddWithValue("@ProductId", productId);
    
    await command.ExecuteNonQueryAsync();
}
```

### After (PostgreSQL):
```csharp
public async Task DeleteProductAsync(int productId)
{
    var connection = await GetConnectionAsync();
    using var transaction = await connection.BeginTransactionAsync();

    try
    {
        // Fetch old values for history
        const string fetchOldValuesSql = @"
            SELECT Price, StockQuantity
            FROM Products
            WHERE ProductId = @ProductId";

        decimal oldPrice;
        int oldStock;
        using (var command = new NpgsqlCommand(fetchOldValuesSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", productId);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = Convert.ToDecimal(reader["Price"]);
                oldStock = Convert.ToInt32(reader["StockQuantity"]);
            }
            else
            {
                throw new InvalidOperationException($"Product with ID {productId} not found.");
            }
        }

        // Log the deletion
        const string insertHistorySql = @"
            INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
            VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP)";

        using (var command = new NpgsqlCommand(insertHistorySql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", productId);
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            command.Parameters.AddWithValue("@OldStock", oldStock);

            await command.ExecuteNonQueryAsync();
        }

        // Delete the product
        const string deleteProductSql = @"
            DELETE FROM Products 
            WHERE ProductId = @ProductId";

        using (var command = new NpgsqlCommand(deleteProductSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", productId);

            await command.ExecuteNonQueryAsync();
        }

        // Update product statistics
        const string updateStatsSql = @"
            UPDATE ProductStats
            SET 
                TotalProducts = TotalProducts - 1,
                AveragePrice = CASE 
                    WHEN TotalProducts > 1 
                    THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
                    ELSE 0
                END,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE StatId = 1";

        using (var command = new NpgsqlCommand(updateStatsSql, connection, transaction))
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

---

## Fix 4: Npgsql Security Vulnerability

### Issue
- Npgsql 8.0.1 had known high severity vulnerability (GHSA-x9vc-6hfv-hg8c)
- Build showed NU1903 security warnings

### Fix Applied
- Updated AdoCore.csproj to use Npgsql 8.0.5
- Verified build with new version

### Before:
```xml
<PackageReference Include="Npgsql" Version="8.0.1" />
```

### After:
```xml
<PackageReference Include="Npgsql" Version="8.0.5" />
```

---

## Summary of SQL Syntax Transformations

| SQL Server Syntax | PostgreSQL Equivalent | Context |
|-------------------|----------------------|---------|
| `SCOPE_IDENTITY()` | `RETURNING ProductId` | Get last inserted ID |
| `GETDATE()` | `CURRENT_TIMESTAMP` | Get current timestamp |
| `BEGIN TRANSACTION;` | `await connection.BeginTransactionAsync()` | Start transaction (ADO.NET level) |
| `COMMIT;` | `await transaction.CommitAsync()` | Commit transaction (ADO.NET level) |
| `DECLARE @Variable` | C# variable with SELECT | Variable declaration |
| `SET @Variable = value` | C# assignment from query result | Variable assignment |
| `@parameter` | `@parameter` (supported by Npgsql) | Named parameters (unchanged) |

---

## Transaction Pattern Transformation

### SQL Server Pattern (Incorrect for PostgreSQL):
```csharp
const string sql = "BEGIN TRANSACTION; [statements]; COMMIT;";
using var command = new NpgsqlCommand(sql, connection);
await command.ExecuteNonQueryAsync();
```

### PostgreSQL Pattern (Correct):
```csharp
using var transaction = await connection.BeginTransactionAsync();
try
{
    using (var cmd1 = new NpgsqlCommand(sql1, connection, transaction)) { await cmd1.ExecuteNonQueryAsync(); }
    using (var cmd2 = new NpgsqlCommand(sql2, connection, transaction)) { await cmd2.ExecuteNonQueryAsync(); }
    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
```

---

## Build Verification Results

### Before Fixes:
- Build Status: SUCCESS (0 errors, 12 warnings)
- Security Warnings: 2 (NU1903 for Npgsql 8.0.1)
- Runtime Status: WOULD FAIL (invalid PostgreSQL syntax)

### After Fixes:
- Build Status: SUCCESS (0 errors, 10 warnings)
- Security Warnings: 0
- Runtime Status: READY FOR TESTING (valid PostgreSQL syntax)

---

## Files Modified

1. **DataAccess/ProductRepository.cs**
   - Complete rewrite with PostgreSQL-compatible implementation
   - All 3 transaction methods converted (Insert, Update, Delete)
   - Backup created: DataAccess/ProductRepository.cs.backup

2. **AdoCore.csproj**
   - Npgsql version updated from 8.0.1 to 8.0.5

---

## Testing Recommendations

### Unit Testing:
1. Test InsertProductAsync with valid product data
2. Test UpdateProductAsync with existing product
3. Test DeleteProductAsync with existing product
4. Test transaction rollback on errors
5. Test with non-existent product IDs

### Integration Testing:
1. Verify RETURNING clause returns correct ProductId
2. Verify CURRENT_TIMESTAMP produces valid timestamps
3. Verify transaction atomicity with concurrent operations
4. Verify ProductHistory logging works correctly
5. Verify ProductStats updates work correctly

### Performance Testing:
1. Measure transaction overhead with multiple commands
2. Compare with original SQL Server performance
3. Test connection pooling behavior
4. Test under load with concurrent transactions

---

**Document Created:** 2026-01-30  
**Author:** AWS Transform CLI General Purpose Agent  
**Migration Project:** AdoCore SQL Server to PostgreSQL
