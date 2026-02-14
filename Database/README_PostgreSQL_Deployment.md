# PostgreSQL Database Deployment Guide

## Overview
This guide provides instructions for deploying the PostgreSQL database schema required for the AdoCore application.

## Prerequisites
1. PostgreSQL 12 or higher installed
2. PostgreSQL client tools (psql) available
3. Database credentials with CREATE DATABASE and CREATE TABLE permissions

## Database Schema
The database includes the following tables:
- **categories**: Product categories with hierarchical structure
- **suppliers**: Supplier information
- **products**: Product catalog with pricing and inventory
- **product_history**: Audit trail for product changes
- **product_stats**: Aggregated statistics for products

## Deployment Steps

### Option 1: Using psql Command Line

1. **Connect to PostgreSQL**:
   ```bash
   psql -U postgres -h localhost
   ```

2. **Create Database** (if needed):
   ```sql
   CREATE DATABASE product_management;
   \c product_management
   ```

3. **Execute Schema Script**:
   ```bash
   psql -U postgres -d product_management -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
   ```

### Option 2: Using pgAdmin

1. Open pgAdmin and connect to your PostgreSQL server
2. Right-click on "Databases" and create a new database named `product_management`
3. Open the Query Tool for the new database
4. Load and execute the `01_InitialSetup_PostgreSQL.sql` script

### Option 3: Using Docker

1. **Start PostgreSQL Container**:
   ```bash
   docker run --name postgres-adocore \
     -e POSTGRES_PASSWORD=postgres \
     -e POSTGRES_DB=product_management \
     -p 5432:5432 \
     -d postgres:14
   ```

2. **Execute Schema Script**:
   ```bash
   docker exec -i postgres-adocore psql -U postgres -d product_management < Database/Scripts/01_InitialSetup_PostgreSQL.sql
   ```

## Connection String Configuration

Update the connection string in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=product_management;Username=postgres;Password=postgres",
    "ProdConnection": "Host=your-production-host;Port=5432;Database=product_management;Username=your-user;Password=your-password"
  }
}
```

## Verification

After deployment, verify the schema:

```sql
-- Check tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Verify sample data
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;

-- Check trigger exists
SELECT trigger_name 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

Expected results:
- 5 tables created: categories, suppliers, products, product_history, product_stats
- 18 products inserted
- 20 categories inserted
- 8 suppliers inserted
- 1 trigger: trg_products_history

## Key PostgreSQL Conversions

The schema has been converted from SQL Server with the following changes:

1. **Data Types**:
   - `INT IDENTITY` → `SERIAL`
   - `NVARCHAR` → `VARCHAR`
   - `BIT` → `BOOLEAN`
   - `DATETIME` → `TIMESTAMP`

2. **Functions**:
   - `GETDATE()` → `CURRENT_TIMESTAMP`
   - `SCOPE_IDENTITY()` → `RETURNING` clause
   - `SYSTEM_USER` → `CURRENT_USER`

3. **Triggers**:
   - SQL Server triggers → PostgreSQL trigger functions
   - Different syntax for trigger creation

4. **Naming Conventions**:
   - PascalCase table/column names → snake_case (PostgreSQL standard)

## Testing Database Operations

After deployment, you can test the application:

```bash
# Build the application
dotnet build

# Run the application
dotnet run
```

The application will connect to PostgreSQL and perform database operations using the converted SQL statements.

## Troubleshooting

### Connection Issues
- Verify PostgreSQL is running: `pg_isready -h localhost -p 5432`
- Check firewall settings allow port 5432
- Verify credentials in connection string

### Schema Issues
- Drop and recreate: `DROP DATABASE product_management; CREATE DATABASE product_management;`
- Check PostgreSQL logs: `tail -f /var/log/postgresql/postgresql-*.log`

### Permission Issues
- Grant permissions: `GRANT ALL PRIVILEGES ON DATABASE product_management TO postgres;`
- Grant schema permissions: `GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;`

## Sample Queries

Test the database with these queries:

```sql
-- Get all products
SELECT * FROM products ORDER BY name;

-- Get products with category info
SELECT p.name, p.price, c.name as category_name
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id;

-- Check product history
SELECT * FROM product_history ORDER BY action_date DESC LIMIT 10;

-- View statistics
SELECT * FROM product_stats;
```

## Notes

- The stored procedures (sp_*) are included for reference only and are NOT used by the ADO.NET application
- The application uses inline SQL statements with the Npgsql driver
- All SQL statements in the application have been converted to PostgreSQL syntax
- The trigger automatically tracks INSERT, UPDATE, and DELETE operations on products
