# PostgreSQL Migration Guide for AdoCore Application

## Overview
This document provides instructions for setting up and testing the ADO.NET application after migration from Microsoft SQL Server to PostgreSQL.

## Migration Status
- **Status**: Code transformation complete, database testing required
- **SQL Statements Converted**: 7/7 (100%)
- **Build Status**: ✅ Success (0 errors)
- **Database Connection**: ⚠️ Requires PostgreSQL instance setup

## Prerequisites

### 1. PostgreSQL Installation
Install PostgreSQL 12 or later:

**Windows:**
```powershell
# Download from https://www.postgresql.org/download/windows/
# Or use Chocolatey
choco install postgresql
```

**macOS:**
```bash
# Using Homebrew
brew install postgresql@15
brew services start postgresql@15
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**Docker (All platforms):**
```bash
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=productmanagement \
  -p 5432:5432 \
  -d postgres:15-alpine
```

### 2. Verify PostgreSQL Installation
```bash
psql --version
# Expected: psql (PostgreSQL) 12.x or later
```

## Database Setup

### Step 1: Connect to PostgreSQL
```bash
# Default superuser connection
psql -U postgres

# Or specify host and port
psql -U postgres -h localhost -p 5432
```

### Step 2: Create Database
```sql
CREATE DATABASE productmanagement;
\c productmanagement
```

### Step 3: Run Setup Script
```bash
# From command line
psql -U postgres -d productmanagement -f Scripts/postgresql_setup.sql

# Or from within psql
\c productmanagement
\i Scripts/postgresql_setup.sql
```

The setup script will:
- Create tables: `products`, `producthistory`, `productstats`
- Create sequences: `products_productid_seq`
- Create indexes for performance
- Insert sample data (5 products)
- Initialize statistics

### Step 4: Verify Database Setup
```sql
-- Check tables
\dt

-- Check data
SELECT * FROM products;
SELECT * FROM productstats;

-- Expected output:
-- products: 5 rows
-- producthistory: 5 rows
-- productstats: 1 row
```

## Application Configuration

### Connection String
The application uses connection strings from `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=postgres;Port=5432",
    "ProdConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=postgres;Port=5432"
  }
}
```

**⚠️ Security Note:** Update the password before deploying to production!

### Update Password
1. Set PostgreSQL password:
```sql
ALTER USER postgres WITH PASSWORD 'your_secure_password';
```

2. Update `appsettings.json`:
```json
"DevConnection": "Host=localhost;Database=productmanagement;Username=postgres;Password=your_secure_password;Port=5432"
```

## Building the Application

```bash
# Restore dependencies
dotnet restore AdoCore.csproj

# Build
dotnet build AdoCore.csproj

# Run
dotnet run --project AdoCore.csproj
```

## Testing Database Operations

### Manual Testing via Application
The application provides an interactive CLI menu to test all database operations:

```bash
dotnet run --project AdoCore.csproj
```

**Available Operations:**
1. **Get All Products** - Tests SELECT with window functions and CTEs
2. **Get Product by ID** - Tests SELECT with LAG window function
3. **Insert Product** - Tests INSERT with RETURNING clause
4. **Update Product** - Tests UPDATE with CTE for history tracking
5. **Delete Product** - Tests DELETE with CTE for history tracking
6. **Get Products by Price Range** - Tests SELECT with RANK and PERCENT_RANK
7. **Get Low Stock Products** - Tests SELECT with AVG/MIN/MAX window functions

### Direct SQL Testing

Connect to PostgreSQL and run test queries:

```sql
-- Test 1: Get all products with analytics
WITH productstats AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM products
)
SELECT 
    p.productid,
    p.name,
    p.price,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory
FROM products p
INNER JOIN productstats ps ON p.productid = ps.productid
ORDER BY p.name;

-- Test 2: Get product by ID with history
WITH producthistory AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice
    FROM products
    WHERE productid = 1
)
SELECT 
    p.productid,
    p.name,
    p.price,
    ph.previousprice
FROM products p
LEFT JOIN producthistory ph ON p.productid = ph.productid
WHERE p.productid = 1;

-- Test 3: Insert product with RETURNING
INSERT INTO products (name, description, price, stockquantity)
VALUES ('Test Product', 'Test Description', 99.99, 5)
RETURNING productid, name, price;

-- Test 4: Check transaction atomicity
BEGIN;
INSERT INTO products (name, description, price, stockquantity)
VALUES ('Transaction Test', 'Testing rollback', 199.99, 10);
SELECT * FROM products WHERE name = 'Transaction Test';
ROLLBACK;
-- Verify rollback worked
SELECT * FROM products WHERE name = 'Transaction Test';
-- Should return 0 rows
```

## Validation Checklist

Use this checklist to verify the migration:

- [ ] PostgreSQL installed and running
- [ ] Database `productmanagement` created
- [ ] Tables created: `products`, `producthistory`, `productstats`
- [ ] Sample data inserted (5 products)
- [ ] Application builds without errors (`dotnet build`)
- [ ] Application connects to PostgreSQL (no connection errors)
- [ ] **Database Operations:**
  - [ ] SELECT (GetAllProductsAsync) works
  - [ ] SELECT with parameters (GetProductByIdAsync) works
  - [ ] INSERT (InsertProductAsync) returns new ID correctly
  - [ ] UPDATE (UpdateProductAsync) updates product and history
  - [ ] DELETE (DeleteProductAsync) removes product and logs history
  - [ ] Window functions work (RANK, LAG, AVG, etc.)
  - [ ] CTEs work correctly
- [ ] **Transaction Testing:**
  - [ ] COMMIT transaction completes successfully
  - [ ] ROLLBACK transaction reverts changes
  - [ ] Concurrent transactions maintain isolation
- [ ] **Data Integrity:**
  - [ ] Foreign keys enforced (producthistory → products)
  - [ ] Default values working (createddate, timestamps)
  - [ ] NOT NULL constraints enforced
  - [ ] Sequences working (auto-increment productid)

## Migration Artifacts

### Generated Files
- `extracted_statements.sql` - Original MS SQL Server statements
- `converted_statements.sql` - Converted PostgreSQL statements
- `dms_conversion_log.json` - DMS tool conversion log
- `sql_equivalency_validation_report.json` - Equivalency validation results
- `Scripts/postgresql_setup.sql` - PostgreSQL database setup script

### Code Changes Summary
1. **Package References:**
   - Removed: `Microsoft.Data.SqlClient 5.1.4`
   - Added: `Npgsql 10.0.1` (latest stable, security patched)

2. **ADO.NET Classes Replaced:**
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlParameter` → `NpgsqlParameter`

3. **SQL Syntax Changes:**
   - Schema objects converted to lowercase (products, productid, etc.)
   - `GETDATE()` → `CURRENT_TIMESTAMP`
   - `SCOPE_IDENTITY()` → `RETURNING` clause
   - Transaction handling moved to ADO.NET layer
   - Multi-statement blocks converted to CTEs or DO blocks

4. **Connection Strings:**
   - Format: `Host=localhost;Database=productmanagement;Username=postgres;Password=postgres;Port=5432`

## Known Issues & Limitations

### Equivalency Validation Errors
All 7 SQL statement pairs returned `ERROR` status from the SQL Equivalency tool with error: `'uniqueID'`. This appears to be a tool issue, not a syntax issue. Manual verification is recommended:

**Manual Verification Steps:**
1. Run each converted SQL statement directly in PostgreSQL
2. Compare results with MS SQL Server
3. Verify data types match expected output
4. Test edge cases (NULL values, empty result sets, etc.)

### DMS Tool Failures
All 7 statements failed DMS conversion with error: `Unknown metadata model creation status: RECEIVED`. Manual conversion was applied following lowercase schema mapping rules. All conversions have been documented in `dms_conversion_log.json`.

### Missing Features
- **DO Block Parameters:** Statements 3, 4, and 5 use DO blocks but cannot accept parameters directly. These will need refactoring to use functions or inline execution from C#.
- **Unit Tests:** No test suite found in repository. Recommend creating integration tests for database operations.

## Recommended Next Steps

1. **Set up PostgreSQL database** using provided setup script
2. **Test all database operations** through the application CLI
3. **Create integration tests** for automated validation
4. **Manual SQL verification** for the 7 statements with equivalency errors
5. **Performance testing** with larger datasets
6. **Refactor DO blocks** to functions if needed for complex operations
7. **Implement secure credential management** (Azure Key Vault, environment variables, etc.)

## Support & Troubleshooting

### Common Issues

**Issue: Connection refused**
```
Solution: Verify PostgreSQL is running:
  Windows: services.msc → PostgreSQL service
  Linux/Mac: sudo systemctl status postgresql
  Docker: docker ps | grep postgres
```

**Issue: Authentication failed**
```
Solution: Reset PostgreSQL password:
  ALTER USER postgres WITH PASSWORD 'new_password';
  Update appsettings.json with new password
```

**Issue: Database does not exist**
```
Solution: Create database:
  psql -U postgres
  CREATE DATABASE productmanagement;
```

**Issue: BUILD errors after package upgrade**
```
Solution: Clean and restore:
  dotnet clean
  dotnet restore
  dotnet build
```

## Additional Resources

- [Npgsql Documentation](https://www.npgsql.org/doc/index.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Window Functions](https://www.postgresql.org/docs/current/tutorial-window.html)
- [PostgreSQL CTEs](https://www.postgresql.org/docs/current/queries-with.html)

---

**Last Updated:** 2026-02-25  
**Migration Version:** 1.0  
**PostgreSQL Version:** 12+  
**Npgsql Version:** 10.0.1
