# PostgreSQL Migration Testing Checklist

## Pre-Testing Setup

### Database Setup
- [ ] PostgreSQL server installed and running
- [ ] PostgreSQL version: 12+ recommended
- [ ] Database `ProductManagement` created
- [ ] Tables created: Products, ProductHistory, ProductStats
- [ ] Test data populated
- [ ] Database user configured with appropriate permissions

### Application Configuration
- [ ] Connection strings updated with actual PostgreSQL credentials
- [ ] Npgsql package properly installed (version 8.0.5)
- [ ] Application builds successfully
- [ ] Application runs without startup errors

---

## 1. Connection Establishment Testing

### Test 1.1: Development Connection
**Objective:** Verify application can connect to PostgreSQL using DevConnection

**Steps:**
1. Set Environment to "Development" in appsettings.json
2. Run the application
3. Verify connection is established without errors

**Expected Result:**
- ✅ Connection successful
- ✅ No connection timeout errors
- ✅ No authentication errors

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 1.2: Production Connection
**Objective:** Verify application can connect using ProdConnection

**Steps:**
1. Set Environment to "Production" in appsettings.json
2. Run the application
3. Verify connection is established without errors

**Expected Result:**
- ✅ Connection successful
- ✅ Correct connection string used

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 2. GetAllProductsAsync Testing

### Test 2.1: Retrieve All Products
**Objective:** Verify CTE with window functions works correctly

**SQL Statement Features:**
- CTE (ProductStats)
- AVG() OVER() window function
- COUNT() OVER() window function
- CASE expressions
- INNER JOIN

**Steps:**
1. Call GetAllProductsAsync()
2. Verify products are returned
3. Verify PriceCategory field is populated correctly
4. Verify PricePercentageOfAverage is calculated

**Test Data Setup:**
```sql
INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES 
  ('Product A', 'Test', 100.00, 10, CURRENT_TIMESTAMP),
  ('Product B', 'Test', 200.00, 20, CURRENT_TIMESTAMP),
  ('Product C', 'Test', 50.00, 5, CURRENT_TIMESTAMP);
```

**Expected Result:**
- ✅ All products returned
- ✅ Average price calculated correctly
- ✅ Price categories assigned correctly ("Above Average", "Below Average", "Average")
- ✅ Percentages calculated correctly
- ✅ Products ordered correctly (price above average first)

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 3. GetProductByIdAsync Testing

### Test 3.1: Retrieve Single Product
**Objective:** Verify CTE with LAG window function works correctly

**SQL Statement Features:**
- CTE (ProductHistory)
- LAG() OVER() window function
- LEFT JOIN
- CASE expression for null handling

**Steps:**
1. Insert a product
2. Update the product (to create ModifiedDate history)
3. Call GetProductByIdAsync(productId)
4. Verify product is returned with history data

**Test Data Setup:**
```sql
INSERT INTO Products (Name, Description, Price, StockQuantity, CreatedDate)
VALUES ('Test Product', 'For history test', 100.00, 10, CURRENT_TIMESTAMP);
-- Get ProductId
-- Update: UPDATE Products SET Price = 150.00, ModifiedDate = CURRENT_TIMESTAMP WHERE ProductId = ?
```

**Expected Result:**
- ✅ Product returned with all fields
- ✅ PreviousPrice and PreviousStock calculated (if multiple records exist)
- ✅ PriceChangePercentage calculated correctly
- ✅ NULL handling works for products without history

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 3.2: Non-Existent Product
**Objective:** Verify null return for non-existent products

**Steps:**
1. Call GetProductByIdAsync(999999)
2. Verify null is returned

**Expected Result:**
- ✅ Returns null
- ✅ No exceptions thrown

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 4. InsertProductAsync Testing

### Test 4.1: Insert New Product
**Objective:** Verify INSERT...RETURNING works correctly

**SQL Statement Features:**
- INSERT with RETURNING clause
- CURRENT_TIMESTAMP function
- Application-level transaction
- Multiple statement execution

**Steps:**
1. Create a new Product object
2. Call InsertProductAsync(product)
3. Verify ProductId is returned
4. Verify product exists in database
5. Verify ProductHistory record created
6. Verify ProductStats updated

**Test Data:**
```csharp
var product = new Product {
    Name = "New Test Product",
    Description = "Testing insert",
    Price = 99.99m,
    StockQuantity = 15
};
```

**Expected Result:**
- ✅ Valid ProductId returned (> 0)
- ✅ Product inserted into Products table
- ✅ CreatedDate populated automatically
- ✅ ProductHistory record created with Action='INSERT'
- ✅ ProductStats.TotalProducts incremented
- ✅ ProductStats.AveragePrice updated correctly
- ✅ ProductStats.LastUpdated set to current timestamp

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 4.2: Insert with Null Description
**Objective:** Verify null handling in INSERT

**Steps:**
1. Create product with Description = null
2. Call InsertProductAsync(product)
3. Verify successful insertion

**Expected Result:**
- ✅ Product inserted successfully
- ✅ Description is NULL in database
- ✅ No exceptions thrown

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 4.3: Transaction Rollback on Error
**Objective:** Verify transaction rollback works

**Steps:**
1. Manually cause an error in one of the transaction statements
   (e.g., violate a constraint in ProductHistory table)
2. Verify entire transaction rolls back
3. Verify no partial data committed

**Expected Result:**
- ✅ Transaction rolls back completely
- ✅ No product inserted
- ✅ No history record created
- ✅ ProductStats unchanged
- ✅ Exception propagated to caller

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 5. UpdateProductAsync Testing

### Test 5.1: Update Existing Product
**Objective:** Verify UPDATE with CURRENT_TIMESTAMP works correctly

**SQL Statement Features:**
- SELECT to retrieve old values
- UPDATE with CURRENT_TIMESTAMP
- INSERT into history table
- UPDATE statistics
- Application-level transaction

**Steps:**
1. Insert a test product
2. Modify product properties (Price, StockQuantity, Name)
3. Call UpdateProductAsync(product)
4. Verify product updated
5. Verify history logged
6. Verify statistics updated

**Test Data:**
```csharp
// Initial insert
var product = new Product { Name = "Original", Price = 100.00m, StockQuantity = 10 };
int id = await InsertProductAsync(product);

// Update
product.ProductId = id;
product.Name = "Updated Name";
product.Price = 150.00m;
product.StockQuantity = 20;
```

**Expected Result:**
- ✅ Product updated in Products table
- ✅ ModifiedDate set to current timestamp
- ✅ ProductHistory record created with Action='UPDATE'
- ✅ OldPrice and OldStock captured correctly
- ✅ ProductStats.AveragePrice recalculated
- ✅ ProductStats.LastUpdated updated

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 5.2: Update Non-Existent Product
**Objective:** Verify error handling for missing product

**Steps:**
1. Create product object with non-existent ProductId
2. Call UpdateProductAsync(product)
3. Verify exception is thrown

**Expected Result:**
- ✅ InvalidOperationException thrown
- ✅ Error message: "Product with ID {id} not found"
- ✅ Transaction rolled back

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 6. DeleteProductAsync Testing

### Test 6.1: Delete Existing Product
**Objective:** Verify DELETE operation works correctly

**SQL Statement Features:**
- SELECT to retrieve old values
- INSERT into history
- DELETE operation
- UPDATE statistics with CASE expression
- Application-level transaction

**Steps:**
1. Insert a test product
2. Call DeleteProductAsync(productId)
3. Verify product deleted
4. Verify history logged
5. Verify statistics updated

**Test Data:**
```csharp
var product = new Product { Name = "To Delete", Price = 75.00m, StockQuantity = 5 };
int id = await InsertProductAsync(product);
await DeleteProductAsync(id);
```

**Expected Result:**
- ✅ Product deleted from Products table
- ✅ ProductHistory record created with Action='DELETE'
- ✅ OldPrice and OldStock captured correctly
- ✅ ProductStats.TotalProducts decremented
- ✅ ProductStats.AveragePrice recalculated correctly
- ✅ CASE expression handles TotalProducts > 1 correctly
- ✅ ProductStats.LastUpdated updated

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 6.2: Delete Non-Existent Product
**Objective:** Verify error handling for missing product

**Steps:**
1. Call DeleteProductAsync(999999)
2. Verify exception is thrown

**Expected Result:**
- ✅ InvalidOperationException thrown
- ✅ Error message: "Product with ID {id} not found"
- ✅ Transaction rolled back

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 6.3: Delete Last Product
**Objective:** Verify CASE expression handles TotalProducts = 1

**Steps:**
1. Delete all products except one
2. Delete the last product
3. Verify ProductStats.AveragePrice set to 0

**Expected Result:**
- ✅ Product deleted successfully
- ✅ ProductStats.AveragePrice = 0 (ELSE branch of CASE)
- ✅ ProductStats.TotalProducts = 0

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 7. GetProductsByPriceRangeAsync Testing

### Test 7.1: Retrieve Products in Range
**Objective:** Verify RANK and PERCENT_RANK window functions work

**SQL Statement Features:**
- CTE (RankedProducts)
- RANK() OVER() window function
- PERCENT_RANK() OVER() window function
- BETWEEN clause
- CASE expression for segmentation

**Steps:**
1. Insert multiple products with varying prices
2. Call GetProductsByPriceRangeAsync(50, 150)
3. Verify only products in range returned
4. Verify ranking and percentiles calculated
5. Verify segmentation (Budget/Mid-Range/Premium) correct

**Test Data:**
```sql
INSERT INTO Products (Name, Price, StockQuantity, CreatedDate) VALUES
  ('Product 1', 25.00, 10, CURRENT_TIMESTAMP),  -- Below range
  ('Product 2', 75.00, 10, CURRENT_TIMESTAMP),  -- In range
  ('Product 3', 100.00, 10, CURRENT_TIMESTAMP), -- In range
  ('Product 4', 125.00, 10, CURRENT_TIMESTAMP), -- In range
  ('Product 5', 200.00, 10, CURRENT_TIMESTAMP); -- Above range
```

**Expected Result:**
- ✅ Only products with Price BETWEEN 50 AND 150 returned (3 products)
- ✅ PriceRank assigned correctly (1, 2, 3)
- ✅ PricePercentile calculated (0.00, 0.50, 1.00 for 3 products)
- ✅ PriceSegment assigned correctly based on percentile
- ✅ Products ordered by PriceRank

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 7.2: Empty Price Range
**Objective:** Verify empty result handling

**Steps:**
1. Call GetProductsByPriceRangeAsync(9999, 10000)
2. Verify empty list returned

**Expected Result:**
- ✅ Empty list returned (not null)
- ✅ No exceptions thrown

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 8. GetLowStockProductsAsync Testing

### Test 8.1: Retrieve Low Stock Products
**Objective:** Verify AVG, MIN, MAX window functions work

**SQL Statement Features:**
- CTE (StockAnalysis)
- AVG() OVER() window function
- MIN() OVER() window function
- MAX() OVER() window function
- CASE expression for stock status
- ROUND function

**Steps:**
1. Insert products with varying stock quantities
2. Call GetLowStockProductsAsync(threshold: 10)
3. Verify only low stock products returned
4. Verify window function calculations
5. Verify stock status categorization

**Test Data:**
```sql
INSERT INTO Products (Name, Price, StockQuantity, CreatedDate) VALUES
  ('Product A', 50.00, 5, CURRENT_TIMESTAMP),   -- Critical
  ('Product B', 50.00, 8, CURRENT_TIMESTAMP),   -- Low
  ('Product C', 50.00, 15, CURRENT_TIMESTAMP),  -- Above threshold
  ('Product D', 50.00, 20, CURRENT_TIMESTAMP);  -- Above threshold
```

**Expected Result:**
- ✅ Only products with StockQuantity <= threshold returned (2 products)
- ✅ AvgStock calculated across ALL products (12.0)
- ✅ MinStock = 5, MaxStock = 20
- ✅ StockStatus assigned correctly:
  - Product A (5): 'Critical' (≤ threshold)
  - Product B (8): 'Critical' or 'Low' (≤ threshold, check AvgStock * 0.5)
- ✅ StockPercentageOfAverage calculated correctly
- ✅ Products ordered by StockQuantity ascending

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 8.2: No Low Stock Products
**Objective:** Verify empty result handling

**Steps:**
1. Ensure all products have StockQuantity > threshold
2. Call GetLowStockProductsAsync(threshold: 5)
3. Verify empty list returned

**Expected Result:**
- ✅ Empty list returned (not null)
- ✅ No exceptions thrown

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 9. Transaction Integrity Testing

### Test 9.1: Concurrent Transactions
**Objective:** Verify transaction isolation

**Steps:**
1. Start two concurrent update operations on the same product
2. Verify transactions don't interfere
3. Verify final state is consistent

**Expected Result:**
- ✅ Both transactions complete successfully (serially)
- ✅ No data corruption
- ✅ Final state reflects both updates

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 9.2: Connection Pooling
**Objective:** Verify connection pooling works correctly

**Steps:**
1. Execute multiple operations rapidly
2. Monitor PostgreSQL connections
3. Verify connections are pooled and reused

**Expected Result:**
- ✅ Connections reused from pool
- ✅ No connection leaks
- ✅ Performance acceptable

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 10. Error Handling & Edge Cases

### Test 10.1: Database Connection Failure
**Objective:** Verify graceful handling of connection errors

**Steps:**
1. Stop PostgreSQL server
2. Attempt database operation
3. Verify appropriate exception thrown

**Expected Result:**
- ✅ Exception thrown with clear error message
- ✅ Application doesn't crash
- ✅ Error logged appropriately

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 10.2: Query Timeout
**Objective:** Verify timeout handling

**Steps:**
1. Execute a slow query (add WAITFOR equivalent or large dataset)
2. Verify timeout occurs if configured
3. Verify appropriate exception handling

**Expected Result:**
- ✅ Timeout exception thrown if exceeded
- ✅ Transaction rolled back
- ✅ Connection returned to pool

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 10.3: Null Parameter Handling
**Objective:** Verify DBNull.Value handling

**Steps:**
1. Insert/Update products with null descriptions
2. Verify proper null handling in all operations

**Expected Result:**
- ✅ Null values handled correctly in INSERTs
- ✅ Null values handled correctly in UPDATEs
- ✅ Null values handled correctly in SELECTs
- ✅ No NullReferenceExceptions

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## 11. Performance Testing

### Test 11.1: Query Execution Time
**Objective:** Benchmark query performance

**Test Data:** 1,000+ products

**Queries to Benchmark:**
- GetAllProductsAsync (with CTE and window functions)
- GetProductsByPriceRangeAsync (with RANK functions)
- GetLowStockProductsAsync (with multiple window functions)

**Steps:**
1. Populate database with test data (1,000-10,000 products)
2. Execute each query multiple times
3. Record execution times
4. Compare with SQL Server baseline (if available)

**Expected Result:**
- ✅ Queries complete in reasonable time (<1 second for 1,000 products)
- ✅ Performance comparable to SQL Server
- ✅ No significant performance degradation

**Actual Results:**
- GetAllProductsAsync: _____ ms
- GetProductsByPriceRangeAsync: _____ ms
- GetLowStockProductsAsync: _____ ms

**Status:** ⬜ Pass ⬜ Fail

---

## 12. Data Type Compatibility

### Test 12.1: Decimal Precision
**Objective:** Verify DECIMAL(18,2) → NUMERIC(18,2) conversion

**Steps:**
1. Insert product with precise decimal price (e.g., 99.99)
2. Retrieve and verify precision maintained
3. Perform calculations and verify rounding

**Expected Result:**
- ✅ Decimal precision maintained
- ✅ No rounding errors
- ✅ ROUND function works correctly

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 12.2: Timestamp Precision
**Objective:** Verify DATETIME → TIMESTAMP conversion

**Steps:**
1. Insert products with CURRENT_TIMESTAMP
2. Verify timestamps stored correctly
3. Verify ModifiedDate updates work

**Expected Result:**
- ✅ Timestamps stored with appropriate precision
- ✅ CURRENT_TIMESTAMP function works
- ✅ Timestamp comparisons work correctly

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

### Test 12.3: String Encoding
**Objective:** Verify NVARCHAR → VARCHAR conversion

**Steps:**
1. Insert products with special characters, Unicode
2. Verify data retrieved correctly
3. Verify no encoding issues

**Expected Result:**
- ✅ All characters stored correctly
- ✅ Unicode characters handled properly
- ✅ No data loss or corruption

**Actual Result:** ___________

**Status:** ⬜ Pass ⬜ Fail

---

## Summary

### Test Execution Summary

**Total Tests:** 27

**Passed:** _____ / 27  
**Failed:** _____ / 27  
**Blocked:** _____ / 27  

### Critical Issues Found
1. _______________________
2. _______________________
3. _______________________

### Non-Critical Issues Found
1. _______________________
2. _______________________

### Performance Notes
- _______________________
- _______________________

### Recommendations
1. _______________________
2. _______________________
3. _______________________

---

## Sign-off

**Tested By:** _______________________  
**Date:** _______________________  
**Environment:** ⬜ Development ⬜ Test ⬜ Staging ⬜ Production  

**PostgreSQL Version:** _______________________  
**Application Version:** _______________________  

**Overall Assessment:** ⬜ Ready for Production ⬜ Needs Further Testing ⬜ Blockers Identified

**Notes:**
_______________________
_______________________
_______________________

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-09  
**Status:** Ready for Testing
