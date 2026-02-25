# Runtime Validation Guide
## PostgreSQL Migration Testing for AdoCore Application

**Purpose:** This guide provides step-by-step instructions for validating the PostgreSQL migration through runtime testing to satisfy exit criteria 12-15.

**Prerequisites:**
- PostgreSQL 12 or higher installed and running
- .NET 9.0 SDK installed
- Access to a PostgreSQL database server

---

## Table of Contents
1. [Environment Setup](#environment-setup)
2. [Database Schema Setup](#database-schema-setup)
3. [Connection Testing](#connection-testing)
4. [Functional Testing](#functional-testing)
5. [Transaction Testing](#transaction-testing)
6. [Test Execution Guide](#test-execution-guide)
7. [Expected Results](#expected-results)
8. [Troubleshooting](#troubleshooting)

---

## 1. Environment Setup

### PostgreSQL Installation Verification

```bash
# Check PostgreSQL version
psql --version

# Check PostgreSQL service status
# On Linux/macOS:
sudo systemctl status postgresql
# or
brew services list | grep postgresql

# On Windows:
sc query postgresql-x64-[version]
```

### Connection String Configuration

The application uses connection strings from `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres",
    "ProdConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres"
  }
}
```

**Security Note:** Change the default password before running in production!

---

## 2. Database Schema Setup

### Step 1: Create the Database

Connect to PostgreSQL as the postgres user:

```bash
psql -U postgres
```

Within psql:

```sql
-- Create the database
CREATE DATABASE productmanagement
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8';

-- Exit psql
\q
```

### Step 2: Execute the Schema Setup Script

```bash
# Navigate to the Database directory
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/Database

# Run the setup script
psql -U postgres -d productmanagement -f setup_postgresql_schema.sql
```

### Step 3: Verify Schema Creation

```bash
# Connect to the database
psql -U postgres -d productmanagement

# List all tables
\dt

# Expected output:
#              List of relations
#  Schema |      Name       | Type  |  Owner   
# --------+-----------------+-------+----------
#  public | products        | table | postgres
#  public | producthistory  | table | postgres
#  public | productstats    | table | postgres
```

Verify sample data:

```sql
SELECT COUNT(*) FROM products;
-- Expected: 10 rows

SELECT COUNT(*) FROM producthistory;
-- Expected: 10 rows

SELECT * FROM productstats;
-- Expected: 1 row with totalproducts=10, averageprice computed
```

---

## 3. Connection Testing
### **Exit Criterion 12: Application successfully connects to PostgreSQL database**

### Test 1: Basic Connection Test

Create a simple test file `TestConnection.cs`:

```csharp
using Npgsql;

class TestConnection
{
    static void Main()
    {
        var connectionString = "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres";
        
        try
        {
            using var conn = new NpgsqlConnection(connectionString);
            conn.Open();
            
            Console.WriteLine("✅ Connection successful!");
            Console.WriteLine($"Database: {conn.Database}");
            Console.WriteLine($"Server version: {conn.ServerVersion}");
            
            // Execute a simple query
            using var cmd = new NpgsqlCommand("SELECT COUNT(*) FROM products", conn);
            var count = cmd.ExecuteScalar();
            Console.WriteLine($"Product count: {count}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Connection failed: {ex.Message}");
        }
    }
}
```

Compile and run:

```bash
dotnet run TestConnection.cs
```

**Expected Result:** 
- Connection successful message
- Product count: 10

**Exit Criterion 12 Status:** ✅ PASS if connection succeeds

---

## 4. Functional Testing
### **Exit Criterion 13: All database operations execute successfully against PostgreSQL database**

### Test 2: Run the Application

```bash
# Navigate to project root
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Build the application
dotnet build

# Run the application
dotnet run
```

### Test Each Database Operation:

#### Test 2.1: GetAllProductsAsync (SELECT with CTE and Window Functions)

**Menu Option:** 1 - List all products

**SQL Query Executed:**
```sql
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
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name
```

**Expected Results:**
- All 10 products displayed
- Price category correctly calculated (Above Average, Below Average, Average)
- Products sorted by price category, then name
- Window functions (AVG, COUNT OVER) work correctly

**Validation:**
- [ ] No errors thrown
- [ ] All products displayed with correct data
- [ ] Price categories correctly assigned
- [ ] Percentage calculations accurate

---

#### Test 2.2: GetProductByIdAsync (SELECT with LAG Window Function)

**Menu Option:** 2 - View product by ID

**SQL Query Executed:**
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
    END as pricechangepercentage
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

**Test Cases:**
1. Enter product ID: 1
2. Enter product ID: 5
3. Enter invalid product ID: 999 (should handle gracefully)

**Expected Results:**
- Product details displayed correctly
- LAG window function works (previousprice and previousstock)
- Price change percentage calculated (may be NULL for new products)

**Validation:**
- [ ] Product found and displayed
- [ ] No errors with LAG window function
- [ ] Price change percentage calculated correctly
- [ ] Invalid ID handled gracefully (returns no data or appropriate message)

---

#### Test 2.3: InsertProductAsync (INSERT with RETURNING, Transaction, Logging)

**Menu Option:** 3 - Add new product

**Test Input:**
- Name: "Test Product"
- Description: "This is a test product for validation"
- Price: 99.99
- Stock Quantity: 25

**Expected Results:**
- New product inserted successfully
- ProductId returned from RETURNING clause
- ProductHistory record created (action='INSERT')
- ProductStats updated (totalproducts incremented, averageprice recalculated)
- All operations committed as a transaction

**Verification Queries:**
```sql
-- Check the new product was inserted
SELECT * FROM products WHERE name = 'Test Product';

-- Check history was logged
SELECT * FROM producthistory WHERE action = 'INSERT' 
ORDER BY actiondate DESC LIMIT 1;

-- Check stats were updated
SELECT * FROM productstats WHERE statid = 1;
```

**Validation:**
- [ ] Product inserted successfully
- [ ] New ProductId returned
- [ ] History record created
- [ ] Statistics updated correctly
- [ ] No errors during transaction

---

#### Test 2.4: UpdateProductAsync (UPDATE with Transaction and Logging)

**Menu Option:** 4 - Update product

**Test Input:**
- Product ID: [ID from Test 2.3]
- Name: "Updated Test Product"
- Description: "Updated description"
- Price: 109.99
- Stock Quantity: 20

**Expected Results:**
- Product updated successfully
- Old values captured before update
- ProductHistory record created (action='UPDATE', old and new values)
- ProductStats updated (averageprice recalculated)
- All operations committed as a transaction

**Verification Queries:**
```sql
-- Check the product was updated
SELECT * FROM products WHERE name = 'Updated Test Product';

-- Check history captured old and new values
SELECT * FROM producthistory WHERE action = 'UPDATE' 
ORDER BY actiondate DESC LIMIT 1;

-- Verify old and new prices are correct
SELECT 
    oldprice, 
    newprice, 
    oldstock, 
    newstock 
FROM producthistory 
WHERE action = 'UPDATE' 
ORDER BY actiondate DESC 
LIMIT 1;
```

**Validation:**
- [ ] Product updated successfully
- [ ] Old values captured correctly
- [ ] New values applied correctly
- [ ] History record created with old/new values
- [ ] Statistics updated
- [ ] No errors during transaction

---

#### Test 2.5: DeleteProductAsync (DELETE with Transaction and Logging)

**Menu Option:** 5 - Delete product

**Test Input:**
- Product ID: [ID from Test 2.3]

**Expected Results:**
- Old values captured before delete
- ProductHistory record created (action='DELETE', old values, NULL new values)
- Product deleted from products table
- ProductStats updated (totalproducts decremented, averageprice recalculated)
- All operations committed as a transaction

**Verification Queries:**
```sql
-- Confirm product is deleted
SELECT * FROM products WHERE name = 'Updated Test Product';
-- Expected: 0 rows

-- Check history logged the deletion
SELECT * FROM producthistory WHERE action = 'DELETE' 
ORDER BY actiondate DESC LIMIT 1;

-- Verify stats were updated
SELECT * FROM productstats WHERE statid = 1;
```

**Validation:**
- [ ] Product deleted successfully
- [ ] History record created with old values
- [ ] Statistics updated correctly (decremented)
- [ ] No errors during transaction

---

#### Test 2.6: GetProductsByPriceRangeAsync (SELECT with RANK and PERCENT_RANK)

**Menu Option:** 6 - Search products by price range

**Test Input:**
- Min Price: 50.00
- Max Price: 150.00

**SQL Query Executed:**
```sql
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank
```

**Expected Results:**
- Products within price range displayed
- RANK() assigned correctly (1, 2, 3... with ties)
- PERCENT_RANK() calculated correctly (0.0 to 1.0)
- Price segments assigned correctly

**Validation:**
- [ ] Only products in price range returned
- [ ] RANK window function works correctly
- [ ] PERCENT_RANK window function works correctly
- [ ] Price segments assigned accurately
- [ ] No errors

---

#### Test 2.7: GetLowStockProductsAsync (SELECT with AVG/MIN/MAX Window Functions)

**Menu Option:** 7 - List low stock products

**Test Input:**
- Threshold: 50

**SQL Query Executed:**
```sql
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity
```

**Expected Results:**
- Only products with stock <= threshold displayed
- AVG/MIN/MAX window functions calculated correctly
- Stock status assigned correctly
- Stock percentage calculated accurately

**Validation:**
- [ ] Correct products filtered (stock <= threshold)
- [ ] AVG/MIN/MAX window functions work
- [ ] Stock status assigned correctly
- [ ] Percentage calculation accurate
- [ ] No errors

**Exit Criterion 13 Status:** ✅ PASS if all 7 database operations execute successfully

---

## 5. Transaction Testing
### **Exit Criterion 14: Transaction blocks maintain atomicity with PostgreSQL database**

### Test 3: Transaction Rollback Test

Create a test to verify transaction rollback on error:

#### Test 3.1: Insert with Rollback Simulation

Modify the database temporarily to test rollback:

```sql
-- Create a trigger that causes an intentional error
CREATE OR REPLACE FUNCTION prevent_expensive_products()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.price > 10000 THEN
        RAISE EXCEPTION 'Price too high (test rollback)';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER test_rollback_trigger
    BEFORE INSERT ON products
    FOR EACH ROW
    EXECUTE FUNCTION prevent_expensive_products();
```

**Test Steps:**
1. Run the application
2. Select option 3 (Add new product)
3. Enter product with price > 10000

**Expected Results:**
- Transaction should fail with error
- NO product inserted in products table
- NO history record created
- NO statistics updated
- Database remains in consistent state

**Verification:**
```sql
-- Check no partial data was committed
SELECT COUNT(*) FROM products WHERE price > 10000;
-- Expected: 0

SELECT COUNT(*) FROM producthistory WHERE newprice > 10000;
-- Expected: 0
```

**Cleanup:**
```sql
-- Remove test trigger
DROP TRIGGER IF EXISTS test_rollback_trigger ON products;
DROP FUNCTION IF EXISTS prevent_expensive_products();
```

**Validation:**
- [ ] Transaction rolled back on error
- [ ] No partial data committed
- [ ] Database remains consistent

#### Test 3.2: Update with Rollback

Similar test for update operations:

```sql
-- Create trigger for updates
CREATE TRIGGER test_update_rollback_trigger
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION prevent_expensive_products();
```

**Test Steps:**
1. Update a product with price > 10000
2. Verify transaction rolls back
3. Verify no partial updates occurred

**Cleanup:**
```sql
DROP TRIGGER IF EXISTS test_update_rollback_trigger ON products;
```

#### Test 3.3: Delete with Rollback

Test delete transaction rollback:

```sql
-- Create trigger for deletes
CREATE OR REPLACE FUNCTION prevent_delete_low_id()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.productid <= 5 THEN
        RAISE EXCEPTION 'Cannot delete products with ID <= 5 (test)';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER test_delete_rollback_trigger
    BEFORE DELETE ON products
    FOR EACH ROW
    EXECUTE FUNCTION prevent_delete_low_id();
```

**Test Steps:**
1. Try to delete product with ID <= 5
2. Verify transaction rolls back
3. Verify product still exists and no history was logged

**Cleanup:**
```sql
DROP TRIGGER IF EXISTS test_delete_rollback_trigger ON products;
DROP FUNCTION IF EXISTS prevent_delete_low_id();
```

**Exit Criterion 14 Status:** ✅ PASS if all transaction rollback tests succeed

---

## 6. Test Execution Guide
### **Exit Criterion 15: Application passes all existing unit tests and integration tests**

### Check for Test Projects

```bash
# Search for test projects
find /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact -name "*Test*" -o -name "*test*"
```

**Current Status:** No test projects found in the codebase.

**Recommendation:** Create integration tests for the migrated application.

### Integration Test Template (if creating tests)

Create `IntegrationTests.cs`:

```csharp
using Xunit;
using AdoCore.DataAccess;
using AdoCore.Models;

public class ProductRepositoryIntegrationTests
{
    private readonly string _connectionString = "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres";
    
    [Fact]
    public async Task GetAllProductsAsync_ReturnsProducts()
    {
        // Arrange
        var repo = new ProductRepository(_connectionString);
        
        // Act
        var products = await repo.GetAllProductsAsync();
        
        // Assert
        Assert.NotNull(products);
        Assert.NotEmpty(products);
    }
    
    [Fact]
    public async Task InsertProductAsync_CreatesProduct()
    {
        // Arrange
        var repo = new ProductRepository(_connectionString);
        var product = new Product 
        { 
            Name = "Integration Test Product",
            Description = "Test",
            Price = 99.99m,
            StockQuantity = 10
        };
        
        // Act
        var newId = await repo.InsertProductAsync(product);
        
        // Assert
        Assert.True(newId > 0);
        
        // Cleanup
        await repo.DeleteProductAsync(newId);
    }
    
    // Add more tests for other operations...
}
```

Run tests:

```bash
dotnet test
```

**Exit Criterion 15 Status:** 
- If tests exist and pass: ✅ PASS
- If no tests exist: ⚠️ NOT APPLICABLE (document this in validation summary)

---

## 7. Expected Results

### Complete Validation Checklist

#### Exit Criterion 12: PostgreSQL Connection
- [ ] Application successfully connects to PostgreSQL
- [ ] Connection string format correct
- [ ] Authentication works
- [ ] Database queries execute

#### Exit Criterion 13: Database Operations
- [ ] GetAllProductsAsync works (CTE, window functions)
- [ ] GetProductByIdAsync works (LAG window function)
- [ ] InsertProductAsync works (RETURNING, transaction, logging)
- [ ] UpdateProductAsync works (transaction, logging)
- [ ] DeleteProductAsync works (transaction, logging)
- [ ] GetProductsByPriceRangeAsync works (RANK, PERCENT_RANK)
- [ ] GetLowStockProductsAsync works (AVG/MIN/MAX window functions)

#### Exit Criterion 14: Transaction Atomicity
- [ ] Insert transaction rolls back on error
- [ ] Update transaction rolls back on error
- [ ] Delete transaction rolls back on error
- [ ] No partial commits occur
- [ ] Database remains consistent

#### Exit Criterion 15: Tests
- [ ] Unit tests executed (if exist)
- [ ] Integration tests executed (if exist)
- [ ] All tests pass
- [ ] Document if no tests exist

---

## 8. Troubleshooting

### Common Issues

#### Issue: Connection Refused

**Error:** `Npgsql.NpgsqlException: Connection refused`

**Solutions:**
1. Verify PostgreSQL is running:
   ```bash
   sudo systemctl status postgresql
   ```
2. Check port 5432 is open:
   ```bash
   netstat -an | grep 5432
   ```
3. Verify pg_hba.conf allows local connections:
   ```bash
   sudo cat /etc/postgresql/[version]/main/pg_hba.conf
   ```
   Ensure line exists:
   ```
   host    all             all             127.0.0.1/32            md5
   ```

#### Issue: Authentication Failed

**Error:** `password authentication failed for user "postgres"`

**Solutions:**
1. Reset postgres password:
   ```bash
   sudo -u postgres psql
   ALTER USER postgres PASSWORD 'postgres';
   ```
2. Update appsettings.json with correct password

#### Issue: Database Does Not Exist

**Error:** `database "productmanagement" does not exist`

**Solution:**
```bash
psql -U postgres
CREATE DATABASE productmanagement;
\q
```

#### Issue: Table Does Not Exist

**Error:** `relation "products" does not exist`

**Solution:**
Run the schema setup script:
```bash
psql -U postgres -d productmanagement -f Database/setup_postgresql_schema.sql
```

#### Issue: Column Name Case Sensitivity

**Error:** `column "ProductId" does not exist`

**Explanation:** PostgreSQL converts unquoted identifiers to lowercase. The migration correctly uses lowercase names.

**Solution:** Ensure all SQL queries use lowercase column names (productid, not ProductId).

---

## Validation Summary Template

After completing all tests, document results:

```markdown
## Runtime Validation Results

**Date:** [Date]
**Tester:** [Name]
**PostgreSQL Version:** [Version]
**Application Version:** [Commit/Version]

### Exit Criterion 12: Database Connection
**Status:** PASS / FAIL
**Evidence:** [Connection test output]

### Exit Criterion 13: Database Operations
**Status:** PASS / FAIL
**Evidence:**
- GetAllProductsAsync: PASS/FAIL
- GetProductByIdAsync: PASS/FAIL
- InsertProductAsync: PASS/FAIL
- UpdateProductAsync: PASS/FAIL
- DeleteProductAsync: PASS/FAIL
- GetProductsByPriceRangeAsync: PASS/FAIL
- GetLowStockProductsAsync: PASS/FAIL

### Exit Criterion 14: Transaction Atomicity
**Status:** PASS / FAIL
**Evidence:** [Transaction test results]

### Exit Criterion 15: Tests
**Status:** PASS / FAIL / NOT APPLICABLE
**Evidence:** [Test execution results or note about no tests]
```

---

## Appendix: Quick Validation Script

Create `validate_migration.sh` for automated validation:

```bash
#!/bin/bash

echo "=== AdoCore PostgreSQL Migration Validation ==="
echo ""

# Test 1: PostgreSQL Connection
echo "Test 1: Checking PostgreSQL connection..."
psql -U postgres -d productmanagement -c "SELECT 1;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL connection successful"
else
    echo "❌ PostgreSQL connection failed"
    exit 1
fi

# Test 2: Schema validation
echo "Test 2: Validating schema..."
TABLE_COUNT=$(psql -U postgres -d productmanagement -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('products', 'producthistory', 'productstats');")
if [ "$TABLE_COUNT" -eq 3 ]; then
    echo "✅ All required tables exist"
else
    echo "❌ Schema validation failed (expected 3 tables, found $TABLE_COUNT)"
    exit 1
fi

# Test 3: Data validation
echo "Test 3: Validating data..."
PRODUCT_COUNT=$(psql -U postgres -d productmanagement -t -c "SELECT COUNT(*) FROM products;")
if [ "$PRODUCT_COUNT" -gt 0 ]; then
    echo "✅ Sample data exists ($PRODUCT_COUNT products)"
else
    echo "⚠️  Warning: No sample data found"
fi

# Test 4: Window functions
echo "Test 4: Testing window functions..."
psql -U postgres -d productmanagement -c "SELECT AVG(price) OVER() FROM products LIMIT 1;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Window functions working"
else
    echo "❌ Window functions failed"
    exit 1
fi

echo ""
echo "=== Database validation complete ==="
echo "Proceed with application runtime testing using the CLI."
```

Run the script:
```bash
chmod +x validate_migration.sh
./validate_migration.sh
```

---

**End of Runtime Validation Guide**
