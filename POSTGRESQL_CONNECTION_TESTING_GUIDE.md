# PostgreSQL Connection Testing Guide

**Project:** AdoCore  
**Database:** PostgreSQL (postgres)  
**Framework:** .NET 9.0 with Npgsql 8.0.5

---

## Prerequisites

### 1. PostgreSQL Server

**Verify PostgreSQL Installation:**
```bash
psql --version
```

**Expected Output:**
```
psql (PostgreSQL) 15.x or higher
```

**Start PostgreSQL Service:**
```bash
# Linux/macOS
sudo systemctl start postgresql

# Windows
net start postgresql-x64-15

# Docker
docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:15
```

### 2. Database Creation

**Connect to PostgreSQL:**
```bash
psql -U postgres -h localhost
```

**Create Database (if not exists):**
```sql
CREATE DATABASE postgres;
\c postgres
```

**Create Schema (default public schema should exist):**
```sql
CREATE SCHEMA IF NOT EXISTS public;
```

### 3. Minimal Test Tables

**Create Products Table:**
```sql
CREATE TABLE IF NOT EXISTS public.products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description TEXT,
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INTEGER NOT NULL,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP
);
```

**Create ProductHistory Table:**
```sql
CREATE TABLE IF NOT EXISTS public.producthistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INTEGER NOT NULL,
    Action VARCHAR(10) NOT NULL,
    OldPrice DECIMAL(18, 2),
    NewPrice DECIMAL(18, 2),
    OldStock INTEGER,
    NewStock INTEGER,
    ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductId) REFERENCES public.products(ProductId) ON DELETE CASCADE
);
```

**Create ProductStats Table:**
```sql
CREATE TABLE IF NOT EXISTS public.productstats (
    StatId INTEGER PRIMARY KEY DEFAULT 1,
    TotalProducts INTEGER NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    TotalStockValue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    LowStockCount INTEGER NOT NULL DEFAULT 0,
    DiscontinuedCount INTEGER NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial stats record
INSERT INTO public.productstats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, CURRENT_TIMESTAMP)
ON CONFLICT (StatId) DO NOTHING;
```

**Insert Sample Data:**
```sql
INSERT INTO public.products (Name, Description, Price, StockQuantity)
VALUES 
    ('Laptop', 'High-performance laptop', 999.99, 10),
    ('Mouse', 'Wireless gaming mouse', 49.99, 20),
    ('Keyboard', 'Mechanical keyboard', 129.99, 15),
    ('Monitor', '27-inch 4K monitor', 399.99, 8),
    ('Headset', 'Noise-cancelling headset', 199.99, 12);

-- Update statistics
UPDATE public.productstats
SET 
    TotalProducts = (SELECT COUNT(*) FROM public.products),
    AveragePrice = (SELECT AVG(Price) FROM public.products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM public.products),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;
```

**Verify Setup:**
```sql
SELECT * FROM public.products;
SELECT * FROM public.productstats;
```

---

## Connection Testing

### 1. Basic Connection Test

**Create Test Script: `test-connection.csx`**
```csharp
#r "nuget: Npgsql, 8.0.5"

using Npgsql;
using System;

var connectionString = "Host=localhost;Database=postgres;Username=postgres;Password=postgres;";

try
{
    using var connection = new NpgsqlConnection(connectionString);
    await connection.OpenAsync();
    
    Console.WriteLine("✅ Connection successful!");
    Console.WriteLine($"Database: {connection.Database}");
    Console.WriteLine($"Server Version: {connection.ServerVersion}");
    Console.WriteLine($"State: {connection.State}");
    
    await connection.CloseAsync();
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Connection failed: {ex.Message}");
}
```

**Run Test:**
```bash
dotnet script test-connection.csx
```

**Expected Output:**
```
✅ Connection successful!
Database: postgres
Server Version: 15.x
State: Open
```

### 2. Connection String Validation

**Test Different Connection String Formats:**

```csharp
using Npgsql;

// Test 1: Basic connection
var conn1 = "Host=localhost;Database=postgres;Username=postgres;Password=postgres;";

// Test 2: With port
var conn2 = "Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres;";

// Test 3: With pooling
var conn3 = "Host=localhost;Database=postgres;Username=postgres;Password=postgres;Pooling=true;MinPoolSize=5;MaxPoolSize=100;";

// Test 4: With timeout
var conn4 = "Host=localhost;Database=postgres;Username=postgres;Password=postgres;Timeout=30;CommandTimeout=60;";

// Test 5: With SSL (for production)
var conn5 = "Host=localhost;Database=postgres;Username=postgres;Password=postgres;SSL Mode=Prefer;Trust Server Certificate=true;";

foreach (var connStr in new[] { conn1, conn2, conn3, conn4, conn5 })
{
    try
    {
        var builder = new NpgsqlConnectionStringBuilder(connStr);
        Console.WriteLine($"✅ Valid: Host={builder.Host}, Database={builder.Database}");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"❌ Invalid: {ex.Message}");
    }
}
```

### 3. Query Execution Test

**Create Test Script: `test-query.csx`**
```csharp
#r "nuget: Npgsql, 8.0.5"

using Npgsql;
using System;

var connectionString = "Host=localhost;Database=postgres;Username=postgres;Password=postgres;";

try
{
    using var connection = new NpgsqlConnection(connectionString);
    await connection.OpenAsync();
    
    // Test 1: Simple SELECT
    var sql1 = "SELECT COUNT(*) FROM public.products";
    using (var cmd = new NpgsqlCommand(sql1, connection))
    {
        var count = await cmd.ExecuteScalarAsync();
        Console.WriteLine($"✅ Test 1 - Count: {count} products");
    }
    
    // Test 2: SELECT with columns
    var sql2 = "SELECT ProductId, Name, Price FROM public.products LIMIT 3";
    using (var cmd = new NpgsqlCommand(sql2, connection))
    using (var reader = await cmd.ExecuteReaderAsync())
    {
        Console.WriteLine("✅ Test 2 - First 3 products:");
        while (await reader.ReadAsync())
        {
            Console.WriteLine($"  ID: {reader["ProductId"]}, Name: {reader["Name"]}, Price: {reader["Price"]}");
        }
    }
    
    // Test 3: Parameterized query
    var sql3 = "SELECT Name, Price FROM public.products WHERE Price > @MinPrice ORDER BY Price";
    using (var cmd = new NpgsqlCommand(sql3, connection))
    {
        cmd.Parameters.AddWithValue("@MinPrice", 100.00m);
        using var reader = await cmd.ExecuteReaderAsync();
        Console.WriteLine("✅ Test 3 - Products over $100:");
        while (await reader.ReadAsync())
        {
            Console.WriteLine($"  {reader["Name"]}: ${reader["Price"]}");
        }
    }
    
    // Test 4: CTE with window function
    var sql4 = @"
        WITH ProductStats AS (
            SELECT 
                ProductId,
                Name,
                Price,
                AVG(Price) OVER() as AvgPrice
            FROM public.products
        )
        SELECT ProductId, Name, Price, AvgPrice
        FROM ProductStats
        LIMIT 3";
    using (var cmd = new NpgsqlCommand(sql4, connection))
    using (var reader = await cmd.ExecuteReaderAsync())
    {
        Console.WriteLine("✅ Test 4 - CTE with window function:");
        while (await reader.ReadAsync())
        {
            Console.WriteLine($"  {reader["Name"]}: ${reader["Price"]} (Avg: ${reader["AvgPrice"]:F2})");
        }
    }
    
    await connection.CloseAsync();
    Console.WriteLine("\n✅ All query tests passed!");
}
catch (Exception ex)
{
    Console.WriteLine($"\n❌ Query test failed: {ex.Message}");
    Console.WriteLine($"Stack trace: {ex.StackTrace}");
}
```

**Run Test:**
```bash
dotnet script test-query.csx
```

### 4. Transaction Test

**Create Test Script: `test-transaction.csx`**
```csharp
#r "nuget: Npgsql, 8.0.5"

using Npgsql;
using System;

var connectionString = "Host=localhost;Database=postgres;Username=postgres;Password=postgres;";

try
{
    using var connection = new NpgsqlConnection(connectionString);
    await connection.OpenAsync();
    
    // Test 1: Successful transaction
    Console.WriteLine("Test 1: Successful transaction");
    using (var transaction = await connection.BeginTransactionAsync())
    {
        try
        {
            var insertSql = @"
                INSERT INTO public.products (Name, Description, Price, StockQuantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING ProductId";
            
            using var cmd = new NpgsqlCommand(insertSql, connection, transaction);
            cmd.Parameters.AddWithValue("@Name", "Test Product");
            cmd.Parameters.AddWithValue("@Description", "Transaction test");
            cmd.Parameters.AddWithValue("@Price", 99.99m);
            cmd.Parameters.AddWithValue("@StockQuantity", 5);
            
            var newId = await cmd.ExecuteScalarAsync();
            Console.WriteLine($"  Inserted product with ID: {newId}");
            
            await transaction.CommitAsync();
            Console.WriteLine("✅ Transaction committed");
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
    
    // Test 2: Rollback transaction
    Console.WriteLine("\nTest 2: Rollback transaction");
    using (var transaction = await connection.BeginTransactionAsync())
    {
        try
        {
            var insertSql = @"
                INSERT INTO public.products (Name, Description, Price, StockQuantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING ProductId";
            
            using var cmd = new NpgsqlCommand(insertSql, connection, transaction);
            cmd.Parameters.AddWithValue("@Name", "Rollback Test");
            cmd.Parameters.AddWithValue("@Description", "Should be rolled back");
            cmd.Parameters.AddWithValue("@Price", 99.99m);
            cmd.Parameters.AddWithValue("@StockQuantity", 5);
            
            var newId = await cmd.ExecuteScalarAsync();
            Console.WriteLine($"  Inserted product with ID: {newId}");
            
            // Intentionally rollback
            await transaction.RollbackAsync();
            Console.WriteLine("✅ Transaction rolled back (intentional)");
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            Console.WriteLine($"❌ Error: {ex.Message}");
        }
    }
    
    // Verify Test 2 rollback
    var verifySql = "SELECT COUNT(*) FROM public.products WHERE Name = 'Rollback Test'";
    using (var cmd = new NpgsqlCommand(verifySql, connection))
    {
        var count = await cmd.ExecuteScalarAsync();
        if (Convert.ToInt32(count) == 0)
        {
            Console.WriteLine("✅ Verified: Rolled back product not found");
        }
        else
        {
            Console.WriteLine("❌ Warning: Rolled back product still exists");
        }
    }
    
    await connection.CloseAsync();
    Console.WriteLine("\n✅ All transaction tests passed!");
}
catch (Exception ex)
{
    Console.WriteLine($"\n❌ Transaction test failed: {ex.Message}");
}
```

**Run Test:**
```bash
dotnet script test-transaction.csx
```

---

## Application Testing

### 1. Build Application

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Restore packages
dotnet restore

# Build
dotnet build
```

**Expected Output:**
```
Restore completed in X ms.
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### 2. Run Application (Interactive Mode)

```bash
dotnet run
```

**Expected Output:**
```
===== Product Management System =====
1. List all products
2. Get product by ID
3. Add new product
4. Update product
5. Delete product
6. Get products by price range
7. Get low stock products
0. Exit

Enter your choice:
```

**Test Operations:**

**Test 1: List All Products (Option 1)**
- Should display all products with window function calculations
- Verify CTE with AVG() OVER() and COUNT() OVER() works

**Test 2: Get Product by ID (Option 2)**
- Enter existing product ID (e.g., 1)
- Should display product details with LAG() window function data

**Test 3: Add New Product (Option 3)**
- Enter: Name, Description, Price, StockQuantity
- Should return new product ID via RETURNING clause
- Verify multi-step transaction (insert + log + stats update)

**Test 4: Update Product (Option 4)**
- Enter: Product ID and new values
- Should use CURRENT_TIMESTAMP for modified date
- Verify multi-step transaction with history logging

**Test 5: Delete Product (Option 5)**
- Enter: Product ID
- Should execute multi-step transaction
- Verify cascading to history table

**Test 6: Price Range Query (Option 6)**
- Enter: Min and Max price (e.g., 50, 200)
- Should return products with RANK() and PERCENT_RANK()

**Test 7: Low Stock Query (Option 7)**
- Enter: Threshold (e.g., 10)
- Should return products with multiple window functions

### 3. Run Application (Command Line Mode)

**List Products:**
```bash
dotnet run -- list
```

**Get Product:**
```bash
dotnet run -- get 1
```

**Add Product:**
```bash
dotnet run -- add "New Product" "Description" 79.99 15
```

**Update Product:**
```bash
dotnet run -- update 1 "Updated Name" "Updated Description" 89.99 20
```

**Delete Product:**
```bash
dotnet run -- delete 1
```

**Price Range:**
```bash
dotnet run -- range 50 200
```

**Low Stock:**
```bash
dotnet run -- lowstock 10
```

---

## Troubleshooting

### Connection Issues

**Problem: "Could not connect to server"**

```
Npgsql.NpgsqlException: Exception while connecting
  ---> System.Net.Sockets.SocketException: Connection refused
```

**Solutions:**
1. Check PostgreSQL is running:
   ```bash
   sudo systemctl status postgresql
   ```

2. Check PostgreSQL is listening:
   ```bash
   sudo netstat -plnt | grep 5432
   ```

3. Check pg_hba.conf allows local connections:
   ```
   # Add to pg_hba.conf
   host    all             all             127.0.0.1/32            md5
   ```

4. Restart PostgreSQL:
   ```bash
   sudo systemctl restart postgresql
   ```

**Problem: "password authentication failed"**

```
Npgsql.NpgsqlException: 28P01: password authentication failed for user "postgres"
```

**Solutions:**
1. Reset password:
   ```bash
   sudo -u postgres psql
   ALTER USER postgres PASSWORD 'postgres';
   ```

2. Update connection string in appsettings.json

3. Check pg_hba.conf authentication method:
   ```
   # Use md5 or scram-sha-256, not peer or ident
   local   all             postgres                                md5
   ```

**Problem: "database does not exist"**

```
Npgsql.NpgsqlException: 3D000: database "postgres" does not exist
```

**Solutions:**
1. Create database:
   ```bash
   createdb postgres -U postgres
   ```

2. Or connect to default database and create:
   ```sql
   psql -U postgres -d template1
   CREATE DATABASE postgres;
   ```

### Query Issues

**Problem: "relation does not exist"**

```
Npgsql.PostgresException: 42P01: relation "products" does not exist
```

**Solutions:**
1. Check schema:
   ```sql
   \dt
   \dt public.*
   ```

2. Create table with schema:
   ```sql
   CREATE TABLE public.products (...);
   ```

3. Verify queries use schema qualification:
   ```sql
   SELECT * FROM public.products;
   ```

**Problem: "column does not exist"**

```
Npgsql.PostgresException: 42703: column "productid" does not exist
```

**Solutions:**
1. Check column names (case-sensitive in PostgreSQL):
   ```sql
   \d public.products
   ```

2. Use exact case:
   ```sql
   SELECT "ProductId" FROM public.products;
   ```

3. Or use lowercase:
   ```sql
   CREATE TABLE public.products (productid SERIAL, ...);
   SELECT productid FROM public.products;
   ```

**Problem: Window function error**

```
Npgsql.PostgresException: 42P20: window function call requires an OVER clause
```

**Solutions:**
1. Add OVER() clause:
   ```sql
   SELECT AVG(Price) OVER() FROM products;
   ```

2. Or use GROUP BY:
   ```sql
   SELECT AVG(Price) FROM products;
   ```

### Transaction Issues

**Problem: "current transaction is aborted"**

```
Npgsql.PostgresException: 25P02: current transaction is aborted, commands ignored until end of transaction block
```

**Solutions:**
1. Always use try-catch with rollback:
   ```csharp
   using var transaction = await connection.BeginTransactionAsync();
   try
   {
       // operations
       await transaction.CommitAsync();
   }
   catch
   {
       await transaction.RollbackAsync();
       throw;
   }
   ```

2. Handle exceptions properly in application code

**Problem: "deadlock detected"**

```
Npgsql.PostgresException: 40P01: deadlock detected
```

**Solutions:**
1. Use consistent lock order
2. Keep transactions short
3. Use appropriate isolation level:
   ```csharp
   var transaction = await connection.BeginTransactionAsync(IsolationLevel.ReadCommitted);
   ```

---

## Performance Monitoring

### Query Performance

**Enable timing:**
```sql
\timing
```

**Analyze queries:**
```sql
EXPLAIN ANALYZE
SELECT * FROM public.products
WHERE Price > 100
ORDER BY Price;
```

**Check slow queries:**
```sql
SELECT query, total_time, calls
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

### Connection Monitoring

**Check active connections:**
```sql
SELECT count(*) FROM pg_stat_activity;
```

**Check connection details:**
```sql
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query
FROM pg_stat_activity
WHERE datname = 'postgres';
```

### Application Logging

**Add logging to appsettings.json:**
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Npgsql": "Debug"
    }
  }
}
```

**Enable Npgsql logging:**
```csharp
NpgsqlLoggingConfiguration.InitializeLogging(loggerFactory);
```

---

## Validation Checklist

### Connection Validation:
- [ ] Can connect to PostgreSQL server
- [ ] Connection string format is correct
- [ ] Database "postgres" exists
- [ ] Tables exist in public schema
- [ ] User has appropriate permissions

### Query Validation:
- [ ] Simple SELECT works
- [ ] Parameterized queries work
- [ ] CTEs work
- [ ] Window functions work
- [ ] RETURNING clause works
- [ ] CURRENT_TIMESTAMP works

### Transaction Validation:
- [ ] Transactions commit successfully
- [ ] Transactions rollback on error
- [ ] Multi-step transactions work
- [ ] No deadlocks or blocking

### Application Validation:
- [ ] Application builds without errors
- [ ] Application runs without exceptions
- [ ] All CRUD operations work
- [ ] Complex queries execute correctly
- [ ] History logging works
- [ ] Statistics updates work

### Performance Validation:
- [ ] Queries execute in reasonable time
- [ ] Connection pooling works
- [ ] No connection leaks
- [ ] Indexes are used appropriately

---

**Guide Version:** 1.0  
**Last Updated:** 2024  
**Target Database:** PostgreSQL 15+  
**Framework:** .NET 9.0 with Npgsql 8.0.5
