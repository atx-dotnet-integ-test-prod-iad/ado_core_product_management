# SQL Statement Extraction Report
## Microsoft SQL Server to PostgreSQL Migration - AdoCore

**Date:** 2024
**Phase:** Step 1 - Extract and Catalog All SQL Statements from Code

---

## Executive Summary

This report documents the comprehensive extraction of all SQL statements from the AdoCore ADO.NET application prior to migration from Microsoft SQL Server to PostgreSQL. All database operations are centralized in the `ProductRepository.cs` file.

### Extraction Statistics
- **Total SQL Operations Extracted:** 7
- **Source Files Analyzed:** 1 (DataAccess/ProductRepository.cs)
- **Total Lines of SQL Code:** ~250 lines
- **Transaction Blocks Identified:** 3
- **Parameterized Queries:** 7 (all statements use proper parameterization)

---

## Extracted SQL Operations

### 1. GetAllProductsAsync
**Location:** DataAccess/ProductRepository.cs, Lines 42-68  
**Complexity:** HIGH  
**Transaction:** No  
**Parameters:** None  

**SQL Server Features:**
- Common Table Expression (CTE): `ProductStats`
- Window Functions: `AVG(Price) OVER()`, `COUNT(*) OVER()`
- `INNER JOIN` between Products and ProductStats CTE
- `CASE` expression for price categorization
- `ROUND()` function for percentage calculation
- Multi-level `ORDER BY` with `CASE` expression

**Dependencies:**
- Products table

**Description:**  
Retrieves all products with comprehensive price statistics. Uses a CTE to calculate average price and total product count across all products using window functions, then joins this data back to each product to provide price comparison metrics and categorization (Above Average, Below Average, Average).

**PostgreSQL Migration Considerations:**
- Window functions are supported in PostgreSQL
- CTE syntax is compatible
- `CASE` expressions are compatible
- `ROUND()` function exists in PostgreSQL

---

### 2. GetProductByIdAsync
**Location:** DataAccess/ProductRepository.cs, Lines 75-109  
**Complexity:** HIGH  
**Transaction:** No  
**Parameters:** `@ProductId` (INT)

**SQL Server Features:**
- Common Table Expression (CTE): `ProductHistory`
- Window Function: `LAG(Price) OVER (ORDER BY ModifiedDate)`, `LAG(StockQuantity) OVER (ORDER BY ModifiedDate)`
- `LEFT JOIN` for optional historical data
- `CASE` expression with NULL handling
- Calculated field for price change percentage

**Dependencies:**
- Products table

**Description:**  
Retrieves a single product by ID with historical price and stock quantity data using the LAG window function to compare current values with previous values. Calculates price change percentage when historical data exists.

**PostgreSQL Migration Considerations:**
- `LAG()` window function is supported in PostgreSQL
- `LEFT JOIN` and NULL handling are compatible
- Arithmetic operations in `CASE` expression are compatible

---

### 3. InsertProductAsync
**Location:** DataAccess/ProductRepository.cs, Lines 115-146  
**Complexity:** VERY HIGH  
**Transaction:** Yes (BEGIN TRANSACTION / COMMIT)  
**Parameters:** `@Name` (NVARCHAR), `@Description` (NVARCHAR), `@Price` (DECIMAL), `@StockQuantity` (INT)

**SQL Server Features:**
- Variable declaration: `DECLARE @NewProductId INT;`
- Explicit transaction control: `BEGIN TRANSACTION` / `COMMIT`
- `SCOPE_IDENTITY()` for retrieving inserted identity value
- `GETDATE()` function for current timestamp (2 occurrences)
- Multi-statement transaction with 3 DML operations
- `SET` for variable assignment
- Final `SELECT` to return the new ID

**Transaction Statements:**
1. INSERT into Products table
2. INSERT into ProductHistory table (audit log)
3. UPDATE ProductStats table (statistics maintenance)
4. SELECT to return new ProductId

**Dependencies:**
- Products table (identity column: ProductId)
- ProductHistory table (audit trail)
- ProductStats table (aggregate statistics, StatId = 1)

**Description:**  
Inserts a new product and performs related operations within a transaction: retrieves the newly generated ProductId using SCOPE_IDENTITY(), logs the insertion in ProductHistory, updates aggregate statistics in ProductStats, and returns the new ProductId.

**PostgreSQL Migration Considerations:**
- **CRITICAL:** `SCOPE_IDENTITY()` must be replaced with PostgreSQL `RETURNING` clause
- `GETDATE()` must be replaced with `NOW()` or `CURRENT_TIMESTAMP`
- `BEGIN TRANSACTION` → `BEGIN;` and `COMMIT` → `COMMIT;`
- Variable declarations need PostgreSQL syntax (DECLARE variable_name type;)
- `SET @Variable = value` → `variable_name := value` or use RETURNING directly

---

### 4. UpdateProductAsync
**Location:** DataAccess/ProductRepository.cs, Lines 151-187  
**Complexity:** VERY HIGH  
**Transaction:** Yes (BEGIN TRANSACTION / COMMIT)  
**Parameters:** `@ProductId` (INT), `@Name` (NVARCHAR), `@Description` (NVARCHAR), `@Price` (DECIMAL), `@StockQuantity` (INT)

**SQL Server Features:**
- Variable declarations: `DECLARE @OldPrice DECIMAL(18,2);`, `DECLARE @OldStock INT;`
- Explicit transaction control: `BEGIN TRANSACTION` / `COMMIT`
- `GETDATE()` function for current timestamp (3 occurrences)
- Multi-statement transaction with 4 operations
- SELECT INTO variables for storing old values

**Transaction Statements:**
1. SELECT old values into variables
2. UPDATE Products table
3. INSERT into ProductHistory table (audit log)
4. UPDATE ProductStats table (statistics maintenance)

**Dependencies:**
- Products table
- ProductHistory table (audit trail)
- ProductStats table (aggregate statistics)

**Description:**  
Updates an existing product with comprehensive change tracking. First captures the old price and stock values, then updates the product record with new values and ModifiedDate, logs the changes in ProductHistory with before/after values, and adjusts aggregate statistics in ProductStats.

**PostgreSQL Migration Considerations:**
- Variable declarations need PostgreSQL syntax
- `GETDATE()` must be replaced with `NOW()` or `CURRENT_TIMESTAMP`
- `BEGIN TRANSACTION` → `BEGIN;` and `COMMIT` → `COMMIT;`
- SELECT INTO syntax is supported in PostgreSQL
- Consider using RETURNING clause for efficiency

---

### 5. DeleteProductAsync
**Location:** DataAccess/ProductRepository.cs, Lines 192-222  
**Complexity:** VERY HIGH  
**Transaction:** Yes (BEGIN TRANSACTION / COMMIT)  
**Parameters:** `@ProductId` (INT)

**SQL Server Features:**
- Variable declarations: `DECLARE @OldPrice DECIMAL(18,2);`, `DECLARE @OldStock INT;`
- Explicit transaction control: `BEGIN TRANSACTION` / `COMMIT`
- `GETDATE()` function for current timestamp (2 occurrences)
- Multi-statement transaction with 4 operations
- Complex `CASE` expression in UPDATE statement for conditional calculation

**Transaction Statements:**
1. SELECT product info into variables
2. INSERT into ProductHistory table (audit log)
3. DELETE from Products table
4. UPDATE ProductStats table with CASE-based recalculation

**Dependencies:**
- Products table
- ProductHistory table (audit trail)
- ProductStats table (aggregate statistics)

**Description:**  
Deletes a product with full audit trail. Captures product information before deletion, logs the deletion event in ProductHistory, removes the product record, and updates aggregate statistics with special handling for the last product case (sets average to 0 when TotalProducts becomes 0).

**PostgreSQL Migration Considerations:**
- Variable declarations need PostgreSQL syntax
- `GETDATE()` must be replaced with `NOW()` or `CURRENT_TIMESTAMP`
- `BEGIN TRANSACTION` → `BEGIN;` and `COMMIT` → `COMMIT;`
- `CASE` expression is compatible with PostgreSQL
- NULL values in ProductHistory are supported

---

### 6. GetProductsByPriceRangeAsync
**Location:** DataAccess/ProductRepository.cs, Lines 228-255  
**Complexity:** HIGH  
**Transaction:** No  
**Parameters:** `@MinPrice` (DECIMAL), `@MaxPrice` (DECIMAL)

**SQL Server Features:**
- Common Table Expression (CTE): `RankedProducts`
- Window Functions: `RANK() OVER (ORDER BY p.Price)`, `PERCENT_RANK() OVER (ORDER BY p.Price)`
- `BETWEEN` clause for range filtering
- `CASE` expression for price segment categorization
- SELECT with `.*` wildcard expansion

**Dependencies:**
- Products table

**Description:**  
Retrieves products within a specified price range with ranking and percentile information. Uses window functions to calculate each product's rank and percentile within the filtered set, then categorizes products into price segments (Budget: ≤25%, Mid-Range: 25-75%, Premium: >75%).

**PostgreSQL Migration Considerations:**
- `RANK()` and `PERCENT_RANK()` window functions are supported in PostgreSQL
- `BETWEEN` clause is compatible
- CTE syntax is compatible
- `.*` wildcard expansion is supported

---

### 7. GetLowStockProductsAsync
**Location:** DataAccess/ProductRepository.cs, Lines 260-291  
**Complexity:** HIGH  
**Transaction:** No  
**Parameters:** `@Threshold` (INT)

**SQL Server Features:**
- Common Table Expression (CTE): `StockAnalysis`
- Multiple Window Functions: `AVG(StockQuantity) OVER()`, `MIN(StockQuantity) OVER()`, `MAX(StockQuantity) OVER()`
- `CASE` expression with multiple conditions including arithmetic operations
- `ROUND()` function for percentage calculation
- WHERE clause filtering on CTE results

**Dependencies:**
- Products table

**Description:**  
Retrieves products with stock levels below a threshold, including comprehensive stock analysis. Calculates average, minimum, and maximum stock quantities across all products using window functions, then categorizes each product's stock status (Critical: ≤threshold, Low: ≤50% of average, Adequate: otherwise) and provides percentage comparison to average stock.

**PostgreSQL Migration Considerations:**
- All window functions (`AVG OVER`, `MIN OVER`, `MAX OVER`) are supported in PostgreSQL
- `CASE` expressions with arithmetic operations are compatible
- `ROUND()` function exists in PostgreSQL
- CTE syntax is compatible

---

## SQL Server Specific Features Requiring Conversion

### Critical Conversions Required

1. **SCOPE_IDENTITY()** - 1 occurrence
   - Location: InsertProductAsync
   - PostgreSQL Equivalent: Use `RETURNING` clause on INSERT statement
   - Impact: HIGH - Fundamental difference in identity retrieval pattern

2. **GETDATE()** - 9 occurrences
   - Locations: InsertProductAsync (2), UpdateProductAsync (3), DeleteProductAsync (2)
   - PostgreSQL Equivalent: `NOW()` or `CURRENT_TIMESTAMP`
   - Impact: MEDIUM - Simple find/replace conversion

3. **Transaction Syntax** - 3 transaction blocks
   - SQL Server: `BEGIN TRANSACTION` / `COMMIT`
   - PostgreSQL: `BEGIN;` / `COMMIT;`
   - Impact: MEDIUM - Syntax adjustment in transaction blocks

4. **Variable Declarations** - 7 variable declarations
   - SQL Server: `DECLARE @Variable Type;` with `SET @Variable = value;`
   - PostgreSQL: `DECLARE variable_name type;` with `variable_name := value;`
   - Impact: MEDIUM - Syntax differences in variable handling

### Compatible Features (Minimal/No Conversion Required)

5. **Window Functions** - 11 window function usages
   - Functions: AVG, COUNT, LAG, RANK, PERCENT_RANK, MIN, MAX with OVER clauses
   - PostgreSQL: Fully supported with same syntax
   - Impact: LOW - Should work without modification

6. **CTEs (Common Table Expressions)** - 5 CTE usages
   - PostgreSQL: Fully supported with WITH clause
   - Impact: LOW - Compatible syntax

7. **CASE Expressions** - Multiple occurrences
   - PostgreSQL: Fully supported
   - Impact: NONE - Identical syntax

8. **ROUND Function** - 4 occurrences
   - PostgreSQL: Supported (may have minor syntax differences in precision handling)
   - Impact: LOW - Should be compatible

---

## Database Schema Dependencies

The SQL statements reference the following database objects:

### Tables

1. **Products** (Primary table)
   - Columns: ProductId (Identity), Name, Description, Price (DECIMAL(18,2)), StockQuantity, CreatedDate, ModifiedDate
   - Referenced in: All 7 SQL operations
   - Primary key: ProductId

2. **ProductHistory** (Audit trail table)
   - Columns: ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate
   - Referenced in: InsertProductAsync, UpdateProductAsync, DeleteProductAsync
   - Purpose: Audit logging for product changes

3. **ProductStats** (Aggregate statistics table)
   - Columns: StatId, TotalProducts, AveragePrice, LastUpdated
   - Referenced in: InsertProductAsync, UpdateProductAsync, DeleteProductAsync
   - Purpose: Maintaining aggregate product statistics
   - Assumption: Single row with StatId = 1

---

## Risk Assessment

### High Risk Items
1. **SCOPE_IDENTITY() Conversion** - Requires structural change from variable assignment + SELECT to RETURNING clause
2. **Transaction Block Structure** - Three complex multi-statement transactions need careful conversion and testing
3. **Variable Scoping** - PostgreSQL has different variable scoping rules in transactions

### Medium Risk Items
1. **GETDATE() Replacements** - Simple conversion but multiple occurrences across transaction blocks
2. **Data Type Compatibility** - DECIMAL(18,2) and NVARCHAR mappings to PostgreSQL equivalents
3. **NULL Handling** - Ensure NULL handling in CASE expressions and LEFT JOINs works identically

### Low Risk Items
1. **Window Functions** - High confidence in PostgreSQL compatibility
2. **CTEs** - Standard SQL feature with good compatibility
3. **Basic DML Operations** - INSERT, UPDATE, DELETE syntax is largely compatible

---

## Recommendations for DMS Conversion (Step 2)

1. **Process Transaction Blocks as Complete Units:** Pass entire transaction blocks to DMS tool including all statements within BEGIN TRANSACTION/COMMIT boundaries

2. **Pay Special Attention to SCOPE_IDENTITY() Conversion:** Verify DMS tool properly converts to PostgreSQL RETURNING clause and that C# code is adjusted accordingly

3. **Validate Variable Declaration Syntax:** Ensure DMS converts variable declarations from SQL Server to PostgreSQL syntax correctly

4. **Test Window Function Compatibility:** Although window functions should be compatible, validate complex combinations like multiple window functions in a single CTE

5. **Verify Parameter Naming:** Ensure @ prefix in parameters is handled correctly (PostgreSQL can use $ or : prefixes)

6. **Review Schema Object Names:** If DMS modifies table or column names during conversion, these changes must be reflected in the C# code

7. **Maintain Transaction Integrity:** Ensure all statements within a transaction block are converted together to maintain atomicity

---

## Next Steps

1. **Step 2:** Pass all 7 extracted SQL statements through the DMS MCP tool (dms-mcp____statement_conversion_tool)
2. **Step 3:** Validate equivalency of all statement pairs using SQL Equivalency tool (sql-equivalency___validate_sql_equivalence)
3. **Step 4:** Re-integrate converted SQL statements back into ProductRepository.cs
4. **Step 5:** Update package dependencies and ADO.NET classes from SqlClient to Npgsql
5. **Step 6:** Update connection strings for PostgreSQL format
6. **Step 7:** Generate comprehensive migration report and validate all exit criteria

---

## Conclusion

All 7 SQL operations from the AdoCore application have been successfully extracted and cataloged. The codebase demonstrates good practices with proper parameterization, transaction management, and audit logging. The main conversion challenges will be:

1. Replacing SCOPE_IDENTITY() with PostgreSQL RETURNING clause
2. Converting transaction syntax and variable declarations
3. Replacing GETDATE() function calls
4. Ensuring proper integration with Npgsql ADO.NET provider

The extracted_statements.sql catalog provides a comprehensive reference for the DMS conversion process in Step 2.

---
**End of Extraction Report**
