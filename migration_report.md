# SQL Server to PostgreSQL Migration Report
## DMS Conversion Summary

### DMS Tool Status
- **Tool**: dms-mcp___statement_conversion_tool
- **Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Status**: FAILED for all 7 statements
- **Error**: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
- **Fallback**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA applied to all statements

### SQL Equivalency Tool Status
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Status**: ERROR for all 7 statement pairs
- **Error**: 'uniqueID' (infrastructure-level error)
- **Note**: This is independent from DMS - both tools had infrastructure issues

### Migration Statistics
| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Successfully converted by DMS | 0 |
| Manual conversion (DMS failure) | 7 |
| Validated as equivalent | 0 |
| Validated as non-equivalent | 0 |
| Equivalency validation errors | 7 |

### Conversion Details

#### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: SELECT with CTE and window functions (AVG, COUNT OVER)
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, SQL syntax compatible as-is
- **Changes**: Table/column names lowercased

#### Statement 2: GetProductByIdAsync  
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: SELECT with CTE and LAG window function
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, SQL syntax compatible as-is
- **Changes**: Table/column names lowercased

#### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), INSERT, UPDATE
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: 
  - SCOPE_IDENTITY() replaced with RETURNING clause via CTE
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT replaced with CTE-based single statement
  - All schema objects lowercased

#### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT, UPDATE
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**:
  - DECLARE/SET replaced with DO $$ block variables
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT replaced with DO $$ BEGIN/END block
  - All schema objects lowercased

#### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: Transaction block with DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**:
  - DECLARE/SET replaced with DO $$ block variables
  - GETDATE() replaced with NOW()
  - BEGIN TRANSACTION/COMMIT replaced with DO $$ BEGIN/END block
  - All schema objects lowercased

#### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: SELECT with CTE, RANK and PERCENT_RANK window functions
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects, SQL syntax compatible as-is
- **Changes**: Table/column names lowercased

#### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: SELECT with CTE and AVG/MIN/MAX window functions
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: 
  - Added ::numeric cast to avoid integer division
  - Lowercase schema objects
  - SQL syntax compatible as-is

### Static Code Changes

#### Package References (AdoCore.csproj)
- Removed: `Microsoft.Data.SqlClient` v5.1.4
- Added: `Npgsql` v8.0.1

#### ADO.NET Class Replacements (ProductRepository.cs)
- `using Microsoft.Data.SqlClient` → `using Npgsql`
- `SqlConnection` → `NpgsqlConnection`
- `SqlCommand` → `NpgsqlCommand`
- `SqlDataReader` → `NpgsqlDataReader`

#### Connection String Updates (appsettings.json)
- `Server=localhost` → `Host=localhost`
- `Database=ProductManagement` → `Database=productmanagement`
- `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True` → `Username=postgres;Password=postgres;`

#### Column Name References in MapProductFromReader
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`
