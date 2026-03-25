# Migration Report: Microsoft SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-25 |
| **Source Database** | Microsoft SQL Server (ProductManagement) |
| **Target Database** | PostgreSQL (ProductManagement) |
| **Application Framework** | .NET 9.0 / ADO.NET |
| **DMS Migration Project** | arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU |

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL statements processed** | 7 |
| **Statements successfully converted by DMS** | 0 |
| **Statements requiring manual intervention** | 7 |
| **Statements validated as equivalent** | 0 |
| **Statements validated as non-equivalent** | 0 |
| **Statements with equivalency tool errors** | 7 |

### DMS Tool Status
- **Statement Conversion Tool (dms-mcp___statement_conversion_tool)**: FAILED for all 7 statements
  - Error: "Metadata model creation/conversion did not complete after N attempts"
  - Root cause: DMS service metadata model operations consistently timing out
  - Multiple retry attempts with varying poll counts (15, 25, 30 attempts) all failed
- **Schema Mapping Tool (dms-mcp___schema_mapping_tool)**: SUCCEEDED
  - Successfully retrieved schema mappings for all 3 tables (Products, ProductHistory, ProductStats)
  - Schema mapping used to guide manual conversion

### SQL Equivalency Tool Status
- **SQL Equivalency Tool (sql-equivalency___validate_sql_equivalence)**: FAILED for all 7 pairs
  - Error: `{"equivalence_status": "ERROR", "error": "'uniqueID'"}`
  - This is a systemic error from the tool service, not related to SQL content
  - Even the simplest query returned the same error

## Detailed Statement Conversion Status

### Statement 1: GetAllProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: SELECT with CTE, window functions (AVG, COUNT), CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool service error)
- **Key Changes**: Table/column names to lowercase

### Statement 2: GetProductByIdAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: SELECT with CTE, LAG window function, LEFT JOIN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool service error)
- **Key Changes**: Table/column names to lowercase

### Statement 3: InsertProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: Transaction block with INSERT, SCOPE_IDENTITY(), GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool service error)
- **Key Changes**: SCOPE_IDENTITY() → RETURNING clause, GETDATE() → clock_timestamp(), T-SQL transaction block → app-level NpgsqlTransaction management

### Statement 4: UpdateProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: Transaction block with DECLARE, SELECT into variables, UPDATE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool service error)
- **Key Changes**: T-SQL DECLARE/SET → C# variables, GETDATE() → clock_timestamp(), T-SQL transaction block → app-level NpgsqlTransaction management

### Statement 5: DeleteProductAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: Transaction block with DECLARE, SELECT into variables, DELETE, CASE, GETDATE()
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool service error)
- **Key Changes**: T-SQL DECLARE/SET → C# variables, GETDATE() → clock_timestamp(), T-SQL transaction block → app-level NpgsqlTransaction management

### Statement 6: GetProductsByPriceRangeAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: SELECT with CTE, RANK, PERCENT_RANK window functions, BETWEEN, CASE
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool service error)
- **Key Changes**: Table/column names to lowercase

### Statement 7: GetLowStockProductsAsync
- **Source File**: DataAccess/ProductRepository.cs
- **Type**: SELECT with CTE, AVG/MIN/MAX window functions, CASE, ROUND
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status**: ERROR (tool service error)
- **Key Changes**: Table/column names to lowercase, added CAST for integer division fix

## Schema Mapping (from DMS Schema Mapping Tool)

| SQL Server Table | PostgreSQL Table | PostgreSQL Schema |
|-----------------|-----------------|-------------------|
| [dbo].[Products] | products | productmanagement_dbo |
| [dbo].[ProductHistory] | producthistory | productmanagement_dbo |
| [dbo].[ProductStats] | productstats | productmanagement_dbo |

### Column Mapping Examples
| SQL Server Column | PostgreSQL Column |
|------------------|-------------------|
| ProductId | productid |
| Name | name |
| Description | description |
| Price | price |
| StockQuantity | stockquantity |
| CreatedDate | createddate |
| ModifiedDate | modifieddate |
| AveragePrice | averageprice |
| TotalProducts | totalproducts |
| LastUpdated | lastupdated |

### Function Mapping
| SQL Server Function | PostgreSQL Function |
|--------------------|---------------------|
| GETDATE() | clock_timestamp() |
| SCOPE_IDENTITY() | RETURNING clause |
| IDENTITY(1,1) | GENERATED ALWAYS AS IDENTITY |

## Files Modified

| File | Change Type | Description |
|------|------------|-------------|
| DataAccess/ProductRepository.cs | Modified | Replaced all SQL statements, ADO.NET classes with Npgsql equivalents |
| AdoCore.csproj | Modified | Replaced Microsoft.Data.SqlClient with Npgsql 8.0.6 |
| appsettings.json | Modified | Updated connection strings to PostgreSQL format |

## New Artifacts Created

| File | Description |
|------|-------------|
| extracted_statements.sql | Complete catalog of all 7 original MS SQL statements |
| converted_statements.sql | Complete catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Comprehensive equivalency validation report for all 7 pairs |
| dms_failure_log.txt | Detailed DMS failure documentation |
| migration_report.md | This report |

## Package Dependency Changes

| Before | After |
|--------|-------|
| Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |
| Microsoft.Extensions.Configuration 8.0.0 | Microsoft.Extensions.Configuration 8.0.0 (unchanged) |
| Microsoft.Extensions.Configuration.Json 8.0.0 | Microsoft.Extensions.Configuration.Json 8.0.0 (unchanged) |
| Microsoft.Extensions.DependencyInjection 8.0.0 | Microsoft.Extensions.DependencyInjection 8.0.0 (unchanged) |

**Note**: Npgsql version 8.0.6 was used instead of 8.0.1 to address known security vulnerability GHSA-x9vc-6hfv-hg8c.

## Connection String Changes

| Parameter | Before (SQL Server) | After (PostgreSQL) |
|-----------|--------------------|--------------------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | MultipleActiveResultSets=true | Removed (not applicable) |
| TrustServerCertificate | TrustServerCertificate=True | Removed (not applicable) |

## ADO.NET Class Replacement Summary

| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|-------------|-------------|
| SqlConnection | NpgsqlConnection | 3 (field, GetConnectionAsync, DisposeAsync) |
| SqlCommand | NpgsqlCommand | 14 (all method command creations) |
| SqlDataReader | NpgsqlDataReader | 1 (MapProductFromReader parameter) |

## Build Status
- **Final Build**: SUCCESS (0 errors, 10 warnings)
- All warnings are pre-existing nullable reference warnings, not related to migration

## Recommendations for Manual Review
1. All 7 SQL statement conversions should be reviewed due to DMS tool unavailability
2. All 7 equivalency validations returned ERROR due to SQL Equivalency tool service issue - manual validation recommended
3. Transaction blocks (Statements 3, 4, 5) were restructured from T-SQL batch blocks to individual NpgsqlCommand calls with app-level transaction management - verify behavior matches original
4. Connection string credentials (Username/Password) should be replaced with actual production values
5. Consider testing all CRUD operations against a PostgreSQL database to verify functional correctness
