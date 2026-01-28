# PostgreSQL Deployment and Runtime Verification Guide

## Overview

This document provides step-by-step instructions for deploying the PostgreSQL database and verifying the runtime functionality of the migrated ADO.NET application.

## Current Migration Status

### Completed (Code Migration)
✅ All SQL Server packages replaced with Npgsql
✅ All ADO.NET classes migrated (SqlConnection → NpgsqlConnection, etc.)
✅ All 7 SQL statements extracted and converted
✅ All SQL statement pairs validated through equivalency tool
✅ Connection strings converted to PostgreSQL format
✅ Transaction handling updated for PostgreSQL
✅ Application builds successfully with zero errors/warnings

### Pending (Runtime Verification)
⏸️ PostgreSQL database server deployment
⏸️ Database schema creation
⏸️ Application connectivity testing
⏸️ Database operations execution testing
⏸️ Transaction atomicity verification
⏸️ Integration test execution

## Prerequisites

### Software Requirements
- PostgreSQL 12+ (recommended: PostgreSQL 15 or 16)
- .NET 9.0 SDK
- psql command-line tool (included with PostgreSQL)
- Optional: pgAdmin 4 or DBeaver for GUI management

### System Requirements
- Operating System: Windows, Linux, or macOS
- Memory: Minimum 2GB available RAM
- Disk Space: Minimum 1GB for PostgreSQL
- Network: Port 5432 available (default PostgreSQL port)

## Step 1: PostgreSQL Installation

### Option A: Local Installation (Development)

#### Windows
1. Download PostgreSQL installer from https://www.postgresql.org/download/windows/
2. Run the installer
3. Set password for postgres user (remember this password!)
4. Accept default port 5432
5. Complete installation

#### Linux (Ubuntu/Debian)
```bash
# Update package list
sudo apt update

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Set password for postgres user
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your_password';"
```

#### macOS (Homebrew)
```bash
# Install PostgreSQL
brew install postgresql@15

# Start PostgreSQL service
brew services start postgresql@15

# Set password for postgres user
psql postgres -c "ALTER USER postgres PASSWORD 'your_password';"
```

### Option B: Docker Container (Development)

```bash
# Pull and run PostgreSQL in Docker
docker run --name postgres-dev \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15

# Verify container is running
docker ps | grep postgres-dev
```

### Option C: AWS RDS (Production)

1. Log in to AWS Console
2. Navigate to RDS service
3. Click "Create database"
4. Select "PostgreSQL"
5. Choose version (recommend 15.x)
6. Select instance size (minimum: db.t3.micro for testing)
7. Configure:
   - DB instance identifier: `productmanagement-db`
   - Master username: `postgres`
   - Master password: (use strong password)
   - VPC and security group settings
8. Create database
9. Note the endpoint URL

## Step 2: Database Schema Creation

### Verify PostgreSQL is Running

```bash
# Check PostgreSQL service status
# Linux:
sudo systemctl status postgresql

# macOS:
brew services list | grep postgresql

# Windows: Check Services app for "postgresql-x64-XX"

# Docker:
docker ps | grep postgres-dev
```

### Create Database and Schema

#### Method 1: Using psql Command Line

```bash
# Connect to PostgreSQL
psql -U postgres -h localhost

# In psql prompt, create database:
CREATE DATABASE "ProductManagement";

# Connect to the new database
\c ProductManagement

# Exit psql
\q

# Run setup script from file
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

#### Method 2: Using pgAdmin 4

1. Open pgAdmin 4
2. Connect to localhost PostgreSQL server
3. Right-click "Databases" → "Create" → "Database"
4. Name: `ProductManagement`
5. Click "Save"
6. Right-click "ProductManagement" → "Query Tool"
7. Open `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
8. Click "Execute" (F5)

#### Method 3: Using Docker

```bash
# Copy script to container
docker cp Database/Scripts/01_InitialSetup_PostgreSQL.sql postgres-dev:/tmp/

# Execute script
docker exec -it postgres-dev psql -U postgres -d ProductManagement -f /tmp/01_InitialSetup_PostgreSQL.sql
```

### Verify Schema Creation

```bash
# Connect to database
psql -U postgres -d ProductManagement

# List all tables
\dt

# Expected output:
#  Schema |      Name       | Type  |  Owner
# --------+-----------------+-------+----------
#  public | categories      | table | postgres
#  public | producthistory  | table | postgres
#  public | products        | table | postgres
#  public | productstats    | table | postgres
#  public | suppliers       | table | postgres

# Check row counts
SELECT 'Categories' as table_name, COUNT(*) as row_count FROM Categories
UNION ALL
SELECT 'Suppliers', COUNT(*) FROM Suppliers
UNION ALL
SELECT 'Products', COUNT(*) FROM Products
UNION ALL
SELECT 'ProductHistory', COUNT(*) FROM ProductHistory
UNION ALL
SELECT 'ProductStats', COUNT(*) FROM ProductStats;

# Expected output:
#   table_name    | row_count
# ----------------+-----------
#  Categories     |        20
#  Suppliers      |         8
#  Products       |        18
#  ProductHistory |         0
#  ProductStats   |         1
```

## Step 3: Configure Application Connection String

### Update appsettings.json

Navigate to the project root and edit `appsettings.json`:

#### For Local PostgreSQL:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_ACTUAL_PASSWORD;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;",
    "ProdConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_ACTUAL_PASSWORD;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;"
  },
  "Environment": "Development"
}
```

#### For Docker PostgreSQL:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;"
  },
  "Environment": "Development"
}
```

#### For AWS RDS:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=local_password;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;",
    "ProdConnection": "Host=your-rds-endpoint.region.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_RDS_PASSWORD;SSL Mode=Require;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100;"
  },
  "Environment": "Production"
}
```

### Security Note
**NEVER commit passwords to source control!** For production:
- Use environment variables
- Use AWS Secrets Manager
- Use Azure Key Vault
- Use .NET User Secrets for development

Example using environment variables:
```bash
export ConnectionStrings__DevConnection="Host=localhost;Database=ProductManagement;Username=postgres;Password=your_password;Pooling=true;"
```

## Step 4: Runtime Verification Tests

### Test 1: Application Build
```bash
# Navigate to project directory
cd /path/to/AdoCore

# Clean and rebuild
dotnet clean
dotnet build

# Expected: Build succeeded. 0 Warning(s). 0 Error(s).
```

### Test 2: Database Connectivity (Criterion 12)
```bash
# Test basic connectivity with a simple command
dotnet run -- list

# Expected output:
# - Application starts without connection errors
# - List of products is displayed
# - No exceptions thrown

# If successful, Criterion 12 is PASSED
```

### Test 3: Read Operations (Part of Criterion 13)
```bash
# Test 1: List all products
dotnet run -- list

# Expected: Display of 18 products with details

# Test 2: Get specific product
dotnet run -- get 1

# Expected: Display details of product with ID 1 (ProBook X1)

# Test 3: Get products by price range
dotnet run -- pricerange 100 500

# Expected: Display products with price between 100 and 500

# Test 4: Get low stock products
dotnet run -- lowstock 10

# Expected: Display products with stock <= 10
```

### Test 4: Write Operations (Part of Criterion 13)

#### Insert Test
```bash
# Add a new product
dotnet run -- add "Test Product" 99.99 50 "Test Description"

# Expected: 
# - Success message displayed
# - New product ID returned
# - Product appears in subsequent list queries

# Verify
dotnet run -- list | grep "Test Product"
```

#### Update Test
```bash
# Update the test product (use ID from insert)
dotnet run -- update 19 "Updated Test Product" 89.99 45 "Updated Description"

# Expected:
# - Success message displayed
# - Product details updated

# Verify
dotnet run -- get 19
```

#### Delete Test
```bash
# Delete the test product
dotnet run -- delete 19

# Expected:
# - Success message displayed
# - Product no longer appears in lists

# Verify
dotnet run -- get 19
# Expected: Product not found
```

### Test 5: Transaction Atomicity (Criterion 14)

Transaction atomicity needs to be verified through the multi-step operations:

```bash
# Test insert operation (uses transaction internally)
dotnet run -- add "Transaction Test 1" 75.00 10 "Testing transaction atomicity"

# Verify in database:
psql -U postgres -d ProductManagement -c "SELECT * FROM Products WHERE Name = 'Transaction Test 1';"

# Also verify ProductHistory was updated:
psql -U postgres -d ProductManagement -c "SELECT * FROM ProductHistory ORDER BY ActionDate DESC LIMIT 1;"

# Expected: Both tables updated (INSERT action in history)

# Test update operation
dotnet run -- update 20 "Transaction Test Updated" 80.00 15 "Updated"

# Verify in database:
psql -U postgres -d ProductManagement -c "SELECT * FROM ProductHistory WHERE ProductId = 20 ORDER BY ActionDate DESC LIMIT 1;"

# Expected: UPDATE action recorded with old and new values

# Test delete operation
dotnet run -- delete 20

# Verify in database:
psql -U postgres -d ProductManagement -c "SELECT * FROM ProductHistory WHERE ProductId = 20 ORDER BY ActionDate DESC LIMIT 1;"

# Expected: DELETE action recorded with old values
```

### Test 6: Complex Queries with CTEs and Window Functions

```bash
# Test GetAllProductsAsync (uses CTE with window functions)
dotnet run -- list

# Verify output includes PriceCategory and PricePercentageOfAverage
# This tests the complex CTE conversion

# Test GetProductByIdAsync (uses LAG window function)
dotnet run -- get 1

# Verify output includes previous price/stock information

# Test GetProductsByPriceRangeAsync (uses RANK and PERCENT_RANK)
dotnet run -- pricerange 100 1000

# Verify output includes price segments (Budget, Mid-Range, Premium)
```

## Step 5: Verification Checklist

Use this checklist to track runtime verification:

### Criterion 12: Application successfully connects to PostgreSQL database
- [ ] PostgreSQL server is running
- [ ] Database "ProductManagement" exists
- [ ] Schema and tables created successfully
- [ ] Connection string configured correctly
- [ ] Application starts without connection errors
- [ ] `dotnet run -- list` executes successfully

**Status**: ☐ PASS ☐ FAIL

### Criterion 13: All database operations execute successfully
- [ ] SELECT operations work (list, get by id)
- [ ] INSERT operations work (add product)
- [ ] UPDATE operations work (update product)
- [ ] DELETE operations work (delete product)
- [ ] Complex queries work (price range, low stock)
- [ ] CTEs with window functions execute correctly
- [ ] No SQL syntax errors

**Status**: ☐ PASS ☐ FAIL

### Criterion 14: Transaction blocks maintain atomicity
- [ ] Insert operations update both Products and ProductHistory
- [ ] Update operations maintain data consistency
- [ ] Delete operations properly cascade
- [ ] Rollback works on error
- [ ] No orphaned records
- [ ] ProductStats updated correctly

**Status**: ☐ PASS ☐ FAIL

### Criterion 15: Application passes all tests
- [ ] All manual CLI tests pass
- [ ] No runtime exceptions
- [ ] Data integrity maintained
- [ ] Performance acceptable

**Status**: ☐ PASS ☐ FAIL

## Step 6: Troubleshooting Common Issues

### Issue 1: Cannot connect to PostgreSQL
**Symptoms**: Connection timeout or authentication failed

**Solutions**:
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list | grep postgresql  # macOS
docker ps | grep postgres  # Docker

# Check port 5432 is listening
netstat -an | grep 5432
# or
ss -tlnp | grep 5432

# Test connection with psql
psql -U postgres -h localhost -d ProductManagement

# Check pg_hba.conf authentication settings
# Location: /etc/postgresql/XX/main/pg_hba.conf (Linux)
# Look for: local all postgres md5 or trust
```

### Issue 2: Database does not exist
**Symptoms**: "database 'ProductManagement' does not exist"

**Solutions**:
```bash
# List all databases
psql -U postgres -l

# Create database if missing
psql -U postgres -c "CREATE DATABASE \"ProductManagement\";"

# Re-run setup script
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### Issue 3: SQL syntax errors
**Symptoms**: Syntax errors during query execution

**Solutions**:
- Verify setup script ran completely
- Check PostgreSQL version (must be 12+)
- Review converted_statements.sql for correct PostgreSQL syntax
- Check application logs for specific error messages

### Issue 4: Transaction errors
**Symptoms**: "current transaction is aborted"

**Solutions**:
```bash
# In psql, rollback and try again:
ROLLBACK;

# Check transaction isolation level:
SHOW transaction_isolation;

# Verify NpgsqlTransaction usage in code
```

### Issue 5: Performance issues
**Symptoms**: Slow query execution

**Solutions**:
```sql
-- Check indexes exist
\di

-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM Products;

-- Update statistics
ANALYZE Products;

-- Check connection pool settings in connection string
```

## Step 7: Production Deployment Checklist

Before deploying to production:

### Security
- [ ] Remove hardcoded passwords from appsettings.json
- [ ] Configure SSL/TLS for PostgreSQL connections
- [ ] Use AWS Secrets Manager or equivalent for credentials
- [ ] Configure firewall rules (only application server can connect to DB)
- [ ] Enable PostgreSQL audit logging
- [ ] Use least-privilege database user (not postgres superuser)

### Performance
- [ ] Configure appropriate connection pool size
- [ ] Set up database backups (automated)
- [ ] Configure PostgreSQL for production workload
- [ ] Set up monitoring (CloudWatch, Datadog, etc.)
- [ ] Test with production data volume

### High Availability
- [ ] Configure RDS Multi-AZ deployment (AWS)
- [ ] Set up read replicas if needed
- [ ] Configure automatic failover
- [ ] Test disaster recovery procedures

### Monitoring
- [ ] Set up application logging
- [ ] Configure database query logging
- [ ] Set up alerts for connection failures
- [ ] Monitor connection pool exhaustion
- [ ] Track query performance metrics

## Step 8: Documentation and Handoff

After successful runtime verification:

1. **Update Validation Summary**
   - Document all test results
   - Record pass/fail status for each criterion
   - Include evidence (screenshots, logs)

2. **Create Runbook**
   - Database maintenance procedures
   - Backup and restore procedures
   - Troubleshooting guide
   - Emergency contacts

3. **Knowledge Transfer**
   - Review migration artifacts with operations team
   - Explain PostgreSQL-specific features
   - Demonstrate common operations
   - Provide access to documentation

## Appendix A: Quick Reference Commands

### PostgreSQL Management
```bash
# Start/stop PostgreSQL
sudo systemctl start postgresql
sudo systemctl stop postgresql
sudo systemctl restart postgresql

# Connect to database
psql -U postgres -d ProductManagement

# Backup database
pg_dump -U postgres ProductManagement > backup.sql

# Restore database
psql -U postgres -d ProductManagement < backup.sql

# Check database size
psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('ProductManagement'));"
```

### Application Commands
```bash
# Build application
dotnet build

# Run application (interactive)
dotnet run

# Run CLI commands
dotnet run -- list
dotnet run -- get <id>
dotnet run -- add "<name>" <price> <quantity> "<description>"
dotnet run -- update <id> "<name>" <price> <quantity> "<description>"
dotnet run -- delete <id>
dotnet run -- pricerange <min> <max>
dotnet run -- lowstock <threshold>
```

### Verification Queries
```sql
-- Count all records
SELECT 
    'Products' as table_name, COUNT(*) as count FROM Products
UNION ALL
SELECT 'ProductHistory', COUNT(*) FROM ProductHistory
UNION ALL
SELECT 'ProductStats', COUNT(*) FROM ProductStats;

-- Check recent history
SELECT * FROM ProductHistory ORDER BY ActionDate DESC LIMIT 10;

-- Verify statistics
SELECT * FROM ProductStats;

-- Test complex query
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT p.Name, p.Price, ps.AvgPrice
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
LIMIT 5;
```

## Appendix B: Environment-Specific Connection Strings

### Development (Local)
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=dev_password;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;
```

### Testing (Docker)
```
Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;
```

### Staging (AWS RDS)
```
Host=staging-db.region.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=app_user;Password=FROM_SECRETS_MANAGER;SSL Mode=Require;Trust Server Certificate=true;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=50;
```

### Production (AWS RDS)
```
Host=prod-db.region.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=app_user;Password=FROM_SECRETS_MANAGER;SSL Mode=Require;Trust Server Certificate=true;Pooling=true;Minimum Pool Size=10;Maximum Pool Size=100;Command Timeout=30;
```

## Summary

This guide provides comprehensive instructions for deploying PostgreSQL and verifying all runtime criteria (12-15). Follow each step carefully and use the verification checklist to track progress. After successful completion, all 16 exit criteria should be met.
