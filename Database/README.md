# PostgreSQL Database Setup Instructions

This document provides instructions for setting up the PostgreSQL database required for the AdoCore application after migration from SQL Server.

## Prerequisites

1. **PostgreSQL Installation**
   - PostgreSQL 12 or higher installed and running
   - Default port: 5432
   - Accessible on localhost

2. **PostgreSQL Client Tools**
   - `psql` command-line tool
   - Or any PostgreSQL GUI client (pgAdmin, DBeaver, etc.)

## Database Setup Steps

### Step 1: Create the Database

Connect to PostgreSQL as superuser (usually `postgres`):

```bash
psql -U postgres
```

Create the database:

```sql
CREATE DATABASE productmanagement;
\q
```

### Step 2: Run the Schema Migration Script

Execute the PostgreSQL initialization script:

```bash
psql -U postgres -d productmanagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

This script will:
- Create the schema `productmanagement_dbo`
- Create all tables (categories, suppliers, products, producthistory, productstats)
- Set up foreign key relationships
- Create indexes for performance
- Insert sample data (20 categories, 8 suppliers, 18 products)
- Create triggers for product history tracking

### Step 3: Verify the Setup

Connect to the database and verify:

```bash
psql -U postgres -d productmanagement
```

Check the schema and tables:

```sql
-- Set the search path
SET search_path TO productmanagement_dbo;

-- List all tables
\dt

-- Verify data was loaded
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;

-- View sample products
SELECT productid, name, price, stockquantity FROM products LIMIT 5;
```

### Step 4: Configure Application Connection String

The application's connection string is configured in `appsettings.json`:

**Development Connection:**
```json
"DevConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres;Include Error Detail=true"
```

**Production Connection:**
```json
"ProdConnection": "Host=localhost;Port=5432;Database=productmanagement;Username=postgres;Password=postgres;SSL Mode=Require;Include Error Detail=true"
```

**⚠️ SECURITY WARNING:**
The current configuration uses hardcoded credentials for development purposes only. Before deploying to production:

1. Create a dedicated database user with appropriate permissions:
   ```sql
   CREATE USER adocore_app WITH PASSWORD 'secure_password_here';
   GRANT CONNECT ON DATABASE productmanagement TO adocore_app;
   GRANT USAGE ON SCHEMA productmanagement_dbo TO adocore_app;
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA productmanagement_dbo TO adocore_app;
   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA productmanagement_dbo TO adocore_app;
   ```

2. Store credentials securely using one of:
   - Environment variables
   - Azure Key Vault
   - AWS Secrets Manager
   - Docker secrets
   - Kubernetes secrets

3. Update connection string to use environment variables:
   ```csharp
   var connectionString = $"Host={Environment.GetEnvironmentVariable("DB_HOST")};" +
                         $"Port={Environment.GetEnvironmentVariable("DB_PORT")};" +
                         $"Database={Environment.GetEnvironmentVariable("DB_NAME")};" +
                         $"Username={Environment.GetEnvironmentVariable("DB_USER")};" +
                         $"Password={Environment.GetEnvironmentVariable("DB_PASSWORD")};" +
                         "SSL Mode=Require;Include Error Detail=true";
   ```

## Schema Overview

### Tables

1. **categories** - Product categories with hierarchical structure
2. **suppliers** - Supplier information
3. **products** - Main product table with pricing, inventory, and relationships
4. **producthistory** - Audit trail for product changes (automated via trigger)
5. **productstats** - Aggregate statistics about products

### Key Differences from SQL Server

| SQL Server | PostgreSQL | Notes |
|------------|-----------|-------|
| `IDENTITY(1,1)` | `SERIAL` | Auto-incrementing primary keys |
| `NVARCHAR` | `VARCHAR` | Unicode strings (PostgreSQL VARCHAR is Unicode by default) |
| `DATETIME` | `TIMESTAMP` | Date/time values |
| `DECIMAL` | `NUMERIC` | Fixed-precision numbers |
| `BIT` | `BOOLEAN` | Boolean values (0/1 becomes TRUE/FALSE) |
| `GETDATE()` | `CURRENT_TIMESTAMP` | Current timestamp function |
| `SCOPE_IDENTITY()` | `RETURNING` clause | Getting last inserted ID |
| Triggers use T-SQL | Triggers use PL/pgSQL | Different trigger syntax and language |
| `GO` statements | Not used | Batch separator not needed |
| `sys.*` queries | `information_schema.*` | System catalog differences |

## Testing Database Connection

You can test the database connection using the AdoCore application:

```bash
# Build the application
dotnet build AdoCore.sln

# Run the application
dotnet run --project AdoCore.csproj

# Or run the compiled executable
./bin/Debug/net6.0/AdoCore
```

The application should connect successfully and display the interactive menu.

## Troubleshooting

### Connection Refused
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check PostgreSQL is listening on port 5432: `netstat -an | grep 5432`
- Verify `pg_hba.conf` allows connections from localhost

### Authentication Failed
- Verify username and password are correct
- Check `pg_hba.conf` authentication method (should be `md5` or `scram-sha-256` for password auth)
- Reset postgres password if needed: `ALTER USER postgres WITH PASSWORD 'new_password';`

### Schema Not Found
- Verify the schema was created: `\dn` in psql
- Set search path: `SET search_path TO productmanagement_dbo;`
- Or use fully qualified names: `SELECT * FROM productmanagement_dbo.products;`

### Permission Denied
- Ensure the database user has appropriate grants
- Run the GRANT statements from Step 4 above

## Sample Queries

Once the database is set up, you can test with these queries:

```sql
-- Set search path
SET search_path TO productmanagement_dbo;

-- Get all products
SELECT productid, name, description, price, stockquantity, createddate, modifieddate
FROM products
ORDER BY name;

-- Get product by ID
SELECT productid, name, description, price, stockquantity, createddate, modifieddate
FROM products
WHERE productid = 1;

-- Get products by price range
SELECT productid, name, price, stockquantity
FROM products
WHERE price BETWEEN 100.00 AND 500.00
ORDER BY price;

-- Get low stock products
SELECT productid, name, stockquantity, reorderlevel
FROM products
WHERE stockquantity <= reorderlevel
ORDER BY stockquantity;

-- Insert a new product (using RETURNING clause)
INSERT INTO products (name, description, price, stockquantity)
VALUES ('Test Product', 'Test Description', 99.99, 10)
RETURNING productid, name, description, price, stockquantity, createddate;

-- Update a product
UPDATE products
SET name = 'Updated Product',
    description = 'Updated Description',
    price = 89.99,
    stockquantity = 15,
    modifieddate = CURRENT_TIMESTAMP
WHERE productid = 1;

-- Delete a product
DELETE FROM products WHERE productid = 1;
```

## Migration Validation

After setting up the database, validate the migration by:

1. **Testing all CRUD operations** - Use the application's interactive menu
2. **Verifying transaction atomicity** - Test rollback scenarios
3. **Checking data integrity** - Verify foreign key constraints work
4. **Testing trigger functionality** - Verify producthistory table captures changes
5. **Performance testing** - Compare query performance with SQL Server baseline

## Next Steps

1. ✅ Create PostgreSQL database
2. ✅ Run schema migration script
3. ✅ Configure connection strings
4. ⚠️ Implement secure credential management
5. 🔲 Run application and test all operations
6. 🔲 Perform comprehensive functional testing
7. 🔲 Create unit and integration test suite
8. 🔲 Load production data (if migrating from existing SQL Server database)
9. 🔲 Performance tuning and optimization

## Support

For issues or questions:
- Review the `final_migration_report.md` for detailed migration information
- Check `sql_equivalency_validation_report.json` for SQL statement equivalency status
- Review application logs for runtime errors
