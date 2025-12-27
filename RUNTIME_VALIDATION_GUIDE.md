# Runtime Validation Guide for PostgreSQL Migration

## Overview
This guide provides step-by-step instructions to complete the remaining validation criteria (12-15) which require an actual PostgreSQL database instance for runtime testing.

## Code Transformation Status: ✅ COMPLETE
All code transformation work has been completed successfully:
- ✅ SQL Server packages replaced with Npgsql
- ✅ ADO.NET classes migrated to Npgsql equivalents  
- ✅ All 7 SQL statements converted through DMS MCP tool
- ✅ SQL equivalency validation performed on all statement pairs
- ✅ Connection strings updated to PostgreSQL format
- ✅ Application compiles without errors

## Remaining Validation Requirements

The following criteria require runtime infrastructure and cannot be validated without an active PostgreSQL database:

### Criterion 12: Application successfully connects to PostgreSQL database
### Criterion 13: All database operations execute successfully against PostgreSQL
### Criterion 14: Transaction blocks maintain atomicity when executed against PostgreSQL
### Criterion 15: Application passes all existing unit tests and integration tests

---

## Prerequisites

1. **PostgreSQL Server**: Version 12.0 or higher
2. **Database Access**: Admin credentials to create schemas and tables
3. **.NET SDK**: Version 6.0 or higher (already installed if application compiled)
4. **psql or pgAdmin**: For executing database setup scripts

---

## Step 1: PostgreSQL Database Setup

### 1.1 Install PostgreSQL (if not already installed)

**On Windows:**
```bash
# Download from: https://www.postgresql.org/download/windows/
# Or use chocolatey:
choco install postgresql
```

**On Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
```

**On macOS:**
```bash
brew install postgresql
brew services start postgresql
```

### 1.2 Create Database and Schema

**Option A: Using psql command line:**
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database (if using a dedicated database)
CREATE DATABASE productmanagement;

# Connect to the database
\c postgres

# Execute the setup script
\i Database/Scripts/01_PostgreSQL_InitialSetup.sql

# Verify tables were created
\dt productmanagement_dbo.*

# Exit psql
\q
```

**Option B: Using pgAdmin:**
1. Open pgAdmin
2. Connect to your PostgreSQL server
3. Right-click on the `postgres` database (or create new database)
4. Select "Query Tool"
5. Open and execute: `Database/Scripts/01_PostgreSQL_InitialSetup.sql`
6. Verify tables in Schema `productmanagement_dbo`

### 1.3 Verify Database Setup

Run this query to verify all tables exist with data:
```sql
SELECT 
    'categories' as table_name, COUNT(*) as row_count 
FROM productmanagement_dbo.categories
UNION ALL
SELECT 'suppliers', COUNT(*) FROM productmanagement_dbo.suppliers
UNION ALL
SELECT 'products', COUNT(*) FROM productmanagement_dbo.products
UNION ALL
SELECT 'producthistory', COUNT(*) FROM productmanagement_dbo.producthistory
UNION ALL
SELECT 'productstats', COUNT(*) FROM productmanagement_dbo.productstats;
```

Expected results:
- categories: 20 rows
- suppliers: 8 rows
- products: 19 rows
- producthistory: 19 rows (from trigger on INSERT)
- productstats: 1 row

---

## Step 2: Update Connection String (if needed)

The application is configured with default connection strings in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=postgres;Username=postgres;Password=postgres",
    "ProdConnection": "Host=localhost;Database=postgres;Username=postgres;Password=postgres"
  }
}
```

**Update if your PostgreSQL setup differs:**
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=YOUR_HOST;Port=5432;Database=postgres;Username=YOUR_USER;Password=YOUR_PASSWORD;",
    "ProdConnection": "Host=YOUR_HOST;Port=5432;Database=postgres;Username=YOUR_USER;Password=YOUR_PASSWORD;"
  }
}
```

---

## Step 3: Test Database Connectivity (Criterion 12)

### 3.1 Build the Application
```bash
cd sourceCode
dotnet build
```

### 3.2 Test Connection
Run the application to verify connectivity:
```bash
dotnet run
```

The application should start and display an interactive menu. If it starts successfully without connection errors, **Criterion 12 is PASSED**.

**Expected Output:**
```
================================
   Product Management System
================================
1. List all products
2. Get product by ID
3. Add new product
4. Update product
5. Delete product
6. Get products by price range
7. Get low stock products
8. Exit
================================
Enter your choice:
```

**If connection fails**, check:
- PostgreSQL service is running: `pg_isready` or `sudo systemctl status postgresql`
- Connection string credentials are correct
- PostgreSQL is listening on the configured port (default: 5432)
- Firewall allows connections to PostgreSQL

---

## Step 4: Functional Testing (Criterion 13)

Test each repository method to verify all database operations work correctly.

### 4.1 Test GetAllProductsAsync (STMT_001)
```bash
# In the interactive menu, select option 1
dotnet run
# Enter: 1
```

**Expected Result:**
- List of all 19 products displayed
- Each product shows: ID, Name, Price, Stock, Price Category
- No errors or exceptions

**Validation:** ✅ CTE with window functions (AVG, COUNT) works correctly

### 4.2 Test GetProductByIdAsync (STMT_002)
```bash
# In the interactive menu, select option 2
dotnet run
# Enter: 2
# Enter Product ID: 1
```

**Expected Result:**
- Product details for ID 1 displayed
- Shows current and previous price/stock values
- Price change percentage calculated (may be NULL for first entry)

**Validation:** ✅ LAG window function and parameter binding work correctly

### 4.3 Test InsertProductAsync (STMT_003)
```bash
# In the interactive menu, select option 3
dotnet run
# Enter: 3
# Enter Name: Test Product
# Enter Description: Test Description
# Enter Price: 99.99
# Enter Stock: 10
```

**Expected Result:**
- Product inserted successfully
- New Product ID returned (should be 20)
- ProductHistory record created automatically (via trigger)
- ProductStats updated (totalproducts incremented)

**Validation:** 
- ✅ INSERT with RETURNING clause retrieves new ID
- ✅ Multi-statement transaction succeeds
- ✅ All statements in transaction execute atomically

**Verify in database:**
```sql
-- Check new product exists
SELECT * FROM productmanagement_dbo.products WHERE productid = 20;

-- Check history was recorded
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = 20 AND action = 'INSERT';

-- Check stats were updated
SELECT totalproducts FROM productmanagement_dbo.productstats WHERE statid = 1;
-- Should show 20 (was 19 + 1 new)
```

### 4.4 Test UpdateProductAsync (STMT_004)
```bash
# In the interactive menu, select option 4
dotnet run
# Enter: 4
# Enter Product ID: 20
# Enter Name: Updated Test Product
# Enter Description: Updated Description
# Enter Price: 149.99
# Enter Stock: 15
```

**Expected Result:**
- Product updated successfully
- ModifiedDate timestamp updated
- ProductHistory record created
- ProductStats averageprice recalculated

**Validation:** 
- ✅ UPDATE operations work
- ✅ Transaction with multiple statements succeeds
- ✅ CURRENT_TIMESTAMP function works

**Verify in database:**
```sql
-- Check product was updated
SELECT name, price, stockquantity, modifieddate 
FROM productmanagement_dbo.products 
WHERE productid = 20;

-- Check history recorded the change
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = 20 AND action = 'UPDATE';
```

### 4.5 Test DeleteProductAsync (STMT_005)
```bash
# In the interactive menu, select option 5
dotnet run
# Enter: 5
# Enter Product ID: 20
# Confirm deletion: Y
```

**Expected Result:**
- Product deleted successfully
- ProductHistory record created before deletion
- ProductStats updated (totalproducts decremented, averageprice recalculated)

**Validation:** 
- ✅ DELETE operations work
- ✅ Transaction with CASE expression in statistics update succeeds
- ✅ Transaction maintains referential integrity

**Verify in database:**
```sql
-- Check product was deleted
SELECT * FROM productmanagement_dbo.products WHERE productid = 20;
-- Should return 0 rows

-- Check history recorded the deletion
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = 20 AND action = 'DELETE';

-- Check stats were updated
SELECT totalproducts FROM productmanagement_dbo.productstats WHERE statid = 1;
-- Should show 19 (was 20 - 1 deleted)
```

### 4.6 Test GetProductsByPriceRangeAsync (STMT_006)
```bash
# In the interactive menu, select option 6
dotnet run
# Enter: 6
# Enter Min Price: 100
# Enter Max Price: 500
```

**Expected Result:**
- Products within price range displayed
- Each product shows: RANK, Price Percentile, Price Segment
- Products ordered by price rank

**Validation:** 
- ✅ RANK() and PERCENT_RANK() window functions work
- ✅ BETWEEN clause with parameters works
- ✅ CASE expression in SELECT works

### 4.7 Test GetLowStockProductsAsync (STMT_007)
```bash
# In the interactive menu, select option 7
dotnet run
# Enter: 7
# Enter Threshold: 15
```

**Expected Result:**
- Products with stock <= 15 displayed
- Each shows: Stock Status (Critical/Low/Adequate), Avg Stock comparison
- Ordered by stock quantity

**Validation:** 
- ✅ Multiple window functions (AVG, MIN, MAX) work
- ✅ Calculated columns work correctly

---

## Step 5: Transaction Testing (Criterion 14)

### 5.1 Test Transaction Rollback on Error

Create a test scenario that forces a transaction to rollback:

**Test: Try to insert product with duplicate SKU**
```bash
# First, insert a product with SKU 'TEST-001'
dotnet run
# Enter: 3 (Add new product)
# Name: Transaction Test 1
# Description: Test
# Price: 50.00
# Stock: 10
# (Manually set SKU to 'TEST-001' in code or database)
```

Then try to insert another with the same SKU:
```bash
# Try to insert another product with same SKU
dotnet run
# Enter: 3 (Add new product)
# Name: Transaction Test 2
# Description: Test
# Price: 60.00
# Stock: 5
# (This should fail due to unique constraint on SKU)
```

**Expected Result:**
- Second insert should fail with unique constraint violation
- Transaction should rollback completely
- ProductHistory should NOT contain entry for failed insert
- ProductStats should NOT be updated

**Validation:** ✅ Transaction atomicity maintained - all or nothing

### 5.2 Test Transaction Commit on Success

Use the successful Insert/Update/Delete tests from Step 4 to verify:

**For each successful operation, verify:**
1. All related tables updated correctly
2. No partial updates occurred
3. ProductStats reflects the change
4. ProductHistory recorded the change

**Validation:** ✅ Transactions commit successfully when all statements succeed

---

## Step 6: Unit and Integration Tests (Criterion 15)

### 6.1 Check for Existing Tests

```bash
# Look for test projects
find . -name "*Test*.csproj" -o -name "*Tests.csproj"

# Or check solution
dotnet sln list
```

### 6.2 Run Tests (if they exist)

```bash
# Run all tests
dotnet test

# Run with verbose output
dotnet test --verbosity detailed

# Generate coverage report
dotnet test --collect:"XPlat Code Coverage"
```

### 6.3 If No Tests Exist

If the project has no unit/integration tests:
- Document this finding
- Consider Criterion 15 as **NOT APPLICABLE** rather than FAILED
- Recommend creating tests for future validation

---

## Validation Checklist

After completing all steps, verify each criterion:

- [ ] **Criterion 12**: Application connects to PostgreSQL successfully
  - Application starts without connection errors
  - Interactive menu displays correctly
  
- [ ] **Criterion 13**: All database operations execute successfully
  - [ ] SELECT with CTE and window functions (GetAllProductsAsync)
  - [ ] SELECT with LAG function (GetProductByIdAsync)
  - [ ] INSERT with RETURNING (InsertProductAsync)
  - [ ] UPDATE in transaction (UpdateProductAsync)
  - [ ] DELETE in transaction (DeleteProductAsync)
  - [ ] SELECT with RANK functions (GetProductsByPriceRangeAsync)
  - [ ] SELECT with multiple window functions (GetLowStockProductsAsync)

- [ ] **Criterion 14**: Transaction blocks maintain atomicity
  - [ ] Successful transactions commit all statements
  - [ ] Failed transactions rollback completely
  - [ ] No partial updates occur on errors

- [ ] **Criterion 15**: Application passes tests
  - [ ] All unit tests pass (if exist)
  - [ ] All integration tests pass (if exist)
  - [ ] Test coverage documented

---

## Troubleshooting

### Common Issues

**1. Connection Timeout**
```
Error: Npgsql.NpgsqlException: Connection timeout
```
**Solution:**
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check connection string host/port
- Verify firewall settings

**2. Schema Not Found**
```
Error: relation "productmanagement_dbo.products" does not exist
```
**Solution:**
- Execute the setup script: `01_PostgreSQL_InitialSetup.sql`
- Verify schema exists: `\dn` in psql

**3. Authentication Failed**
```
Error: password authentication failed for user "postgres"
```
**Solution:**
- Update connection string with correct credentials
- Check PostgreSQL pg_hba.conf for authentication method

**4. Unique Constraint Violation**
```
Error: duplicate key value violates unique constraint "ix_products_sku"
```
**Solution:**
- This is expected for transaction rollback testing
- Verify the transaction rolled back completely

**5. Parameter Issues**
```
Error: parameter @ProductId not found
```
**Solution:**
- Verify Npgsql is using correct parameter syntax (@ prefix)
- Check parameter names match between C# and SQL

---

## Documentation

After completing runtime validation, document results in:

1. **Test Results Log**: Create `runtime_test_results.log` with:
   - Each test executed
   - Expected vs actual results
   - Pass/Fail status
   - Any errors encountered

2. **Updated Validation Summary**: Update `validation_summary.md` with:
   - Updated status for criteria 12-15
   - Evidence of testing
   - Screenshots or output logs
   - Final overall status (should be PASS if all criteria met)

---

## Next Steps

1. Execute database setup (Step 1)
2. Test connectivity (Step 3)
3. Run functional tests (Step 4)
4. Verify transactions (Step 5)
5. Run test suite if exists (Step 6)
6. Document results
7. Update validation summary with final status

---

## Contact & Support

If you encounter issues not covered in this guide:
- Check PostgreSQL logs: `/var/log/postgresql/` (Linux) or Event Viewer (Windows)
- Review application logs: Check console output or log files
- Verify all steps completed in order
- Check DMS conversion log for any statement-specific issues
