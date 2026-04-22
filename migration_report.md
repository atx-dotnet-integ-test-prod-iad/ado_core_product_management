# Migration Report: MS SQL Server to PostgreSQL

## Overview
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13 (postgres)
- **Application Framework**: .NET 9.0 ADO.NET
- **Migration Date**: 2026-04-22
- **DMS Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU

---

## SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Statements Successfully Converted by DMS** | 0 |
| **Statements Requiring Manual Intervention** | 7 |
| **Equivalency Validated as EQUIVALENT** | 0 |
| **Equivalency Validated as NOT_EQUIVALENT** | 0 |
| **Equivalency Validation ERRORS** | 7 |

### DMS Conversion Details

All 7 SQL statements were passed through the DMS MCP statement_conversion_tool. All 7 failed with the same error:

```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple retry attempts were made with varied parameters (max_poll_attempts: 15-30, poll_interval_seconds: 10-20). Schema mappings were successfully retrieved via the DMS schema_mapping_tool, which provided the target schema structure used for manual conversion.

### Manual Conversion Applied

All 7 statements were manually converted using `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA` rules:
- All schema object names (tables, columns) converted to lowercase
- Schema prefix `productmanagement_dbo` applied per DMS schema mapping
- SQL Server-specific constructs converted to PostgreSQL equivalents

### SQL Equivalency Validation Details

All 7 statement pairs were validated through the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence). All returned ERROR status with error `'uniqueID'` - a tool infrastructure issue unrelated to the statements themselves.

---

## Detailed Statement Conversions

### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), CASE, ROUND, ORDER BY
- **Key Changes**: Table/column names lowercased, schema prefixed, CTE renamed to `productstats_cte`
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, CASE, ROUND
- **Key Changes**: Table/column names lowercased, schema prefixed, CTE renamed to `producthistory_cte`
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, SCOPE_IDENTITY(), GETDATE(), INSERT, UPDATE
- **Key Changes**: Restructured to writable CTEs with INSERT...RETURNING/NOW(), removed DECLARE/SCOPE_IDENTITY
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, GETDATE(), SELECT INTO variable, UPDATE, INSERT
- **Key Changes**: Restructured to writable CTEs with old_values CTE, replaced GETDATE() with NOW()
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, GETDATE(), SELECT INTO variable, INSERT, DELETE, UPDATE
- **Key Changes**: Restructured to writable CTEs with old_values CTE, replaced GETDATE() with NOW()
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK(), PERCENT_RANK(), BETWEEN, CASE, ORDER BY
- **Key Changes**: Table/column names lowercased, schema prefixed
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Key Changes**: Table/column names lowercased, schema prefixed, added CAST for integer division
- **DMS Status**: Failed
- **Equivalency Status**: ERROR

---

## Files Modified

### 1. AdoCore.csproj
- **Change**: Package reference update
- Removed: `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- Added: `<PackageReference Include="Npgsql" Version="8.0.6" />`

### 2. DataAccess/ProductRepository.cs
- **Changes**:
  - Import: `using Microsoft.Data.SqlClient` → `using Npgsql`
  - Field: `SqlConnection _connection` → `NpgsqlConnection _connection`
  - Method return type: `Task<SqlConnection>` → `Task<NpgsqlConnection>`
  - Constructor: `new SqlConnection()` → `new NpgsqlConnection()`
  - Commands: `new SqlCommand()` → `new NpgsqlCommand()` (7 instances)
  - Reader parameter: `SqlDataReader` → `NpgsqlDataReader`
  - Reader column references: Updated to lowercase (e.g., `reader["ProductId"]` → `reader["productid"]`)
  - All 7 SQL statements replaced with PostgreSQL equivalents

### 3. appsettings.json
- **Change**: Connection string format update
  - `Server=localhost` → `Host=localhost`
  - Added `Port=5432`
  - `Database=ProductManagement` → `Database=postgres`
  - Removed `Trusted_Connection=True`, `MultipleActiveResultSets=true`, `TrustServerCertificate=True`
  - Added `Username=postgres;Password=your_password_here`

## Files Not Modified (No SQL/DB Code)

| File | Reason |
|------|--------|
| Program.cs | No DB-specific code, uses IConfiguration (provider-agnostic) |
| Models/Product.cs | Pure model/POCO class |
| Business/ProductService.cs | Business logic only, no direct DB access |
| CLI/CommandLineInterface.cs | UI/CLI layer |
| CLI/InteractiveMenu.cs | UI/menu layer |

---

## Schema Mapping (from DMS schema_mapping_tool)

| Source (MS SQL) | Target (PostgreSQL) |
|-----------------|---------------------|
| dbo.Products | productmanagement_dbo.products |
| dbo.ProductHistory | productmanagement_dbo.producthistory |
| dbo.ProductStats | productmanagement_dbo.productstats |

### Column Mappings (Products table)

| Source Column | Target Column | Source Type | Target Type |
|---------------|---------------|-------------|-------------|
| ProductId | productid | int IDENTITY | INTEGER GENERATED ALWAYS AS IDENTITY |
| Name | name | nvarchar(100) | VARCHAR(100) |
| Description | description | nvarchar(500) | VARCHAR(500) |
| Price | price | decimal(18,2) | NUMERIC(18,2) |
| StockQuantity | stockquantity | int | INTEGER |
| CreatedDate | createddate | datetime DEFAULT GETDATE() | TIMESTAMP DEFAULT clock_timestamp() |
| ModifiedDate | modifieddate | datetime NULL | TIMESTAMP NULL |

---

## Build Verification

- **Build Command**: `dotnet build sourceCode/AdoCore.csproj`
- **Result**: ✅ **Build Succeeded**
- **Errors**: 0
- **Warnings**: 10 (all pre-existing nullable reference warnings, unrelated to migration)

---

## Transformation Artifacts

| Artifact | Description |
|----------|-------------|
| extracted_statements.sql | Complete catalog of all 7 original MS SQL statements |
| converted_statements.sql | Complete catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | Comprehensive equivalency validation report for all 7 statement pairs |
| dms_conversion_log.txt | Detailed DMS failure documentation for all 7 statements |
| migration_report.md | This report |

---

## Recommendations for Manual Review

1. **SQL Equivalency**: All 7 statement pairs returned ERROR from the SQL Equivalency tool. Manual review of converted SQL statements is recommended.
2. **Writable CTEs (Statements 3, 4, 5)**: The INSERT/UPDATE/DELETE transaction blocks were converted to PostgreSQL writable CTEs. These should be tested against a real PostgreSQL database to ensure correct behavior.
3. **Connection Strings**: Update the placeholder password (`your_password_here`) with actual PostgreSQL credentials before deployment.
4. **Schema**: Ensure the `productmanagement_dbo` schema exists in the target PostgreSQL database.
5. **Integer Division (Statement 7)**: Added explicit CAST for StockQuantity integer division to prevent PostgreSQL integer division truncation.
