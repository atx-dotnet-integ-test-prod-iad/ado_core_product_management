# PostgreSQL Migration - Runtime Testing Guide

## Overview
This guide provides step-by-step instructions for completing the runtime validation of the SQL Server to PostgreSQL migration. All code-level transformations have been completed successfully, but runtime testing with a live PostgreSQL database is required to meet exit criteria 12-15.

## Prerequisites
- PostgreSQL 12 or later installed and running
- .NET 9.0 SDK installed
- Network access to PostgreSQL instance
- PostgreSQL credentials (username/password)

## Exit Criteria Status

### ✅ Completed (12/16 criteria)
1. ✅ All SQL Server packages replaced with PostgreSQL equivalents
2. ✅ All ADO.NET classes replaced (SqlConnection → NpgsqlConnection, etc.)
3. ✅ All SQL statements processed through DMS MCP tool
4. ✅ Comprehensive SQL catalog exists
5. ✅ All SQL pairs validated through SQL Equivalency tool
6. ✅ Comprehensive equivalency report generated
7. ✅ No agent judgment used for equivalency determination
8. ✅ Failed DMS conversions documented
9. ✅ Connection strings updated to PostgreSQL format
10. ✅ Transaction handling updated to PostgreSQL syntax
11. ✅ Application compiles without errors
16. ✅ Final report includes complete SQL statement listing

### ⚠️ Requires Runtime Testing (4/16 criteria)
12. ❌ Application successfully connects to PostgreSQL database
13. ❌ All database operations execute successfully
14. ❌ Transaction blocks maintain atomicity
15. ❌ Application passes all unit/integration tests

## Setup Instructions

### Step 1: Install PostgreSQL (if not already installed)

#### On Linux (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### On macOS:
```bash
brew install postgresql@15
brew services start postgresql@15
```

#### On Windows:
Download and install from: https://www.postgresql.org/download/windows/

### Step 2: Create PostgreSQL Database and Schema

1. **Connect to PostgreSQL as postgres user:**
```bash
# Linux/macOS
sudo -u postgres psql

# Windows (from psql command line tool)
psql -U postgres
```

2. **Create the database:**
```sql
CREATE DATABASE "ProductManagement";
\c ProductManagement
```

3. **Run the setup script:**
```bash
# From command line
psql -U postgres -d ProductManagement -f Database/Scripts/02_PostgreSQL_Setup.sql
```

Or copy and paste the contents of `Database/Scripts/02_PostgreSQL_Setup.sql` into psql.

### Step 3: Verify Database Setup

```sql
-- Verify schema exists
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'productmanagement_dbo';

-- Verify tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'productmanagement_dbo';

-- Verify sample data
SELECT COUNT(*) FROM productmanagement_dbo.products;
SELECT COUNT(*) FROM productmanagement_dbo.categories;
SELECT COUNT(*) FROM productmanagement_dbo.suppliers;
```

Expected results:
- 18 products
- 20 categories
- 8 suppliers

### Step 4: Update Connection String

Edit `appsettings.json` with your PostgreSQL connection details:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Port=5432;Username=postgres;Password=YOUR_PASSWORD;Pooling=true",
    "ProdConnection": "Host=localhost;Database=ProductManagement;Port=5432;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
  },
  "Environment": "Development"
}
```

Replace `YOUR_PASSWORD` with your actual PostgreSQL password.

### Step 5: Test Database Connection

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Build the application
dotnet build

# Test connection by listing products
dotnet run -- list
```

**Expected Result**: Should display all 18 products without errors.

**✅ If successful**: Exit Criterion 12 is MET

## Testing All Database Operations

### Test 1: SELECT Operations (GetAllProductsAsync)

```bash
dotnet run -- list
```

**Expected**: Display all 18 products with details
- Verify window functions (AVG OVER, COUNT OVER)
- Verify CTE query execution
- Check price and stock quantity values

**Validates**: GetAllProductsAsync, GetProductsByPriceRangeAsync, GetLowStockProductsAsync

### Test 2: SELECT by ID (GetProductByIdAsync)

```bash
dotnet run -- get 1
dotnet run -- get 5
dotnet run -- get 10
```

**Expected**: Display specific product details
- Verify LAG window function works
- Verify previous price calculation

**Validates**: GetProductByIdAsync

### Test 3: INSERT Operation (InsertProductAsync)

```bash
dotnet run -- add "Test Product" 99.99 50 "Test description"
```

**Expected**: 
- New product created successfully
- Returns new ProductId
- ProductHistory record created
- ProductStats updated

**Verify**:
```sql
-- Check new product exists
SELECT * FROM productmanagement_dbo.products WHERE name = 'Test Product';

-- Check history was logged
SELECT * FROM productmanagement_dbo.producthistory 
WHERE action = 'INSERT' 
ORDER BY actiondate DESC LIMIT 1;

-- Check stats updated
SELECT * FROM productmanagement_dbo.productstats;
```

**Validates**: InsertProductAsync with RETURNING clause

### Test 4: UPDATE Operation (UpdateProductAsync)

```bash
# Update the test product we just created
dotnet run -- update <PRODUCT_ID> "Updated Test Product" 129.99 60 "Updated description"
```

**Expected**:
- Product updated successfully
- Old values captured
- ProductHistory record created with UPDATE action
- ProductStats updated
- Transaction commits all changes atomically

**Verify**:
```sql
-- Check product updated
SELECT * FROM productmanagement_dbo.products WHERE productid = <PRODUCT_ID>;

-- Check history logged with old and new values
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = <PRODUCT_ID> AND action = 'UPDATE';

-- Verify stats updated
SELECT * FROM productmanagement_dbo.productstats;
```

**Validates**: UpdateProductAsync transaction (4 operations)

### Test 5: DELETE Operation (DeleteProductAsync)

```bash
dotnet run -- delete <PRODUCT_ID>
```

**Expected**:
- Product deleted successfully
- ProductHistory record created with DELETE action before deletion
- ProductStats updated with correct calculations
- Transaction commits all changes atomically

**Verify**:
```sql
-- Check product deleted
SELECT * FROM productmanagement_dbo.products WHERE productid = <PRODUCT_ID>;
-- Should return no rows

-- Check history logged before deletion
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = <PRODUCT_ID> AND action = 'DELETE';

-- Verify stats updated
SELECT * FROM productmanagement_dbo.productstats;
```

**Validates**: DeleteProductAsync transaction (3 operations)

### Test 6: Transaction Atomicity (UpdateProductAsync)

**Test transaction rollback by simulating an error**:

1. Temporarily modify ProductRepository.cs to throw an exception mid-transaction
2. Attempt an update operation
3. Verify NO partial changes were committed

**Expected**: Either all changes commit or all rollback - no partial updates.

### Test 7: Complex Queries with Window Functions

```bash
# Test price range query with RANK() and PERCENT_RANK()
dotnet run -- list
```

**Verify in PostgreSQL**:
```sql
-- Test GetProductsByPriceRangeAsync equivalent
WITH RankedProducts AS (
    SELECT 
        productid,
        name,
        price,
        stockquantity,
        RANK() OVER (ORDER BY price DESC NULLS FIRST) AS pricerank,
        PERCENT_RANK() OVER (ORDER BY price DESC NULLS FIRST) AS pricepercentile
    FROM productmanagement_dbo.products
    WHERE price BETWEEN 100 AND 500
)
SELECT * FROM RankedProducts ORDER BY pricerank;
```

### Test 8: Low Stock Products Query

```sql
-- Test GetLowStockProductsAsync equivalent
WITH StockAnalysis AS (
    SELECT 
        productid,
        name,
        stockquantity,
        reorderlevel,
        AVG(stockquantity) OVER () AS avgstock,
        MIN(stockquantity) OVER () AS minstock,
        MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products
    WHERE stockquantity <= reorderlevel
)
SELECT * FROM StockAnalysis ORDER BY stockquantity;
```

**✅ If all tests pass**: Exit Criteria 13, 14 are MET

## Validation Checklist

Use this checklist to track testing progress:

### Connection Testing (Criterion 12)
- [ ] Application connects to PostgreSQL without errors
- [ ] Connection pooling works correctly
- [ ] Connection string parameters parsed correctly
- [ ] No authentication errors

### Database Operations (Criterion 13)
- [ ] GetAllProductsAsync returns correct data
- [ ] GetProductByIdAsync returns correct product
- [ ] InsertProductAsync creates new product with RETURNING
- [ ] UpdateProductAsync modifies existing product
- [ ] DeleteProductAsync removes product
- [ ] GetProductsByPriceRangeAsync filters correctly
- [ ] GetLowStockProductsAsync identifies low stock items

### Transaction Testing (Criterion 14)
- [ ] UpdateProductAsync transaction commits all 4 operations atomically
- [ ] DeleteProductAsync transaction commits all 3 operations atomically
- [ ] Transaction rollback leaves database unchanged
- [ ] No partial commits occur
- [ ] ProductHistory logging occurs within transactions
- [ ] ProductStats updates occur within transactions

### SQL Equivalency Verification
- [ ] Window functions (AVG OVER, COUNT OVER) produce correct results
- [ ] LAG function returns correct previous values
- [ ] RANK() and PERCENT_RANK() calculations match expectations
- [ ] CTE queries return expected data
- [ ] RETURNING clause returns inserted/updated IDs
- [ ] clock_timestamp() records current time correctly
- [ ] CASE expressions evaluate correctly
- [ ] COALESCE handles NULL values properly

## Common Issues and Solutions

### Issue 1: Connection Refused
**Error**: `Npgsql.NpgsqlException: Connection refused`
**Solution**: 
- Verify PostgreSQL is running: `systemctl status postgresql`
- Check connection string Host and Port
- Verify firewall allows port 5432

### Issue 2: Authentication Failed
**Error**: `password authentication failed for user "postgres"`
**Solution**:
- Verify password in appsettings.json
- Check PostgreSQL pg_hba.conf authentication method
- Try resetting postgres password

### Issue 3: Schema Not Found
**Error**: `relation "productmanagement_dbo.products" does not exist`
**Solution**:
- Run 02_PostgreSQL_Setup.sql script
- Verify schema exists: `\dn` in psql
- Check search_path: `SHOW search_path;`

### Issue 4: Window Function Errors
**Error**: Window function calculation issues
**Solution**:
- Compare results with extracted_statements.sql (original SQL)
- Verify ORDER BY NULLS FIRST/LAST placement
- Check for data type differences

## Performance Considerations

### Verify Query Performance
```sql
-- Enable query timing
\timing on

-- Analyze query plans
EXPLAIN ANALYZE SELECT * FROM productmanagement_dbo.products;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan 
FROM pg_stat_user_indexes 
WHERE schemaname = 'productmanagement_dbo';
```

### Connection Pooling
Verify connection pooling is working:
```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity WHERE datname = 'ProductManagement';
```

## Final Validation Report

After completing all tests, document results:

### Exit Criterion 12: Database Connection ✅/❌
- [ ] Connection successful: Yes/No
- [ ] Connection string valid: Yes/No
- [ ] Pooling working: Yes/No
- Issues found: _________________

### Exit Criterion 13: Database Operations ✅/❌
- [ ] All SELECT operations work: Yes/No
- [ ] INSERT with RETURNING works: Yes/No
- [ ] UPDATE operations work: Yes/No
- [ ] DELETE operations work: Yes/No
- [ ] Window functions correct: Yes/No
- Issues found: _________________

### Exit Criterion 14: Transaction Atomicity ✅/❌
- [ ] UpdateProductAsync transaction atomic: Yes/No
- [ ] DeleteProductAsync transaction atomic: Yes/No
- [ ] Rollback behavior correct: Yes/No
- Issues found: _________________

### Exit Criterion 15: Tests Pass ✅/❌
- [ ] All manual tests pass: Yes/No
- [ ] No data corruption observed: Yes/No
- [ ] Performance acceptable: Yes/No
- Issues found: _________________

## Next Steps

1. **If all tests pass**: Update validation_summary.md with SUCCESS status for criteria 12-15
2. **If tests fail**: Document specific failures and SQL statements that need adjustment
3. **Production readiness**: After successful testing, application is ready for production deployment

## Reference Documentation

- Original SQL statements: `extracted_statements.sql`
- Converted SQL statements: `converted_statements.sql`
- DMS conversion log: `dms_conversion_log.json`
- Equivalency validation: `sql_equivalency_validation_report.json`
- Migration summary: `final_migration_report.json`
- Manual review notes: `MANUAL_REVIEW_REQUIRED.md`

## Contact

For issues during testing:
1. Check the migration artifacts listed above
2. Review PostgreSQL logs: `/var/log/postgresql/`
3. Check application build log: `build.log`
4. Refer to transformation definition for requirements
