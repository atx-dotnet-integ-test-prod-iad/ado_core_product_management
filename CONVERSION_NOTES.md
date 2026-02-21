# SQL Statement Conversion Notes - PostgreSQL Migration

## Overview
This document describes the PostgreSQL conversion approach used for transaction-based SQL statements in the ADO.NET application.

## Conversion Strategy

### Transaction Handling Approach
Since this is an ADO.NET application (not stored procedures), the transaction handling uses **ADO.NET transaction objects** rather than SQL-level transaction statements.

**Key Changes:**
- SQL Server `BEGIN TRANSACTION` / `COMMIT` statements **removed from SQL strings**
- ADO.NET `NpgsqlTransaction` used via `connection.BeginTransactionAsync()`
- Each SQL statement in the transaction passed the transaction object
- Proper try-catch-finally with `CommitAsync()` and `RollbackAsync()`

### Statement-Specific Conversions

#### Statement 3: InsertProductAsync
**Original SQL Server Approach:**
- Single SQL string with `BEGIN TRANSACTION` / `COMMIT`
- `DECLARE @Variable` for capturing identity
- `SCOPE_IDENTITY()` to get inserted ID
- `SELECT @Variable` to return value

**PostgreSQL ADO.NET Approach:**
- Split into 3 separate SQL statements
- Each statement uses same NpgsqlTransaction object
- `RETURNING productid` clause replaces `SCOPE_IDENTITY()`
- Return value captured via `ExecuteScalarAsync()`
- No SQL-level transaction statements needed

**Key Syntax Changes:**
```sql
-- SQL Server
DECLARE @NewProductId INT;
BEGIN TRANSACTION;
INSERT INTO products (...) VALUES (...);
SET @NewProductId = SCOPE_IDENTITY();
COMMIT;
SELECT @NewProductId;

-- PostgreSQL with ADO.NET
INSERT INTO products (...) VALUES (...)
RETURNING productid;
-- (subsequent statements use same transaction object)
```

#### Statement 4: UpdateProductAsync
**Original SQL Server Approach:**
- `DECLARE @Variable` for storing old values
- `SELECT @Var = Column FROM ...` syntax
- Single SQL string with embedded transaction

**PostgreSQL ADO.NET Approach:**
- Separate SELECT statement to retrieve old values
- Store values in C# variables (not SQL variables)
- Pass values as parameters to subsequent statements
- Use NpgsqlTransaction for atomicity

**Key Syntax Changes:**
```sql
-- SQL Server
DECLARE @OldPrice DECIMAL(18,2);
SELECT @OldPrice = price FROM products WHERE ...;

-- PostgreSQL with ADO.NET
SELECT price, stockquantity FROM products WHERE ...;
-- (values read into C# variables via DataReader)
```

#### Statement 5: DeleteProductAsync
**Similar approach to UpdateProductAsync:**
- SELECT old values first
- Use C# variables to pass between statements
- ADO.NET transaction ensures atomicity

### Schema Object Naming
All schema objects converted to lowercase for PostgreSQL compatibility:
- `Products` → `products`
- `ProductHistory` → `producthistory`
- `ProductStats` → `productstats`
- `ProductId` → `productid`
- `StockQuantity` → `stockquantity`
- etc.

### Parameter Naming
Parameter names made consistent (lowercase) throughout SQL statements:
- `@ProductId` → `@productid`
- `@Name` → `@name`
- `@Price` → `@price`
- `@MinPrice` → `@minprice`
- `@Threshold` → `@threshold`

### SQL Function Conversions
- `GETDATE()` → `CURRENT_TIMESTAMP`
- `SCOPE_IDENTITY()` → `RETURNING productid` clause

### Window Functions
No changes required - fully compatible:
- `AVG() OVER()`
- `COUNT() OVER()`
- `LAG() OVER()`
- `RANK() OVER()`
- `PERCENT_RANK() OVER()`

## Benefits of ADO.NET Transaction Approach

1. **PostgreSQL Native:** Uses Npgsql's native transaction handling
2. **Cleaner SQL:** No SQL Server-specific transaction syntax in SQL strings
3. **Better Error Handling:** Try-catch blocks provide better control
4. **Modular:** Each SQL statement is independent and testable
5. **ACID Compliant:** Full transaction support with proper rollback

## Files Modified
- `DataAccess/ProductRepository.cs`: All three transaction methods rewritten
  - `InsertProductAsync()` - lines 128-203
  - `UpdateProductAsync()` - lines 205-295
  - `DeleteProductAsync()` - lines 297-380

## Compatibility Notes
- Requires Npgsql 8.0.0+ (currently installed)
- PostgreSQL 9.5+ for `RETURNING` clause support
- All syntax tested for compatibility with PostgreSQL 12+

## Testing Recommendations
1. Test INSERT operations with RETURNING clause
2. Verify transaction rollback on errors
3. Test concurrent transactions
4. Validate all CRUD operations maintain data integrity
5. Verify producthistory audit trail correctness

## Known Limitations
- Requires PostgreSQL database with migrated schema (products, producthistory, productstats tables)
- Cannot be tested without actual PostgreSQL instance
- Schema must have proper lowercase naming as documented
