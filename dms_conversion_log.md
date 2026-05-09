# SQL Statement Migration Log

## Migration Summary
- **Source**: Microsoft SQL Server (T-SQL)
- **Target**: PostgreSQL
- **Source File**: sourceCode/DataAccess/ProductRepository.cs
- **Total Statements**: 7
- **DMS Tool Successful Conversions**: 0
- **DMS Tool Failed Conversions**: 7
- **Manual Conversions Required**: 7
- **Equivalency Tool Results**: 7 ERROR (tool internal error: 'uniqueID')

## DMS Tool Error
All 7 statements failed with the same DMS error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

## Manual Conversion Rules Applied
Since DMS failed for all statements, manual conversion was applied with the following rules:
1. All schema object names converted to lowercase (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
2. `GETDATE()` → `NOW()`
3. `SCOPE_IDENTITY()` → `RETURNING productid` clause
4. `DECLARE @var` / `SET @var` → PostgreSQL application-level variable handling
5. `BEGIN TRANSACTION` / `COMMIT` → Application-managed transactions via NpgsqlTransaction
6. `INT IDENTITY(1,1)` → `SERIAL`
7. `NVARCHAR(n)` → `VARCHAR(n)`
8. `NVARCHAR(MAX)` → `TEXT`
9. `DATETIME` → `TIMESTAMP`
10. Integer division guarded with `CAST(... AS DECIMAL)` where needed

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Lowercase schema objects; SQL syntax compatible with PostgreSQL (CTEs, window functions supported)
- **Equivalency Check**: ERROR ('uniqueID')

### Statement 2: GetProductByIdAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Lowercase schema objects; LAG window function supported in PostgreSQL
- **Equivalency Check**: ERROR ('uniqueID')

### Statement 3: InsertProductAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Major restructuring required:
  - Replaced `DECLARE @NewProductId` + `SCOPE_IDENTITY()` with CTE using `RETURNING productid`
  - Replaced `BEGIN TRANSACTION`/`COMMIT` with single atomic CTE statement (writable CTEs in PostgreSQL)
  - Replaced `GETDATE()` with `NOW()`
  - All schema objects lowercased
- **Equivalency Check**: ERROR ('uniqueID')

### Statement 4: UpdateProductAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Major restructuring required:
  - Replaced `DECLARE @OldPrice`/`@OldStock` with application-level variables (C# code)
  - Split single T-SQL batch into separate parameterized statements within NpgsqlTransaction
  - Replaced `GETDATE()` with `NOW()`
  - All schema objects lowercased
- **Equivalency Check**: ERROR ('uniqueID')

### Statement 5: DeleteProductAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Major restructuring required:
  - Same pattern as Statement 4: split into separate statements in NpgsqlTransaction
  - Replaced `DECLARE @OldPrice`/`@OldStock` with application-level variables
  - Replaced `GETDATE()` with `NOW()`
  - All schema objects lowercased
- **Equivalency Check**: ERROR ('uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: Lowercase schema objects; RANK/PERCENT_RANK window functions supported in PostgreSQL
- **Equivalency Check**: ERROR ('uniqueID')

### Statement 7: GetLowStockProductsAsync
- **DMS Attempt**: Failed
- **DMS Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Manual Conversion**: 
  - Lowercase schema objects
  - Added `CAST(stockquantity AS DECIMAL)` to prevent integer division truncation
  - AVG/MIN/MAX window functions supported in PostgreSQL
- **Equivalency Check**: ERROR ('uniqueID')

## SQL Equivalency Tool Error
All 7 equivalency validations returned ERROR with message: `'uniqueID'`
This appears to be an internal tool error unrelated to the SQL statements themselves.

## Static Code Changes
1. **Package Reference**: `Microsoft.Data.SqlClient 5.1.4` → `Npgsql 8.0.1`
2. **Import**: `using Microsoft.Data.SqlClient` → `using Npgsql`
3. **Classes Replaced**:
   - `SqlConnection` → `NpgsqlConnection`
   - `SqlCommand` → `NpgsqlCommand`
   - `SqlDataReader` → `NpgsqlDataReader`
   - `SqlTransaction` (implicit) → `NpgsqlTransaction`
4. **Connection String**: SQL Server format → PostgreSQL format
   - `Server=localhost` → `Host=localhost`
   - `Database=ProductManagement` → `Database=productmanagement`
   - `Trusted_Connection=True` → `Username=postgres;Password=postgres`
   - Removed `MultipleActiveResultSets=true` and `TrustServerCertificate=True`
