# PostgreSQL Database Setup Guide

This guide provides instructions for setting up the PostgreSQL database for the migrated ADO.NET Core application.

## Prerequisites

- PostgreSQL 12 or later installed
- pgAdmin or psql command-line tool
- Appropriate database permissions

## Installation Options

### Option 1: Using Docker (Recommended for Development)

```bash
# Pull and run PostgreSQL container
docker run --name postgres-productmgmt \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15

# Verify container is running
docker ps | grep postgres-productmgmt
```

### Option 2: Native PostgreSQL Installation

#### Windows
1. Download PostgreSQL installer from https://www.postgresql.org/download/windows/
2. Run installer and follow the setup wizard
3. Note the password you set for the postgres user
4. Add PostgreSQL bin directory to PATH (usually `C:\Program Files\PostgreSQL\15\bin`)

#### macOS
```bash
# Using Homebrew
brew install postgresql@15
brew services start postgresql@15

# Create default user (if needed)
createuser -s postgres
```

#### Linux (Ubuntu/Debian)
```bash
# Install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Set password for postgres user
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
```

## Database Setup

### Step 1: Create Database (if not already created)

Using psql:
```bash
psql -U postgres -h localhost -p 5432
```

Then run:
```sql
CREATE DATABASE "ProductManagement";
\q
```

### Step 2: Run Schema Setup Script

Navigate to the project's Database/Scripts directory:

```bash
cd /path/to/AdoCore/Database/Scripts
```

Execute the PostgreSQL setup script:

```bash
psql -U postgres -h localhost -p 5432 -d ProductManagement -f 01_PostgreSQL_InitialSetup.sql
```

Or using pgAdmin:
1. Open pgAdmin
2. Connect to your PostgreSQL server
3. Right-click on "ProductManagement" database → Query Tool
4. Open file: `01_PostgreSQL_InitialSetup.sql`
5. Execute (F5)

### Step 3: Verify Database Setup

Run these verification queries:

```sql
-- Connect to database
\c ProductManagement

-- Check tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Verify data
SELECT COUNT(*) as category_count FROM categories;
SELECT COUNT(*) as supplier_count FROM suppliers;
SELECT COUNT(*) as product_count FROM products;

-- Test a sample query
SELECT product_id, name, price, stock_quantity 
FROM products 
LIMIT 5;
```

Expected results:
- 5 tables: categories, suppliers, products, product_history, product_stats
- 20 categories
- 8 suppliers
- 18 products
- 0-18 product_history records (depending on trigger execution)
- 1 product_stats record

## Connection String Configuration

### Development Environment

Update `appsettings.json` with your actual credentials:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD_HERE;Pooling=true",
    "ProdConnection": "Host=your-prod-server;Port=5432;Database=ProductManagement;Username=your_user;Password=YOUR_PASSWORD_HERE;Pooling=true;SSL Mode=Require"
  },
  "Environment": "Development"
}
```

### Production Environment (Using Environment Variables)

For production, use environment variables instead of hardcoded credentials:

```bash
export DB_HOST="your-prod-server"
export DB_PORT="5432"
export DB_NAME="ProductManagement"
export DB_USER="your_prod_user"
export DB_PASSWORD="your_secure_password"
```

Then update connection string to read from environment:
```csharp
var connectionString = $"Host={Environment.GetEnvironmentVariable("DB_HOST")};" +
                      $"Port={Environment.GetEnvironmentVariable("DB_PORT")};" +
                      $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
                      $"Username={Environment.GetEnvironmentVariable("DB_USER")};" +
                      $"Password={Environment.GetEnvironmentVariable("DB_PASSWORD")};" +
                      "Pooling=true;SSL Mode=Require";
```

### Cloud Deployment Options

#### AWS RDS PostgreSQL
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-instance.region.rds.amazonaws.com;Port=5432;Database=ProductManagement;Username=admin;Password=YOUR_PASSWORD;SSL Mode=Require;Trust Server Certificate=true"
  }
}
```

#### Azure Database for PostgreSQL
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=your-server.postgres.database.azure.com;Port=5432;Database=ProductManagement;Username=admin@your-server;Password=YOUR_PASSWORD;SSL Mode=Require"
  }
}
```

#### Google Cloud SQL PostgreSQL
```json
{
  "ConnectionStrings": {
    "ProdConnection": "Host=/cloudsql/project:region:instance;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD"
  }
}
```

## Testing the Application

### Step 1: Build the Application

```bash
cd /path/to/AdoCore
dotnet build
```

Expected output:
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### Step 2: Test Database Connectivity

Run a simple query:

```bash
dotnet run -- list
```

Expected output: List of products from the database

### Step 3: Test CRUD Operations

```bash
# Create a product
dotnet run -- add "Test Product" 99.99 10 "Test Description"

# Get product by ID (use the returned ID)
dotnet run -- get 19

# Update product
dotnet run -- update 19 "Updated Product" 89.99 15 "Updated Description"

# Delete product
dotnet run -- delete 19
```

### Step 4: Verify Transaction Integrity

Test transaction rollback by attempting to insert invalid data:

```sql
-- In psql, try to insert a product with invalid foreign key
INSERT INTO products (name, price, stock_quantity, category_id) 
VALUES ('Test', 10.00, 5, 999);
-- Should fail with foreign key constraint error
```

## Database Schema Overview

### Tables

1. **categories** - Product categories (hierarchical)
2. **suppliers** - Product suppliers
3. **products** - Main product data
4. **product_history** - Audit trail for product changes
5. **product_stats** - Aggregate statistics

### Key Migrations from SQL Server

| SQL Server Feature | PostgreSQL Equivalent |
|-------------------|----------------------|
| `IDENTITY(1,1)` | `SERIAL` |
| `NVARCHAR` | `VARCHAR` |
| `BIT` | `BOOLEAN` |
| `GETDATE()` | `CURRENT_TIMESTAMP` |
| `SCOPE_IDENTITY()` | `RETURNING` clause |
| Stored Procedures | Functions |
| Triggers (AFTER) | Triggers with Functions |

## Troubleshooting

### Connection Failed

**Error:** "could not connect to server: Connection refused"

**Solutions:**
1. Verify PostgreSQL is running: `sudo systemctl status postgresql`
2. Check port 5432 is open: `netstat -an | grep 5432`
3. Verify pg_hba.conf allows connections from your host
4. Check firewall settings

### Authentication Failed

**Error:** "password authentication failed for user 'postgres'"

**Solutions:**
1. Verify password in connection string
2. Reset postgres password:
   ```bash
   sudo -u postgres psql
   ALTER USER postgres PASSWORD 'newpassword';
   \q
   ```

### Permission Denied

**Error:** "permission denied for table products"

**Solutions:**
1. Grant permissions:
   ```sql
   GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
   GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
   GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres;
   ```

### SSL Connection Error

**Error:** "SSL connection has been requested but SSL is not available"

**Solutions:**
1. Add `SSL Mode=Disable` to connection string for local development
2. For production, enable SSL in postgresql.conf
3. Use `SSL Mode=Prefer` for flexible SSL handling

## Performance Optimization

### Recommended Configuration Changes

Edit `postgresql.conf`:

```ini
# Memory Settings (adjust based on available RAM)
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB
maintenance_work_mem = 128MB

# Connection Settings
max_connections = 100
superuser_reserved_connections = 3

# Query Planning
random_page_cost = 1.1  # For SSD storage
effective_io_concurrency = 200
```

### Index Monitoring

```sql
-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### Connection Pool Configuration

In `appsettings.json`, optimize connection pooling:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=20;Connection Idle Lifetime=300"
  }
}
```

## Backup and Restore

### Create Backup

```bash
# Full database backup
pg_dump -U postgres -h localhost ProductManagement > productmgmt_backup.sql

# Backup with compression
pg_dump -U postgres -h localhost ProductManagement | gzip > productmgmt_backup.sql.gz

# Custom format (recommended for large databases)
pg_dump -U postgres -h localhost -Fc ProductManagement > productmgmt_backup.dump
```

### Restore Backup

```bash
# From SQL file
psql -U postgres -h localhost ProductManagement < productmgmt_backup.sql

# From compressed file
gunzip -c productmgmt_backup.sql.gz | psql -U postgres -h localhost ProductManagement

# From custom format
pg_restore -U postgres -h localhost -d ProductManagement productmgmt_backup.dump
```

## Monitoring and Maintenance

### Regular Maintenance Tasks

```sql
-- Vacuum and analyze (run weekly)
VACUUM ANALYZE;

-- Reindex (run monthly)
REINDEX DATABASE "ProductManagement";

-- Update statistics
ANALYZE;
```

### Monitor Database Size

```sql
SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
WHERE datname = 'ProductManagement';
```

### Monitor Active Connections

```sql
SELECT 
    datname,
    count(*) as connections
FROM pg_stat_activity
GROUP BY datname
ORDER BY connections DESC;
```

## Security Best Practices

1. **Never use default passwords in production**
2. **Use SSL/TLS for all connections**
3. **Implement least privilege access**
4. **Enable audit logging**
5. **Regular security updates**
6. **Use connection string encryption**
7. **Implement IP whitelisting**
8. **Regular backup testing**

## Next Steps

1. ✅ Install PostgreSQL
2. ✅ Run setup script
3. ✅ Update connection string
4. ✅ Test application
5. ✅ Verify all CRUD operations
6. ✅ Test transaction integrity
7. ✅ Set up monitoring
8. ✅ Configure backups
9. ✅ Implement production security
10. ✅ Performance tuning

## Support

For PostgreSQL documentation: https://www.postgresql.org/docs/
For Npgsql documentation: https://www.npgsql.org/doc/
