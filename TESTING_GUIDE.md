# PostgreSQL Database Setup and Testing Guide

## Overview

This guide provides step-by-step instructions for setting up the PostgreSQL database and testing the migrated AdoCore application.

## Prerequisites

1. **PostgreSQL Server** (version 13 or higher recommended)
   - Download: https://www.postgresql.org/download/
   - Ensure PostgreSQL service is running

2. **.NET 9.0 SDK** installed
   - Check: `dotnet --version`

3. **PostgreSQL Client Tools**
   - `psql` command-line tool (included with PostgreSQL)
   - Or GUI tool like pgAdmin, DBeaver, etc.

## Step 1: PostgreSQL Database Setup

### Option A: Using psql Command Line

1. **Connect to PostgreSQL as superuser:**
   ```bash
   psql -U postgres
   ```

2. **Create the database:**
   ```sql
   CREATE DATABASE "ProductManagement";
   \c ProductManagement
   ```

3. **Run the setup script:**
   ```bash
   psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
   ```

### Option B: Using pgAdmin or GUI Tool

1. Open pgAdmin and connect to your PostgreSQL server
2. Right-click on "Databases" → "Create" → "Database"
3. Set database name to: `ProductManagement`
4. Open Query Tool and paste the contents of `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
5. Execute the script

### Verify Database Setup

Run these queries to verify:

```sql
-- Check tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Should show: categories, producthistory, products, productstats, suppliers

-- Check products count
SELECT COUNT(*) FROM products;
-- Should return: 18 (sample products)

-- Check product stats
SELECT * FROM productstats WHERE statid = 1;
-- Should show statistics for 18 products
```

## Step 2: Update Connection String (if needed)

If your PostgreSQL setup differs from the defaults, update `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD",
    "ProdConnection": "Host=YOUR_HOST;Port=5432;Database=ProductManagement;Username=YOUR_USER;Password=YOUR_PASSWORD"
  },
  "Environment": "Development"
}
```

**Common PostgreSQL Ports:**
- Default: 5432
- Check with: `SHOW port;` in psql

## Step 3: Test Database Connection

### Build the Application

```bash
cd sourceCode
dotnet build
```

### Test Connection (Manual Method)

Create a test program to verify connection:

```bash
dotnet run
```

The application should start without connection errors.

### Test Connection (Programmatic Method)

Add this to your `Program.cs` temporarily to test:

```csharp
// Add at the top of Main method
var config = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false)
    .Build();

var testTool = new AdoCore.Testing.DatabaseConnectionTest(config);
var success = await testTool.TestConnectionAsync();

if (!success)
{
    Console.WriteLine("Database connection test failed. Please fix issues before proceeding.");
    return;
}
```

Expected output:
```
=== PostgreSQL Database Connection Test ===

Environment: Development
Connection Name: DevConnection
Connection String: Host=localhost; Port=5432; Database=ProductManagement; Username=postgres; Password=********

Test 1: Testing basic connection...
✓ Connection successful! State: Open
  PostgreSQL Version: 13.x
  Server: localhost:5432
  Database: ProductManagement

Test 2: Testing query execution...
✓ Query execution successful!
  Current Database: ProductManagement
  Current User: postgres
  Version: PostgreSQL 13.x...

Test 3: Checking required tables...
  ✓ Table 'products': EXISTS
  ✓ Table 'producthistory': EXISTS
  ✓ Table 'productstats': EXISTS

Test 4: Counting products...
✓ Products table accessible: 18 products found

Test 5: Testing transaction handling...
✓ Transaction test successful (test ID: 19)
  Rolling back transaction...
✓ Rollback successful (test data removed)

=== All Tests Passed! ===

Database connection is working correctly.
The application is ready to use PostgreSQL.
```

## Step 4: Test CRUD Operations

### Test GetAllProductsAsync

```bash
dotnet run -- list
```

Expected: List of all 18 products with price categories (Above Average, Below Average, Average)

### Test GetProductByIdAsync

```bash
dotnet run -- get --id 1
```

Expected: Details for product ID 1 (ProBook X1)

### Test InsertProductAsync

```bash
dotnet run -- add --name "Test Product" --description "Test Description" --price 99.99 --stock 10
```

Expected: New product created with returned ID

Verify in database:
```sql
SELECT * FROM products WHERE name = 'Test Product';
SELECT * FROM producthistory WHERE action = 'INSERT' ORDER BY actiondate DESC LIMIT 1;
SELECT * FROM productstats WHERE statid = 1; -- Should show updated totalproducts
```

### Test UpdateProductAsync

```bash
dotnet run -- update --id 19 --name "Updated Test Product" --price 109.99 --stock 15
```

Expected: Product updated successfully

Verify in database:
```sql
SELECT * FROM products WHERE productid = 19;
SELECT * FROM producthistory WHERE productid = 19 AND action = 'UPDATE' ORDER BY actiondate DESC LIMIT 1;
```

### Test DeleteProductAsync

```bash
dotnet run -- delete --id 19
```

Expected: Product deleted successfully

Verify in database:
```sql
SELECT * FROM products WHERE productid = 19; -- Should return no rows
SELECT * FROM producthistory WHERE productid = 19 AND action = 'DELETE' ORDER BY actiondate DESC LIMIT 1;
SELECT * FROM productstats WHERE statid = 1; -- Should show decreased totalproducts
```

### Test GetProductsByPriceRangeAsync

```bash
dotnet run -- pricerange --min 100 --max 500
```

Expected: Products in the $100-$500 range with price segments (Budget, Mid-Range, Premium)

### Test GetLowStockProductsAsync

```bash
dotnet run -- lowstock --threshold 10
```

Expected: Products with stock quantity <= 10 with stock status (Critical, Low, Adequate)

## Step 5: Verify Transaction Atomicity

### Test Transaction Rollback

Create a test that intentionally fails during a multi-statement operation:

1. Insert a product (should succeed)
2. Insert history record with invalid data (should fail)
3. Verify the product insert was rolled back

Database state should remain unchanged if any part of the transaction fails.

### Manual SQL Test

```sql
BEGIN;

-- Insert a test product
INSERT INTO products (name, price, stockquantity)
VALUES ('Transaction Test', 99.99, 10)
RETURNING productid;

-- Intentionally cause an error
INSERT INTO products (name, price, stockquantity)
VALUES (NULL, 99.99, 10); -- This should fail (name is NOT NULL)

-- This won't execute due to error
COMMIT;

-- Verify rollback
SELECT * FROM products WHERE name = 'Transaction Test';
-- Should return no rows
```

## Step 6: Performance Testing (Optional)

### Test Window Functions Performance

```sql
-- Test GetAllProductsAsync query
EXPLAIN ANALYZE
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.price,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY p.name;
```

Expected: Query should execute in < 100ms with 18 products

## Step 7: Verify All Exit Criteria

### Exit Criteria Checklist

- [x] **Criterion 1**: SQL Server packages replaced with Npgsql ✓
- [x] **Criterion 2**: All ADO.NET classes replaced ✓
- [x] **Criterion 3**: All SQL statements processed through DMS MCP tool ✓
- [x] **Criterion 4**: Comprehensive catalog exists ✓
- [x] **Criterion 5**: All SQL pairs validated with SQL Equivalency tool ✓
- [x] **Criterion 6**: Comprehensive equivalency validation report ✓
- [x] **Criterion 7**: No agent judgment for equivalency ✓
- [x] **Criterion 8**: Failed DMS conversions documented ✓
- [x] **Criterion 9**: Connection strings updated ✓
- [x] **Criterion 10**: Transaction handling updated ✓
- [x] **Criterion 11**: Application compiles ✓
- [ ] **Criterion 12**: Application connects to PostgreSQL (TEST THIS)
- [ ] **Criterion 13**: Database operations execute successfully (TEST THIS)
- [ ] **Criterion 14**: Transaction atomicity maintained (TEST THIS)
- [ ] **Criterion 15**: Application passes all tests (NO TEST SUITE EXISTS)
- [x] **Criterion 16**: Final report with equivalency status ✓

## Troubleshooting

### Connection Refused Error

**Error:** `could not connect to server: Connection refused`

**Solutions:**
1. Verify PostgreSQL is running:
   ```bash
   # Linux/Mac
   sudo systemctl status postgresql
   
   # Windows
   # Check Services app for "postgresql" service
   ```

2. Check port:
   ```bash
   sudo netstat -plnt | grep 5432
   ```

3. Verify pg_hba.conf allows connections:
   ```bash
   # Location varies by OS
   # Linux: /etc/postgresql/*/main/pg_hba.conf
   # Mac: /usr/local/var/postgres/pg_hba.conf
   # Windows: C:\Program Files\PostgreSQL\*\data\pg_hba.conf
   
   # Add this line if needed:
   host    all             all             127.0.0.1/32            md5
   ```

4. Restart PostgreSQL after changes

### Authentication Failed

**Error:** `password authentication failed for user "postgres"`

**Solutions:**
1. Reset postgres password:
   ```bash
   sudo -u postgres psql
   ALTER USER postgres PASSWORD 'newpassword';
   ```

2. Update appsettings.json with correct password

### Database Does Not Exist

**Error:** `database "ProductManagement" does not exist`

**Solution:**
```bash
psql -U postgres
CREATE DATABASE "ProductManagement";
```

### Table Does Not Exist

**Error:** `relation "products" does not exist`

**Solutions:**
1. Run the PostgreSQL setup script (Step 1)
2. Verify you're connected to the correct database:
   ```sql
   SELECT current_database();
   ```

### Lowercase vs Uppercase Issues

**Error:** `column "ProductId" does not exist`

**Cause:** PostgreSQL is case-sensitive for quoted identifiers

**Solution:** The code has been updated to use lowercase column names. Ensure your database schema uses lowercase:
```sql
-- Correct
SELECT productid FROM products;

-- Incorrect
SELECT ProductId FROM Products;
```

### Npgsql Vulnerability Warning

**Warning:** `NU1903: Package 'Npgsql' 8.0.1 has a known high severity vulnerability`

**Note:** This is a known issue with Npgsql 8.0.1. Monitor for updates:
```bash
dotnet list package --vulnerable
dotnet add package Npgsql --version [latest-secure-version]
```

## Validation Results Summary

After completing all tests, document results:

1. **Connection Test**: ✓ Pass / ✗ Fail
2. **GetAllProductsAsync**: ✓ Pass / ✗ Fail
3. **GetProductByIdAsync**: ✓ Pass / ✗ Fail
4. **InsertProductAsync**: ✓ Pass / ✗ Fail
5. **UpdateProductAsync**: ✓ Pass / ✗ Fail
6. **DeleteProductAsync**: ✓ Pass / ✗ Fail
7. **GetProductsByPriceRangeAsync**: ✓ Pass / ✗ Fail
8. **GetLowStockProductsAsync**: ✓ Pass / ✗ Fail
9. **Transaction Atomicity**: ✓ Pass / ✗ Fail

## Next Steps

1. **If all tests pass**: Document results and mark exit criteria 12-14 as PASS
2. **If tests fail**: Review error messages and consult troubleshooting section
3. **For Criterion 15** (test suite): Consider creating unit and integration tests using xUnit or NUnit
4. **Production deployment**: Update connection strings with production credentials and test again

## Contact and Support

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **.NET Documentation**: https://docs.microsoft.com/en-us/dotnet/

---

**Generated**: February 24, 2026  
**Transformation ID**: 20260224_222612_2a5e1572  
**Migration Status**: Code migration complete - Runtime testing required
