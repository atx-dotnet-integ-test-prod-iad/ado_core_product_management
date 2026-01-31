# Runtime Testing Guide for PostgreSQL Migration

## Overview
This guide provides comprehensive instructions for testing the migrated AdoCore application against a PostgreSQL database. All code transformations have been completed successfully, but runtime verification requires a PostgreSQL database instance.

## Prerequisites
1. PostgreSQL 12+ installed and running
2. Database user with CREATE DATABASE permissions
3. PostgreSQL connection details matching appsettings.json

## Step 1: Create PostgreSQL Database Schema

Create a file `01_PostgreSQL_InitialSetup.sql` with the following content:

```sql
-- Create ProductManagement Database
CREATE DATABASE "ProductManagement";

\c ProductManagement;

-- Create Categories Table
CREATE TABLE Categories (
    CategoryId SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Description VARCHAR(200),
    ParentCategoryId INT,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add self-referencing foreign key for Categories
ALTER TABLE Categories
ADD CONSTRAINT FK_Categories_Categories 
FOREIGN KEY (ParentCategoryId) REFERENCES Categories (CategoryId);

-- Create Suppliers Table
CREATE TABLE Suppliers (
    SupplierId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    ContactName VARCHAR(100),
    Email VARCHAR(100),
    Phone VARCHAR(20),
    Address VARCHAR(200),
    Country VARCHAR(50),
    IsActive BOOLEAN NOT NULL DEFAULT TRUE,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create Products Table
CREATE TABLE Products (
    ProductId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500),
    Price DECIMAL(18, 2) NOT NULL,
    StockQuantity INT NOT NULL,
    CategoryId INT,
    SupplierId INT,
    SKU VARCHAR(50),
    Weight DECIMAL(10, 2),
    Dimensions VARCHAR(50),
    IsDiscontinued BOOLEAN NOT NULL DEFAULT FALSE,
    ReorderLevel INT NOT NULL DEFAULT 10,
    CreatedDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate TIMESTAMP,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) 
        REFERENCES Categories (CategoryId),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierId) 
        REFERENCES Suppliers (SupplierId)
);

-- Create ProductHistory Table
CREATE TABLE ProductHistory (
    HistoryId SERIAL PRIMARY KEY,
    ProductId INT NOT NULL,
    Action VARCHAR(10) NOT NULL,
    OldPrice DECIMAL(18, 2),
    NewPrice DECIMAL(18, 2),
    OldStock INT,
    NewStock INT,
    ActionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ModifiedBy VARCHAR(100)
);

-- Create ProductStats Table
CREATE TABLE ProductStats (
    StatId INT PRIMARY KEY DEFAULT 1,
    TotalProducts INT NOT NULL DEFAULT 0,
    AveragePrice DECIMAL(18, 2) NOT NULL DEFAULT 0,
    TotalStockValue DECIMAL(18, 2) NOT NULL DEFAULT 0,
    LowStockCount INT NOT NULL DEFAULT 0,
    DiscontinuedCount INT NOT NULL DEFAULT 0,
    LastUpdated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT CHK_StatId_One CHECK (StatId = 1)
);

-- Create Indexes
CREATE INDEX IX_Products_CategoryId ON Products (CategoryId);
CREATE INDEX IX_Products_SupplierId ON Products (SupplierId);
CREATE UNIQUE INDEX IX_Products_SKU ON Products (SKU);
CREATE INDEX IX_ProductHistory_ProductId ON ProductHistory (ProductId);
CREATE INDEX IX_ProductHistory_ActionDate ON ProductHistory (ActionDate);

-- Insert Sample Categories
INSERT INTO Categories (Name, Description, ParentCategoryId)
VALUES 
    ('Electronics', 'Electronic devices and accessories', NULL),
    ('Computers', 'Computers and related equipment', 1),
    ('Peripherals', 'Computer peripherals and accessories', 1),
    ('Audio', 'Audio equipment and accessories', 1),
    ('Storage', 'Data storage devices', 1),
    ('Gaming', 'Gaming equipment and accessories', NULL),
    ('Office', 'Office equipment and supplies', NULL),
    ('Networking', 'Networking equipment and accessories', 1),
    ('Laptops', 'Portable computers', 2),
    ('Desktops', 'Desktop computers', 2),
    ('Keyboards', 'Computer keyboards', 3),
    ('Mice', 'Computer mice and pointing devices', 3),
    ('Headphones', 'Audio headphones and headsets', 4),
    ('Speakers', 'Audio speakers', 4),
    ('External Drives', 'External storage devices', 5),
    ('Gaming PCs', 'Gaming computers', 6),
    ('Gaming Accessories', 'Gaming peripherals', 6),
    ('Printers', 'Printing devices', 7),
    ('Routers', 'Network routers', 8),
    ('Switches', 'Network switches', 8);

-- Insert Sample Suppliers
INSERT INTO Suppliers (Name, ContactName, Email, Phone, Address, Country)
VALUES 
    ('TechGlobal Inc.', 'John Smith', 'john@techglobal.com', '+1-555-0101', '123 Tech Street, Silicon Valley, CA', 'USA'),
    ('ElectroParts Ltd.', 'Sarah Johnson', 'sarah@electroparts.com', '+44-20-7123-4567', '45 Circuit Road, London', 'UK'),
    ('Digital Solutions', 'Michael Chen', 'michael@digitalsolutions.com', '+86-10-1234-5678', '789 Digital Avenue, Beijing', 'China'),
    ('Gaming Gear Co.', 'David Wilson', 'david@gaminggear.com', '+1-555-0202', '456 Game Street, Seattle, WA', 'USA'),
    ('AudioTech Systems', 'Emma Brown', 'emma@audiotech.com', '+1-555-0303', '789 Sound Road, Nashville, TN', 'USA'),
    ('Storage Solutions', 'James Lee', 'james@storagesolutions.com', '+1-555-0404', '321 Data Drive, Austin, TX', 'USA'),
    ('Office Supplies Pro', 'Lisa Anderson', 'lisa@officesupplies.com', '+1-555-0505', '654 Office Park, Chicago, IL', 'USA'),
    ('Network Experts', 'Robert Taylor', 'robert@networkexperts.com', '+1-555-0606', '987 Network Way, Boston, MA', 'USA');

-- Insert Sample Products
INSERT INTO Products (Name, Description, Price, StockQuantity, CategoryId, SupplierId, SKU, Weight, Dimensions, ReorderLevel)
VALUES 
    -- Laptops
    ('ProBook X1', 'High-performance business laptop with 16GB RAM', 1299.99, 15, 9, 1, 'LAP-X1-001', 1.8, '14" x 9" x 0.7"', 5),
    ('Gaming Beast', 'Gaming laptop with RTX 3080, 32GB RAM', 2499.99, 8, 9, 4, 'LAP-GB-001', 2.5, '15.6" x 11" x 1"', 3),
    ('UltraBook Air', 'Ultra-thin laptop with 12-hour battery', 999.99, 20, 9, 1, 'LAP-UA-001', 1.2, '13" x 8" x 0.5"', 7),
    
    -- Desktops
    ('WorkStation Pro', 'Professional workstation with dual monitors', 1999.99, 10, 10, 1, 'DESK-WP-001', 15.0, '18" x 8" x 16"', 4),
    ('Gaming Tower', 'High-end gaming desktop with liquid cooling', 2999.99, 5, 16, 4, 'DESK-GT-001', 20.0, '20" x 10" x 18"', 2),
    
    -- Keyboards
    ('Mechanical Pro', 'Mechanical keyboard with RGB lighting', 149.99, 30, 11, 2, 'KB-MP-001', 1.2, '17" x 5" x 1.5"', 10),
    ('Wireless Elite', 'Wireless keyboard with numeric pad', 79.99, 25, 11, 2, 'KB-WE-001', 0.8, '18" x 6" x 1"', 8),
    
    -- Mice
    ('Gaming Mouse Pro', 'High-precision gaming mouse', 89.99, 40, 12, 4, 'M-GP-001', 0.3, '5" x 3" x 1.5"', 15),
    ('Wireless Track', 'Wireless mouse with long battery life', 49.99, 35, 12, 2, 'M-WT-001', 0.2, '4" x 2.5" x 1.2"', 12),
    
    -- Headphones
    ('Noise Cancelling Pro', 'Premium noise-cancelling headphones', 299.99, 20, 13, 5, 'HP-NC-001', 0.4, '7" x 6" x 3"', 8),
    ('Gaming Headset', '7.1 surround sound gaming headset', 129.99, 25, 13, 4, 'HP-GH-001', 0.5, '8" x 7" x 4"', 10),
    
    -- Speakers
    ('Studio Monitors', 'Professional studio monitors', 399.99, 10, 14, 5, 'SP-SM-001', 8.0, '12" x 8" x 10"', 4),
    ('Bluetooth Soundbar', 'Wireless soundbar with subwoofer', 249.99, 15, 14, 5, 'SP-BS-001', 5.0, '36" x 3" x 4"', 6),
    
    -- External Drives
    ('SSD Pro 1TB', '1TB external SSD with USB 3.1', 199.99, 30, 15, 6, 'ED-SP-001', 0.2, '4" x 2" x 0.5"', 12),
    ('HDD Backup 4TB', '4TB external HDD for backup', 129.99, 25, 15, 6, 'ED-HB-001', 0.5, '5" x 3" x 1"', 10),
    
    -- Printers
    ('Laser Pro', 'Business laser printer with duplex', 399.99, 12, 18, 7, 'PR-LP-001', 25.0, '18" x 16" x 12"', 5),
    ('Photo Inkjet', 'Photo-quality inkjet printer', 299.99, 15, 18, 7, 'PR-PI-001', 15.0, '16" x 14" x 8"', 6),
    
    -- Networking
    ('WiFi 6 Router', 'High-speed WiFi 6 router', 199.99, 20, 19, 8, 'NET-WR-001', 1.5, '10" x 7" x 2"', 8),
    ('Gigabit Switch', '24-port gigabit network switch', 299.99, 10, 20, 8, 'NET-GS-001', 3.0, '17" x 10" x 1.5"', 4);

-- Insert initial stats record
INSERT INTO ProductStats (StatId, TotalProducts, AveragePrice, TotalStockValue, LowStockCount, DiscontinuedCount, LastUpdated)
VALUES (1, 0, 0, 0, 0, 0, CURRENT_TIMESTAMP);

-- Update initial statistics
UPDATE ProductStats
SET 
    TotalProducts = (SELECT COUNT(*) FROM Products),
    AveragePrice = (SELECT AVG(Price) FROM Products),
    TotalStockValue = (SELECT SUM(Price * StockQuantity) FROM Products),
    LowStockCount = (SELECT COUNT(*) FROM Products WHERE StockQuantity <= ReorderLevel),
    DiscontinuedCount = (SELECT COUNT(*) FROM Products WHERE IsDiscontinued = TRUE),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;
```

Execute this script:
```bash
psql -U postgres -f 01_PostgreSQL_InitialSetup.sql
```

## Step 2: Update Connection String

Verify the connection string in `appsettings.json` matches your PostgreSQL setup:

```json
{
  "ConnectionStrings": {
    "DevConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true",
    "ProdConnection": "Host=localhost;Port=5432;Database=ProductManagement;Username=postgres;Password=YOUR_PASSWORD;Pooling=true"
  },
  "Environment": "Development"
}
```

## Step 3: Test Database Connectivity

Run the application to test connectivity:

```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet run
```

Expected: Application should start without connection errors.

## Step 4: Test Database Operations

### Test 1: GetAllProductsAsync() - Statement 1
- **Purpose**: Verify SELECT with CTE and window functions
- **Test**: Run the interactive menu option to view all products
- **Expected**: Should return 18 products with price categories and percentages

### Test 2: GetProductByIdAsync() - Statement 2
- **Purpose**: Verify SELECT with LAG window function
- **Test**: Query for ProductId = 1
- **Expected**: Should return product details (may have NULL for previous values on first query)

### Test 3: InsertProductAsync() - Statement 3
- **Purpose**: Verify INSERT with RETURNING and transaction handling
- **Test**: Insert a new product
  ```
  Name: Test Product
  Description: Test Description
  Price: 99.99
  StockQuantity: 10
  ```
- **Expected**: 
  - Should return new ProductId
  - ProductHistory should have INSERT record
  - ProductStats should be updated

### Test 4: UpdateProductAsync() - Statement 4
- **Purpose**: Verify UPDATE within transaction
- **Test**: Update the test product created in Test 3
  ```
  Change Price: 149.99
  Change StockQuantity: 15
  ```
- **Expected**:
  - Product should be updated
  - ProductHistory should have UPDATE record with old/new values
  - ProductStats should be recalculated

### Test 5: DeleteProductAsync() - Statement 5
- **Purpose**: Verify DELETE within transaction
- **Test**: Delete the test product
- **Expected**:
  - Product should be removed
  - ProductHistory should have DELETE record
  - ProductStats should be decremented

### Test 6: GetProductsByPriceRangeAsync() - Statement 6
- **Purpose**: Verify RANK and PERCENT_RANK functions
- **Test**: Query for price range 100.00 to 500.00
- **Expected**: Should return products with price rankings and segments (Budget/Mid-Range/Premium)

### Test 7: GetLowStockProductsAsync() - Statement 7
- **Purpose**: Verify multiple window functions
- **Test**: Query for threshold = 10
- **Expected**: Should return products with stock <= 10, showing stock status and percentages

## Step 5: Test Transaction Atomicity

### Rollback Test for Insert
Modify InsertProductAsync to throw an exception after the first INSERT:
```csharp
// Add after first INSERT
throw new Exception("Test rollback");
```

**Expected**: No records should be inserted in any table (Products, ProductHistory, ProductStats unchanged)

### Rollback Test for Update
Modify UpdateProductAsync to throw an exception before commit:
```csharp
// Add before transaction.CommitAsync()
throw new Exception("Test rollback");
```

**Expected**: Product should remain unchanged, no history record created

### Rollback Test for Delete
Modify DeleteProductAsync to throw an exception before commit:
```csharp
// Add before transaction.CommitAsync()
throw new Exception("Test rollback");
```

**Expected**: Product should not be deleted, no history record created

## Step 6: Verify Data Consistency

After all operations, verify:

```sql
-- Check ProductStats is accurate
SELECT 
    ps.TotalProducts,
    ps.AveragePrice,
    (SELECT COUNT(*) FROM Products) as ActualCount,
    (SELECT AVG(Price) FROM Products) as ActualAvgPrice
FROM ProductStats ps
WHERE StatId = 1;
```

**Expected**: TotalProducts and AveragePrice should match actual counts

```sql
-- Check ProductHistory records all operations
SELECT Action, COUNT(*) 
FROM ProductHistory 
GROUP BY Action;
```

**Expected**: Should show counts for INSERT, UPDATE, DELETE operations performed

## Success Criteria

✅ Application connects to PostgreSQL without errors (Exit Criterion 12)
✅ All 7 SQL statements execute successfully (Exit Criterion 13)
✅ Transaction rollbacks work correctly (Exit Criterion 14)
✅ Data remains consistent across all operations (Exit Criterion 15)

## Troubleshooting

### Connection Errors
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check pg_hba.conf allows local connections
- Verify username/password in appsettings.json

### SQL Errors
- Check PostgreSQL logs: `tail -f /var/log/postgresql/postgresql-*.log`
- Verify schema was created successfully
- Check for case-sensitivity issues with identifiers

### Transaction Errors
- Ensure IsolationLevel is compatible with PostgreSQL
- Check for deadlocks in pg_stat_activity
- Verify transaction timeout settings

## Notes

1. **Window Functions**: PostgreSQL fully supports all window functions used (AVG, COUNT, LAG, RANK, PERCENT_RANK)
2. **RETURNING Clause**: PostgreSQL's RETURNING is more powerful than SQL Server's SCOPE_IDENTITY()
3. **CURRENT_TIMESTAMP**: Direct replacement for GETDATE(), no compatibility issues
4. **Parameters**: @Parameter syntax works identically in Npgsql
5. **Transactions**: ADO.NET transaction management is database-agnostic

## Completion Report

After completing all tests, document results:

- [ ] Database connectivity successful
- [ ] Statement 1 (GetAllProducts) executed successfully
- [ ] Statement 2 (GetProductById) executed successfully
- [ ] Statement 3 (InsertProduct) executed successfully with proper RETURNING
- [ ] Statement 4 (UpdateProduct) executed successfully in transaction
- [ ] Statement 5 (DeleteProduct) executed successfully in transaction
- [ ] Statement 6 (GetProductsByPriceRange) executed successfully
- [ ] Statement 7 (GetLowStockProducts) executed successfully
- [ ] Transaction atomicity verified (rollback tests passed)
- [ ] Data consistency verified (stats match actual data)
- [ ] All equivalency concerns addressed (see sql_equivalency_validation_report.json)
