# PostgreSQL Database Setup and Testing Guide

## Overview
This guide provides instructions for setting up the PostgreSQL database required for this application and testing the migrated code.

## Prerequisites
- PostgreSQL 12 or higher installed
- Access to PostgreSQL server (local or remote)
- psql command-line tool or pgAdmin

## Database Setup

### Step 1: Create Database
```sql
CREATE DATABASE "ProductManagement";
```

### Step 2: Connect to Database
```bash
psql -U postgres -d ProductManagement
```

### Step 3: Create Schema
```sql
CREATE SCHEMA IF NOT EXISTS productmanagement_dbo;
```

### Step 4: Create Tables

#### Products Table
```sql
CREATE TABLE productmanagement_dbo.products (
    productid SERIAL PRIMARY KEY,
    productname VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL DEFAULT 0,
    categoryid INTEGER,
    isactive BOOLEAN DEFAULT TRUE,
    createdat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedat TIMESTAMP
);
```

#### Product History Table
```sql
CREATE TABLE productmanagement_dbo.producthistory (
    historyid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    actiontype VARCHAR(50) NOT NULL,
    actiondate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    oldprice DECIMAL(18, 2),
    newprice DECIMAL(18, 2),
    changedby VARCHAR(100),
    FOREIGN KEY (productid) REFERENCES productmanagement_dbo.products(productid)
);
```

#### Product Stats Table
```sql
CREATE TABLE productmanagement_dbo.productstats (
    statsid SERIAL PRIMARY KEY,
    productid INTEGER NOT NULL,
    totalviews INTEGER DEFAULT 0,
    totalsales INTEGER DEFAULT 0,
    averagerating DECIMAL(3, 2),
    lastupdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (productid) REFERENCES productmanagement_dbo.products(productid)
);
```

### Step 5: Create Indexes (Optional but recommended)
```sql
CREATE INDEX idx_products_categoryid ON productmanagement_dbo.products(categoryid);
CREATE INDEX idx_products_price ON productmanagement_dbo.products(price);
CREATE INDEX idx_producthistory_productid ON productmanagement_dbo.producthistory(productid);
CREATE INDEX idx_productstats_productid ON productmanagement_dbo.productstats(productid);
```

### Step 6: Insert Test Data
```sql
-- Insert sample products
INSERT INTO productmanagement_dbo.products 
    (productname, description, price, stockquantity, categoryid, isactive) 
VALUES 
    ('Laptop Pro 15', 'High-performance laptop with 15-inch display', 1299.99, 50, 1, TRUE),
    ('Wireless Mouse', 'Ergonomic wireless mouse with precision tracking', 29.99, 200, 1, TRUE),
    ('USB-C Cable', 'Durable USB-C charging cable', 15.99, 500, 1, TRUE),
    ('External SSD 1TB', 'Fast external solid-state drive', 149.99, 75, 1, TRUE),
    ('Mechanical Keyboard', 'RGB mechanical gaming keyboard', 89.99, 30, 1, TRUE),
    ('Webcam HD', 'Full HD webcam with autofocus', 79.99, 100, 1, TRUE),
    ('Laptop Stand', 'Adjustable aluminum laptop stand', 39.99, 150, 1, TRUE),
    ('Screen Protector', 'Tempered glass screen protector', 19.99, 300, 1, TRUE),
    ('Laptop Bag', 'Padded laptop bag with multiple compartments', 49.99, 80, 1, TRUE),
    ('Portable Charger', '20000mAh portable power bank', 45.99, 120, 1, TRUE);

-- Insert product history records
INSERT INTO productmanagement_dbo.producthistory 
    (productid, actiontype, oldprice, newprice, changedby)
VALUES 
    (1, 'PRICE_UPDATE', 1399.99, 1299.99, 'admin'),
    (2, 'PRICE_UPDATE', 34.99, 29.99, 'admin'),
    (4, 'PRICE_UPDATE', 169.99, 149.99, 'admin');

-- Insert product stats
INSERT INTO productmanagement_dbo.productstats 
    (productid, totalviews, totalsales, averagerating)
VALUES 
    (1, 1500, 45, 4.5),
    (2, 2300, 180, 4.7),
    (3, 3500, 450, 4.3),
    (4, 1200, 65, 4.6),
    (5, 800, 28, 4.8),
    (6, 950, 95, 4.4),
    (7, 1100, 140, 4.5),
    (8, 2800, 280, 4.2),
    (9, 600, 75, 4.6),
    (10, 1400, 115, 4.5);
```

## Testing the Application

### Test 1: Database Connectivity (Exit Criterion 12)
Run the application to verify connection:
```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet run
```

Expected: Application starts without connection errors.

### Test 2: GetAllProductsAsync (Read Operation)
Test the CTE and window functions:
- Expected to return all products with ranking information
- Verify: LAG, RANK, and DENSE_RANK window functions work correctly

### Test 3: GetProductByIdAsync (Single Record Read)
Test retrieval of a specific product:
```bash
# Test with productid = 1
```
- Expected: Returns product details with previous price from LAG function
- Verify: LAG window function works correctly

### Test 4: InsertProductAsync (Create Operation with Transaction)
Test insert operation with RETURNING clause:
```bash
# Insert a new product
```
- Expected: New product inserted with returned ID
- Verify: RETURNING clause works, CURRENT_TIMESTAMP is set
- Verify: Transaction commits on success

### Test 5: UpdateProductAsync (Update Operation with Transaction)
Test multi-statement transaction:
```bash
# Update product price and quantity
```
- Expected: Product updated and history record created in single transaction
- Verify: Both statements execute or both rollback
- Verify: Transaction atomicity maintained

### Test 6: DeleteProductAsync (Delete Operation with Transaction)
Test cascading delete with CASE statement:
```bash
# Delete a product with low stock
```
- Expected: Product deleted along with related records
- Verify: CASE expression works in DELETE statement
- Verify: All related records cleaned up in transaction

### Test 7: GetProductsByPriceRangeAsync (Window Functions)
Test RANK and PERCENT_RANK functions:
```bash
# Query products between $20 and $100
```
- Expected: Products ranked by price within range
- Verify: RANK and PERCENT_RANK calculations correct

### Test 8: GetLowStockProductsAsync (Aggregate Window Functions)
Test aggregate window functions:
```bash
# Query products with stock below threshold
```
- Expected: Low stock products with category averages
- Verify: AVG and SUM window functions work correctly

## Transaction Atomicity Testing (Exit Criterion 14)

### Test Scenario 1: Successful Transaction
1. Start with known database state
2. Execute UpdateProductAsync
3. Verify both product update and history insert succeed
4. Verify data consistency

### Test Scenario 2: Transaction Rollback
1. Modify UpdateProductAsync to force an error after first statement
2. Execute the operation
3. Verify complete rollback (no partial updates)
4. Verify database returns to initial state

### Test Scenario 3: Concurrent Transactions
1. Execute multiple UpdateProductAsync calls simultaneously
2. Verify no data corruption
3. Verify all transactions properly isolated

## Verification Checklist

- [ ] Database and schema created successfully
- [ ] All tables created with correct structure
- [ ] Test data inserted successfully
- [ ] Application connects to PostgreSQL database (Criterion 12)
- [ ] All 7 repository methods execute without errors (Criterion 13)
- [ ] SELECT operations return correct data
- [ ] INSERT operations return correct IDs via RETURNING clause
- [ ] UPDATE operations modify data correctly
- [ ] DELETE operations remove data correctly
- [ ] Transactions commit on success (Criterion 14)
- [ ] Transactions rollback on failure (Criterion 14)
- [ ] No SQL syntax errors in converted statements
- [ ] Window functions (LAG, RANK, PERCENT_RANK) work correctly
- [ ] Aggregate window functions (AVG, SUM) work correctly
- [ ] CTE (Common Table Expressions) work correctly
- [ ] CASE expressions work correctly

## Troubleshooting

### Connection Issues
- Verify PostgreSQL is running: `systemctl status postgresql` (Linux) or check Services (Windows)
- Check connection string in appsettings.json
- Verify PostgreSQL accepts connections on port 5432
- Check pg_hba.conf for authentication settings

### Schema Issues
- Verify schema exists: `\dn` in psql
- Check table ownership and permissions
- Ensure schema is in search_path

### Query Issues
- Check PostgreSQL logs: `/var/log/postgresql/` (Linux) or Event Viewer (Windows)
- Enable query logging in postgresql.conf
- Use EXPLAIN ANALYZE to debug slow queries

### Transaction Issues
- Check isolation level settings
- Verify proper connection handling (no leaked connections)
- Monitor connection pool usage

## Performance Optimization (Optional)

After successful testing, consider:
1. Analyze query execution plans
2. Add appropriate indexes based on query patterns
3. Configure connection pooling parameters
4. Set up query caching if needed
5. Monitor and tune PostgreSQL configuration

## References
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Npgsql Documentation](https://www.npgsql.org/doc/)
- [PostgreSQL Window Functions](https://www.postgresql.org/docs/current/tutorial-window.html)
- [PostgreSQL Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
