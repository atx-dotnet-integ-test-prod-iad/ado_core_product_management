# PostgreSQL Migration - Deployment & Testing Guide

## Overview
This guide provides step-by-step instructions for deploying the PostgreSQL database and validating the migrated .NET ADO Core application.

---

## Prerequisites

### Software Requirements
- PostgreSQL 13 or higher
- .NET 9.0 SDK
- psql command-line tool (included with PostgreSQL)
- Optional: pgAdmin 4 for GUI-based database management

### Access Requirements
- PostgreSQL server with administrative access
- Ability to create databases and schemas
- Network connectivity to PostgreSQL server

---

## Part 1: PostgreSQL Database Deployment

### Step 1: Install PostgreSQL (if not already installed)

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**MacOS (using Homebrew):**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Windows:**
- Download installer from https://www.postgresql.org/download/windows/
- Run installer and follow prompts
- Note the superuser password you set during installation

### Step 2: Create Database

Connect to PostgreSQL as superuser:
```bash
# Linux/MacOS
sudo -u postgres psql

# Windows (from Command Prompt with PostgreSQL in PATH)
psql -U postgres
```

Create the ProductManagement database:
```sql
CREATE DATABASE "ProductManagement" 
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

\c ProductManagement
```

### Step 3: Run Setup Script

From the command line (outside psql):
```bash
# Navigate to the scripts directory
cd /path/to/sourceCode/Database/Scripts/

# Run the PostgreSQL setup script
psql -U postgres -d ProductManagement -f 01_PostgreSQL_Setup.sql
```

Or from within psql:
```sql
\c ProductManagement
\i /path/to/sourceCode/Database/Scripts/01_PostgreSQL_Setup.sql
```

### Step 4: Verify Database Setup

Run these verification queries:
```sql
-- Check schema
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'productmanagement_dbo';

-- Check tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'productmanagement_dbo' 
ORDER BY table_name;

-- Check data
SELECT COUNT(*) as total_products FROM productmanagement_dbo.products;
SELECT COUNT(*) as total_categories FROM productmanagement_dbo.categories;
SELECT COUNT(*) as total_suppliers FROM productmanagement_dbo.suppliers;

-- Check triggers
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'productmanagement_dbo';

-- Verify sample data
SELECT productid, name, price, stockquantity 
FROM productmanagement_dbo.products 
LIMIT 5;
```

Expected Results:
- Schema: productmanagement_dbo exists
- Tables: categories, products, producthistory, productstats, suppliers
- Products: 18 sample products
- Categories: 20 categories
- Suppliers: 8 suppliers
- Trigger: trg_products_history on products table

---

## Part 2: Application Configuration

### Step 1: Update Connection String

Edit `appsettings.json` in the application root:

**For Development (localhost):**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=your_actual_password;Pooling=true;SSL Mode=Prefer"
  },
  "Environment": "Development"
}
```

**For Production:**
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-prod-server;Port=5432;Database=ProductManagement;Username=your_prod_user;Password=your_secure_password;Pooling=true;SSL Mode=Require"
  },
  "Environment": "Production"
}
```

**Security Best Practice - Using Environment Variables:**

Instead of hardcoding credentials, use environment variables:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};Username=${DB_USER};Password=${DB_PASSWORD};Pooling=true;SSL Mode=Prefer"
  }
}
```

Set environment variables:
```bash
# Linux/MacOS
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=ProductManagement
export DB_USER=postgres
export DB_PASSWORD=your_password

# Windows (Command Prompt)
set DB_HOST=localhost
set DB_PORT=5432
set DB_NAME=ProductManagement
set DB_USER=postgres
set DB_PASSWORD=your_password

# Windows (PowerShell)
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
$env:DB_NAME="ProductManagement"
$env:DB_USER="postgres"
$env:DB_PASSWORD="your_password"
```

### Step 2: Restore NuGet Packages

```bash
cd /path/to/sourceCode
dotnet restore
```

### Step 3: Build Application

```bash
dotnet build --configuration Release
```

Expected output:
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

---

## Part 3: Runtime Validation & Testing

### Test 1: Database Connectivity

Create a simple test program or add this to `Program.cs`:

```csharp
using Npgsql;
using Microsoft.Extensions.Configuration;

var configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .Build();

var connectionString = configuration.GetConnectionString("DevConnection");

try
{
    using var connection = new NpgsqlConnection(connectionString);
    await connection.OpenAsync();
    Console.WriteLine("✅ Database connection successful!");
    Console.WriteLine($"Database: {connection.Database}");
    Console.WriteLine($"Server Version: {connection.ServerVersion}");
    await connection.CloseAsync();
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Database connection failed: {ex.Message}");
}
```

Run:
```bash
dotnet run
```

### Test 2: Query Execution Validation

Test each converted SQL statement:

#### Test 2.1: GetAllProductsAsync
```sql
-- Expected query from application
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;
```

Validation checklist:
- [ ] Query executes without errors
- [ ] Returns 18 products (sample data count)
- [ ] PriceCategory calculated correctly
- [ ] Results ordered correctly (above average first, then by name)

#### Test 2.2: GetProductByIdAsync
```sql
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = 1)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = 1;
```

Validation checklist:
- [ ] Query executes without errors
- [ ] Returns exactly 1 product
- [ ] Product details match expected values
- [ ] Price history fields populated correctly

#### Test 2.3: InsertProductAsync
```sql
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES ('Test Product', 'Test Description', 99.99, 10, CURRENT_TIMESTAMP)
RETURNING productid;
```

Validation checklist:
- [ ] Insert executes without errors
- [ ] Returns new productid
- [ ] Record visible in products table
- [ ] History trigger creates INSERT record in producthistory table
- [ ] CreatedDate automatically populated

Verify trigger:
```sql
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = (SELECT MAX(productid) FROM productmanagement_dbo.products)
ORDER BY actiondate DESC LIMIT 1;
```

#### Test 2.4: UpdateProductAsync
```sql
UPDATE productmanagement_dbo.products
SET name = 'Updated Product', 
    description = 'Updated Description', 
    price = 149.99, 
    stockquantity = 15, 
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = 1;
```

Validation checklist:
- [ ] Update executes without errors
- [ ] Record updated in products table
- [ ] ModifiedDate automatically updated
- [ ] History trigger creates UPDATE record with old/new values

Verify trigger:
```sql
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = 1 AND action = 'UPDATE'
ORDER BY actiondate DESC LIMIT 1;
```

#### Test 2.5: DeleteProductAsync
```sql
DELETE FROM productmanagement_dbo.products
WHERE productid = 1;
```

Validation checklist:
- [ ] Delete executes without errors
- [ ] Record removed from products table
- [ ] History trigger creates DELETE record with old values

**Note:** This will fail with FK constraint if producthistory records exist. Test with a newly inserted product instead.

#### Test 2.6: GetProductsByPriceRangeAsync
```sql
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN 100 AND 500)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;
```

Validation checklist:
- [ ] Query executes without errors
- [ ] Returns only products in price range
- [ ] PriceRank calculated correctly
- [ ] PriceSegment assigned correctly
- [ ] Results ordered by rank

#### Test 2.7: GetLowStockProductsAsync
```sql
WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= 10 THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= 10
    ORDER BY stockquantity NULLS FIRST;
```

Validation checklist:
- [ ] Query executes without errors
- [ ] Returns only products with stock <= threshold
- [ ] StockStatus calculated correctly
- [ ] Window functions return correct averages
- [ ] Results ordered by stock quantity

### Test 3: Transaction Validation

Test transaction atomicity:

```csharp
// This should be in your repository
public async Task<bool> TestTransactionRollback()
{
    using var connection = new NpgsqlConnection(_connectionString);
    await connection.OpenAsync();
    using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Insert a product
        var insertCmd = new NpgsqlCommand(
            "INSERT INTO productmanagement_dbo.products (name, price, stockquantity) VALUES (@name, @price, @stock) RETURNING productid",
            connection, transaction);
        insertCmd.Parameters.AddWithValue("name", "Transaction Test");
        insertCmd.Parameters.AddWithValue("price", 99.99m);
        insertCmd.Parameters.AddWithValue("stock", 10);
        var productId = (int)await insertCmd.ExecuteScalarAsync();
        
        // Intentionally cause an error (e.g., FK constraint violation)
        var errorCmd = new NpgsqlCommand(
            "INSERT INTO productmanagement_dbo.products (name, price, stockquantity, categoryid) VALUES (@name, @price, @stock, 9999)",
            connection, transaction);
        errorCmd.Parameters.AddWithValue("name", "Should Fail");
        errorCmd.Parameters.AddWithValue("price", 99.99m);
        errorCmd.Parameters.AddWithValue("stock", 10);
        await errorCmd.ExecuteNonQueryAsync(); // This should fail
        
        await transaction.CommitAsync();
        return false; // Should not reach here
    }
    catch
    {
        await transaction.RollbackAsync();
        
        // Verify the first insert was rolled back
        var checkCmd = new NpgsqlCommand(
            "SELECT COUNT(*) FROM productmanagement_dbo.products WHERE name = 'Transaction Test'",
            connection);
        var count = (long)await checkCmd.ExecuteScalarAsync();
        return count == 0; // Should be 0 if rollback worked
    }
}
```

Validation checklist:
- [ ] Transaction begins successfully
- [ ] First operation executes
- [ ] Error occurs as expected
- [ ] Transaction rolls back
- [ ] No partial data committed
- [ ] Database state consistent

### Test 4: Connection Pooling

Test connection pooling behavior:

```csharp
public async Task TestConnectionPooling()
{
    var tasks = new List<Task>();
    
    for (int i = 0; i < 50; i++)
    {
        tasks.Add(Task.Run(async () =>
        {
            using var connection = new NpgsqlConnection(_connectionString);
            await connection.OpenAsync();
            var cmd = new NpgsqlCommand("SELECT COUNT(*) FROM productmanagement_dbo.products", connection);
            await cmd.ExecuteScalarAsync();
        }));
    }
    
    await Task.WhenAll(tasks);
    Console.WriteLine("✅ Connection pooling test completed");
}
```

Validation checklist:
- [ ] All 50 connections succeed
- [ ] No connection timeout errors
- [ ] Pooling configuration respected
- [ ] Connections returned to pool

### Test 5: Performance Benchmarking

Compare query execution times:

```csharp
public async Task BenchmarkQueries()
{
    var sw = Stopwatch.StartNew();
    
    // Test complex query (GetAllProductsAsync)
    using var connection = new NpgsqlConnection(_connectionString);
    await connection.OpenAsync();
    
    for (int i = 0; i < 100; i++)
    {
        var cmd = new NpgsqlCommand(@"
            WITH productstats AS (
                SELECT productid, AVG(price) OVER () AS avgprice
                FROM productmanagement_dbo.products
            )
            SELECT p.* FROM productmanagement_dbo.products p
            INNER JOIN productstats ps ON p.productid = ps.productid
        ", connection);
        
        using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync()) { }
    }
    
    sw.Stop();
    Console.WriteLine($"100 iterations completed in {sw.ElapsedMilliseconds}ms");
    Console.WriteLine($"Average: {sw.ElapsedMilliseconds / 100.0}ms per query");
}
```

Validation checklist:
- [ ] Query performance acceptable
- [ ] No significant degradation vs SQL Server baseline
- [ ] Window functions perform adequately
- [ ] CTEs execute efficiently

---

## Part 4: Integration Test Checklist

### Functional Tests
- [ ] All 7 repository methods execute without errors
- [ ] Data retrieved matches expected format and values
- [ ] Inserts return correct product IDs
- [ ] Updates modify records correctly
- [ ] Deletes remove records successfully
- [ ] Transactions maintain atomicity
- [ ] Triggers fire correctly for history logging

### Data Integrity Tests
- [ ] Foreign key constraints enforced
- [ ] Unique constraints enforced (SKU)
- [ ] Default values applied (CreatedDate, IsDiscontinued, etc.)
- [ ] NULL handling works correctly
- [ ] Data types compatible (DECIMAL, VARCHAR, TIMESTAMP, etc.)

### Performance Tests
- [ ] Query response times acceptable (<100ms for simple queries)
- [ ] Complex queries with CTEs complete in reasonable time
- [ ] Connection pooling reduces overhead
- [ ] No connection leaks detected
- [ ] Concurrent operations handled correctly

### Security Tests
- [ ] SSL/TLS connections work (if configured)
- [ ] Authentication succeeds with correct credentials
- [ ] Authentication fails with incorrect credentials
- [ ] Parameterized queries prevent SQL injection
- [ ] User permissions restrict unauthorized access

---

## Part 5: SQL Equivalency Manual Review

Since the SQL Equivalency tool could not formally verify equivalency, manual review is required:

### Statement 001: GetAllProductsAsync
**Original (SQL Server):**
- Uses `Products` table (implicit dbo schema)
- PascalCase identifiers
- No explicit NULL handling in ORDER BY

**Converted (PostgreSQL):**
- Uses `productmanagement_dbo.products` table
- lowercase identifiers
- Explicit `NULLS FIRST` in ORDER BY

**Manual Verification:**
1. Run both queries against respective databases with identical sample data
2. Compare result sets (row count, column values, ordering)
3. Verify window functions return same results
4. Confirm CTE behavior identical

**Expected Equivalency:** YES (schema and case differences only)

### Statement 002: GetProductByIdAsync
**Key Differences:**
- LAG window function identical in both
- LEFT JOIN vs LEFT OUTER JOIN (semantically equivalent)
- Parameter handling same (@ProductId)

**Manual Verification:**
1. Test with existing product ID
2. Test with non-existent product ID
3. Verify previous price/stock calculation
4. Confirm percentage calculation

**Expected Equivalency:** YES

### Statement 003: InsertProductAsync
**Original (SQL Server):**
```sql
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
-- Then: SELECT SCOPE_IDENTITY()
```

**Converted (PostgreSQL):**
```sql
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity, createddate)
VALUES (@Name, @Description, @Price, @StockQuantity, CURRENT_TIMESTAMP)
RETURNING productid;
```

**Key Differences:**
- SCOPE_IDENTITY() replaced with RETURNING clause
- Explicit CURRENT_TIMESTAMP for createddate

**Manual Verification:**
1. Insert test record in both databases
2. Verify returned product ID
3. Confirm CreatedDate populated automatically
4. Check trigger creates history record

**Expected Equivalency:** YES (functionally equivalent, different syntax)

### Statement 004: UpdateProductAsync
**Key Differences:**
- GETDATE() replaced with CURRENT_TIMESTAMP
- Schema and case transformations

**Manual Verification:**
1. Update existing record in both databases
2. Verify ModifiedDate updated
3. Confirm all fields updated correctly
4. Check trigger creates UPDATE history record

**Expected Equivalency:** YES

### Statement 005: DeleteProductAsync
**Manual Verification:**
1. Delete test record in both databases
2. Verify record removed
3. Confirm trigger creates DELETE history record

**Expected Equivalency:** YES

### Statement 006: GetProductsByPriceRangeAsync
**Key Differences:**
- RANK() and PERCENT_RANK() window functions (same in both)
- BETWEEN clause handling (same in both)

**Manual Verification:**
1. Test with various price ranges
2. Verify ranking calculation
3. Confirm percentile calculation
4. Check segment categorization

**Expected Equivalency:** YES

### Statement 007: GetLowStockProductsAsync
**Key Differences:**
- Multiple window functions (AVG, MIN, MAX)
- Threshold comparison logic

**Manual Verification:**
1. Test with various threshold values
2. Verify window function calculations
3. Confirm status categorization
4. Check filtering and ordering

**Expected Equivalency:** YES

---

## Part 6: Production Deployment Checklist

### Pre-Deployment
- [ ] PostgreSQL production instance provisioned
- [ ] Schema deployed via 01_PostgreSQL_Setup.sql
- [ ] Production data migrated from SQL Server
- [ ] All integration tests passed
- [ ] Performance benchmarks acceptable
- [ ] Security audit completed
- [ ] Backup strategy implemented

### Configuration
- [ ] Production connection string configured
- [ ] SSL/TLS certificates installed
- [ ] Connection pooling settings optimized
- [ ] Firewall rules configured
- [ ] VPC/Network security configured

### Application
- [ ] Application built in Release mode
- [ ] Npgsql package version verified (8.0.5)
- [ ] No SQL Server dependencies remain
- [ ] Configuration files reviewed
- [ ] Environment variables configured
- [ ] Logging configured for production

### Post-Deployment
- [ ] Application starts successfully
- [ ] Database connectivity verified
- [ ] All operations execute correctly
- [ ] Monitoring configured
- [ ] Alerting configured
- [ ] Documentation updated

### Rollback Plan
- [ ] SQL Server instance available as fallback
- [ ] Connection string can be quickly reverted
- [ ] Data synchronization strategy in place
- [ ] Rollback procedure documented and tested

---

## Part 7: Troubleshooting

### Common Issues

#### Issue 1: Connection Failed
**Error:** `could not connect to server`

**Solutions:**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list  # MacOS

# Check PostgreSQL listening on correct port
sudo netstat -plnt | grep 5432  # Linux
lsof -i :5432  # MacOS

# Check pg_hba.conf for authentication settings
sudo nano /etc/postgresql/[version]/main/pg_hba.conf

# Add/modify line for password authentication:
host    all             all             0.0.0.0/0               md5
```

#### Issue 2: Authentication Failed
**Error:** `password authentication failed for user`

**Solutions:**
```bash
# Reset PostgreSQL password
sudo -u postgres psql
ALTER USER postgres PASSWORD 'new_password';

# Or create new user
CREATE USER app_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO app_user;
GRANT ALL PRIVILEGES ON SCHEMA productmanagement_dbo TO app_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA productmanagement_dbo TO app_user;
```

#### Issue 3: Schema Not Found
**Error:** `schema "productmanagement_dbo" does not exist`

**Solutions:**
```bash
# Verify schema exists
psql -U postgres -d ProductManagement -c "SELECT schema_name FROM information_schema.schemata;"

# Re-run setup script if needed
psql -U postgres -d ProductManagement -f 01_PostgreSQL_Setup.sql
```

#### Issue 4: Case Sensitivity Issues
**Error:** `column "ProductId" does not exist`

**Solution:**
- PostgreSQL identifiers are case-insensitive unless quoted
- Ensure application code uses lowercase column names
- Review MapProductFromReader methods in repository

#### Issue 5: Function/Trigger Issues
**Error:** `function productmanagement_dbo.trg_products_history_func() does not exist`

**Solutions:**
```sql
-- Check triggers
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_schema = 'productmanagement_dbo';

-- Recreate trigger if needed (from setup script)
\i /path/to/01_PostgreSQL_Setup.sql
```

---

## Part 8: Success Criteria

### All Tests Pass
- ✅ Database deployment completes without errors
- ✅ Application builds successfully
- ✅ Database connectivity test succeeds
- ✅ All 7 SQL queries execute without errors
- ✅ Insert operations return correct IDs
- ✅ Update operations modify records
- ✅ Delete operations remove records
- ✅ Transactions maintain atomicity
- ✅ Triggers fire correctly
- ✅ Connection pooling works
- ✅ Performance acceptable

### Production Ready
- ✅ All integration tests pass
- ✅ Manual SQL equivalency review completed
- ✅ Security requirements met
- ✅ Monitoring configured
- ✅ Documentation complete
- ✅ Team trained on PostgreSQL differences

---

## Appendix: Quick Reference

### Connection String Format
```
Host=server;Port=5432;Database=dbname;Username=user;Password=pass;Pooling=true;SSL Mode=Prefer
```

### Common psql Commands
```bash
\l                  # List databases
\c dbname           # Connect to database
\dn                 # List schemas
\dt schema.*        # List tables in schema
\d+ table_name      # Describe table
\df schema.*        # List functions in schema
\q                  # Quit
```

### Schema References
- Tables: `productmanagement_dbo.tablename`
- Columns: Always lowercase
- Functions: `productmanagement_dbo.functionname()`

---

**Document Version:** 1.0  
**Last Updated:** January 24, 2024  
**Migration Status:** Code Complete - Runtime Validation Required
