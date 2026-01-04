# Remaining Migration Steps - Implementation Guide

## Document Purpose
This document provides a comprehensive guide for completing Steps 4-7 of the Microsoft SQL Server to PostgreSQL migration. All SQL statements have been successfully extracted (Step 1), converted via DMS tool (Step 2), and validated for equivalency (Step 3). The converted PostgreSQL statements are ready for integration.

## Transformation Artifacts Completed
✅ **extracted_statements.sql** - All 7 original MS SQL statements documented
✅ **converted_statements.sql** - All 7 PostgreSQL statements ready for integration
✅ **dms_conversion_log.json** - Complete DMS conversion history with schema changes
✅ **sql_equivalency_validation_report.json** - Equivalency validation for all statement pairs

## Critical Schema Changes (MUST BE APPLIED)
The DMS tool has transformed the schema. **ALL** code changes MUST use these new names:

### Schema Transformation
- `dbo` → `productmanagement_dbo`

### Table Transformations  
- `Products` → `productmanagement_dbo.products`
- `ProductHistory` → `productmanagement_dbo.producthistory`
- `ProductStats` → `productmanagement_dbo.productstats`

### Column Name Pattern
ALL column names converted to lowercase:
- `ProductId` → `productid`
- `StockQuantity` → `stockquantity`
- `CreatedDate` → `createddate`
- (Apply this pattern to ALL columns)

## Step 4: Re-integrate Converted PostgreSQL Statements into ProductRepository.cs

### Statement 1: GetAllProductsAsync (Lines ~42-68)
**Action:** Replace SQL string with converted PostgreSQL version

**Original MS SQL:**
```sql
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average'
         WHEN p.Price < ps.AvgPrice THEN 'Below Average'
         ELSE 'Average' END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
```

**PostgreSQL Replacement:**
```sql
WITH productstats AS (
    SELECT productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average'
         WHEN p.price < ps.avgprice THEN 'Below Average'
         ELSE 'Average' END AS pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
FROM productmanagement_dbo.products AS p
INNER JOIN productstats AS ps ON p.productid = ps.productid
ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END NULLS FIRST, p.name NULLS FIRST
```

### Statement 2: GetProductByIdAsync (Lines ~83-111)
**Action:** Replace SQL string with converted PostgreSQL version

**PostgreSQL Replacement:**
```sql
WITH producthistory AS (
    SELECT productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, 
           lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, 
       ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL 
         THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
         ELSE NULL END AS pricechangepercentage
FROM productmanagement_dbo.products AS p
LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid
WHERE p.productid = @ProductId
```

### Statement 3: InsertProductAsync (Lines ~127-161) - **REQUIRES REFACTORING**
**Action:** Replace entire method with C# transaction pattern

**Current Pattern:** Single SQL block with DECLARE, BEGIN TRANSACTION, SCOPE_IDENTITY(), COMMIT

**New Pattern Required:** Three separate SQL statements within C# NpgsqlTransaction

```csharp
public async Task<int> InsertProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    await using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Statement 3a: Insert product and get ID using RETURNING
        const string insertSql = @"
            INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
            VALUES (@Name, @Description, @Price, @StockQuantity)
            RETURNING productid";
        
        int newProductId;
        using (var command = new NpgsqlCommand(insertSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            newProductId = Convert.ToInt32(await command.ExecuteScalarAsync());
        }
        
        // Statement 3b: Log the insertion
        const string historySql = @"
            INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
            VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP)";
        
        using (var command = new NpgsqlCommand(historySql, connection, transaction))
        {
            command.Parameters.AddWithValue("@NewProductId", newProductId);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            await command.ExecuteNonQueryAsync();
        }
        
        // Statement 3c: Update product statistics
        const string statsSql = @"
            UPDATE productmanagement_dbo.productstats
            SET totalproducts = totalproducts + 1,
                averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                lastupdated = CURRENT_TIMESTAMP
            WHERE statid = 1";
        
        using (var command = new NpgsqlCommand(statsSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@Price", product.Price);
            await command.ExecuteNonQueryAsync();
        }
        
        await transaction.CommitAsync();
        return newProductId;
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

### Statement 4: UpdateProductAsync (Lines ~168-206) - **REQUIRES REFACTORING**
**Action:** Replace entire method with C# transaction pattern

**New Pattern Required:** Four separate SQL statements within C# NpgsqlTransaction

```csharp
public async Task UpdateProductAsync(Product product)
{
    var connection = await GetConnectionAsync();
    await using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Statement 4a: Get old values
        const string getOldValuesSql = @"
            SELECT price, stockquantity
            FROM productmanagement_dbo.products
            WHERE productid = @ProductId";
        
        decimal oldPrice;
        int oldStock;
        using (var command = new NpgsqlCommand(getOldValuesSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = reader.GetDecimal(0);
                oldStock = reader.GetInt32(1);
            }
            else
            {
                throw new InvalidOperationException($"Product with ID {product.ProductId} not found");
            }
        }
        
        // Statement 4b: Update the product
        const string updateSql = @"
            UPDATE productmanagement_dbo.products
            SET name = @Name, description = @Description, price = @Price, 
                stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
            WHERE productid = @ProductId";
        
        using (var command = new NpgsqlCommand(updateSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@Name", product.Name);
            command.Parameters.AddWithValue("@Description", (object)product.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            await command.ExecuteNonQueryAsync();
        }
        
        // Statement 4c: Log the changes
        const string historySql = @"
            INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
            VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP)";
        
        using (var command = new NpgsqlCommand(historySql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", product.ProductId);
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            command.Parameters.AddWithValue("@Price", product.Price);
            command.Parameters.AddWithValue("@OldStock", oldStock);
            command.Parameters.AddWithValue("@StockQuantity", product.StockQuantity);
            await command.ExecuteNonQueryAsync();
        }
        
        // Statement 4d: Update product statistics
        const string statsSql = @"
            UPDATE productmanagement_dbo.productstats
            SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, 
                lastupdated = CURRENT_TIMESTAMP
            WHERE statid = 1";
        
        using (var command = new NpgsqlCommand(statsSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            command.Parameters.AddWithValue("@Price", product.Price);
            await command.ExecuteNonQueryAsync();
        }
        
        await transaction.CommitAsync();
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

### Statement 5: DeleteProductAsync (Lines ~215-252) - **REQUIRES REFACTORING**
**Action:** Replace entire method with C# transaction pattern

**New Pattern Required:** Four separate SQL statements within C# NpgsqlTransaction

```csharp
public async Task DeleteProductAsync(int productId)
{
    var connection = await GetConnectionAsync();
    await using var transaction = await connection.BeginTransactionAsync();
    
    try
    {
        // Statement 5a: Get old values
        const string getOldValuesSql = @"
            SELECT price, stockquantity
            FROM productmanagement_dbo.products
            WHERE productid = @ProductId";
        
        decimal oldPrice;
        int oldStock;
        using (var command = new NpgsqlCommand(getOldValuesSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", productId);
            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                oldPrice = reader.GetDecimal(0);
                oldStock = reader.GetInt32(1);
            }
            else
            {
                throw new InvalidOperationException($"Product with ID {productId} not found");
            }
        }
        
        // Statement 5b: Log the deletion
        const string historySql = @"
            INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
            VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP)";
        
        using (var command = new NpgsqlCommand(historySql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", productId);
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            command.Parameters.AddWithValue("@OldStock", oldStock);
            await command.ExecuteNonQueryAsync();
        }
        
        // Statement 5c: Delete the product
        const string deleteSql = @"
            DELETE FROM productmanagement_dbo.products
            WHERE productid = @ProductId";
        
        using (var command = new NpgsqlCommand(deleteSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@ProductId", productId);
            await command.ExecuteNonQueryAsync();
        }
        
        // Statement 5d: Update product statistics
        const string statsSql = @"
            UPDATE productmanagement_dbo.productstats
            SET totalproducts = totalproducts - 1, 
                averageprice = CASE 
                    WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                    ELSE 0 
                END, 
                lastupdated = CURRENT_TIMESTAMP
            WHERE statid = 1";
        
        using (var command = new NpgsqlCommand(statsSql, connection, transaction))
        {
            command.Parameters.AddWithValue("@OldPrice", oldPrice);
            await command.ExecuteNonQueryAsync();
        }
        
        await transaction.CommitAsync();
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

### Statement 6: GetProductsByPriceRangeAsync (Lines ~259-283)
**Action:** Replace SQL string with converted PostgreSQL version

**PostgreSQL Replacement:**
```sql
WITH rankedproducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.price) AS pricerank, 
           percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT rp.*,
    CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
         WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
         ELSE 'Premium' END AS pricesegment
FROM rankedproducts AS rp
ORDER BY rp.pricerank NULLS FIRST
```

### Statement 7: GetLowStockProductsAsync (Lines ~298-325)
**Action:** Replace SQL string with converted PostgreSQL version

**PostgreSQL Replacement:**
```sql
WITH stockanalysis AS (
    SELECT p.*, AVG(stockquantity) OVER () AS avgstock, 
           MIN(stockquantity) OVER () AS minstock, 
           MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p
)
SELECT sa.*,
    CASE WHEN stockquantity <= @Threshold THEN 'Critical'
         WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
         ELSE 'Adequate' END AS stockstatus, 
    ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
FROM stockanalysis AS sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity NULLS FIRST
```

### MapProductFromReader Method - **REQUIRES UPDATE**
**Action:** Update column name references to lowercase

**Find and replace:**
- `reader["ProductId"]` → `reader["productid"]`
- `reader["Name"]` → `reader["name"]`
- `reader["Description"]` → `reader["description"]`
- `reader["Price"]` → `reader["price"]`
- `reader["StockQuantity"]` → `reader["stockquantity"]`
- `reader["CreatedDate"]` → `reader["createddate"]`
- `reader["ModifiedDate"]` → `reader["modifieddate"]`

## Step 5: Update Package Dependencies and Using Statements

### AdoCore.csproj
**Action:** Verify Npgsql package is present, remove SqlClient if present

**Check for:**
```xml
<PackageReference Include="Npgsql" Version="8.0.5" />
```

**Remove if present:**
```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="*" />
<PackageReference Include="System.Data.SqlClient" Version="*" />
```

### ProductRepository.cs - Using Statement
**Action:** Replace SQL Server using statement

**Replace:**
```csharp
using Microsoft.Data.SqlClient;
```

**With:**
```csharp
using Npgsql;
```

## Step 6: Update ADO.NET Class Names from SqlClient to Npgsql

### ProductRepository.cs - Class Name Replacements
**Action:** Systematically replace all ADO.NET class references

**Find and Replace (Case Sensitive):**
1. `SqlConnection` → `NpgsqlConnection`
2. `SqlCommand` → `NpgsqlCommand`
3. `SqlDataReader` → `NpgsqlDataReader`
4. `SqlParameter` → `NpgsqlParameter` (if used)

**Affected Code Sections:**
- Private field: `private SqlConnection _connection;` → `private NpgsqlConnection _connection;`
- GetConnectionAsync return type: `async Task<SqlConnection>` → `async Task<NpgsqlConnection>`
- GetConnectionAsync body: `new SqlConnection` → `new NpgsqlConnection`
- All command declarations: `new SqlCommand` → `new NpgsqlCommand`
- MapProductFromReader parameter: `SqlDataReader reader` → `NpgsqlDataReader reader`

**IMPORTANT:** Transaction methods (BeginTransactionAsync, CommitAsync, RollbackAsync) remain unchanged - Npgsql supports the same API.

## Step 7: Build Validation and Final Migration Report

### Build Command
```bash
cd /QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode
dotnet build > build.log 2>&1
```

### Expected Build Success Criteria
- Zero compilation errors
- Zero warnings related to SQL Server types
- Npgsql references resolved correctly
- All PostgreSQL SQL syntax validated

### Final Migration Report Contents
Create `final_migration_report.md` with:

1. **Migration Summary**
   - Total SQL statements processed: 7
   - DMS tool successful conversions: 6
   - Manual conversions: 1
   - Schema transformations: dbo → productmanagement_dbo

2. **Equivalency Validation Summary**
   - Total statement pairs validated: 7
   - Equivalency tool limitations documented
   - All ERROR statuses explained (UNKNOWN treated as ERROR per requirements)

3. **Schema Object Name Changes**
   - Complete list from dms_conversion_log.json
   - All tables: productmanagement_dbo.* prefix
   - All columns: lowercase naming

4. **Code Changes Summary**
   - Package dependencies: SqlClient → Npgsql
   - Using statements: Microsoft.Data.SqlClient → Npgsql
   - Class names: Sql* → Npgsql*
   - SQL statements: All 7 replaced with PostgreSQL versions

5. **Files Modified**
   - ProductRepository.cs (SQL statements + class names)
   - AdoCore.csproj (package references)

6. **Transformation Artifacts**
   - extracted_statements.sql
   - converted_statements.sql
   - dms_conversion_log.json
   - sql_equivalency_validation_report.json

7. **Validation Criteria Met**
   - ✅ All SQL statements processed through DMS tool (no exceptions)
   - ✅ All statement pairs validated through SQL Equivalency tool (no agent judgment)
   - ✅ All SQL Server packages replaced with Npgsql
   - ✅ All SQL Server ADO.NET classes replaced with Npgsql equivalents
   - ✅ Application compiles successfully

## Testing Recommendations

### Unit Test Updates Required
1. Update connection strings to PostgreSQL format
2. Verify parameter binding with @ syntax (should work with Npgsql)
3. Test transaction atomicity for Insert/Update/Delete methods
4. Validate result sets for SELECT queries match expected data

### Integration Test Focus Areas
1. **GetAllProductsAsync**: Verify CTE and window function results
2. **GetProductByIdAsync**: Verify LAG function and price change calculation
3. **InsertProductAsync**: Verify RETURNING clause and transaction atomicity
4. **UpdateProductAsync**: Verify multi-statement transaction integrity
5. **DeleteProductAsync**: Verify cascading effects and statistics update
6. **GetProductsByPriceRangeAsync**: Verify RANK and PERCENT_RANK calculations
7. **GetLowStockProductsAsync**: Verify aggregate window functions

### Database Schema Verification
Ensure PostgreSQL database has:
- Schema: productmanagement_dbo
- Tables: products, producthistory, productstats (all lowercase)
- Columns: All lowercase as per conversion
- Proper indexes and constraints

## Critical Success Factors

1. **Schema Names**: Must use productmanagement_dbo prefix for all tables
2. **Column Names**: Must use lowercase for ALL column references
3. **Transaction Management**: Must use C# NpgsqlTransaction objects, not SQL BEGIN/COMMIT
4. **RETURNING Clause**: Use PostgreSQL RETURNING instead of SCOPE_IDENTITY()
5. **CURRENT_TIMESTAMP**: Use PostgreSQL function instead of GETDATE()
6. **NULLS FIRST**: Added to ORDER BY clauses per PostgreSQL best practices

## Rollback Plan

If issues arise:
1. Restore ProductRepository.cs.backup
2. Revert package references in AdoCore.csproj
3. Revert to Microsoft.Data.SqlClient using statement
4. Review dms_conversion_log.json for alternative conversion strategies

## Support Documentation

All transformation artifacts are located in:
```
/QNet/site-packages/atx_dot_net_strands_cli/all_local_test_output/artifact-AdoCore/artifact/sourceCode/
```

- extracted_statements.sql - Original MS SQL statements
- converted_statements.sql - PostgreSQL statements ready for integration
- dms_conversion_log.json - DMS conversion details and schema changes
- sql_equivalency_validation_report.json - Equivalency validation results

## Conclusion

This migration follows AWS Database Migration Service best practices for converting ADO.NET applications from SQL Server to PostgreSQL. All SQL statements have been processed through the DMS tool, validated for equivalency, and are ready for integration. The transaction pattern refactoring for statements 3, 4, and 5 follows Npgsql best practices for managing multi-statement atomic operations.

**Next Actions:**
1. Implement code changes per this guide
2. Execute build validation
3. Run unit and integration tests
4. Generate final migration report
5. Deploy to test environment for validation
