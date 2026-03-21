# Migration Report: MS SQL Server to PostgreSQL - AdoCore Application

## Executive Summary

This report documents the comprehensive migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL. The migration involved converting all 7 SQL statements, updating database access code to use Npgsql, and ensuring PostgreSQL-compatible connection strings and transaction handling.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Tool Conversion Attempts | 14 (7 initial + 7 retry) |
| DMS Tool Successes | 0 |
| DMS Tool Failures | 14 |
| Manual Conversions (DMS Failure) | 7 |
| Equivalency Validations Performed | 7 |
| Equivalency: EQUIVALENT | 0 |
| Equivalency: NOT_EQUIVALENT | 0 |
| Equivalency: ERROR | 7 |
| Files Modified | 3 (converted_statements.sql, sql_equivalency_validation_report.json, migration_report.md) |
| Artifacts Generated | 4 |
| Final Build Status | SUCCESS (0 errors) |

## DMS Conversion Results

All 7 statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) twice (initial + retry) with parameters:
- `schema_name`: dbo
- `database_name`: ProductManagement
- `migration_project_identifier`: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

All 14 DMS conversion attempts failed due to metadata model creation timeout errors. Schema mappings were successfully retrieved via the DMS schema mapping tool, which provided the target schema names and column mappings used for manual conversion.

### Statement-by-Statement DMS Results

| # | Method | DMS Initial Status | DMS Retry Status | Failure Reason |
|---|--------|-------------------|------------------|----------------|
| 1 | GetAllProductsAsync | FAILED | FAILED | Metadata model creation did not complete after 15 attempts |
| 2 | GetProductByIdAsync | FAILED | FAILED | Metadata model creation did not complete after 15 attempts |
| 3 | InsertProductAsync | FAILED | FAILED | Metadata model creation did not complete after 15 attempts |
| 4 | UpdateProductAsync | FAILED | FAILED | Metadata model creation did not complete after 15 attempts |
| 5 | DeleteProductAsync | FAILED | FAILED | Metadata model creation did not complete after 15 attempts |
| 6 | GetProductsByPriceRangeAsync | FAILED | FAILED | Metadata model creation did not complete after 15 attempts |
| 7 | GetLowStockProductsAsync | FAILED | FAILED | Metadata model creation did not complete after 15 attempts |

### Manual Conversion Applied

Since all DMS conversions failed, manual conversion was applied with `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` method using the following transformation rules derived from the DMS schema mapping tool:

| Transformation | MS SQL Server | PostgreSQL |
|---------------|---------------|------------|
| Schema | dbo | productmanagement_dbo |
| Table: Products | dbo.Products | productmanagement_dbo.products |
| Table: ProductHistory | dbo.ProductHistory | productmanagement_dbo.producthistory |
| Table: ProductStats | dbo.ProductStats | productmanagement_dbo.productstats |
| Function: GETDATE() | GETDATE() | clock_timestamp() |
| Identity: SCOPE_IDENTITY() | SCOPE_IDENTITY() | RETURNING clause with CTE |
| Data Types: DECIMAL | DECIMAL(18,2) | NUMERIC(18,2) |
| Data Types: INT | INT | INTEGER |
| Data Types: NVARCHAR | NVARCHAR(n) | VARCHAR(n) |
| Data Types: DATETIME | DATETIME | TIMESTAMP WITHOUT TIME ZONE |
| Data Types: BIT | BIT | NUMERIC(1,0) |
| Variable Prefix | @ | var_ (in DO blocks) |
| Column Names | CamelCase | lowercase |
| ORDER BY | Default sort | Added NULLS FIRST for compatibility |

## SQL Equivalency Validation Results

All 7 statement pairs were validated through the SQL Equivalency MCP tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR status with error: `'uniqueID'` - a systemic tool error.

| # | Method | Equivalency Status | Tool Error | Timestamp |
|---|--------|-------------------|------------|-----------|
| 1 | GetAllProductsAsync | ERROR | 'uniqueID' | 2026-03-21T00:05:14 |
| 2 | GetProductByIdAsync | ERROR | 'uniqueID' | 2026-03-21T00:05:45 |
| 3 | InsertProductAsync | ERROR | 'uniqueID' | 2026-03-21T00:06:01 |
| 4 | UpdateProductAsync | ERROR | 'uniqueID' | 2026-03-21T00:06:19 |
| 5 | DeleteProductAsync | ERROR | 'uniqueID' | 2026-03-21T00:06:36 |
| 6 | GetProductsByPriceRangeAsync | ERROR | 'uniqueID' | 2026-03-21T00:06:50 |
| 7 | GetLowStockProductsAsync | ERROR | 'uniqueID' | 2026-03-21T00:07:04 |

**Note**: Per transformation requirements, equivalency status is reported SOLELY from tool output. No agent judgment was used.

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
**Type**: SELECT with CTE, Window Functions (AVG, COUNT)

**Original MS SQL**:
```sql
WITH ProductStats AS (SELECT ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts FROM dbo.Products) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average' WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END AS PriceCategory, ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage FROM dbo.Products AS p INNER JOIN ProductStats AS ps ON p.ProductId = ps.ProductId ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
```

**Converted PostgreSQL**:
```sql
WITH productstats AS (SELECT productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts FROM productmanagement_dbo.products) SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage FROM productmanagement_dbo.products AS p INNER JOIN productstats AS ps ON p.productid = ps.productid ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END NULLS FIRST, p.name NULLS FIRST
```

### Statement 2: GetProductByIdAsync
**Type**: SELECT with CTE, LAG Window Function

**Original MS SQL**:
```sql
WITH ProductHistory AS (SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock FROM dbo.Products WHERE ProductId = @ProductId) SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate, ph.PreviousPrice, ph.PreviousStock, CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2) ELSE NULL END AS PriceChangePercentage FROM dbo.Products AS p LEFT OUTER JOIN ProductHistory AS ph ON p.ProductId = ph.ProductId WHERE p.ProductId = @ProductId
```

**Converted PostgreSQL**:
```sql
WITH producthistory AS (SELECT productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock FROM productmanagement_dbo.products WHERE productid = @ProductId) SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock, CASE WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL END AS pricechangepercentage FROM productmanagement_dbo.products AS p LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid WHERE p.productid = @ProductId
```

### Statement 3: InsertProductAsync
**Type**: Multi-statement INSERT with SCOPE_IDENTITY, History Logging, Stats Update

**Original MS SQL**:
```sql
DECLARE @NewProductId INT; INSERT INTO dbo.Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity); SET @NewProductId = SCOPE_IDENTITY(); INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE()); UPDATE dbo.ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1; SELECT @NewProductId AS ProductId;
```

**Converted PostgreSQL**:
```sql
WITH ins AS (INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity) VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid), hist AS (INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp() FROM ins), stats AS (UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp() WHERE statid = 1) SELECT productid FROM ins
```

### Statement 4: UpdateProductAsync
**Type**: Multi-statement UPDATE with Variable Declaration, History Logging

**Original MS SQL**:
```sql
DECLARE @OldPrice DECIMAL(18, 2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId; UPDATE dbo.Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId; INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE()); UPDATE dbo.ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE() WHERE StatId = 1;
```

**Converted PostgreSQL**:
```sql
DO $$ DECLARE var_OldPrice NUMERIC(18, 2); var_OldStock INTEGER; BEGIN SELECT price, stockquantity INTO var_OldPrice, var_OldStock FROM productmanagement_dbo.products WHERE productid = @ProductId; UPDATE productmanagement_dbo.products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId; INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp()); UPDATE productmanagement_dbo.productstats SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp() WHERE statid = 1; END $$
```

### Statement 5: DeleteProductAsync
**Type**: Multi-statement DELETE with Variable Declaration, History Logging

**Original MS SQL**:
```sql
DECLARE @OldPrice DECIMAL(18, 2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId; INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE()); DELETE FROM dbo.Products WHERE ProductId = @ProductId; UPDATE dbo.ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1;
```

**Converted PostgreSQL**:
```sql
DO $$ DECLARE var_OldPrice NUMERIC(18, 2); var_OldStock INTEGER; BEGIN SELECT price, stockquantity INTO var_OldPrice, var_OldStock FROM productmanagement_dbo.products WHERE productid = @ProductId; INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp()); DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId; UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1) ELSE 0 END, lastupdated = clock_timestamp() WHERE statid = 1; END $$
```

### Statement 6: GetProductsByPriceRangeAsync
**Type**: SELECT with CTE, RANK and PERCENT_RANK Window Functions

**Original MS SQL**:
```sql
WITH RankedProducts AS (SELECT p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile FROM dbo.Products AS p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice) SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget' WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS PriceSegment FROM RankedProducts AS rp ORDER BY rp.PriceRank
```

**Converted PostgreSQL**:
```sql
WITH rankedproducts AS (SELECT p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile FROM productmanagement_dbo.products AS p WHERE p.price BETWEEN @MinPrice AND @MaxPrice) SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget' WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS pricesegment FROM rankedproducts AS rp ORDER BY rp.pricerank NULLS FIRST
```

### Statement 7: GetLowStockProductsAsync
**Type**: SELECT with CTE, AVG/MIN/MAX Window Functions

**Original MS SQL**:
```sql
WITH StockAnalysis AS (SELECT p.*, AVG(StockQuantity) OVER () AS AvgStock, MIN(StockQuantity) OVER () AS MinStock, MAX(StockQuantity) OVER () AS MaxStock FROM dbo.Products AS p) SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical' WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low' ELSE 'Adequate' END AS StockStatus, ROUND((StockQuantity / AvgStock) * 100, 2) AS StockPercentageOfAverage FROM StockAnalysis AS sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
```

**Converted PostgreSQL**:
```sql
WITH stockanalysis AS (SELECT p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock FROM productmanagement_dbo.products AS p) SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical' WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage FROM stockanalysis AS sa WHERE stockquantity <= @Threshold ORDER BY stockquantity NULLS FIRST
```

## Static Code Verification

### Package Dependencies
- ✅ `Npgsql 8.0.6` present in AdoCore.csproj
- ✅ No `Microsoft.Data.SqlClient` references found
- ✅ No `System.Data.SqlClient` references found

### Database Access Classes
- ✅ `NpgsqlConnection` used (ProductRepository.cs)
- ✅ `NpgsqlCommand` used (ProductRepository.cs)
- ✅ `NpgsqlDataReader` used (ProductRepository.cs)
- ✅ `using Npgsql;` import present
- ✅ No `SqlConnection`, `SqlCommand`, `SqlDataReader`, `SqlParameter` references found

### Connection Strings (appsettings.json)
- ✅ PostgreSQL format: `Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres`
- ✅ No SQL Server format (`Server=`, `Integrated Security=`) found

### Transaction Handling
- ✅ `BeginTransactionAsync()` used in `ExecuteInTransactionAsync` method
- ✅ `CommitAsync()` used for successful commits
- ✅ `RollbackAsync()` used in catch block for error rollback

## File Change Log

| File | Status | Changes |
|------|--------|---------|
| DataAccess/ProductRepository.cs | Verified | SQL statements match converted PostgreSQL forms, Npgsql classes used |
| AdoCore.csproj | Verified | Uses Npgsql 8.0.6, no SQL Server packages |
| appsettings.json | Verified | Uses PostgreSQL connection format |
| Program.cs | Verified | No database-specific code, no changes needed |
| Business/ProductService.cs | Verified | No database-specific code, no changes needed |
| CLI/CommandLineInterface.cs | Verified | No database-specific code, no changes needed |
| CLI/InteractiveMenu.cs | Verified | No database-specific code, no changes needed |
| Models/Product.cs | Verified | No database-specific code, no changes needed |

## Artifacts Generated

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | Catalog of all 7 original MS SQL statements with method locations |
| converted_statements.sql | sourceCode/ | Catalog of all 7 converted PostgreSQL statements with DMS status |
| sql_equivalency_validation_report.json | sourceCode/ | Comprehensive equivalency report for all 7 statement pairs |
| migration_report.md | sourceCode/ | This comprehensive migration report |

## Build Verification

Final build completed successfully:
```
Build succeeded.
    0 Error(s)
```

## Statements Requiring Manual Review

All 7 statements require manual review due to:
1. DMS tool conversion failures (metadata model creation timeout errors) - manual conversion was applied
2. SQL Equivalency tool errors (`'uniqueID'` error) - equivalency could not be verified by the tool

**Recommendation**: Manually verify all 7 SQL statement conversions against the PostgreSQL database to confirm functional equivalency, as automated tools were unable to complete validation.
