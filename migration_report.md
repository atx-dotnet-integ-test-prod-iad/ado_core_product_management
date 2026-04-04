# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-04 |
| **Source Database** | Microsoft SQL Server 2019 (ProductManagement) |
| **Target Database** | PostgreSQL 13 (postgres) |
| **Application** | AdoCore (.NET 9 ADO.NET Application) |
| **Migration Project ARN** | arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU |

---

## SQL Statement Conversion Summary

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS MCP Tool** | 0 |
| **Requiring Manual Intervention** | 7 |
| **Validated as Equivalent** | 0 |
| **Validated as Non-Equivalent** | 0 |
| **With Equivalency Errors** | 7 |

### DMS Tool Status
- **DMS Statement Conversion Tool**: FAILED for all statements
  - Error: Metadata model creation did not complete after multiple attempts (timeout)
  - Attempts: 4 total with varying poll configurations
- **DMS Schema Mapping Tool**: SUCCEEDED for all 3 tables
  - Products → products (schema: productmanagement_dbo)
  - ProductHistory → producthistory (schema: productmanagement_dbo)
  - ProductStats → productstats (schema: productmanagement_dbo)

### SQL Equivalency Tool Status
- **Status**: ERROR for all 7 statement pairs
- **Error**: `'uniqueID'` - consistent infrastructure/configuration issue
- **Note**: All 7 pairs were submitted; tool returned the same error for each

### Conversion Method
All statements converted using: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- Schema mappings obtained from DMS schema_mapping_tool
- All table/column names lowercased per DMS schema mapping output

---

## SQL Statement Details

### Statement 1: GetAllProductsAsync
- **Method**: `GetAllProductsAsync()`
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: CTE with window functions (AVG, COUNT OVER), CASE, ROUND
- **Changes**: All identifiers lowercased, CTE renamed from `ProductStats` to `productstats_cte`
- **DMS Status**: FAILED | **Equivalency Status**: ERROR

### Statement 2: GetProductByIdAsync
- **Method**: `GetProductByIdAsync(int productId)`
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: CTE with LAG window function, parameterized query
- **Changes**: All identifiers lowercased, CTE renamed from `ProductHistory` to `producthistory_cte`
- **DMS Status**: FAILED | **Equivalency Status**: ERROR

### Statement 3: InsertProductAsync
- **Method**: `InsertProductAsync(Product product)`
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: Transaction block with SCOPE_IDENTITY(), GETDATE()
- **Changes**: 
  - SCOPE_IDENTITY() → INSERT...RETURNING productid
  - GETDATE() → NOW()
  - DECLARE @var / BEGIN TRANSACTION → CTE-based approach (new_product, log_insertion, update_stats)
  - All identifiers lowercased
- **DMS Status**: FAILED | **Equivalency Status**: ERROR

### Statement 4: UpdateProductAsync
- **Method**: `UpdateProductAsync(Product product)`
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: Transaction block with DECLARE variables, GETDATE()
- **Changes**:
  - DECLARE @OldPrice/@OldStock → CTE `old_values`
  - GETDATE() → NOW()
  - BEGIN TRANSACTION → CTE-based approach (old_values, do_update, log_changes)
  - All identifiers lowercased
- **DMS Status**: FAILED | **Equivalency Status**: ERROR

### Statement 5: DeleteProductAsync
- **Method**: `DeleteProductAsync(int productId)`
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: Transaction block with DECLARE variables, CASE, GETDATE()
- **Changes**:
  - DECLARE @OldPrice/@OldStock → CTE `old_values`
  - GETDATE() → NOW()
  - BEGIN TRANSACTION → CTE-based approach (old_values, log_deletion, do_delete)
  - All identifiers lowercased
- **DMS Status**: FAILED | **Equivalency Status**: ERROR

### Statement 6: GetProductsByPriceRangeAsync
- **Method**: `GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)`
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: CTE with RANK/PERCENT_RANK window functions, BETWEEN, CASE
- **Changes**: All identifiers lowercased, CTE renamed from `RankedProducts` to `rankedproducts`
- **DMS Status**: FAILED | **Equivalency Status**: ERROR

### Statement 7: GetLowStockProductsAsync
- **Method**: `GetLowStockProductsAsync(int threshold)`
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **Changes**: All identifiers lowercased, CTE renamed from `StockAnalysis` to `stockanalysis`, added CAST(stockquantity AS NUMERIC) for integer division fix
- **DMS Status**: FAILED | **Equivalency Status**: ERROR

---

## File Changes Summary

### Modified Files

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statements with PostgreSQL equivalents; Updated ADO.NET classes (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader); Updated using directive; Updated column name references in MapProductFromReader to lowercase |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| `appsettings.json` | Updated connection strings from SQL Server format to PostgreSQL format |

### Created Files

| File | Purpose |
|------|---------|
| `extracted_statements.sql` | Catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `dms_conversion_summary.log` | DMS conversion attempt documentation |
| `migration_report.md` | This report |

---

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) | Occurrences |
|------------------------|--------------------------|-------------|
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return type, instantiation) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

---

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Port=5432;Database=postgres;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| `Server=localhost` | `Host=localhost` |
| `Database=ProductManagement` | `Database=postgres` |
| `Trusted_Connection=True` | Removed (not applicable) |
| `MultipleActiveResultSets=true` | Removed (not applicable) |
| `TrustServerCertificate=True` | Removed (not applicable) |
| N/A | `Port=5432` (added) |
| N/A | `Username=postgres` (added) |
| N/A | `Password=postgres` (added) |

---

## Package Reference Changes

### Before
```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />
```

### After
```xml
<PackageReference Include="Npgsql" Version="8.0.6" />
```

Note: Initially targeted Npgsql 8.0.1 per plan, but upgraded to 8.0.6 to resolve a known high-severity vulnerability (GHSA-x9vc-6hfv-hg8c) in version 8.0.1.

---

## Build Verification

- **Final Build Status**: ✅ Build Succeeded
- **Errors**: 0
- **Warnings**: 10 (pre-existing nullable reference warnings, not related to migration)
- **Build Framework**: .NET 9.0
- **Output**: AdoCore.dll

---

## Artifacts Checklist

| Artifact | Status |
|----------|--------|
| `extracted_statements.sql` | ✅ Created |
| `converted_statements.sql` | ✅ Created |
| `sql_equivalency_validation_report.json` | ✅ Created |
| `dms_conversion_summary.log` | ✅ Created |
| `migration_report.md` | ✅ Created |

---

## Notes and Recommendations

1. **DMS Statement Conversion**: The DMS statement_conversion_tool consistently timed out during metadata model creation. This may be a transient infrastructure issue. Consider retrying the DMS conversion once the infrastructure is stable.

2. **SQL Equivalency**: The SQL equivalency tool returned errors for all 7 statement pairs with `'uniqueID'` error. This appears to be a configuration issue with the tool itself, not related to the SQL statements. Manual review of the converted statements is recommended.

3. **Schema Mapping**: Despite statement conversion failures, the DMS schema_mapping_tool successfully provided table/column mappings, which were used to guide the manual conversion.

4. **PostgreSQL CTE with DML**: The converted INSERT/UPDATE/DELETE statements use PostgreSQL's writeable CTE feature (CTEs with INSERT...RETURNING, UPDATE, DELETE). This is a PostgreSQL-specific feature and should be tested against the actual database.

5. **Connection String Security**: The connection string currently uses plaintext credentials (Username=postgres;Password=postgres). For production, consider using environment variables or a secrets manager.
