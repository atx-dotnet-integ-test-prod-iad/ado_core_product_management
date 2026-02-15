# PostgreSQL Deployment Guide

## Overview
This guide provides instructions for deploying and testing the migrated ADO.NET application with PostgreSQL.

## Prerequisites
- PostgreSQL 12 or higher installed and running
- psql command-line tool or pgAdmin
- .NET 9.0 SDK installed

## Database Setup

### Step 1: Create PostgreSQL Database and User

Connect to PostgreSQL as superuser and run:

```sql
-- Create database
CREATE DATABASE "ProductManagement";

-- Create user (if needed)
CREATE USER postgres WITH PASSWORD 'postgres';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO postgres;
```

### Step 2: Initialize Database Schema

Connect to the ProductManagement database:

```bash
psql -U postgres -d ProductManagement
```

Then execute the schema setup script:

```bash
\i Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

Or using psql from command line:

```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

### Step 3: Verify Database Setup

Check that all tables were created:

```sql
\dt
```

Expected tables:
- categories
- suppliers
- products
- producthistory
- productstats

Check sample data:

```sql
SELECT COUNT(*) FROM Products;
SELECT COUNT(*) FROM Categories;
SELECT COUNT(*) FROM Suppliers;
```

## Connection String Configuration

### Development Environment

The default connection string in `appsettings.json` is:

```json
"DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres;Port=5432;Pooling=true"
```

### Production Environment

For production, update the connection string with:
1. Secure credentials (use environment variables or secrets manager)
2. Appropriate host/server address
3. SSL/TLS settings if required

Example production connection string:

```
Host=prod-server.example.com;Database=ProductManagement;Username=prod_user;Password=${DB_PASSWORD};Port=5432;Pooling=true;SSL Mode=Require
```

**Security Best Practices:**
- Never commit production credentials to source control
- Use environment variables: `${DB_PASSWORD}` or Azure Key Vault / AWS Secrets Manager
- Enable SSL/TLS for production connections
- Use principle of least privilege for database users

## Building the Application

```bash
dotnet build
```

Expected output: Build succeeded with 0 errors

## Running the Application

```bash
dotnet run
```

The application will:
1. Connect to PostgreSQL using the DevConnection string
2. Execute various database operations
3. Display results in the console

## Testing Database Operations

### Manual Testing via psql

Test the converted SQL statements:

1. **Test SELECT with CTE:**
```sql
WITH product_summary AS (
    SELECT CategoryId, COUNT(*) as ProductCount, AVG(Price) as AvgPrice
    FROM Products
    GROUP BY CategoryId
)
SELECT c.Name, ps.ProductCount, ps.AvgPrice
FROM Categories c
INNER JOIN product_summary ps ON c.CategoryId = ps.CategoryId
ORDER BY ps.ProductCount DESC;
```

2. **Test INSERT with RETURNING:**
```sql
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ('Test Product', 'Test Description', 99.99, 100)
RETURNING ProductId, Name, CreatedDate;
```

3. **Test UPDATE:**
```sql
UPDATE Products
SET Price = Price * 1.1, ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = 1
RETURNING ProductId, Name, Price;
```

4. **Test Transaction:**
```sql
BEGIN;

WITH old_values AS (
    SELECT ProductId, Price, StockQuantity
    FROM Products
    WHERE ProductId = 1
)
UPDATE Products
SET StockQuantity = StockQuantity - 5,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = 1;

SELECT * FROM Products WHERE ProductId = 1;

COMMIT;
```

## Verifying Migration Success

### Checklist:

- [ ] PostgreSQL database created and accessible
- [ ] All tables created successfully (5 tables)
- [ ] Sample data loaded (18+ products, 20 categories, 8 suppliers)
- [ ] Application builds without errors
- [ ] Application connects to PostgreSQL successfully
- [ ] SELECT operations return correct results
- [ ] INSERT operations create new records with auto-generated IDs
- [ ] UPDATE operations modify records correctly
- [ ] DELETE operations remove records and trigger history
- [ ] Transactions maintain atomicity (commit/rollback work correctly)
- [ ] Triggers fire correctly (ProductHistory entries created)

## Common Issues and Solutions

### Issue: Connection refused
**Solution:** Ensure PostgreSQL is running:
```bash
sudo systemctl status postgresql
sudo systemctl start postgresql
```

### Issue: Authentication failed
**Solution:** Check pg_hba.conf for authentication settings:
```bash
sudo nano /etc/postgresql/14/main/pg_hba.conf
```
Add/modify line:
```
host    all    postgres    127.0.0.1/32    md5
```
Reload configuration:
```bash
sudo systemctl reload postgresql
```

### Issue: Database does not exist
**Solution:** Create database manually:
```bash
createdb -U postgres ProductManagement
```

### Issue: Permission denied
**Solution:** Grant necessary privileges:
```sql
GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
```

## Migration Artifacts

The following files document the complete migration:

1. **extracted_statements.sql** - Original SQL Server statements
2. **converted_statements.sql** - Converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Equivalency validation results
4. **final_migration_report.md** - Comprehensive migration report

## Next Steps

1. Deploy PostgreSQL database using the provided script
2. Test all database operations manually
3. Run application and verify functionality
4. Perform integration testing with realistic data
5. Update production connection strings with secure credentials
6. Deploy to production environment

## Support

For issues with:
- **PostgreSQL setup:** Refer to PostgreSQL documentation
- **Migration artifacts:** Review final_migration_report.md
- **SQL equivalency:** Check sql_equivalency_validation_report.json
- **.NET build issues:** Run `dotnet build -v detailed` for diagnostics
