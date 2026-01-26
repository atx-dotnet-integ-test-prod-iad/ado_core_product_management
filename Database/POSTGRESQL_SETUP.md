# PostgreSQL Database Setup Guide

## Prerequisites
- PostgreSQL 12 or higher installed and running
- PostgreSQL client (psql) or pgAdmin installed
- Admin/superuser access to PostgreSQL

## Quick Setup Instructions

### 1. Install PostgreSQL (if not already installed)

#### On Windows:
```bash
# Download from https://www.postgresql.org/download/windows/
# Or use chocolatey:
choco install postgresql
```

#### On macOS:
```bash
brew install postgresql
brew services start postgresql
```

#### On Linux (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. Create Database and User

Connect to PostgreSQL as superuser:
```bash
psql -U postgres
```

Then run:
```sql
-- Create the database
CREATE DATABASE "ProductManagement";

-- Create user (if different from default)
-- CREATE USER myuser WITH PASSWORD 'mypassword';
-- GRANT ALL PRIVILEGES ON DATABASE "ProductManagement" TO myuser;
```

### 3. Run the Setup Script

#### Option A: Using psql command line
```bash
psql -U postgres -d ProductManagement -f Database/Scripts/01_InitialSetup_PostgreSQL.sql
```

#### Option B: Using pgAdmin
1. Open pgAdmin
2. Connect to your PostgreSQL server
3. Right-click on the "ProductManagement" database
4. Select "Query Tool"
5. Open the file `Database/Scripts/01_InitialSetup_PostgreSQL.sql`
6. Execute the script

### 4. Verify Setup

Connect to the database and verify:
```bash
psql -U postgres -d ProductManagement
```

```sql
-- Check tables
\dt

-- Verify sample data
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM suppliers;

-- Should return 18, 20, and 8 rows respectively
```

### 5. Update Connection String (if needed)

The default connection string in `appsettings.json` is:
```json
"DevConnection": "Host=localhost;Database=ProductManagement;Port=5432;Username=postgres;Password=postgres;Pooling=true;Minimum Pool Size=1;Maximum Pool Size=20"
```

Update the following if your setup differs:
- `Host`: Change if PostgreSQL is on a different server
- `Port`: Default is 5432
- `Username`: Your PostgreSQL username
- `Password`: Your PostgreSQL password

## Database Schema

The setup script creates the following tables:

### Core Tables
- **categories**: Product categories with hierarchical structure
- **suppliers**: Supplier information
- **products**: Main product catalog
- **product_history**: Audit trail for product changes
- **product_stats**: Aggregated statistics

### Key Features
- Automatic history tracking via triggers
- Sample data (18 products, 20 categories, 8 suppliers)
- Indexes for performance
- Foreign key constraints for data integrity

## Testing the Connection

### Using the CLI Application
```bash
cd sourceCode
dotnet run
```

The application should connect and display the menu.

### Manual Testing with psql
```bash
psql -U postgres -d ProductManagement -c "SELECT * FROM products LIMIT 5;"
```

## Troubleshooting

### Connection Refused
- Ensure PostgreSQL service is running:
  - Windows: Check Services (services.msc)
  - macOS: `brew services list`
  - Linux: `sudo systemctl status postgresql`

### Authentication Failed
- Verify username/password in connection string
- Check `pg_hba.conf` for authentication method
- Default location:
  - Windows: `C:\Program Files\PostgreSQL\<version>\data\pg_hba.conf`
  - macOS: `/usr/local/var/postgres/pg_hba.conf`
  - Linux: `/etc/postgresql/<version>/main/pg_hba.conf`

### Database Does Not Exist
```bash
createdb -U postgres ProductManagement
```

### Port Already in Use
- Check if PostgreSQL is running on port 5432
- Update connection string if using different port

## Next Steps

After setting up the database:

1. **Run the Application**
   ```bash
   dotnet run
   ```

2. **Test All Operations**
   - List all products (GetAllProductsAsync)
   - Get product by ID (GetProductByIdAsync)
   - Insert new product (InsertProductAsync)
   - Update product (UpdateProductAsync)
   - Delete product (DeleteProductAsync)
   - Get products by price range (GetProductsByPriceRangeAsync)
   - Get low stock products (GetLowStockProductsAsync)

3. **Verify Transaction Handling**
   - Test rollback on error
   - Verify history tracking in product_history table
   - Check stats updates in product_stats table

4. **Performance Testing**
   - Test with larger datasets
   - Monitor query performance
   - Review execution plans if needed

## Migration Notes

This database has been migrated from Microsoft SQL Server to PostgreSQL. Key changes:

1. **Data Types**
   - `NVARCHAR` → `VARCHAR`
   - `BIT` → `BOOLEAN`
   - `DATETIME` → `TIMESTAMP`
   - `IDENTITY` → `SERIAL`

2. **Functions**
   - `GETDATE()` → `CURRENT_TIMESTAMP`
   - `SCOPE_IDENTITY()` → `RETURNING` clause
   - Stored procedures → PostgreSQL functions

3. **Triggers**
   - SQL Server triggers → PostgreSQL trigger functions

4. **Syntax**
   - Case sensitivity: PostgreSQL identifiers are lowercase by default
   - String literals: Single quotes only
   - System functions: Different naming conventions

For detailed conversion information, see:
- `converted_statements.sql` - All converted SQL statements
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `migration_final_report.json` - Complete migration report
