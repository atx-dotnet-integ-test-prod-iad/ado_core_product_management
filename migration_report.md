# Migration Report: Microsoft SQL Server to PostgreSQL
# Application: AdoCore (.NET ADO.NET Application)
# Date: 2026-04-11
# Migration Project ARN: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

## Executive Summary

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS MCP Tool | 0 |
| Manual Conversion After DMS Failure | 7 |
| Validated as Equivalent (SQL Equivalency Tool) | 0 |
| Validated as Non-Equivalent | 0 |
| Equivalency Validation Errors | 7 |
| Files Modified | 3 |
| Build Status | SUCCESS (0 errors, 10 pre-existing warnings) |

## DMS Tool Results

### Statement Conversion Tool (dms-mcp___statement_conversion_tool)
- **Status**: FAILED for all 7 statements
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Impact**: All 7 statements required manual conversion

### Schema Mapping Tool (dms-mcp___schema_mapping_tool)
- **Status**: SUCCEEDED for all 3 tables
- **Mappings**:
  - `dbo.Products` → `productmanagement_dbo.products` (all columns lowercase)
  - `dbo.ProductHistory` → `productmanagement_dbo.producthistory` (all columns lowercase)
  - `dbo.ProductStats` → `productmanagement_dbo.productstats` (all columns lowercase)

## SQL Equivalency Tool Results

### Tool (sql-equivalency___validate_sql_equivalence)
- **Status**: ERROR for all 7 statement pairs
- **Error**: `'uniqueID'` (internal tool error affecting all validations)
- **Note**: Per transformation definition, all equivalency statuses marked as ERROR since tool failed. No agent judgment was used.

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetAllProductsAsync()
- **Type**: SELECT with CTE, window functions (AVG OVER, COUNT OVER), CASE, ROUND, ORDER BY CASE
- **DMS Conversion**: FAILED
- **DMS Output**: `{"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}`
- **Manual Conversion**: Applied
  - Table names: Products → productmanagement_dbo.products
  - Column names: All lowercase (ProductId → productid, Price → price, etc.)
  - CTE alias: ProductStats → productstats_cte (to avoid conflict with table name)
  - SQL syntax: Preserved (compatible with PostgreSQL)
- **Equivalency**: ERROR (tool internal error)

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductByIdAsync()
- **Type**: SELECT with CTE, LAG window function, parameterized with @ProductId
- **DMS Conversion**: FAILED
- **DMS Output**: `{"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}`
- **Manual Conversion**: Applied
  - Table names: Products → productmanagement_dbo.products
  - Column names: All lowercase
  - CTE alias: ProductHistory → producthistory_cte (to avoid conflict with table name)
  - SQL syntax: Preserved (compatible with PostgreSQL)
- **Equivalency**: ERROR (tool internal error)

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: InsertProductAsync()
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE(), variable declaration
- **DMS Conversion**: FAILED
- **DMS Output**: `{"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}`
- **Manual Conversion**: Applied (major restructuring required)
  - SCOPE_IDENTITY() → INSERT...RETURNING productid
  - GETDATE() → NOW()
  - DECLARE @var / SET @var → Removed, restructured as multiple C# commands
  - BEGIN TRANSACTION / COMMIT → C# BeginTransactionAsync() / CommitAsync()
  - Table/column names: All lowercase with schema prefix
  - Single monolithic SQL block → 3 separate SQL commands in C# transaction
- **Equivalency**: ERROR (tool internal error)

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: UpdateProductAsync()
- **Type**: Transaction block with UPDATE, DECLARE, SELECT into variables, GETDATE()
- **DMS Conversion**: FAILED
- **DMS Output**: `{"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}`
- **Manual Conversion**: Applied (major restructuring required)
  - DECLARE @OldPrice / @OldStock → C# variables captured via ExecuteReaderAsync
  - SELECT @var = col → Separate SELECT query with C# reader
  - GETDATE() → NOW()
  - Table/column names: All lowercase with schema prefix
  - Single monolithic SQL block → 4 separate SQL commands in C# transaction
- **Equivalency**: ERROR (tool internal error)

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: DeleteProductAsync()
- **Type**: Transaction block with DELETE, DECLARE, CASE expression, GETDATE()
- **DMS Conversion**: FAILED
- **DMS Output**: `{"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}`
- **Manual Conversion**: Applied (major restructuring required)
  - DECLARE @OldPrice / @OldStock → C# variables captured via ExecuteReaderAsync
  - SELECT @var = col → Separate SELECT query with C# reader
  - GETDATE() → NOW()
  - CASE expression: Preserved (compatible with PostgreSQL)
  - Table/column names: All lowercase with schema prefix
  - Single monolithic SQL block → 4 separate SQL commands in C# transaction
- **Equivalency**: ERROR (tool internal error)

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetProductsByPriceRangeAsync()
- **Type**: SELECT with CTE, RANK, PERCENT_RANK window functions, BETWEEN
- **DMS Conversion**: FAILED
- **DMS Output**: `{"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}`
- **Manual Conversion**: Applied
  - Table names: Products → productmanagement_dbo.products
  - Column names: All lowercase
  - CTE alias: RankedProducts → rankedproducts
  - SQL syntax: Preserved (RANK, PERCENT_RANK, BETWEEN compatible with PostgreSQL)
- **Equivalency**: ERROR (tool internal error)

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Method**: GetLowStockProductsAsync()
- **Type**: SELECT with CTE, AVG, MIN, MAX window functions, ROUND
- **DMS Conversion**: FAILED
- **DMS Output**: `{"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}`
- **Manual Conversion**: Applied
  - Table names: Products → productmanagement_dbo.products
  - Column names: All lowercase
  - CTE alias: StockAnalysis → stockanalysis
  - Added CAST(stockquantity AS NUMERIC) for integer division in ROUND
  - SQL syntax: Preserved (AVG, MIN, MAX compatible with PostgreSQL)
- **Equivalency**: ERROR (tool internal error)

## Code Changes Summary

### Package Dependencies
| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient v5.1.4 | Npgsql v9.0.3 |

### ADO.NET Class Replacements
| SQL Server Class | PostgreSQL Class |
|-----------------|-----------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |

### Connection String Changes
| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|-------------------|-------------------|
| Server | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=postgres |
| Port | (default 1433) | Port=5432 |
| Auth | Trusted_Connection=True | Username=postgres;Password=postgres |
| MARS | MultipleActiveResultSets=true | (removed - not applicable) |
| TLS | TrustServerCertificate=True | (removed - not applicable) |

### SQL Syntax Conversions
| SQL Server | PostgreSQL |
|-----------|-----------|
| SCOPE_IDENTITY() | INSERT...RETURNING productid |
| GETDATE() | NOW() |
| BEGIN TRANSACTION/COMMIT | C# BeginTransactionAsync/CommitAsync |
| DECLARE @var / SET @var | C# variable capture via reader |
| StockQuantity / AvgStock | CAST(stockquantity AS NUMERIC) / avgstock |

## Migration Artifacts

| Artifact | Status |
|----------|--------|
| extracted_statements.sql | COMPLETE (7 statements) |
| converted_statements.sql | COMPLETE (7 statements) |
| sql_equivalency_validation_report.json | COMPLETE (7 pairs, all ERROR due to tool failure) |
| dms_failure_summary.md | COMPLETE (all 7 DMS failures documented) |
| migration_report.md | COMPLETE (this file) |

## Files Modified
1. **sourceCode/DataAccess/ProductRepository.cs** - SQL statements, ADO.NET classes, connection handling
2. **sourceCode/AdoCore.csproj** - Package reference (Microsoft.Data.SqlClient → Npgsql)
3. **sourceCode/appsettings.json** - Connection strings (SQL Server → PostgreSQL format)

## Build Verification
- **Final Build**: SUCCESS
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference warnings, not introduced by migration)
- **Output**: AdoCore.dll compiled successfully for net9.0
