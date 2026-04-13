# SQL Server to PostgreSQL Migration Report

## Overview
- **Project**: AdoCore (.NET 9.0 ADO.NET Application)
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13 (postgres)
- **Migration Date**: 2026-04-13
- **DMS Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| DMS tool conversion successful | 0 |
| DMS tool conversion failed | 7 |
| Manual conversion applied | 7 |
| Equivalency validated (EQUIVALENT) | 0 |
| Equivalency validated (NOT_EQUIVALENT) | 0 |
| Equivalency validation ERROR | 7 |

### DMS Tool Status
- **All 7 statements were submitted to DMS MCP tool** (dms-mcp___statement_conversion_tool)
- **All 7 failed** with: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Schema mapping tool succeeded** - provided target schema/table/column mappings
- Manual conversion applied using DMS schema mappings with lowercase naming convention

### SQL Equivalency Tool Status
- **All 7 statement pairs were submitted to SQL Equivalency tool** (sql-equivalency___validate_sql_equivalence)
- **All 7 returned ERROR** with: `'uniqueID'` (service-side error)
- Status is reported as-is from the tool; no agent judgment was used for equivalency determination

## Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Type**: SELECT with CTE, Window Functions (AVG, COUNT), CASE, ROUND
- **Key Changes**: Table/column names lowercased, CTE renamed to avoid conflict
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR (tool error)

### Statement 2: GetProductByIdAsync
- **Type**: SELECT with CTE, LAG Window Function, CASE, ROUND
- **Key Changes**: Table/column names lowercased
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR (tool error)

### Statement 3: InsertProductAsync
- **Type**: Multi-statement transaction (INSERT, SCOPE_IDENTITY, INSERT, UPDATE)
- **Key Changes**: 
  - `SCOPE_IDENTITY()` → `INSERT ... RETURNING productid` via writable CTE
  - `GETDATE()` → `NOW()`
  - T-SQL transaction block → Writable CTE chain
  - T-SQL variables → CTE subquery references
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR (tool error)

### Statement 4: UpdateProductAsync
- **Type**: Multi-statement transaction (DECLARE, SELECT INTO, UPDATE, INSERT, UPDATE)
- **Key Changes**:
  - `DECLARE @OldPrice / @OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - T-SQL transaction block → Writable CTE chain
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR (tool error)

### Statement 5: DeleteProductAsync
- **Type**: Multi-statement transaction (DECLARE, SELECT INTO, INSERT, DELETE, UPDATE with CASE)
- **Key Changes**:
  - `DECLARE @OldPrice / @OldStock` → CTE `old_values` subquery
  - `GETDATE()` → `NOW()`
  - T-SQL transaction block → Writable CTE chain
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR (tool error)

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: SELECT with CTE, RANK, PERCENT_RANK, BETWEEN, CASE
- **Key Changes**: Table/column names lowercased
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR (tool error)

### Statement 7: GetLowStockProductsAsync
- **Type**: SELECT with CTE, AVG/MIN/MAX Window Functions, CASE, ROUND
- **Key Changes**: Table/column names lowercased
- **DMS Status**: FAILED
- **Equivalency Status**: ERROR (tool error)

## Schema Mapping (from DMS Schema Mapping Tool)

| Source (SQL Server) | Target (PostgreSQL) |
|---------------------|---------------------|
| `[dbo].[Products]` | `productmanagement_dbo.products` |
| `[dbo].[ProductHistory]` | `productmanagement_dbo.producthistory` |
| `[dbo].[ProductStats]` | `productmanagement_dbo.productstats` |

### Column Mappings

**Products → products**
| SQL Server | PostgreSQL |
|-----------|-----------|
| ProductId (int IDENTITY) | productid (INTEGER GENERATED ALWAYS AS IDENTITY) |
| Name (nvarchar) | name (VARCHAR) |
| Description (nvarchar) | description (VARCHAR) |
| Price (decimal) | price (NUMERIC) |
| StockQuantity (int) | stockquantity (INTEGER) |
| CreatedDate (datetime) | createddate (TIMESTAMP WITHOUT TIME ZONE) |
| ModifiedDate (datetime) | modifieddate (TIMESTAMP WITHOUT TIME ZONE) |

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | SQL statements converted, ADO.NET classes replaced, column references lowercased |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.0 |
| `appsettings.json` | Connection strings updated to PostgreSQL format |

## Package Changes

| Action | Package | Version |
|--------|---------|---------|
| Removed | Microsoft.Data.SqlClient | 5.1.4 |
| Added | Npgsql | 8.0.0 |
| Unchanged | Microsoft.Extensions.Configuration | 8.0.0 |
| Unchanged | Microsoft.Extensions.Configuration.Json | 8.0.0 |
| Unchanged | Microsoft.Extensions.DependencyInjection | 8.0.0 |

## ADO.NET Class Replacements

| SQL Server (Microsoft.Data.SqlClient) | PostgreSQL (Npgsql) |
|---------------------------------------|---------------------|
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|-----------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=postgres |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed - not applicable) |
| TrustServerCertificate | True | (removed - not applicable) |

## Statements Requiring Manual Review

**ALL 7 statements** should be manually reviewed because:
1. DMS conversion tool failed for all statements, requiring manual conversion
2. SQL Equivalency tool returned ERROR for all statement pairs
3. Transaction blocks (Statements 3, 4, 5) were converted from T-SQL patterns to PostgreSQL writable CTEs

## Migration Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| extracted_statements.sql | sourceCode/ | 7 original MS SQL statements |
| converted_statements.sql | sourceCode/ | 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | sourceCode/ | Complete equivalency report for all 7 pairs |
| migration_report.md | sourceCode/ | This report |
