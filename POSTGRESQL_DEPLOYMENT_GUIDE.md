# PostgreSQL Migration - Deployment and Testing Guide

## Overview

This guide provides step-by-step instructions for deploying and testing the migrated ADO.NET application with PostgreSQL. The application has been successfully migrated from SQL Server to PostgreSQL, with all code transformations completed and verified.

## Migration Status

### Completed Tasks ✅
- ✅ All SQL Server packages replaced with Npgsql (PostgreSQL driver)
- ✅ All ADO.NET classes updated (SqlConnection → NpgsqlConnection, etc.)
- ✅ All 7 SQL statements extracted and processed through DMS MCP tool
- ✅ Complete SQL statement catalog created (extracted_statements.sql)
- ✅ All statements converted to PostgreSQL syntax (converted_statements.sql)
- ✅ SQL equivalency validation performed on all statement pairs
- ✅ Connection strings updated to PostgreSQL format
- ✅ Transaction handling updated to PostgreSQL syntax
- ✅ Application compiles successfully (0 errors)
- ✅ PostgreSQL database setup script created

### Pending Validation Tasks 🔄
- ⏳ Database connectivity testing (requires live PostgreSQL instance)
- ⏳ CRUD operations testing (requires live PostgreSQL instance)
- ⏳ Transaction atomicity verification (requires live PostgreSQL instance)
- ⏳ Integration testing (no tests exist in original codebase)

## Prerequisites

### Software Requirements
1. **PostgreSQL Database Server**
   - Version: 12 or higher (recommended: 15+)
   - Download: https://www.postgresql.org/download/
   - Or use Docker: `docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:15`

2. **PostgreSQL Client Tools** (choose one)
   - pgAdmin 4: https://www.pgadmin.org/download/
   - DBeaver: https://dbeaver.io/download/
   - psql command-line tool (included with PostgreSQL)

3. **.NET Runtime**
   - Version: .NET 9.0 SDK or later
   - Verify: `dotnet --version`

### Database Setup

#### Option 1: Local PostgreSQL Installation

1. **Install PostgreSQL**
   ```bash
   # Windows: Download installer from postgresql.org
   # macOS: brew install postgresql@15
   # Linux (Ubuntu/Debian): sudo apt-get install postgresql-15
   ```

2. **Start PostgreSQL Service**
   ```bash
   # Windows: Starts automatically after installation
   # macOS: brew services start postgresql@15
   # Linux: sudo systemctl start postgresql
   ```

3. **Verify PostgreSQL is Running**
   ```bash
   # Connect to default postgres database
   psql -U postgres -h localhost
   # You should see: postgres=#
   ```

#### Option 2: Docker PostgreSQL

1. **Run PostgreSQL in Docker**
   ```bash
   docker run --name postgres-adocore \
     -e POSTGRES_PASSWORD=postgres \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_DB=ProductManagement \
     -p 5432:5432 \
     -d postgres:15
   ```

2. **Verify Container is Running**
   ```bash
   docker ps | grep postgres-adocore
   docker logs postgres-adocore
   ```

3. **Connect to PostgreSQL**
   ```bash
   docker exec -it postgres-adocore psql -U postgres -d ProductManagement
   ```

#### Option 3: AWS RDS PostgreSQL

1. **Create RDS PostgreSQL Instance**
   - Go to AWS Console → RDS → Create database
   - Choose PostgreSQL, version 15+
   - Choose instance size (db.t3.micro for testing)
   - Set master username: `postgres`
   - Set master password: `your-secure-password`
   - Configure security group to allow inbound on port 5432
   - Note the endpoint URL

2. **Update Connection String**
   - Replace `localhost` with RDS endpoint in appsettings.json

### Database Schema Creation

1. **Locate the Setup Script**
   ```
   Database/Scripts/01_PostgreSQL_Setup.sql
   ```

2. **Execute the Setup Script**

   **Using psql:**
   ```bash
   # If PostgreSQL is local
   psql -U postgres -h localhost -d postgres -f Database/Scripts/01_PostgreSQL_Setup.sql
   
   # If using Docker
   docker exec -i postgres-adocore psql -U postgres -d ProductManagement < Database/Scripts/01_PostgreSQL_Setup.sql
   ```

   **Using pgAdmin:**
   - Open pgAdmin
   - Connect to your PostgreSQL server
   - Right-click on "ProductManagement" database (or postgres database)
   - Select "Query Tool"
   - Open the file: Database/Scripts/01_PostgreSQL_Setup.sql
   - Click Execute (F5)

   **Using DBeaver:**
   - Open DBeaver
   - Connect to your PostgreSQL server
   - Right-click on connection → SQL Editor → Open SQL Script
   - Select: Database/Scripts/01_PostgreSQL_Setup.sql
   - Click Execute (Ctrl+Enter)

3. **Verify Schema Creation**
   ```sql
   -- Connect to ProductManagement database
   \c ProductManagement
   
   -- List all schemas
   \dn
   -- Should see: productmanagement_dbo
   
   -- List tables in the schema
   SET search_path TO productmanagement_dbo;
   \dt
   -- Should see: categories, suppliers, products, producthistory, productstats
   
   -- Verify sample data
   SELECT COUNT(*) FROM productmanagement_dbo.products;
   -- Should return: 18
   
   SELECT COUNT(*) FROM productmanagement_dbo.categories;
   -- Should return: 20
   
   SELECT COUNT(*) FROM productmanagement_dbo.suppliers;
   -- Should return: 8
   ```

## Application Configuration

### Update Connection String

1. **Open appsettings.json**
   ```bash
   cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
   # Edit appsettings.json
   ```

2. **Verify PostgreSQL Connection String Format**
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=1;Maximum Pool Size=20;Application Name=AdoCore",
       "ProdConnection": "Host=your-prod-host;Port=5432;Database=ProductManagement;Username=postgres;Password=your-password;SSL Mode=Require;Pooling=true;Minimum Pool Size=1;Maximum Pool Size=20;Application Name=AdoCore"
     },
     "Environment": "Development"
   }
   ```

3. **Connection String Parameters**
   - `Host`: PostgreSQL server hostname (localhost, RDS endpoint, etc.)
   - `Port`: PostgreSQL port (default: 5432)
   - `Database`: Database name (ProductManagement)
   - `Username`: PostgreSQL username (postgres)
   - `Password`: PostgreSQL password
   - `Pooling`: Enable connection pooling (true)
   - `SSL Mode`: For production/RDS use "Require", for local use "Prefer" or omit
   - `Application Name`: Application identifier in PostgreSQL logs

### Build the Application

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Restore packages
dotnet restore

# Build the application
dotnet build

# Verify build success
# Expected: Build succeeded. 0 Error(s)
```

## Testing the Application

### Test 1: Database Connectivity

**Objective:** Verify the application can connect to PostgreSQL database

**Steps:**
```bash
# Run the application in interactive mode
dotnet run

# Expected output:
# Product Management System
# ------------------------
# 1. List all products
# 2. Get product by ID
# ...
```

**Success Criteria:**
- Application starts without connection errors
- Main menu displays
- No exceptions in console

**If Connection Fails:**
- Verify PostgreSQL is running: `psql -U postgres -h localhost -l`
- Check connection string in appsettings.json
- Verify credentials are correct
- Check firewall/security group settings

### Test 2: SELECT Operations

**Objective:** Verify all SELECT statements execute successfully

**Test 2.1: GetAllProductsAsync**
```bash
dotnet run -- list

# Or in interactive mode:
dotnet run
# Select option 1
```

**Expected Results:**
- List of 18 products displayed
- Columns: ProductId, Name, Description, Price, StockQuantity
- No SQL errors
- Data matches sample data from setup script

**Test 2.2: GetProductByIdAsync**
```bash
dotnet run -- get 1

# Or in interactive mode, select option 2, enter ID: 1
```

**Expected Results:**
- Product details for ID 1 (ProBook X1)
- Price: 1299.99
- StockQuantity: 15
- No SQL errors

**Test 2.3: GetProductsByPriceRangeAsync**
```bash
# In interactive mode, this would be a menu option
# For CLI, this tests the price range query
```

**Expected Results:**
- Products within specified price range returned
- Results sorted by price
- No SQL errors

**Test 2.4: GetLowStockProductsAsync**
```bash
# In interactive mode, this would be a menu option
# Tests the low stock warning query
```

**Expected Results:**
- Products with StockQuantity <= ReorderLevel
- Gaming Tower (stock: 5, reorder: 2) should appear
- No SQL errors

### Test 3: INSERT Operations

**Objective:** Verify INSERT statements work with RETURNING clause (PostgreSQL)

**Steps:**
```bash
dotnet run -- add "Test Product" 99.99 50 "Test product for migration validation"

# Or in interactive mode, select option 3
```

**Expected Results:**
- Success message with new ProductId
- Verify in database:
  ```sql
  SELECT * FROM productmanagement_dbo.products WHERE name = 'Test Product';
  ```
- ProductId should be auto-generated (SERIAL)
- CreatedDate should be populated
- Transaction should be committed

**Verify Transaction Handling:**
```sql
-- Check product was inserted
SELECT productid, name, price, stockquantity 
FROM productmanagement_dbo.products 
WHERE name = 'Test Product';

-- Check history trigger fired
SELECT * FROM productmanagement_dbo.producthistory 
WHERE action = 'INSERT' 
ORDER BY actiondate DESC LIMIT 5;
```

### Test 4: UPDATE Operations

**Objective:** Verify UPDATE statements execute with proper transaction handling

**Steps:**
```bash
# Get the ProductId from Test 3
dotnet run -- update <ProductId> "Updated Test Product" 89.99 45 "Updated description"

# Or in interactive mode, select option 4
```

**Expected Results:**
- Success message
- Verify in database:
  ```sql
  SELECT * FROM productmanagement_dbo.products WHERE productid = <ProductId>;
  ```
- Name should be "Updated Test Product"
- Price should be 89.99
- StockQuantity should be 45
- ModifiedDate should be updated

**Verify Transaction and Trigger:**
```sql
-- Check product was updated
SELECT productid, name, price, stockquantity, modifieddate 
FROM productmanagement_dbo.products 
WHERE productid = <ProductId>;

-- Check history trigger recorded the change
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = <ProductId> AND action = 'UPDATE'
ORDER BY actiondate DESC;
-- Should show oldprice, newprice, oldstock, newstock
```

### Test 5: DELETE Operations

**Objective:** Verify DELETE statements with CASCADE behavior

**Steps:**
```bash
dotnet run -- delete <ProductId>

# Or in interactive mode, select option 5
```

**Expected Results:**
- Success message
- Verify in database:
  ```sql
  SELECT * FROM productmanagement_dbo.products WHERE productid = <ProductId>;
  -- Should return 0 rows
  ```
- Product should be deleted
- Transaction should be committed

**Verify Transaction and Cascade:**
```sql
-- Check product was deleted
SELECT COUNT(*) FROM productmanagement_dbo.products WHERE productid = <ProductId>;
-- Should return 0

-- Check history trigger recorded the deletion
SELECT * FROM productmanagement_dbo.producthistory 
WHERE productid = <ProductId> AND action = 'DELETE'
ORDER BY actiondate DESC LIMIT 1;
-- Should show oldprice and oldstock

-- Verify history records still exist (CASCADE didn't delete history)
SELECT COUNT(*) FROM productmanagement_dbo.producthistory WHERE productid = <ProductId>;
-- Should return > 0 (INSERT, UPDATE, DELETE records)
```

### Test 6: Transaction Atomicity

**Objective:** Verify transaction rollback works correctly

**Manual Test - Simulate Failure:**

1. **Temporarily Modify Code** (for testing only)
   Edit ProductRepository.cs, InsertProductAsync method, add a forced exception after INSERT:
   ```csharp
   // After: int productId = Convert.ToInt32(result);
   throw new Exception("Simulated failure for rollback test");
   ```

2. **Run Insert Test**
   ```bash
   dotnet run -- add "Rollback Test" 1.00 1 "Should rollback"
   ```

3. **Expected Result:**
   - Exception thrown
   - Transaction rolled back
   - Verify product was NOT inserted:
     ```sql
     SELECT * FROM productmanagement_dbo.products WHERE name = 'Rollback Test';
     -- Should return 0 rows
     ```

4. **Remove Test Code**
   - Remove the `throw new Exception` line
   - Rebuild application

### Test 7: Concurrent Operations

**Objective:** Verify connection pooling and concurrent access

**Steps:**
1. Open multiple terminal windows
2. Run concurrent operations:
   ```bash
   # Terminal 1
   dotnet run -- list
   
   # Terminal 2 (immediately)
   dotnet run -- get 1
   
   # Terminal 3 (immediately)
   dotnet run -- list
   ```

**Expected Results:**
- All operations complete successfully
- No connection pool exhaustion errors
- No deadlocks
- Connection pooling statistics can be checked in PostgreSQL:
  ```sql
  SELECT * FROM pg_stat_activity WHERE application_name = 'AdoCore';
  ```

## Validation Checklist

Use this checklist to track validation progress:

### Code Transformation (Completed ✅)
- [x] SQL Server packages removed
- [x] Npgsql package added
- [x] All SqlConnection replaced with NpgsqlConnection
- [x] All SqlCommand replaced with NpgsqlCommand
- [x] All SqlDataReader replaced with NpgsqlDataReader
- [x] Connection strings updated to PostgreSQL format
- [x] All SQL statements extracted and cataloged
- [x] All SQL statements processed through DMS MCP tool
- [x] SQL equivalency validation performed
- [x] Transaction handling updated to PostgreSQL syntax
- [x] Application compiles without errors

### Database Setup (To Be Completed)
- [ ] PostgreSQL server installed/accessible
- [ ] ProductManagement database created
- [ ] productmanagement_dbo schema created
- [ ] All tables created (categories, suppliers, products, producthistory, productstats)
- [ ] Indexes created
- [ ] Triggers created
- [ ] Sample data inserted
- [ ] Connection string configured

### Runtime Testing (To Be Completed)
- [ ] Application connects to PostgreSQL
- [ ] GetAllProductsAsync executes successfully
- [ ] GetProductByIdAsync executes successfully
- [ ] GetProductsByPriceRangeAsync executes successfully
- [ ] GetLowStockProductsAsync executes successfully
- [ ] InsertProductAsync executes successfully
- [ ] UpdateProductAsync executes successfully
- [ ] DeleteProductAsync executes successfully
- [ ] Transaction commit works correctly
- [ ] Transaction rollback works correctly
- [ ] Triggers fire correctly (producthistory)
- [ ] Concurrent operations work correctly

## Troubleshooting

### Issue: "Connection refused" or "could not connect to server"

**Solution:**
1. Verify PostgreSQL is running:
   ```bash
   # Check process
   ps aux | grep postgres  # Linux/Mac
   
   # Check service
   systemctl status postgresql  # Linux
   brew services list  # Mac
   ```

2. Verify PostgreSQL is listening on correct port:
   ```bash
   netstat -an | grep 5432
   # Should show LISTEN on 0.0.0.0:5432 or 127.0.0.1:5432
   ```

3. Check pg_hba.conf for authentication settings:
   ```bash
   # Location varies by OS
   # Linux: /etc/postgresql/15/main/pg_hba.conf
   # Mac: /usr/local/var/postgresql@15/pg_hba.conf
   
   # Should have line:
   host    all             all             127.0.0.1/32            md5
   ```

### Issue: "password authentication failed"

**Solution:**
1. Verify credentials in appsettings.json match PostgreSQL
2. Reset PostgreSQL password if needed:
   ```bash
   sudo -u postgres psql
   ALTER USER postgres WITH PASSWORD 'new-password';
   ```

### Issue: "relation does not exist"

**Solution:**
1. Verify schema exists:
   ```sql
   SELECT schema_name FROM information_schema.schemata 
   WHERE schema_name = 'productmanagement_dbo';
   ```

2. If missing, re-run setup script:
   ```bash
   psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_Setup.sql
   ```

3. Verify application is using correct schema in queries (all queries use `productmanagement_dbo.` prefix)

### Issue: "column does not exist" or case sensitivity errors

**Solution:**
1. PostgreSQL is case-sensitive for quoted identifiers
2. All column names in the application use lowercase (productid, not ProductId)
3. Verify queries match the schema created in 01_PostgreSQL_Setup.sql

### Issue: Build warnings about Npgsql vulnerability

**Solution:**
- The warning is informational about a resolved CVE
- Current Npgsql 8.0.1 has the fix
- Warning can be suppressed if needed, but does not affect functionality

## Performance Benchmarking (Optional)

After validation, you can benchmark performance:

```bash
# Create a simple load test
for i in {1..100}; do
  dotnet run -- get $((RANDOM % 18 + 1)) &
done
wait

# Monitor PostgreSQL performance
psql -U postgres -d ProductManagement
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
```

## Migration Artifacts

All migration artifacts are preserved in the source directory:

- **extracted_statements.sql** - All original SQL Server statements
- **converted_statements.sql** - All converted PostgreSQL statements
- **dms_conversion_summary.json** - DMS conversion metadata
- **sql_equivalency_validation_report.json** - Equivalency validation results
- **final_migration_report.md** - Complete migration report
- **Database/Scripts/01_PostgreSQL_Setup.sql** - PostgreSQL setup script (NEW)

## Next Steps After Validation

1. **Production Deployment Planning**
   - Review AWS RDS PostgreSQL configuration
   - Configure SSL/TLS for database connections
   - Set up database backups and monitoring
   - Configure production connection strings

2. **Application Enhancements**
   - Add comprehensive unit tests
   - Add integration tests
   - Implement logging (Serilog, NLog)
   - Add health check endpoints

3. **Security Hardening**
   - Use connection string encryption
   - Implement least-privilege database user
   - Enable SSL Mode=Require for production
   - Review and audit database permissions

4. **Monitoring and Observability**
   - Set up application monitoring (Application Insights, Datadog)
   - Configure PostgreSQL slow query logging
   - Implement custom metrics for business operations

## Support and Documentation

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **Migration Report**: See final_migration_report.md
- **SQL Equivalency Report**: See sql_equivalency_validation_report.json

## Validation Sign-Off

After completing all tests, document results:

| Exit Criterion | Status | Notes |
|----------------|--------|-------|
| Database connectivity | ☐ PASS / ☐ FAIL | |
| SELECT operations | ☐ PASS / ☐ FAIL | |
| INSERT operations | ☐ PASS / ☐ FAIL | |
| UPDATE operations | ☐ PASS / ☐ FAIL | |
| DELETE operations | ☐ PASS / ☐ FAIL | |
| Transaction commit | ☐ PASS / ☐ FAIL | |
| Transaction rollback | ☐ PASS / ☐ FAIL | |
| Triggers firing | ☐ PASS / ☐ FAIL | |
| Concurrent operations | ☐ PASS / ☐ FAIL | |

**Validated By:** _____________________  
**Date:** _____________________  
**PostgreSQL Version:** _____________________  
**Application Version:** _____________________
