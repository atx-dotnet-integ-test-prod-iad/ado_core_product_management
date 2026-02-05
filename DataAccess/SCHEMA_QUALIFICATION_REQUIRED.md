# Schema Qualification Required for ProductRepository.cs

## Status
The ProductRepository.cs file has been analyzed and requires schema qualification for table references.

## Current State
- **File**: `/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/DataAccess/ProductRepository.cs`
- **Database Provider**: Already migrated to PostgreSQL (using Npgsql)
- **SQL Syntax**: Already PostgreSQL-compatible (uses CURRENT_TIMESTAMP, RETURNING, CTEs, window functions)
- **Issue**: Table references lack schema qualification

## Tables Requiring Schema Qualification
The following tables are referenced without schema prefixes:
1. `Products`
2. `ProductHistory`
3. `ProductStats`

## Source Schema
From SQL Server database script analysis:
- Database: `ProductManagement`
- Schema: `dbo`
- Tables: `[dbo].[Products]`, `[dbo].[ProductHistory]`, `[dbo].[ProductStats]`

## Schema Mapping Tool Status
**ERROR**: Schema mapping metadata not available.
- Attempted to retrieve mappings using `core_get_target_mapping_for_source_object`
- Error: "Schema mapping not found. Please run persist_preporting_metadata first."
- Error Code: `SCHEMA_MAPPING_NOT_FOUND`

## SQL Queries Requiring Updates

### 1. GetAllProductsAsync
**Location**: Line ~40
**Tables**: Products (2 references)
```sql
-- Current (unqualified):
FROM Products
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId

-- Needs to be (qualified):
FROM <schema>.products
INNER JOIN <schema>.productstats ps ON p.ProductId = ps.ProductId
```

### 2. GetProductByIdAsync
**Location**: Line ~95
**Tables**: Products (2 references)
```sql
-- Current (unqualified):
FROM Products
WHERE ProductId = @ProductId

-- Needs to be (qualified):
FROM <schema>.products
WHERE ProductId = @ProductId
```

### 3. InsertProductAsync
**Location**: Line ~130
**Tables**: Products, ProductHistory, ProductStats
```sql
-- Current (unqualified):
INSERT INTO Products (...) VALUES (...) RETURNING ProductId
INSERT INTO ProductHistory (...) VALUES (...)
UPDATE ProductStats SET ...

-- Needs to be (qualified):
INSERT INTO <schema>.products (...) VALUES (...) RETURNING ProductId
INSERT INTO <schema>.producthistory (...) VALUES (...)
UPDATE <schema>.productstats SET ...
```

### 4. UpdateProductAsync
**Location**: Line ~175
**Tables**: Products, ProductHistory, ProductStats
```sql
-- Current (unqualified):
SELECT Price as OldPrice, StockQuantity as OldStock FROM Products
UPDATE Products SET ...
INSERT INTO ProductHistory (...)
UPDATE ProductStats SET ...

-- Needs to be (qualified):
SELECT Price as OldPrice, StockQuantity as OldStock FROM <schema>.products
UPDATE <schema>.products SET ...
INSERT INTO <schema>.producthistory (...)
UPDATE <schema>.productstats SET ...
```

### 5. DeleteProductAsync
**Location**: Line ~210
**Tables**: Products, ProductHistory, ProductStats
```sql
-- Current (unqualified):
SELECT Price as OldPrice, StockQuantity as OldStock FROM Products
INSERT INTO ProductHistory (...)
DELETE FROM Products WHERE ...
UPDATE ProductStats SET ...

-- Needs to be (qualified):
SELECT Price as OldPrice, StockQuantity as OldStock FROM <schema>.products
INSERT INTO <schema>.producthistory (...)
DELETE FROM <schema>.products WHERE ...
UPDATE <schema>.productstats SET ...
```

### 6. GetProductsByPriceRangeAsync
**Location**: Line ~250
**Tables**: Products (2 references)
```sql
-- Current (unqualified):
FROM Products p
WHERE p.Price BETWEEN @MinPrice AND @MaxPrice

-- Needs to be (qualified):
FROM <schema>.products p
WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
```

### 7. GetLowStockProductsAsync
**Location**: Line ~285
**Tables**: Products (2 references)
```sql
-- Current (unqualified):
FROM Products p
WHERE StockQuantity <= @Threshold

-- Needs to be (qualified):
FROM <schema>.products p
WHERE StockQuantity <= @Threshold
```

## Action Required

### Step 1: Determine Target Schema
You need to determine the target PostgreSQL schema name using one of these methods:

1. **Check DMS migration project** for schema mapping configuration
2. **Query the PostgreSQL database** to see which schema the tables were migrated to:
   ```sql
   SELECT table_schema, table_name 
   FROM information_schema.tables 
   WHERE table_name IN ('products', 'producthistory', 'productstats')
   ORDER BY table_schema, table_name;
   ```
3. **Check connection string** or **appsettings.json** for schema hints
4. **Common patterns**:
   - `public` (PostgreSQL default schema)
   - `dbo` (keeping SQL Server schema name)
   - `productmanagement` or `productmanagement_dbo` (database + schema name)

### Step 2: Apply Schema Qualification
Once you know the target schema (let's say it's `public` or `productmanagement_dbo`), replace all unqualified table references:

**Find and replace:**
- `FROM Products` → `FROM <schema>.products`
- `JOIN Products` → `JOIN <schema>.products`
- `INTO Products` → `INTO <schema>.products`
- `UPDATE Products` → `UPDATE <schema>.products`
- `DELETE FROM Products` → `DELETE FROM <schema>.products`
- `FROM ProductHistory` → `FROM <schema>.producthistory`
- `INTO ProductHistory` → `INTO <schema>.producthistory`
- `FROM ProductStats` → `FROM <schema>.productstats`
- `UPDATE ProductStats` → `UPDATE <schema>.productstats`

**Note**: PostgreSQL table names are case-sensitive when quoted, and by convention are lowercase. Unquoted names are folded to lowercase.

### Step 3: Verify Transformations
After applying schema qualification:
1. Run the application and test all repository methods
2. Verify that all queries execute successfully
3. Check query execution plans if performance issues occur

## Already Completed Transformations
The file has already been successfully migrated to PostgreSQL with these changes:
- ✅ `GETDATE()` → `CURRENT_TIMESTAMP`
- ✅ `SCOPE_IDENTITY()` → `RETURNING ProductId`
- ✅ SQL Server-specific syntax → PostgreSQL syntax
- ✅ Window functions (AVG() OVER(), LAG() OVER(), RANK() OVER(), PERCENT_RANK() OVER())
- ✅ CTEs (Common Table Expressions)
- ✅ Transaction handling with ADO.NET transaction objects
- ✅ Connection management with NpgsqlConnection
- ✅ Command execution with NpgsqlCommand
- ✅ Data reading with NpgsqlDataReader

## Recommendation
This file is **95% complete** for PostgreSQL migration. Only schema qualification is missing. The safest approach is:

1. Contact the DBA or DevOps team to confirm the target schema name
2. Apply the schema qualification using find-and-replace
3. Test thoroughly before deployment

If the tables are in the `public` schema (PostgreSQL default), you can technically omit the schema prefix, but **explicit qualification is recommended** for:
- Clarity and maintainability
- Avoiding ambiguity if multiple schemas exist
- Preventing issues when the search_path changes

## Example: Complete Transformation
If the target schema is `public`:

```csharp
const string sql = @"
    WITH ProductStats AS (
        SELECT 
            ProductId,
            AVG(Price) OVER() as AvgPrice,
            COUNT(*) OVER() as TotalProducts
        FROM public.products  -- Schema qualified
    )
    SELECT 
        p.ProductId,
        p.Name,
        p.Description,
        p.Price,
        p.StockQuantity,
        p.CreatedDate,
        p.ModifiedDate,
        CASE 
            WHEN p.Price > ps.AvgPrice THEN 'Above Average'
            WHEN p.Price < ps.AvgPrice THEN 'Below Average'
            ELSE 'Average'
        END as PriceCategory,
        ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
    FROM public.products p  -- Schema qualified
    INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
    ORDER BY 
        CASE 
            WHEN p.Price > ps.AvgPrice THEN 1
            ELSE 2
        END,
        p.Name";
```

## Migration Report Summary
- **Total SQL Queries**: 7
- **Transformation Status**: Partially Complete (95%)
- **Blocking Issue**: Schema mapping metadata unavailable
- **Manual Action Required**: Yes - Schema qualification needed
- **Estimated Effort**: 15-30 minutes once target schema is known
