# PostgreSQL Database Setup Guide

## Overview
This guide provides step-by-step instructions for setting up the PostgreSQL database environment required for the AdoCore application after migration from Microsoft SQL Server.

## Prerequisites
- PostgreSQL 12 or later installed
- Administrative access to PostgreSQL server
- Network connectivity to PostgreSQL server
- Basic knowledge of SQL and PostgreSQL administration

## 1. Install PostgreSQL

### Linux (Ubuntu/Debian)
```bash
# Add PostgreSQL repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update package list
sudo apt-get update

# Install PostgreSQL
sudo apt-get install postgresql-14
```

### macOS
```bash
# Using Homebrew
brew install postgresql@14

# Start PostgreSQL service
brew services start postgresql@14
```

### Windows
Download and install from: https://www.postgresql.org/download/windows/

### Docker (All Platforms)
```bash
# Pull PostgreSQL image
docker pull postgres:14

# Run PostgreSQL container
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:14
```

## 2. Access PostgreSQL

### Connect to PostgreSQL
```bash
# Linux/macOS
sudo -u postgres psql

# Docker
docker exec -it postgres-adocore psql -U postgres

# Windows (using pgAdmin or psql from command prompt)
psql -U postgres -h localhost
```

## 3. Create Database

```sql
-- Create the database
CREATE DATABASE productmanagement
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Connect to the new database
\c productmanagement
```

## 4. Create Schema

```sql
-- Create application schema
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo
    AUTHORIZATION postgres;

-- Set search path to include new schema
SET search_path TO productmanagement_dbo, public;
```

## 5. Create Tables

### 5.1 Products Table
```sql
CREATE TABLE productmanagement_dbo.products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(18, 2) NOT NULL DEFAULT 0.00,
    quantity INTEGER NOT NULL DEFAULT 0,
    category VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_date TIMESTAMP,
    created_by VARCHAR(100),
    modified_by VARCHAR(100),
    CONSTRAINT chk_products_price CHECK (price >= 0),
    CONSTRAINT chk_products_quantity CHECK (quantity >= 0)
);

-- Create indexes for better query performance
CREATE INDEX idx_products_name ON productmanagement_dbo.products(name);
CREATE INDEX idx_products_category ON productmanagement_dbo.products(category);
CREATE INDEX idx_products_is_active ON productmanagement_dbo.products(is_active);
CREATE INDEX idx_products_created_date ON productmanagement_dbo.products(created_date);

-- Add comments for documentation
COMMENT ON TABLE productmanagement_dbo.products IS 'Main products table storing product information';
COMMENT ON COLUMN productmanagement_dbo.products.id IS 'Primary key, auto-incrementing product ID';
COMMENT ON COLUMN productmanagement_dbo.products.name IS 'Product name (required)';
COMMENT ON COLUMN productmanagement_dbo.products.price IS 'Product price (must be >= 0)';
```

### 5.2 Product History Table
```sql
CREATE TABLE productmanagement_dbo.producthistory (
    history_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100),
    CONSTRAINT fk_producthistory_product FOREIGN KEY (product_id) 
        REFERENCES productmanagement_dbo.products(id) 
        ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX idx_producthistory_product_id ON productmanagement_dbo.producthistory(product_id);
CREATE INDEX idx_producthistory_changed_date ON productmanagement_dbo.producthistory(changed_date);
CREATE INDEX idx_producthistory_action_type ON productmanagement_dbo.producthistory(action_type);

-- Add comments
COMMENT ON TABLE productmanagement_dbo.producthistory IS 'Audit trail for product changes';
COMMENT ON COLUMN productmanagement_dbo.producthistory.action_type IS 'Type of action: INSERT, UPDATE, DELETE';
```

### 5.3 Product Stats Table
```sql
CREATE TABLE productmanagement_dbo.productstats (
    stat_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    stat_date DATE NOT NULL DEFAULT CURRENT_DATE,
    views_count INTEGER NOT NULL DEFAULT 0,
    sales_count INTEGER NOT NULL DEFAULT 0,
    revenue NUMERIC(18, 2) NOT NULL DEFAULT 0.00,
    average_rating NUMERIC(3, 2),
    review_count INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT fk_productstats_product FOREIGN KEY (product_id) 
        REFERENCES productmanagement_dbo.products(id) 
        ON DELETE CASCADE,
    CONSTRAINT chk_productstats_views CHECK (views_count >= 0),
    CONSTRAINT chk_productstats_sales CHECK (sales_count >= 0),
    CONSTRAINT chk_productstats_revenue CHECK (revenue >= 0),
    CONSTRAINT chk_productstats_rating CHECK (average_rating IS NULL OR (average_rating >= 0 AND average_rating <= 5)),
    CONSTRAINT uq_productstats_product_date UNIQUE (product_id, stat_date)
);

-- Create indexes
CREATE INDEX idx_productstats_product_id ON productmanagement_dbo.productstats(product_id);
CREATE INDEX idx_productstats_stat_date ON productmanagement_dbo.productstats(stat_date);

-- Add comments
COMMENT ON TABLE productmanagement_dbo.productstats IS 'Daily statistics for products';
COMMENT ON COLUMN productmanagement_dbo.productstats.average_rating IS 'Average rating (0-5 scale)';
```

## 6. Create Application User (Recommended for Security)

```sql
-- Create dedicated application user
CREATE USER adocore_app WITH PASSWORD 'CHANGE_THIS_PASSWORD';

-- Grant connection to database
GRANT CONNECT ON DATABASE productmanagement TO adocore_app;

-- Grant schema usage
GRANT USAGE ON SCHEMA productmanagement_dbo TO adocore_app;

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO adocore_app;

-- Grant sequence permissions (for SERIAL columns)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO adocore_app;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO adocore_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA productmanagement_dbo 
    GRANT USAGE, SELECT ON SEQUENCES TO adocore_app;
```

## 7. Insert Sample Data

```sql
-- Insert sample products
INSERT INTO productmanagement_dbo.products (name, description, price, quantity, category, created_by) 
VALUES 
    ('Laptop Pro 15', 'High-performance laptop with 15-inch display', 1299.99, 50, 'Electronics', 'system'),
    ('Wireless Mouse', 'Ergonomic wireless mouse with USB receiver', 29.99, 200, 'Electronics', 'system'),
    ('Office Chair', 'Comfortable ergonomic office chair', 249.99, 75, 'Furniture', 'system'),
    ('USB-C Cable', '6-foot USB-C charging cable', 19.99, 500, 'Electronics', 'system'),
    ('Standing Desk', 'Adjustable height standing desk', 599.99, 30, 'Furniture', 'system'),
    ('Mechanical Keyboard', 'RGB mechanical gaming keyboard', 149.99, 100, 'Electronics', 'system'),
    ('Monitor 27"', '4K Ultra HD 27-inch monitor', 449.99, 60, 'Electronics', 'system'),
    ('Desk Lamp', 'LED desk lamp with adjustable brightness', 39.99, 150, 'Furniture', 'system'),
    ('Webcam HD', '1080p HD webcam with microphone', 79.99, 120, 'Electronics', 'system'),
    ('Notebook Pack', 'Pack of 5 professional notebooks', 24.99, 300, 'Office Supplies', 'system');

-- Insert sample product stats
INSERT INTO productmanagement_dbo.productstats (product_id, stat_date, views_count, sales_count, revenue, average_rating, review_count)
SELECT 
    id,
    CURRENT_DATE - INTERVAL '1 day',
    FLOOR(RANDOM() * 1000 + 100)::INTEGER,
    FLOOR(RANDOM() * 50 + 1)::INTEGER,
    price * FLOOR(RANDOM() * 50 + 1)::INTEGER,
    ROUND((RANDOM() * 2 + 3)::NUMERIC, 2),
    FLOOR(RANDOM() * 100 + 10)::INTEGER
FROM productmanagement_dbo.products;

-- Insert sample product history
INSERT INTO productmanagement_dbo.producthistory (product_id, action_type, new_value, changed_by)
SELECT 
    id,
    'INSERT',
    'Initial product creation',
    'system'
FROM productmanagement_dbo.products;
```

## 8. Verify Installation

```sql
-- Check tables
\dt productmanagement_dbo.*

-- Check sequences
\ds productmanagement_dbo.*

-- Verify data
SELECT COUNT(*) as product_count FROM productmanagement_dbo.products;
SELECT COUNT(*) as stats_count FROM productmanagement_dbo.productstats;
SELECT COUNT(*) as history_count FROM productmanagement_dbo.producthistory;

-- Test a sample query similar to application queries
SELECT 
    id,
    name,
    price,
    quantity,
    category,
    AVG(price) OVER (PARTITION BY category) as avg_category_price,
    COUNT(*) OVER (PARTITION BY category) as products_in_category
FROM productmanagement_dbo.products
WHERE is_active = true
ORDER BY category, name;
```

## 9. Update Application Connection String

After database setup, update the connection string in your application:

### Option 1: User Secrets (Development)
```bash
cd /path/to/sourceCode
dotnet user-secrets set "ConnectionStrings:DevConnection" "Host=localhost;Port=5432;Database=productmanagement;Username=adocore_app;Password=YOUR_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20;Timeout=30"
```

### Option 2: Environment Variable
```bash
export ConnectionStrings__DevConnection="Host=localhost;Port=5432;Database=productmanagement;Username=adocore_app;Password=YOUR_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20;Timeout=30"
```

### Option 3: Direct Update (Not Recommended for Production)
Edit `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=adocore_app;Password=YOUR_PASSWORD;Pooling=true;MinPoolSize=1;MaxPoolSize=20;Timeout=30"
  }
}
```

## 10. Test Application Connectivity

```bash
# Navigate to source code directory
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode

# Build the application
dotnet build

# Run the application
dotnet run

# Follow the interactive menu to test database operations:
# 1. Get All Products - Tests SELECT queries
# 2. Get Product by ID - Tests parameterized queries
# 3. Insert Product - Tests INSERT and transactions
# 4. Update Product - Tests UPDATE and transactions
# 5. Delete Product - Tests DELETE and transactions
```

## 11. Common Issues and Troubleshooting

### Issue: Connection refused
**Solution**: Ensure PostgreSQL is running
```bash
# Linux
sudo systemctl status postgresql
sudo systemctl start postgresql

# Docker
docker ps
docker start postgres-adocore

# macOS
brew services list
brew services start postgresql@14
```

### Issue: Authentication failed
**Solution**: Check credentials and pg_hba.conf
```bash
# Edit pg_hba.conf (Linux location example)
sudo nano /etc/postgresql/14/main/pg_hba.conf

# Add or modify line:
host    all             all             127.0.0.1/32            md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Issue: Database does not exist
**Solution**: Create database using psql
```bash
sudo -u postgres psql -c "CREATE DATABASE productmanagement;"
```

### Issue: Permission denied for schema
**Solution**: Grant necessary permissions
```sql
GRANT USAGE ON SCHEMA productmanagement_dbo TO adocore_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA productmanagement_dbo TO adocore_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO adocore_app;
```

### Issue: SSL connection required
**Solution**: Add SSL parameters to connection string
```
SslMode=Require
```

## 12. Performance Optimization

### Enable Query Statistics
```sql
-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View slow queries
SELECT 
    mean_exec_time,
    calls,
    query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### Analyze Tables
```sql
-- Update statistics for query planner
ANALYZE productmanagement_dbo.products;
ANALYZE productmanagement_dbo.producthistory;
ANALYZE productmanagement_dbo.productstats;

-- Or analyze all tables
ANALYZE;
```

### Vacuum Tables Regularly
```sql
-- Reclaim storage and update statistics
VACUUM ANALYZE productmanagement_dbo.products;
VACUUM ANALYZE productmanagement_dbo.producthistory;
VACUUM ANALYZE productmanagement_dbo.productstats;
```

## 13. Backup and Restore

### Create Backup
```bash
# Backup entire database
pg_dump -U postgres -d productmanagement -F c -f productmanagement_backup.dump

# Backup schema only
pg_dump -U postgres -d productmanagement -s -f productmanagement_schema.sql

# Backup data only
pg_dump -U postgres -d productmanagement -a -f productmanagement_data.sql
```

### Restore Backup
```bash
# Restore from dump file
pg_restore -U postgres -d productmanagement -c productmanagement_backup.dump

# Restore from SQL file
psql -U postgres -d productmanagement -f productmanagement_schema.sql
```

## 14. Monitoring

### Check Active Connections
```sql
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query
FROM pg_stat_activity
WHERE datname = 'productmanagement';
```

### Check Table Sizes
```sql
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'productmanagement_dbo'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Check Index Usage
```sql
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'productmanagement_dbo'
ORDER BY idx_scan DESC;
```

## 15. Next Steps

After completing this setup:

1. ✅ Verify database connectivity from the application
2. ✅ Test all CRUD operations (Create, Read, Update, Delete)
3. ✅ Verify transaction handling and rollback functionality
4. ✅ Run application unit tests against the database
5. ✅ Review and implement security recommendations from SECURITY_RECOMMENDATIONS.md
6. ✅ Set up database backups and monitoring
7. ✅ Configure connection pooling for optimal performance
8. ✅ Plan for production deployment with proper credentials management

## 16. References

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Installation Guide](https://www.postgresql.org/download/)
- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/security.html)

---

**Document Version**: 1.0  
**Last Updated**: January 21, 2026  
**Compatible with**: PostgreSQL 12+, AdoCore Application v1.0
