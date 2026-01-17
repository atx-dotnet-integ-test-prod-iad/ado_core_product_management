# PostgreSQL Runtime Testing Guide

## Overview
This document provides instructions for setting up the PostgreSQL database environment and validating the AdoCore application migration from SQL Server to PostgreSQL.

## Prerequisites
- PostgreSQL 12 or higher installed
- Access to create databases and schemas
- .NET 9.0 SDK installed
- AdoCore application compiled successfully

## Step 1: Database Setup

### 1.1 Install PostgreSQL
If PostgreSQL is not already installed:

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**macOS (using Homebrew):**
```bash
brew install postgresql@16
brew services start postgresql@16
```

**Windows:**
Download and install from: https://www.postgresql.org/download/windows/

### 1.2 Create Database and Schema
```bash
# Connect to PostgreSQL as superuser
sudo -u postgres psql

# Or on Windows/macOS:
psql -U postgres

# In psql, create the database:
CREATE DATABASE "ProductManagement";

# Exit psql
\q

# Run the setup script
psql -U postgres -d ProductManagement -f /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

### 1.3 Verify Database Setup
```bash
psql -U postgres -d ProductManagement

# In psql:
\dt productmanagement_dbo.*

# Should show:
# - productmanagement_dbo.categories
# - productmanagement_dbo.suppliers
# - productmanagement_dbo.products
# - productmanagement_dbo.producthistory
# - productmanagement_dbo.productstats

# Check record counts:
SELECT COUNT(*) FROM productmanagement_dbo.products;
# Expected: 18 products

SELECT COUNT(*) FROM productmanagement_dbo.categories;
# Expected: 20 categories

SELECT COUNT(*) FROM productmanagement_dbo.suppliers;
# Expected: 8 suppliers

\q
```

## Step 2: Update Connection String

### 2.1 Edit appsettings.json
The connection string should already be configured for PostgreSQL. Verify it matches your environment:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100"
  }
}
```

**Update the connection string if needed:**
- Change `Host` if PostgreSQL is on a different server
- Change `Port` if using non-default port
- Change `Username` and `Password` to match your PostgreSQL credentials

## Step 3: Run the Application

### 3.1 Build and Run
```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Build the application
dotnet build

# Run the application
dotnet run
```

### 3.2 Expected Application Behavior
The application should start and display an interactive menu with options for:
1. View All Products
2. Search Product by ID
3. Add New Product
4. Update Product
5. Delete Product
6. View Product Statistics
7. View Products with Price Analysis
8. Exit

## Step 4: Runtime Validation Tests

### Test 1: Database Connection (Criterion 12)
**Objective:** Verify the application successfully connects to PostgreSQL database

**Steps:**
1. Run the application: `dotnet run`
2. Select option "1. View All Products"
3. Expected Result: Application displays list of 18 products without connection errors

**Success Criteria:** No connection errors, products displayed correctly

**Failure Indicators:**
- Npgsql.NpgsqlException: Connection refused
- Authentication failed
- Database "ProductManagement" does not exist

---

### Test 2: SELECT Operations (Part of Criterion 13)
**Objective:** Verify all SELECT queries execute successfully

**Test 2a: GetAllProducts**
1. Select option "1. View All Products"
2. Expected Result: List of all 18 products with details
3. Verify: ProductId, Name, Description, Price, StockQuantity displayed

**Test 2b: GetProductById**
1. Select option "2. Search Product by ID"
2. Enter ProductId: 1
3. Expected Result: Display details of "ProBook X1"
4. Verify: All fields match database record

**Test 2c: GetProductsWithPriceAnalysis (Complex Query)**
1. Select option "7. View Products with Price Analysis"
2. Expected Result: Products with price rank, lag, and percentile calculations
3. Verify: No SQL syntax errors, valid ranking data

**Test 2d: GetProductStatistics (Aggregation Query)**
1. Select option "6. View Product Statistics"
2. Expected Result: Summary statistics
   - Total Products: 18
   - Average Price: ~$570 (calculated average)
   - Total Stock Value: ~$100,000+ (calculated sum)
   - Low Stock Count: varies
   - Discontinued Count: 0

---

### Test 3: INSERT Operations (Part of Criterion 13)
**Objective:** Verify INSERT queries execute successfully

**Steps:**
1. Select option "3. Add New Product"
2. Enter product details:
   - Name: Test Product
   - Description: Test Description
   - Price: 99.99
   - Stock Quantity: 100
3. Expected Result: "Product added successfully with ID: [NewId]"
4. Verify: Select option "1" to confirm new product appears in list

**Verification in Database:**
```bash
psql -U postgres -d ProductManagement -c "SELECT * FROM productmanagement_dbo.products WHERE name = 'Test Product';"
```

---

### Test 4: UPDATE Operations (Part of Criterion 13)
**Objective:** Verify UPDATE queries execute successfully

**Steps:**
1. Select option "4. Update Product"
2. Enter Product ID: [ID from Test 3]
3. Enter updated details:
   - Name: Updated Test Product
   - Description: Updated Description
   - Price: 149.99
   - Stock Quantity: 75
4. Expected Result: "Product updated successfully"

**Verification:**
1. Select option "2. Search Product by ID"
2. Enter the same Product ID
3. Verify: All fields show updated values

**Database Verification:**
```bash
psql -U postgres -d ProductManagement -c "SELECT * FROM productmanagement_dbo.products WHERE productid = [NewId];"
psql -U postgres -d ProductManagement -c "SELECT * FROM productmanagement_dbo.producthistory WHERE productid = [NewId] ORDER BY actiondate DESC LIMIT 2;"
# Should show both INSERT and UPDATE history records
```

---

### Test 5: DELETE Operations (Part of Criterion 13)
**Objective:** Verify DELETE queries execute successfully

**Steps:**
1. Select option "5. Delete Product"
2. Enter Product ID: [ID from Test 3]
3. Expected Result: "Product deleted successfully"

**Verification:**
1. Select option "2. Search Product by ID"
2. Enter the same Product ID
3. Expected Result: "Product not found"

**Database Verification:**
```bash
psql -U postgres -d ProductManagement -c "SELECT * FROM productmanagement_dbo.products WHERE productid = [NewId];"
# Expected: 0 rows

psql -U postgres -d ProductManagement -c "SELECT * FROM productmanagement_dbo.producthistory WHERE productid = [NewId] AND action = 'DELETE';"
# Expected: 1 row with DELETE action
```

---

### Test 6: Transaction Atomicity (Criterion 14)
**Objective:** Verify transaction blocks maintain atomicity

**Test 6a: Successful Transaction Commit**
1. Add a new product (option 3) - this uses ExecuteInTransactionAsync
2. Verify product is added successfully
3. Database verification:
```bash
psql -U postgres -d ProductManagement -c "SELECT * FROM productmanagement_dbo.products ORDER BY productid DESC LIMIT 1;"
```

**Test 6b: Transaction Rollback on Error**
This test requires code modification to simulate an error. However, you can verify the transaction infrastructure is in place:

1. Check ProductRepository.cs contains BeginTransactionAsync()
2. Verify commit and rollback logic is implemented
3. Manual test: Try to insert a product with invalid data (e.g., negative price if validation exists)

**Code Inspection:**
```bash
grep -n "BeginTransactionAsync" /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
grep -n "CommitAsync" /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
grep -n "RollbackAsync" /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs
```

---

### Test 7: Complex SQL Features (Window Functions, CTEs)
**Objective:** Verify DMS-converted complex SQL statements execute correctly

**Test 7a: GetProductsWithPriceAnalysis (Window Functions)**
This query uses:
- CTEs (Common Table Expressions)
- LAG() window function
- RANK() window function  
- PERCENT_RANK() window function

**Steps:**
1. Select option "7. View Products with Price Analysis"
2. Expected Result: List of products with:
   - Price ranking
   - Previous product price (lag)
   - Price percentile
3. Verify: No "syntax error" or "function does not exist" errors

**Success Criteria:**
- All 18+ products displayed
- price_rank values are sequential (1, 2, 3, ...)
- previous_price shows previous product's price
- price_percentile shows values between 0 and 1

---

## Step 5: Exit Criteria Validation Checklist

### Criterion 12: Application Successfully Connects to PostgreSQL ✓/✗
- [ ] Application starts without connection errors
- [ ] Connection string format is correct
- [ ] Database authentication succeeds
- [ ] Initial query executes successfully

### Criterion 13: All Database Operations Execute Successfully ✓/✗
- [ ] SELECT operations: GetAllProducts works
- [ ] SELECT operations: GetProductById works
- [ ] SELECT operations: GetProductsWithPriceAnalysis works (complex query)
- [ ] SELECT operations: GetProductStatistics works (aggregation)
- [ ] INSERT operations: InsertProductAsync works
- [ ] UPDATE operations: UpdateProductAsync works
- [ ] DELETE operations: DeleteProductAsync works

### Criterion 14: Transaction Blocks Maintain Atomicity ✓/✗
- [ ] BeginTransactionAsync code is present
- [ ] CommitAsync code is present
- [ ] RollbackAsync code is present
- [ ] Transaction-wrapped operations complete successfully
- [ ] ProductHistory trigger fires correctly (verifies AFTER trigger atomicity)

### Criterion 15: Application Passes Tests ✓/✗
- [ ] No unit test files found in codebase (marked as N/A)
- [ ] No integration test files found (marked as N/A)
- [ ] Manual integration testing completed successfully (documented above)

---

## Step 6: Common Issues and Troubleshooting

### Issue 1: Connection Refused
**Error:** `Npgsql.NpgsqlException: Connection refused`

**Solutions:**
1. Verify PostgreSQL is running: `sudo systemctl status postgresql`
2. Check PostgreSQL is listening: `sudo netstat -plnt | grep 5432`
3. Verify connection parameters in appsettings.json

### Issue 2: Authentication Failed
**Error:** `password authentication failed for user "postgres"`

**Solutions:**
1. Verify password in appsettings.json
2. Check PostgreSQL authentication method:
```bash
sudo nano /etc/postgresql/[version]/main/pg_hba.conf
# Ensure line exists: local all postgres md5
```
3. Restart PostgreSQL: `sudo systemctl restart postgresql`

### Issue 3: Database Does Not Exist
**Error:** `database "ProductManagement" does not exist`

**Solution:**
```bash
sudo -u postgres psql -c "CREATE DATABASE \"ProductManagement\";"
```

### Issue 4: Schema Does Not Exist
**Error:** `schema "productmanagement_dbo" does not exist`

**Solution:**
Run the setup script:
```bash
psql -U postgres -d ProductManagement -f /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

### Issue 5: Table Not Found
**Error:** `relation "productmanagement_dbo.products" does not exist`

**Solutions:**
1. Verify schema exists: `\dn` in psql
2. Verify tables exist: `\dt productmanagement_dbo.*` in psql
3. Re-run setup script if tables are missing

### Issue 6: Column Does Not Exist
**Error:** `column "ProductId" does not exist`

**Cause:** PostgreSQL converted column names to lowercase, but code is using PascalCase

**Solution:** This should have been fixed during migration. Verify ProductRepository.cs uses lowercase column names in SQL queries.

---

## Step 7: Performance Validation (Optional)

### Load Testing
```bash
# Run application in loop to test connection pooling
for i in {1..100}; do
  echo "Test iteration $i"
  echo "1" | dotnet run --no-build
done
```

### Query Performance Analysis
```sql
-- Enable query timing in psql
\timing on

-- Test complex query performance
SELECT * FROM productmanagement_dbo.products p
CROSS JOIN LATERAL (
    SELECT 
        RANK() OVER (ORDER BY price DESC) as price_rank,
        LAG(price) OVER (ORDER BY price) as previous_price,
        PERCENT_RANK() OVER (ORDER BY price) as price_percentile
    FROM productmanagement_dbo.products
    WHERE productid = p.productid
) price_analysis
ORDER BY p.price DESC;
```

---

## Step 8: Validation Summary Report

After completing all tests, document results:

**Database Connection Status:**
- [ ] PASS - Application connects successfully
- [ ] FAIL - [Document error details]

**CRUD Operations Status:**
- [ ] PASS - All SELECT operations work
- [ ] PASS - INSERT operations work
- [ ] PASS - UPDATE operations work
- [ ] PASS - DELETE operations work
- [ ] FAIL - [Document which operations failed and why]

**Transaction Handling Status:**
- [ ] PASS - Transaction infrastructure verified
- [ ] PASS - Commit operations work
- [ ] PASS - Rollback infrastructure present
- [ ] FAIL - [Document issues]

**Complex Query Features:**
- [ ] PASS - Window functions (LAG, RANK, PERCENT_RANK) work
- [ ] PASS - CTEs (Common Table Expressions) work
- [ ] PASS - Aggregate functions work
- [ ] FAIL - [Document which features failed]

**Overall Migration Status:**
- [ ] SUCCESS - All runtime tests passed
- [ ] PARTIAL - Some tests passed, some failed (document details)
- [ ] FAIL - Critical failures prevent operation

---

## Appendix: SQL Statement Equivalency Verification

The following SQL statement pairs were converted by the DMS tool and should be manually verified for functional equivalence during runtime testing:

### Statement 1: GetAllProductsAsync
**Original (SQL Server):**
```sql
SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate 
FROM Products 
ORDER BY Name
```

**Converted (PostgreSQL):**
```sql
SELECT productid, name, description, price, stockquantity, createddate, modifieddate 
FROM productmanagement_dbo.products 
ORDER BY name
```

**Verification:** Compare results from both databases with same test data.

### Statement 2: GetProductByIdAsync
**Original (SQL Server):**
```sql
SELECT ProductId, Name, Description, Price, StockQuantity, CreatedDate, ModifiedDate 
FROM Products 
WHERE ProductId = @productId
```

**Converted (PostgreSQL):**
```sql
SELECT productid, name, description, price, stockquantity, createddate, modifieddate 
FROM productmanagement_dbo.products 
WHERE productid = @productId
```

**Verification:** Test with multiple ProductId values, verify exact match.

### Statement 3-7: [Continue for remaining statements...]

---

## Support and Documentation

**Migration Artifacts Location:**
- Extracted Statements: `/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/extracted_statements.sql`
- Converted Statements: `/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/converted_statements.sql`
- Migration Log: `/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/migration_log.md`
- Equivalency Report: `/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/sql_equivalency_validation_report.json`
- Final Report: `/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/final_migration_report.md`

**PostgreSQL Documentation:**
- https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/

**Contact:** For issues or questions, refer to the AWS Transform CLI documentation.
