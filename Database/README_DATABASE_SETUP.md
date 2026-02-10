# PostgreSQL Database Setup Guide

## Overview
This guide provides instructions for setting up the PostgreSQL database required to run and test the migrated ADO.NET application.

## Prerequisites
- PostgreSQL 12 or higher installed
- Access to PostgreSQL server (localhost or remote)
- PostgreSQL client tools (psql) or GUI tool (pgAdmin, DBeaver, etc.)

## Quick Setup Instructions

### Option 1: Using psql Command Line

1. **Create the database** (as PostgreSQL superuser):
```bash
psql -U postgres
CREATE DATABASE "ProductManagement";
\q
```

2. **Run the setup script**:
```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_PostgreSQL_Setup.sql
```

### Option 2: Using Docker (Recommended for Testing)

1. **Start PostgreSQL in Docker**:
```bash
docker run --name postgres-product-db \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:14
```

2. **Wait a few seconds for PostgreSQL to start, then run the setup script**:
```bash
docker exec -i postgres-product-db psql -U postgres -d ProductManagement < Database/Scripts/01_PostgreSQL_Setup.sql
```

3. **To stop the container later**:
```bash
docker stop postgres-product-db
docker rm postgres-product-db
```

### Option 3: Using pgAdmin

1. Open pgAdmin and connect to your PostgreSQL server
2. Create a new database named `ProductManagement`
3. Open the Query Tool for the ProductManagement database
4. Load and execute `Database/Scripts/01_PostgreSQL_Setup.sql`

## Verify Setup

After running the setup script, verify the installation:

```sql
-- Connect to ProductManagement database
\c ProductManagement

-- Verify tables were created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Should return:
-- categories
-- productstats
-- products
-- producthistory
-- suppliers

-- Verify sample data was loaded
SELECT COUNT(*) as product_count FROM products;
-- Should return: 18

SELECT COUNT(*) as category_count FROM categories;
-- Should return: 20

SELECT COUNT(*) as supplier_count FROM suppliers;
-- Should return: 8
```

## Connection String Configuration

Update the connection string in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=postgres;Pooling=true"
  }
}
```

**Important**: Change the username and password to match your PostgreSQL setup!

## Testing the Application

1. **Build the application**:
```bash
dotnet build
```

2. **Run the application**:
```bash
dotnet run
```

3. **Test database operations**:
The application should now be able to:
- Connect to PostgreSQL database
- Execute SELECT queries (GetAllProducts, GetProductById, etc.)
- Execute INSERT operations (InsertProduct)
- Execute UPDATE operations (UpdateProduct)
- Execute DELETE operations (DeleteProduct)
- Handle transactions correctly

## Database Schema Overview

### Tables Created:
- **Categories**: Product categories with hierarchical structure
- **Suppliers**: Product suppliers
- **Products**: Main product table with foreign keys to Categories and Suppliers
- **ProductHistory**: Audit trail of product changes (via trigger)
- **ProductStats**: Aggregate statistics about products

### Sample Data:
- 20 categories (Electronics, Computers, Gaming, etc.)
- 8 suppliers from various countries
- 18 products across different categories
- Initialized statistics record

### Database Features:
- **Triggers**: Automatic history tracking on INSERT/UPDATE/DELETE
- **Functions**: PostgreSQL equivalents of SQL Server stored procedures
- **Indexes**: Optimized for common query patterns
- **Foreign Keys**: Referential integrity enforcement

## Troubleshooting

### Connection Issues

**Error**: "password authentication failed for user"
- **Solution**: Verify the username and password in appsettings.json match your PostgreSQL setup

**Error**: "database 'ProductManagement' does not exist"
- **Solution**: Run `CREATE DATABASE "ProductManagement";` before running the setup script

**Error**: "could not connect to server"
- **Solution**: 
  - Verify PostgreSQL is running: `systemctl status postgresql` (Linux) or check Services (Windows)
  - Verify the port (default: 5432) in connection string
  - Check firewall settings

### Schema Issues

**Error**: "relation already exists"
- **Solution**: The setup script includes DROP TABLE statements, but if you need a clean slate:
```sql
DROP DATABASE "ProductManagement";
CREATE DATABASE "ProductManagement";
-- Then re-run the setup script
```

## Migration Validation

To validate that all exit criteria are met:

1. ✅ **Database connectivity**: Run `dotnet run` - application should start without connection errors
2. ✅ **SELECT operations**: GetAllProducts() should return 18 products
3. ✅ **INSERT operations**: Test adding a new product
4. ✅ **UPDATE operations**: Test updating a product's price/stock
5. ✅ **DELETE operations**: Test deleting a product
6. ✅ **Transaction atomicity**: Transactions should commit or rollback correctly

## Additional Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Npgsql Documentation: https://www.npgsql.org/doc/
- ADO.NET with PostgreSQL: https://www.npgsql.org/doc/basic-usage.html

## Support

If you encounter issues not covered in this guide:
1. Check the PostgreSQL logs for detailed error messages
2. Verify all connection string parameters
3. Ensure PostgreSQL version is 12 or higher
4. Check that the Npgsql package (version 8.0.5) is properly installed
