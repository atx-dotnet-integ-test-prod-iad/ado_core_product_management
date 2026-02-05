# PostgreSQL Migration Guide

This document provides a comprehensive guide for the migration from Microsoft SQL Server to PostgreSQL, including setup instructions, validation steps, and troubleshooting.

## Migration Overview

**Migration Date**: February 2025  
**Source Database**: Microsoft SQL Server  
**Target Database**: PostgreSQL 12+  
**Application Framework**: .NET 9.0 with ADO.NET  

### What Was Migrated

1. ✅ **Database Provider**: Microsoft.Data.SqlClient → Npgsql 10.0.1
2. ✅ **ADO.NET Classes**: SqlConnection, SqlCommand, SqlDataReader → Npgsql equivalents
3. ✅ **SQL Syntax**: 7 SQL statements converted from T-SQL to PostgreSQL
4. ✅ **Connection Strings**: SQL Server format → PostgreSQL format
5. ✅ **Transaction Handling**: SQL Server transactions → PostgreSQL transactions
6. ✅ **Security**: Removed hardcoded credentials, upgraded to secure Npgsql version

### Migration Artifacts

The following files document the complete migration:

| File | Description |
|------|-------------|
| `extracted_statements.sql` | All 7 original SQL Server statements with metadata |
| `converted_statements.sql` | SQL Server to PostgreSQL conversion pairs with notes |
| `sql_equivalency_validation_report.json` | Equivalency validation results for all statement pairs |
| `dms_conversion_issues.log` | DMS tool processing log (all conversions failed, manual conversion performed) |
| `TRANSFORMATION_VALIDATION_REPORT.md` | Complete validation report against exit criteria |

## Prerequisites for Running the Migrated Application

### Required Software

1. **PostgreSQL**: Version 12 or later (15+ recommended)
   - Download: https://www.postgresql.org/download/
   - Or use Docker: `docker run --name postgres -e POSTGRES_PASSWORD=yourpassword -p 5432:5432 -d postgres:15`

2. **.NET SDK**: Version 9.0 or later
   - Download: https://dotnet.microsoft.com/download
   - Verify: `dotnet --version` (should show 9.0.x)

3. **Database Management Tool** (optional but recommended):
   - pgAdmin 4: https://www.pgadmin.org/
   - DBeaver: https://dbeaver.io/
   - Azure Data Studio with PostgreSQL extension

## Step-by-Step Setup Guide

### Step 1: Install PostgreSQL

#### Option A: Native Installation (Recommended)

**Windows**:
```powershell
# Download installer from https://www.postgresql.org/download/windows/
# Run installer and remember your postgres user password
# Default port: 5432
```

**macOS**:
```bash
# Using Homebrew
brew install postgresql@15
brew services start postgresql@15

# Create postgres user if needed
createuser -s postgres
```

**Linux (Ubuntu/Debian)**:
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Set postgres password
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'yourpassword';"
```

#### Option B: Docker (Quick Start)

```bash
# Pull and run PostgreSQL
docker run --name postgres-adocore \
  -e POSTGRES_PASSWORD=yourpassword \
  -e POSTGRES_DB=ProductManagement \
  -p 5432:5432 \
  -d postgres:15

# Verify running
docker ps | grep postgres
```

### Step 2: Create Database and Schema

Connect to PostgreSQL using your preferred tool and run:

```sql
-- Create database (skip if using Docker with POSTGRES_DB set)
CREATE DATABASE "ProductManagement";

-- Connect to the database
\c ProductManagement

-- Create Products table
CREATE TABLE "Products" (
    "ProductId" SERIAL PRIMARY KEY,
    "Name" VARCHAR(255) NOT NULL,
    "Price" DECIMAL(10, 2) NOT NULL,
    "StockQuantity" INTEGER NOT NULL,
    "Description" TEXT,
    "CreatedDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "ModifiedDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_products_name ON "Products"("Name");
CREATE INDEX idx_products_price ON "Products"("Price");

-- Optional: Create audit/history tables
CREATE TABLE "ProductHistory" (
    "HistoryId" SERIAL PRIMARY KEY,
    "ProductId" INTEGER NOT NULL,
    "ChangeDate" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "ChangeType" VARCHAR(50),
    "OldValue" TEXT,
    "NewValue" TEXT,
    FOREIGN KEY ("ProductId") REFERENCES "Products"("ProductId") ON DELETE CASCADE
);

CREATE TABLE "ProductStats" (
    "StatId" SERIAL PRIMARY KEY,
    "ProductId" INTEGER NOT NULL UNIQUE,
    "ViewCount" INTEGER DEFAULT 0,
    "LastViewed" TIMESTAMP,
    FOREIGN KEY ("ProductId") REFERENCES "Products"("ProductId") ON DELETE CASCADE
);

-- Insert sample data
INSERT INTO "Products" ("Name", "Price", "StockQuantity", "Description") VALUES
('Gaming Mouse', 49.99, 10, 'High-performance gaming mouse with RGB lighting'),
('Mechanical Keyboard', 89.99, 15, 'Cherry MX Red switches, RGB backlight'),
('USB-C Cable', 12.99, 50, '6ft USB-C to USB-C charging cable'),
('Wireless Headset', 129.99, 8, 'Noise-cancelling wireless gaming headset'),
('4K Monitor', 399.99, 5, '27-inch 4K IPS display with HDR support');

-- Verify data
SELECT * FROM "Products";
```

**Using psql command line**:
```bash
# Connect to PostgreSQL
psql -U postgres

# Paste the SQL above, or:
psql -U postgres -d ProductManagement -f database_setup.sql
```

### Step 3: Configure Application Connection String

#### Option A: Using Local Configuration File (Development)

1. Create `appsettings.Development.json` in the `sourceCode` directory:

```bash
cd sourceCode
cp appsettings.Development.json.template appsettings.Development.json
```

2. Edit `appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Database=ProductManagement;Username=postgres;Password=YOUR_REAL_PASSWORD;Port=5432;Pooling=true;Timeout=30"
  },
  "Environment": "Development"
}
```

Replace `YOUR_REAL_PASSWORD` with your actual PostgreSQL password.

**Note**: This file is in `.gitignore` and won't be committed to source control.

#### Option B: Using Environment Variables (Production)

**Linux/macOS**:
```bash
export CONNECTIONSTRINGS__DEVCONNECTION="Host=localhost;Database=ProductManagement;Username=postgres;Password=yourpassword;Port=5432;Pooling=true;Timeout=30"
```

**Windows PowerShell**:
```powershell
$env:CONNECTIONSTRINGS__DEVCONNECTION="Host=localhost;Database=ProductManagement;Username=postgres;Password=yourpassword;Port=5432;Pooling=true;Timeout=30"
```

**Windows Command Prompt**:
```cmd
set CONNECTIONSTRINGS__DEVCONNECTION=Host=localhost;Database=ProductManagement;Username=postgres;Password=yourpassword;Port=5432;Pooling=true;Timeout=30
```

### Step 4: Build and Test the Application

```bash
# Navigate to source directory
cd sourceCode

# Restore packages
dotnet restore

# Build
dotnet build --configuration Release

# Verify build success
echo $?  # Should output 0 on Linux/Mac
echo %ERRORLEVEL%  # Should output 0 on Windows
```

Expected output:
```
Build succeeded.
    10 Warning(s)  # Nullable reference warnings - non-breaking
    0 Error(s)
```

### Step 5: Run Application Tests

#### Test 1: List All Products

```bash
dotnet run -- list
```

Expected output:
```
=== All Products ===
ID: 1, Name: Gaming Mouse, Price: $49.99, Stock: 10
ID: 2, Name: Mechanical Keyboard, Price: $89.99, Stock: 15
ID: 3, Name: USB-C Cable, Price: $12.99, Stock: 50
...
```

#### Test 2: Get Product by ID

```bash
dotnet run -- get 1
```

Expected output:
```
=== Product Details ===
ID: 1
Name: Gaming Mouse
Price: $49.99
Stock: 10
Description: High-performance gaming mouse with RGB lighting
Created: 2025-02-05 ...
```

#### Test 3: Add New Product

```bash
dotnet run -- add "Test Product" 29.99 5 "Test description"
```

Expected output:
```
Product added successfully with ID: 6
```

#### Test 4: Update Product

```bash
dotnet run -- update 6 "Updated Test Product" 34.99 10 "Updated description"
```

Expected output:
```
Product updated successfully
```

#### Test 5: Update Stock

```bash
dotnet run -- stock 6 20
```

Expected output:
```
Stock quantity updated successfully
```

#### Test 6: Delete Product

```bash
dotnet run -- delete 6
```

Expected output:
```
Product deleted successfully
```

### Step 6: Interactive Mode Testing

```bash
dotnet run
```

Navigate through all menu options to verify functionality:
1. List all products
2. Get product by ID
3. Create new product
4. Update product
5. Delete product
6. Update product stock
Q. Quit

## Validation Checklist

Use this checklist to verify the migration is complete:

### Database Validation
- [ ] PostgreSQL server is running (`pg_isready`)
- [ ] ProductManagement database exists
- [ ] Products table exists with correct schema
- [ ] Sample data is inserted (5 products)
- [ ] Indexes are created
- [ ] Connection from application works

### Application Validation
- [ ] .NET 9.0 SDK is installed
- [ ] Application builds without errors (0 errors)
- [ ] Npgsql 10.0.1 is referenced (no vulnerabilities)
- [ ] No hardcoded passwords in source control
- [ ] All SQL Server references removed (SqlConnection, SqlCommand, etc.)
- [ ] All using statements changed to Npgsql

### Functionality Validation
- [ ] List products works (SELECT)
- [ ] Get product by ID works (SELECT with WHERE)
- [ ] Create product works (INSERT with RETURNING)
- [ ] Update product works (UPDATE)
- [ ] Delete product works (DELETE)
- [ ] Update stock works (UPDATE specific column)
- [ ] Transaction handling works (rollback on error)

### Security Validation
- [ ] No passwords in appsettings.json (placeholders only)
- [ ] appsettings.Development.json is in .gitignore
- [ ] Environment variables work for connection strings
- [ ] All queries use parameterized commands
- [ ] No SQL injection vulnerabilities

## SQL Statement Conversion Reference

This section documents the 7 SQL statements that were converted:

### Statement 1: List All Products with Window Functions

**Original (SQL Server)**:
```sql
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Price,
    p.StockQuantity,
    p.Description,
    p.CreatedDate,
    p.ModifiedDate,
    ps.AvgPrice,
    ps.TotalProducts
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY p.ProductId
```

**Converted (PostgreSQL)**:
```sql
WITH "ProductStats" AS (
    SELECT 
        "ProductId",
        AVG("Price") OVER() as "AvgPrice",
        COUNT(*) OVER() as "TotalProducts"
    FROM "Products"
)
SELECT 
    p."ProductId",
    p."Name",
    p."Price",
    p."StockQuantity",
    p."Description",
    p."CreatedDate",
    p."ModifiedDate",
    ps."AvgPrice",
    ps."TotalProducts"
FROM "Products" p
INNER JOIN "ProductStats" ps ON p."ProductId" = ps."ProductId"
ORDER BY p."ProductId"
```

**Key Changes**:
- Added double quotes around identifiers (optional but explicit)
- Window functions work identically in PostgreSQL

### Statement 2: Get Product by ID

**Original (SQL Server)**:
```sql
SELECT 
    ProductId,
    Name,
    Price,
    StockQuantity,
    Description,
    CreatedDate,
    ModifiedDate
FROM Products
WHERE ProductId = @productId
```

**Converted (PostgreSQL)**:
```sql
SELECT 
    "ProductId",
    "Name",
    "Price",
    "StockQuantity",
    "Description",
    "CreatedDate",
    "ModifiedDate"
FROM "Products"
WHERE "ProductId" = @productId
```

**Key Changes**:
- Added double quotes (optional)
- Parameter syntax remains @productId

### Statement 3: Insert Product with RETURNING

**Original (SQL Server)**:
```sql
INSERT INTO Products (Name, Price, StockQuantity, Description, CreatedDate, ModifiedDate)
VALUES (@name, @price, @stockQuantity, @description, GETDATE(), GETDATE());
SELECT SCOPE_IDENTITY();
```

**Converted (PostgreSQL)**:
```sql
INSERT INTO "Products" ("Name", "Price", "StockQuantity", "Description", "CreatedDate", "ModifiedDate")
VALUES (@name, @price, @stockQuantity, @description, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
RETURNING "ProductId"
```

**Key Changes**:
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `SCOPE_IDENTITY()` → `RETURNING "ProductId"`
- Single statement instead of two

### Statement 4: Update Product

**Original (SQL Server)**:
```sql
UPDATE Products
SET 
    Name = @name,
    Price = @price,
    StockQuantity = @stockQuantity,
    Description = @description,
    ModifiedDate = GETDATE()
WHERE ProductId = @productId
```

**Converted (PostgreSQL)**:
```sql
UPDATE "Products"
SET 
    "Name" = @name,
    "Price" = @price,
    "StockQuantity" = @stockQuantity,
    "Description" = @description,
    "ModifiedDate" = CURRENT_TIMESTAMP
WHERE "ProductId" = @productId
```

**Key Changes**:
- `GETDATE()` → `CURRENT_TIMESTAMP`

### Statement 5: Delete Product

**Original (SQL Server)**:
```sql
DELETE FROM Products WHERE ProductId = @productId
```

**Converted (PostgreSQL)**:
```sql
DELETE FROM "Products" WHERE "ProductId" = @productId
```

**Key Changes**:
- Minimal changes (double quotes added)

### Statement 6: Update Stock Quantity

**Original (SQL Server)**:
```sql
UPDATE Products
SET 
    StockQuantity = @stockQuantity,
    ModifiedDate = GETDATE()
WHERE ProductId = @productId
```

**Converted (PostgreSQL)**:
```sql
UPDATE "Products"
SET 
    "StockQuantity" = @stockQuantity,
    "ModifiedDate" = CURRENT_TIMESTAMP
WHERE "ProductId" = @productId
```

**Key Changes**:
- `GETDATE()` → `CURRENT_TIMESTAMP`

### Statement 7: Get Products with Filtering

**Original (SQL Server)**:
```sql
SELECT ProductId, Name, Price
FROM Products
WHERE Price > @minPrice
ORDER BY Price DESC
```

**Converted (PostgreSQL)**:
```sql
SELECT "ProductId", "Name", "Price"
FROM "Products"
WHERE "Price" > @minPrice
ORDER BY "Price" DESC
```

**Key Changes**:
- Double quotes added for clarity

## Troubleshooting Common Issues

### Issue 1: Connection Failed

**Error**: `Npgsql.NpgsqlException: Connection refused`

**Solutions**:
1. Verify PostgreSQL is running:
   ```bash
   # Linux
   sudo systemctl status postgresql
   
   # Mac
   brew services list | grep postgresql
   
   # Docker
   docker ps | grep postgres
   ```

2. Check PostgreSQL is listening:
   ```bash
   netstat -an | grep 5432
   # Or
   ss -tlnp | grep 5432
   ```

3. Verify connection details in connection string

### Issue 2: Authentication Failed

**Error**: `password authentication failed for user "postgres"`

**Solutions**:
1. Verify password in `appsettings.Development.json` or environment variable
2. Reset PostgreSQL password:
   ```bash
   sudo -u postgres psql
   ALTER USER postgres PASSWORD 'newpassword';
   ```
3. Check `pg_hba.conf` authentication method (should be `md5` or `scram-sha-256`)

### Issue 3: Database Does Not Exist

**Error**: `database "ProductManagement" does not exist`

**Solution**:
```bash
psql -U postgres -c "CREATE DATABASE \"ProductManagement\";"
```

### Issue 4: Table Does Not Exist

**Error**: `relation "Products" does not exist`

**Solution**:
Run the database setup script from Step 2 above.

### Issue 5: Build Warnings About Nullable References

**Warning**: `CS8601: Possible null reference assignment`

**Note**: These are non-breaking warnings from C# nullable reference types. The application will run correctly. To fix (optional):
- Add null checks in code
- Use nullable reference type annotations (`string?`)
- Suppress with `#nullable disable` (not recommended)

### Issue 6: Port Already in Use

**Error**: Port 5432 is already in use

**Solutions**:
1. Stop other PostgreSQL instance
2. Use different port in connection string:
   ```
   Host=localhost;Port=5433;Database=...
   ```
3. Check what's using the port:
   ```bash
   lsof -i :5432
   # Or
   netstat -ano | findstr :5432
   ```

## Performance Tuning

### PostgreSQL Configuration

For better performance, tune these PostgreSQL settings in `postgresql.conf`:

```ini
# Memory settings
shared_buffers = 256MB              # 25% of RAM for dedicated server
effective_cache_size = 1GB          # 50-75% of RAM
work_mem = 16MB                     # Per operation memory
maintenance_work_mem = 128MB        # For VACUUM, CREATE INDEX

# Connection settings
max_connections = 100               # Adjust based on application needs

# Performance settings
random_page_cost = 1.1              # For SSD storage
effective_io_concurrency = 200      # For SSD storage
```

After changes:
```bash
sudo systemctl restart postgresql
```

### Application-Side Optimization

Connection string optimization:
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=yourpassword;Port=5432;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100;Timeout=30
```

## Production Deployment Checklist

- [ ] Use production-grade PostgreSQL (AWS RDS, Azure Database, GCP Cloud SQL)
- [ ] Enable SSL/TLS (`SslMode=Require` in connection string)
- [ ] Use secrets manager (AWS Secrets Manager, Azure Key Vault)
- [ ] Create dedicated database user (not postgres superuser)
- [ ] Set up automated backups
- [ ] Configure monitoring and alerts
- [ ] Enable connection pooling with appropriate limits
- [ ] Set up read replicas for scaling (if needed)
- [ ] Configure firewall rules (database access only from app servers)
- [ ] Enable audit logging
- [ ] Regular security updates for Npgsql and PostgreSQL

## Rollback Plan

If issues occur and rollback to SQL Server is needed:

1. **Code Rollback**:
   ```bash
   git revert <migration-commit-hash>
   ```

2. **Package Rollback** in `AdoCore.csproj`:
   ```xml
   <PackageReference Include="Microsoft.Data.SqlClient" Version="5.0.0" />
   <!-- Remove: <PackageReference Include="Npgsql" Version="10.0.1" /> -->
   ```

3. **Connection String Rollback**:
   ```json
   "DevConnection": "Server=localhost;Database=ProductManagement;Trusted_Connection=True;..."
   ```

4. **Code Rollback**: Revert all `Npgsql*` classes to `Sql*` classes

## Support and Resources

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Npgsql Documentation**: https://www.npgsql.org/doc/
- **.NET ADO.NET Guide**: https://docs.microsoft.com/dotnet/framework/data/adonet/
- **Migration Validation Report**: See `TRANSFORMATION_VALIDATION_REPORT.md`
- **Security Guide**: See `SECURITY.md`

## FAQ

**Q: Can I use PgBouncer for connection pooling?**  
A: Yes, PgBouncer is compatible. Update connection string to point to PgBouncer port (usually 6432).

**Q: How do I migrate existing SQL Server data?**  
A: Use AWS DMS, pgLoader, or export/import via CSV. Schema must match the PostgreSQL table definitions.

**Q: What PostgreSQL version should I use?**  
A: PostgreSQL 15 or later is recommended. Minimum supported version is 12.

**Q: Can I use this with PostgreSQL on AWS RDS?**  
A: Yes, fully compatible. Just update the Host in connection string to your RDS endpoint.

**Q: Do I need to change my application logic?**  
A: No, the business logic remains unchanged. Only database access layer was modified.

---

**Last Updated**: February 5, 2025  
**Migration Version**: 1.0
