# PostgreSQL Database Setup Guide

This guide provides step-by-step instructions for setting up the PostgreSQL database required to complete runtime validation of the migrated application.

## Prerequisites

- PostgreSQL 12 or higher installed
- Database administrator access
- psql command-line tool or pgAdmin

## Quick Setup (Command Line)

### 1. Install PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
```

**macOS (using Homebrew):**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Windows:**
Download and install from: https://www.postgresql.org/download/windows/

### 2. Create Database and User

```bash
# Switch to postgres user
sudo -u postgres psql

# In psql, run:
CREATE DATABASE "ProductManagement";
CREATE USER postgres WITH PASSWORD 'postgres';
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO postgres;

# Connect to the database
\c ProductManagement

# Grant schema privileges
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

\q
```

### 3. Run the Schema Script

```bash
# From the project directory
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### 4. Verify the Setup

```bash
psql -U postgres -d ProductManagement

# In psql, verify tables:
\dt

# Should show:
# categories
# products
# product_history
# product_stats
# suppliers

# Check sample data:
SELECT COUNT(*) FROM products;
# Should return 18

\q
```

## Alternative Setup (pgAdmin)

### 1. Launch pgAdmin

- Open pgAdmin 4
- Connect to your PostgreSQL server

### 2. Create Database

- Right-click on "Databases"
- Select "Create" > "Database"
- Name: `ProductManagement`
- Owner: `postgres`
- Click "Save"

### 3. Execute Schema Script

- Expand the "ProductManagement" database
- Click on "Tools" > "Query Tool"
- Open the file: `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
- Click "Execute" (F5)

### 4. Verify Tables

- Expand "Schemas" > "public" > "Tables"
- You should see: categories, products, product_history, product_stats, suppliers

## Connection String

The application uses this connection string (already configured in `appsettings.json`):

```json
"Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432"
```

**For Production:** Update the connection string with appropriate credentials:
- Change `Username` and `Password` to secure values
- Change `Host` if not running locally
- Change `Port` if using non-default port

## Running the Application

After database setup, test the application:

```bash
# Build the application
dotnet build

# Run the application
dotnet run
```

## Validation Checklist

Once the database is set up, verify:

- [ ] Database "ProductManagement" exists
- [ ] All 5 tables created (categories, suppliers, products, product_history, product_stats)
- [ ] Sample data loaded (18 products, 20 categories, 8 suppliers)
- [ ] Application compiles successfully
- [ ] Application connects to database without errors
- [ ] SELECT operations return data
- [ ] INSERT operations create new records
- [ ] UPDATE operations modify records
- [ ] DELETE operations remove records
- [ ] Transactions commit on success
- [ ] Transactions rollback on error

## Common Issues

### Connection Refused

**Problem:** Application cannot connect to PostgreSQL
**Solution:** 
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Start if not running
sudo systemctl start postgresql
```

### Authentication Failed

**Problem:** Password authentication fails
**Solution:**
Edit `pg_hba.conf`:
```bash
# Find the file
sudo find / -name pg_hba.conf

# Edit and change 'peer' to 'md5' for local connections
sudo nano /etc/postgresql/14/main/pg_hba.conf

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Permission Denied

**Problem:** User lacks permissions
**Solution:**
```sql
-- Grant all privileges
\c ProductManagement
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
```

## Testing Database Operations

Use the following SQL to manually test operations:

```sql
-- Test SELECT
SELECT * FROM products LIMIT 5;

-- Test INSERT
INSERT INTO products (name, description, price, stock_quantity)
VALUES ('Test Product', 'Test Description', 99.99, 10);

-- Test UPDATE
UPDATE products 
SET price = 109.99 
WHERE name = 'Test Product';

-- Test DELETE
DELETE FROM products 
WHERE name = 'Test Product';

-- Test Transaction
BEGIN;
INSERT INTO products (name, description, price, stock_quantity)
VALUES ('Transaction Test', 'Test', 50.00, 5);
ROLLBACK;  -- Should not persist
```

## Next Steps

After successful database setup:

1. Run the application: `dotnet run`
2. Test each repository method
3. Verify transaction handling
4. Monitor for any runtime errors
5. Review logs for connection issues

## Support

For PostgreSQL documentation:
- Official docs: https://www.postgresql.org/docs/
- Npgsql docs: https://www.npgsql.org/doc/

For migration issues:
- Review `conversion_log.json` for SQL conversion details
- Review `sql_equivalency_validation_report.json` for equivalency status
- Review `final_migration_report.json` for overall migration status
