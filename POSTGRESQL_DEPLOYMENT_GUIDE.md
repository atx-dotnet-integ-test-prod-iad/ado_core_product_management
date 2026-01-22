# PostgreSQL Migration Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the migrated AdoCore application from Microsoft SQL Server to PostgreSQL.

## Prerequisites

### 1. PostgreSQL Installation
- PostgreSQL 12 or higher installed and running
- Access to PostgreSQL with superuser privileges (or database creation privileges)
- Port 5432 accessible (or adjust connection string accordingly)

### 2. Application Requirements
- .NET 9.0 SDK or runtime installed
- Npgsql 10.0.1 package (already configured in AdoCore.csproj)

## Deployment Steps

### Step 1: Install PostgreSQL (if not already installed)

#### On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### On macOS (using Homebrew):
```bash
brew install postgresql@15
brew services start postgresql@15
```

#### On Windows:
Download and install from: https://www.postgresql.org/download/windows/

### Step 2: Create Database and Schema

1. **Connect to PostgreSQL as superuser:**
```bash
sudo -u postgres psql
```

2. **Create the database:**
```sql
CREATE DATABASE productmanagement;
```

3. **Create application user (recommended for production):**
```sql
CREATE USER adocore_app WITH PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE productmanagement TO adocore_app;
```

4. **Exit psql:**
```sql
\q
```

5. **Run the setup script:**
```bash
psql -U postgres -d productmanagement -f Database/Scripts/01_PostgreSQL_InitialSetup.sql
```

### Step 3: Configure Connection String

**For Development:**
The current `appsettings.json` contains:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true"
  }
}
```

**For Production (REQUIRED):**
Update `appsettings.json` with secure credentials:
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-db-host;Port=5432;Database=ProductManagement;Username=adocore_app;Password=your_secure_password;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100;SSL Mode=Require"
  }
}
```

**Environment Variables (Recommended for Production):**
Instead of hardcoding credentials, use environment variables:
```bash
export DB_HOST="your-db-host"
export DB_PORT="5432"
export DB_NAME="ProductManagement"
export DB_USER="adocore_app"
export DB_PASSWORD="your_secure_password"
```

Then modify connection string to:
```
Host=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};Username=${DB_USER};Password=${DB_PASSWORD};Pooling=true;SSL Mode=Require
```

### Step 4: Verify Database Schema

Run these verification queries to ensure schema is correctly created:

```sql
-- Connect to database
\c productmanagement

-- Verify tables exist
SELECT table_schema, table_name 
FROM information_schema.tables 
WHERE table_schema = 'productmanagement_dbo'
ORDER BY table_name;

-- Expected output:
-- productmanagement_dbo | categories
-- productmanagement_dbo | producthistory
-- productmanagement_dbo | products
-- productmanagement_dbo | productstats
-- productmanagement_dbo | suppliers

-- Verify column names are lowercase
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'productmanagement_dbo'
  AND table_name = 'products'
ORDER BY ordinal_position;

-- Verify sample data loaded
SELECT COUNT(*) AS total_products FROM productmanagement_dbo.products;
SELECT COUNT(*) AS total_categories FROM productmanagement_dbo.categories;
SELECT COUNT(*) AS total_suppliers FROM productmanagement_dbo.suppliers;
```

### Step 5: Build the Application

```bash
cd sourceCode
dotnet restore
dotnet build
```

Expected output:
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### Step 6: Test Database Connectivity

Create a simple test to verify connection before running full application:

```bash
dotnet run --project AdoCore.csproj -- --test-connection
```

If connection test is not built into the application, you can test manually using psql:

```bash
psql -h localhost -p 5432 -U postgres -d ProductManagement -c "SELECT COUNT(*) FROM productmanagement_dbo.products;"
```

### Step 7: Run the Application

```bash
dotnet run
```

## Validation Checklist

### Database Validation
- [ ] PostgreSQL database created successfully
- [ ] Schema `productmanagement_dbo` exists
- [ ] All tables created with lowercase column names:
  - [ ] products
  - [ ] categories
  - [ ] suppliers
  - [ ] producthistory
  - [ ] productstats
- [ ] Sample data loaded (18 products, 20 categories, 8 suppliers)
- [ ] Indexes created successfully
- [ ] Trigger `trg_products_history` created and functional
- [ ] Foreign key constraints in place

### Application Validation
- [ ] Application builds without errors
- [ ] Npgsql package version 10.0.1 or higher (security fix)
- [ ] Connection string configured correctly
- [ ] Application connects to PostgreSQL successfully
- [ ] SELECT operations work (GetAllProducts, GetProductById, etc.)
- [ ] INSERT operations work with RETURNING clause
- [ ] UPDATE operations work
- [ ] DELETE operations work
- [ ] Transaction handling works correctly
- [ ] Window function queries execute successfully

### Security Validation
- [ ] Default credentials (postgres/postgres) replaced in production
- [ ] Database user has minimum required privileges
- [ ] SSL/TLS enabled for database connections (production)
- [ ] Connection string not hardcoded in production deployment
- [ ] Npgsql vulnerability (GHSA-x9vc-6hfv-hg8c) addressed

## Troubleshooting

### Issue: Connection Refused
**Solution:**
1. Verify PostgreSQL is running: `sudo systemctl status postgresql`
2. Check port 5432 is listening: `netstat -an | grep 5432`
3. Verify pg_hba.conf allows connections from your host
4. Check firewall rules

### Issue: Authentication Failed
**Solution:**
1. Verify credentials in connection string
2. Check PostgreSQL user exists: `\du` in psql
3. Verify pg_hba.conf authentication method (md5 or scram-sha-256)

### Issue: Schema Not Found
**Solution:**
1. Verify schema exists: `\dn` in psql
2. Ensure search_path includes schema: `SET search_path TO productmanagement_dbo, public;`
3. Re-run setup script if schema missing

### Issue: Column Names Don't Match
**Solution:**
All PostgreSQL column names should be lowercase. If queries fail:
1. Verify column names in database match converted statements
2. Check that DMS-converted schema names are being used
3. Review converted_statements.sql for correct column references

### Issue: Transaction Errors
**Solution:**
1. Verify PostgreSQL connection pooling is enabled
2. Check transaction isolation level settings
3. Ensure CommitAsync/RollbackAsync are called properly
4. Review transaction logs for deadlocks

## Performance Tuning (Optional)

### Connection Pool Settings
```
Minimum Pool Size=5;Maximum Pool Size=100;Connection Lifetime=300;Connection Idle Lifetime=180;
```

### PostgreSQL Configuration
Edit `postgresql.conf` for optimal performance:
```
shared_buffers = 256MB          # 25% of RAM
effective_cache_size = 1GB      # 50-75% of RAM
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1          # For SSD
effective_io_concurrency = 200  # For SSD
work_mem = 16MB
```

## Monitoring

### Database Monitoring
```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity WHERE datname = 'ProductManagement';

-- Check table sizes
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE schemaname = 'productmanagement_dbo'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check slow queries (if pg_stat_statements is enabled)
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;
```

### Application Monitoring
- Monitor Npgsql connection pool metrics
- Log query execution times
- Track transaction success/failure rates
- Monitor memory usage and GC pressure

## Rollback Plan

If issues occur during deployment:

1. **Keep SQL Server database intact** until PostgreSQL deployment is validated
2. **Backup PostgreSQL database** before major changes:
   ```bash
   pg_dump -U postgres -d ProductManagement -F c -f productmanagement_backup.dump
   ```
3. **Restore from backup** if needed:
   ```bash
   pg_restore -U postgres -d ProductManagement -c productmanagement_backup.dump
   ```

## Next Steps

1. **Create Integration Tests:** Build test suite to validate all CRUD operations
2. **Performance Testing:** Run load tests to ensure acceptable performance
3. **Documentation:** Update API documentation to reflect any behavior changes
4. **Training:** Brief development team on PostgreSQL-specific considerations
5. **Monitoring:** Set up alerting for database issues

## Support and Resources

- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **Npgsql Documentation:** https://www.npgsql.org/doc/
- **Migration Reports:** Review these files in the project root:
  - `final_migration_report.md` - Complete migration summary
  - `sql_equivalency_validation_report.json` - Statement equivalency validation
  - `converted_statements.sql` - All converted SQL statements
  - `dms_conversion_failures.log` - DMS conversion issues and resolutions

## Contact

For issues or questions related to this migration, refer to the transformation artifacts and migration reports in the project root directory.
