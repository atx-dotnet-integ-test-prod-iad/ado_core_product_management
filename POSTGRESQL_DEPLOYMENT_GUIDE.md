# PostgreSQL Database Setup and Deployment Guide

## Overview
This guide provides complete instructions for deploying and testing the AdoCore application with PostgreSQL after migration from SQL Server.

## Prerequisites
- PostgreSQL 12 or higher installed
- .NET 9.0 SDK
- psql command-line tool or pgAdmin GUI tool
- Appropriate permissions to create databases

## Part 1: PostgreSQL Installation

### Option A: Windows
```powershell
# Download and install PostgreSQL from https://www.postgresql.org/download/windows/
# Or use Chocolatey:
choco install postgresql

# Default installation creates postgres superuser with password you set during installation
```

### Option B: Linux (Ubuntu/Debian)
```bash
# Install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Switch to postgres user
sudo -i -u postgres
```

### Option C: macOS
```bash
# Using Homebrew
brew install postgresql@16
brew services start postgresql@16

# Or download from https://www.postgresql.org/download/macosx/
```

### Option D: Docker (Recommended for Testing)
```bash
# Pull and run PostgreSQL in Docker
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:16

# Verify container is running
docker ps | grep postgres-adocore

# Connect to container
docker exec -it postgres-adocore psql -U postgres -d ProductManagement
```

## Part 2: Database Schema Setup

### Step 1: Create Database (if not using Docker)
```bash
# Connect to PostgreSQL as superuser
psql -U postgres

# Inside psql, create the database
CREATE DATABASE "ProductManagement";

# Connect to the new database
\c ProductManagement

# Exit psql
\q
```

### Step 2: Run PostgreSQL Schema Script
```bash
# Navigate to the scripts directory
cd /path/to/sourceCode/Database/Scripts

# Execute the PostgreSQL setup script
psql -U postgres -d ProductManagement -f 01_InitialSetup_PostgreSQL.sql

# Verify tables were created
psql -U postgres -d ProductManagement -c "\dt"

# Expected output: List of tables including:
# - categories
# - suppliers
# - products
# - producthistory
# - productstats
```

### Step 3: Verify Sample Data
```bash
# Check sample data was inserted
psql -U postgres -d ProductManagement -c "SELECT COUNT(*) FROM products;"
# Expected: 18 products

psql -U postgres -d ProductManagement -c "SELECT COUNT(*) FROM categories;"
# Expected: 20 categories

psql -U postgres -d ProductManagement -c "SELECT COUNT(*) FROM suppliers;"
# Expected: 8 suppliers
```

## Part 3: Application Configuration

### Step 1: Update Connection String
Edit `appsettings.json` with your actual PostgreSQL credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true",
    "ProdConnection": "Host=YOUR_PROD_HOST;Port=5432;Database=ProductManagement;Username=YOUR_USER;Password=YOUR_PASSWORD;Pooling=true;SSL Mode=Require"
  },
  "Environment": "Development"
}
```

### Connection String Parameters Explained:
- **Host**: PostgreSQL server hostname (localhost for local, or IP/domain for remote)
- **Port**: PostgreSQL port (default: 5432)
- **Database**: Database name (ProductManagement)
- **Username**: PostgreSQL user (postgres for superuser, or create application-specific user)
- **Password**: User password
- **Pooling**: Enable connection pooling (recommended: true)
- **SSL Mode**: For production, use "Require" or "Prefer"

### Step 2: Build the Application
```bash
# Navigate to source code directory
cd /path/to/sourceCode

# Restore dependencies
dotnet restore

# Build the application
dotnet build

# Expected output: Build succeeded with 0 errors
```

## Part 4: Runtime Validation

### Test 1: Database Connection (Criterion 12)
```bash
# Run the application
dotnet run

# The application should:
# 1. Start without connection errors
# 2. Display the main menu
# 3. Show that connection was established
```

**Success Indicators:**
- No connection exceptions thrown
- Application starts and displays menu
- No "connection refused" or "authentication failed" errors

### Test 2: CRUD Operations (Criterion 13)

#### Test 2a: Read Operations
```bash
# From application menu, test:
# 1. Get All Products - Should display 18 products
# 2. Get Product by ID - Try ID: 1, should return "ProBook X1"
# 3. Get Products by Price Range - Try 100-500, should return multiple products
# 4. Get Low Stock Products - Should return products with stock <= reorder level
```

#### Test 2b: Insert Operation
```bash
# From application menu:
# 1. Select "Insert Product"
# 2. Enter test data:
#    Name: Test Product
#    Description: Test Description
#    Price: 99.99
#    Stock: 50
# 3. Verify product is inserted (should return new ProductId)
# 4. Query database to confirm:

psql -U postgres -d ProductManagement -c "SELECT * FROM products WHERE name = 'Test Product';"
```

#### Test 2c: Update Operation
```bash
# From application menu:
# 1. Select "Update Product"
# 2. Enter ProductId of test product from 2b
# 3. Update price to 149.99
# 4. Verify update succeeded
# 5. Query database to confirm:

psql -U postgres -d ProductManagement -c "SELECT * FROM products WHERE name = 'Test Product';"
# Expected: Price should be 149.99
```

#### Test 2d: Delete Operation
```bash
# From application menu:
# 1. Select "Delete Product"
# 2. Enter ProductId of test product
# 3. Verify delete succeeded
# 4. Query database to confirm:

psql -U postgres -d ProductManagement -c "SELECT * FROM products WHERE name = 'Test Product';"
# Expected: 0 rows returned
```

### Test 3: Transaction Atomicity (Criterion 14)

#### Test 3a: Successful Transaction
```bash
# This tests that all operations in a transaction commit together

# 1. Insert a product (creates product + history entry in one transaction)
# 2. Verify both records exist:

psql -U postgres -d ProductManagement -c "
SELECT p.productid, p.name, h.action 
FROM products p 
JOIN producthistory h ON p.productid = h.productid 
WHERE p.name = 'Your Test Product Name';
"
# Expected: Should show product with corresponding INSERT history entry
```

#### Test 3b: Transaction Rollback (Error Scenario)
```bash
# Manually test rollback by inserting invalid data
# This should rollback and not insert any data

# Create a test script:
cat > test_rollback.sql << 'EOF'
BEGIN;
INSERT INTO products (name, price, stockquantity) VALUES ('Rollback Test', 99.99, 10);
-- Force an error with invalid foreign key
INSERT INTO products (name, price, stockquantity, categoryid) VALUES ('Invalid', 99.99, 10, 9999);
COMMIT;
EOF

# Execute the script (should fail)
psql -U postgres -d ProductManagement -f test_rollback.sql

# Verify rollback occurred:
psql -U postgres -d ProductManagement -c "SELECT * FROM products WHERE name = 'Rollback Test';"
# Expected: 0 rows (transaction rolled back due to error)
```

## Part 5: Validation Checklist

Use this checklist to verify all exit criteria:

### Code-Level Validation (✓ Already Passed)
- [x] Criterion 1: SQL Server packages replaced with Npgsql
- [x] Criterion 2: SQL Server ADO.NET classes replaced with Npgsql equivalents
- [x] Criterion 3: All SQL statements processed through DMS MCP tool
- [x] Criterion 4: Comprehensive SQL statement catalog exists
- [x] Criterion 5: All SQL pairs validated through SQL Equivalency MCP tool
- [x] Criterion 6: Comprehensive equivalency validation report generated
- [x] Criterion 7: No agent judgment used for SQL equivalency
- [x] Criterion 8: DMS failures documented with manual conversion
- [x] Criterion 9: Connection strings updated to PostgreSQL format
- [x] Criterion 10: Transaction handling updated to PostgreSQL syntax
- [x] Criterion 11: Application compiles without errors

### Runtime Validation (Requires PostgreSQL Database)
- [ ] **Criterion 12**: Application successfully connects to PostgreSQL
  - Start application with `dotnet run`
  - Verify no connection errors
  - Confirm main menu displays

- [ ] **Criterion 13**: All database operations execute successfully
  - [ ] SELECT - Get All Products
  - [ ] SELECT - Get Product By ID
  - [ ] SELECT - Get Products By Price Range
  - [ ] SELECT - Get Low Stock Products
  - [ ] INSERT - Insert new product
  - [ ] UPDATE - Update existing product
  - [ ] DELETE - Delete product

- [ ] **Criterion 14**: Transaction atomicity maintained
  - [ ] Successful transaction commits all operations
  - [ ] Failed transaction rolls back all operations
  - [ ] ProductHistory entries created correctly
  - [ ] No orphaned records after rollback

- [ ] **Criterion 15**: Tests pass (N/A - no tests in project)

- [ ] **Criterion 16**: Final report complete (✓ Already completed)

## Part 6: Troubleshooting

### Issue: Connection Refused
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list  # macOS
docker ps  # Docker

# Check PostgreSQL is listening on port 5432
sudo netstat -tlnp | grep 5432  # Linux
lsof -i :5432  # macOS

# Verify pg_hba.conf allows connections
sudo cat /etc/postgresql/*/main/pg_hba.conf  # Linux
# Look for: host all all 127.0.0.1/32 md5
```

### Issue: Authentication Failed
```bash
# Reset postgres user password
sudo -u postgres psql
ALTER USER postgres PASSWORD 'newpassword';
\q

# Update appsettings.json with new password
```

### Issue: Database Does Not Exist
```bash
# List all databases
psql -U postgres -l

# Create database if missing
psql -U postgres -c "CREATE DATABASE \"ProductManagement\";"
```

### Issue: Application Can't Find Connection String
```bash
# Ensure appsettings.json is in the output directory
cd /path/to/sourceCode
dotnet build
ls bin/Debug/net9.0/appsettings.json

# If missing, check .csproj has:
# <None Update="appsettings.json">
#   <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
# </None>
```

### Issue: SQL Syntax Errors
```bash
# Check PostgreSQL logs for detailed error messages
# Linux:
sudo tail -f /var/log/postgresql/postgresql-*-main.log

# Docker:
docker logs postgres-adocore

# Common issues:
# - Case sensitivity: Use lowercase table/column names
# - Parameter syntax: Use $1, $2 instead of @param1, @param2
# - Functions: GETDATE() → CURRENT_TIMESTAMP, SCOPE_IDENTITY() → RETURNING
```

## Part 7: Performance Optimization (Post-Deployment)

After successful deployment, consider these optimizations:

### 1. Create Additional Indexes
```sql
-- For frequently queried columns
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_discontinued ON products(isdiscontinued) WHERE isdiscontinued = false;
```

### 2. Configure Connection Pooling
```json
// In appsettings.json
"ConnectionStrings": {
  "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;MinPoolSize=5;MaxPoolSize=100;CommandTimeout=30"
}
```

### 3. Enable Query Logging (Development Only)
```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/*/main/postgresql.conf

# Add/modify:
log_statement = 'all'
log_duration = on
log_min_duration_statement = 100

# Restart PostgreSQL
sudo systemctl restart postgresql
```

## Part 8: Security Best Practices

### 1. Create Application-Specific User (Recommended for Production)
```sql
-- Connect as postgres superuser
CREATE USER adocore_app WITH PASSWORD 'strong_password_here';

-- Grant necessary privileges
GRANT CONNECT ON DATABASE "ProductManagement" TO adocore_app;
GRANT USAGE ON SCHEMA public TO adocore_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO adocore_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO adocore_app;

-- Update appsettings.json to use adocore_app user instead of postgres
```

### 2. Enable SSL for Production
```bash
# Generate SSL certificates (or use Let's Encrypt)
# Update postgresql.conf:
ssl = on
ssl_cert_file = '/path/to/server.crt'
ssl_key_file = '/path/to/server.key'

# Update connection string:
"ProdConnection": "Host=...;SSL Mode=Require;Trust Server Certificate=true"
```

### 3. Never Commit Credentials
```bash
# Use environment variables for sensitive data
export DB_PASSWORD="your_secure_password"

# Or use .NET User Secrets (development)
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=...;Password=secret"

# Or use Azure Key Vault / AWS Secrets Manager (production)
```

## Part 9: Migration Success Confirmation

### Final Validation Report
After completing all tests, document results:

```bash
# Generate database statistics
psql -U postgres -d ProductManagement << 'EOF'
\echo '=== Database Migration Validation Report ==='
\echo ''
\echo 'Tables Created:'
SELECT schemaname, tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
\echo ''
\echo 'Record Counts:'
SELECT 'Categories' as table_name, COUNT(*) FROM categories
UNION ALL SELECT 'Suppliers', COUNT(*) FROM suppliers
UNION ALL SELECT 'Products', COUNT(*) FROM products
UNION ALL SELECT 'ProductHistory', COUNT(*) FROM producthistory
UNION ALL SELECT 'ProductStats', COUNT(*) FROM productstats;
\echo ''
\echo 'Indexes Created:'
SELECT tablename, indexname FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;
\echo ''
\echo 'Foreign Keys:'
SELECT conname as constraint_name, conrelid::regclass as table_name, confrelid::regclass as referenced_table
FROM pg_constraint WHERE contype = 'f' AND connamespace = 'public'::regnamespace;
EOF
```

### Application Test Results
Create a test results document:

```markdown
# AdoCore PostgreSQL Migration - Test Results

## Test Execution Date: [DATE]
## Tester: [NAME]
## PostgreSQL Version: [VERSION]

### Criterion 12: Database Connectivity
- [x] Application starts without errors
- [x] Connection established to PostgreSQL
- [x] No authentication failures
- **Status**: PASS

### Criterion 13: CRUD Operations
- [x] Get All Products: Retrieved 18 products
- [x] Get Product By ID: Successfully retrieved product ID 1
- [x] Get Products By Price Range: Returned correct filtered results
- [x] Get Low Stock Products: Returned products with stock <= reorder level
- [x] Insert Product: Successfully inserted new product
- [x] Update Product: Successfully updated product price and stock
- [x] Delete Product: Successfully deleted test product
- **Status**: PASS

### Criterion 14: Transaction Atomicity
- [x] Insert transaction: Product + history created together
- [x] Update transaction: Product + history updated atomically
- [x] Delete transaction: Product + history handled correctly
- [x] Rollback test: Failed transaction rolled back completely
- **Status**: PASS

## Overall Migration Status: SUCCESS
All runtime validation criteria have been met.
```

## Conclusion

After completing this guide, you will have:
1. ✓ PostgreSQL database deployed with correct schema
2. ✓ Application successfully connecting to PostgreSQL
3. ✓ All CRUD operations working correctly
4. ✓ Transaction atomicity verified
5. ✓ Migration fully validated

The migration from SQL Server to PostgreSQL is complete and production-ready!

---

## Quick Reference Commands

```bash
# Start PostgreSQL (Docker)
docker start postgres-adocore

# Connect to database
psql -U postgres -d ProductManagement

# Run application
cd /path/to/sourceCode && dotnet run

# View logs
docker logs -f postgres-adocore

# Backup database
pg_dump -U postgres ProductManagement > backup.sql

# Restore database
psql -U postgres -d ProductManagement < backup.sql
```

For additional support, refer to:
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- AdoCore Project README: /path/to/sourceCode/README.md
