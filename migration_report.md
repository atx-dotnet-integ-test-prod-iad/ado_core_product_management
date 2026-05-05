# Migration Report: SQL Server to PostgreSQL
# Application: AdoCore (.NET ADO Application)
# Date: 2026-05-05
# Migration Tool: AWS DMS MCP Statement Conversion Tool + Manual Conversion

## Executive Summary

This report documents the migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL. The migration involved extracting and converting 7 SQL statements, updating package dependencies, updating ADO.NET class references, and modifying connection strings.

## Migration Statistics

| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Statements Successfully Converted by DMS | 0 |
| Statements Requiring Manual Intervention | 7 |
| Equivalency Validations Performed | 7 |
| Statements Validated as Equivalent | 0 |
| Statements Validated as Non-Equivalent | 0 |
| Statements with Equivalency Errors | 7 |

## DMS Tool Status

The DMS MCP Statement Conversion Tool (dms-mcp___statement_conversion_tool) failed for ALL 7 statements with the following consistent error:

```
Status: error
Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

**Migration Project ARN:** arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

As per the transformation rules, manual conversion was applied with lowercase schema object names (conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

## SQL Equivalency Validation Status

The SQL Equivalency tool (sql-equivalency___validate_sql_equivalence) returned ERROR for all 7 statement pairs with error: "'uniqueID'". As per the transformation rules, these are marked as ERROR status (no agent judgment was applied to override tool results).

## SQL Statement Conversion Details

### Statement 1: GetAllProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetAllProductsAsync()
- **Type:** CTE with AVG/COUNT window functions
- **DMS Status:** FAILED
- **Manual Conversion:** Applied lowercase schema object names
- **Key Changes:** Table/column names lowercased (Products→products, ProductId→productid, etc.)
- **Equivalency Status:** ERROR (tool returned "'uniqueID'" error)

### Statement 2: GetProductByIdAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductByIdAsync()
- **Type:** CTE with LAG window function and ROUND
- **DMS Status:** FAILED
- **Manual Conversion:** Applied lowercase schema object names
- **Key Changes:** Table/column names lowercased
- **Equivalency Status:** ERROR (tool returned "'uniqueID'" error)

### Statement 3: InsertProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** InsertProductAsync()
- **Type:** Transaction block with SCOPE_IDENTITY(), GETDATE(), INSERT into multiple tables
- **DMS Status:** FAILED
- **Manual Conversion:** Applied lowercase schema + function replacements
- **Key Changes:**
  - SCOPE_IDENTITY() → lastval()
  - GETDATE() → NOW()
  - BEGIN TRANSACTION → BEGIN
  - DECLARE/SET variable → removed (used lastval() directly)
- **Equivalency Status:** ERROR (tool returned "'uniqueID'" error)

### Statement 4: UpdateProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** UpdateProductAsync()
- **Type:** Transaction block with DECLARE variables, UPDATE with GETDATE()
- **DMS Status:** FAILED
- **Manual Conversion:** Applied lowercase schema + restructured queries
- **Key Changes:**
  - DECLARE variables → subquery approach
  - GETDATE() → NOW()
  - BEGIN TRANSACTION → BEGIN
  - SELECT INTO variables → subquery in INSERT...SELECT
- **Equivalency Status:** ERROR (tool returned "'uniqueID'" error)

### Statement 5: DeleteProductAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** DeleteProductAsync()
- **Type:** Transaction block with DECLARE variables, DELETE with CASE expression
- **DMS Status:** FAILED
- **Manual Conversion:** Applied lowercase schema + restructured queries
- **Key Changes:**
  - DECLARE variables → subquery approach
  - GETDATE() → NOW()
  - BEGIN TRANSACTION → BEGIN
  - SELECT INTO variables → INSERT...SELECT for history logging
- **Equivalency Status:** ERROR (tool returned "'uniqueID'" error)

### Statement 6: GetProductsByPriceRangeAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetProductsByPriceRangeAsync()
- **Type:** CTE with RANK()/PERCENT_RANK() window functions and BETWEEN
- **DMS Status:** FAILED
- **Manual Conversion:** Applied lowercase schema object names
- **Key Changes:** Table/column names lowercased
- **Equivalency Status:** ERROR (tool returned "'uniqueID'" error)

### Statement 7: GetLowStockProductsAsync
- **Source File:** DataAccess/ProductRepository.cs
- **Method:** GetLowStockProductsAsync()
- **Type:** CTE with AVG/MIN/MAX window functions and ROUND
- **DMS Status:** FAILED
- **Manual Conversion:** Applied lowercase schema + numeric cast
- **Key Changes:**
  - Table/column names lowercased
  - StockQuantity/AvgStock division → stockquantity::numeric/avgstock for proper ROUND behavior
- **Equivalency Status:** ERROR (tool returned "'uniqueID'" error)

## Package Dependency Changes

| Component | Before | After |
|-----------|--------|-------|
| Database Client Package | Microsoft.Data.SqlClient 5.1.4 | Npgsql 8.0.6 |
| Connection Class | SqlConnection | NpgsqlConnection |
| Command Class | SqlCommand | NpgsqlCommand |
| Reader Class | SqlDataReader | NpgsqlDataReader |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | Server=localhost | Host=localhost |
| Database | Database=ProductManagement | Database=ProductManagement |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets | true | (removed - not applicable) |
| TrustServerCertificate | True | (removed - not applicable) |

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) |
|-----------------------|--------------------------|
| using Microsoft.Data.SqlClient | using Npgsql |
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| Task<SqlConnection> | Task<NpgsqlConnection> |

## Files Modified

1. **DataAccess/ProductRepository.cs** - SQL statements, imports, and type references
2. **AdoCore.csproj** - Package reference (Microsoft.Data.SqlClient → Npgsql)
3. **appsettings.json** - Connection strings

## Artifacts Generated

1. **extracted_statements.sql** - Catalog of all 7 original MS SQL statements
2. **converted_statements.sql** - Catalog of all 7 converted PostgreSQL statements
3. **sql_equivalency_validation_report.json** - Comprehensive equivalency validation report
4. **migration_report.md** - This report

## Build Status

Final build: **SUCCESS** (0 Errors, 0 Vulnerability Warnings)

## Notes and Caveats

1. All DMS conversions failed due to metadata model creation issues. Manual conversion was applied per transformation rules.
2. All SQL equivalency validations returned ERROR from the tool, possibly due to a system-level issue with the equivalency service.
3. The manual conversions follow standard SQL Server → PostgreSQL patterns and should be functionally equivalent.
4. The PostgreSQL parameter syntax (@param) is supported by Npgsql and does not require changes.
5. Transaction blocks in SQL statements use BEGIN/COMMIT which PostgreSQL supports natively.
