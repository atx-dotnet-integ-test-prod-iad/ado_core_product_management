# Migration Report: Microsoft SQL Server to PostgreSQL

## Summary
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL, including SQL statement conversion, ADO.NET class replacement, package dependency updates, and connection string changes.

## Migration Overview

| Metric | Value |
|--------|-------|
| Application | AdoCore (.NET 9.0) |
| Source Database | Microsoft SQL Server |
| Target Database | PostgreSQL |
| Source ADO Package | Microsoft.Data.SqlClient 5.1.4 |
| Target ADO Package | Npgsql 8.0.1 |
| Total SQL Statements | 7 |
| Files Modified | 3 (ProductRepository.cs, AdoCore.csproj, appsettings.json) |
| Files Created | 4 (extracted_statements.sql, converted_statements.sql, sql_equivalency_validation_report.json, migration_report.md) |

## SQL Statement Conversion Results

### DMS Tool Results
All 7 SQL statements were submitted to the AWS DMS MCP tool for conversion.

| Statement | Method | DMS Result | DMS Error |
|-----------|--------|------------|-----------|
| Statement 1 (GetAllProductsAsync) | GetAllProductsAsync | FAILED | Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'} |
| Statement 2 (GetProductByIdAsync) | GetProductByIdAsync | FAILED | Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'} |
| Statement 3 (InsertProductAsync) | InsertProductAsync | FAILED | Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'} |
| Statement 4 (UpdateProductAsync) | UpdateProductAsync | FAILED | Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'} |
| Statement 5 (DeleteProductAsync) | DeleteProductAsync | FAILED | Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'} |
| Statement 6 (GetProductsByPriceRangeAsync) | GetProductsByPriceRangeAsync | FAILED | Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'} |
| Statement 7 (GetLowStockProductsAsync) | GetLowStockProductsAsync | FAILED | Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'} |

**DMS Summary**: 0/7 successfully converted, 7/7 failed. All failures due to same error.

### Manual Conversion Applied
Since DMS failed for all 7 statements, manual conversion was applied with lowercase schema naming convention per the transformation definition's guidance (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA).

#### Key Conversion Rules Applied:
1. **Lowercase schema objects**: All table names, column names, aliases converted to lowercase
   - `Products` → `products`, `ProductId` → `productid`, `StockQuantity` → `stockquantity`, etc.
2. **SCOPE_IDENTITY() → RETURNING clause**: Used writable CTEs with `RETURNING productid`
3. **GETDATE() → NOW()**: PostgreSQL equivalent for current timestamp
4. **T-SQL DECLARE/SET variables → CTE-based approach**: Restructured transaction blocks using PostgreSQL writable CTEs
5. **BEGIN TRANSACTION/COMMIT → Writable CTEs**: PostgreSQL handles transactions at the connection level; inline transaction blocks restructured
6. **Integer division fix**: Added `CAST(stockquantity AS NUMERIC)` in Statement 7 for proper division behavior

### SQL Equivalency Validation Results

| Statement | Equivalency Status | Tool Output |
|-----------|-------------------|-------------|
| Statement 1 (GetAllProductsAsync) | ERROR | {'equivalence_status': 'ERROR', 'error': "'uniqueID'"} |
| Statement 2 (GetProductByIdAsync) | ERROR | {'equivalence_status': 'ERROR', 'error': "'uniqueID'"} |
| Statement 3 (InsertProductAsync) | ERROR | {'equivalence_status': 'ERROR', 'error': "'uniqueID'"} |
| Statement 4 (UpdateProductAsync) | ERROR | {'equivalence_status': 'ERROR', 'error': "'uniqueID'"} |
| Statement 5 (DeleteProductAsync) | ERROR | {'equivalence_status': 'ERROR', 'error': "'uniqueID'"} |
| Statement 6 (GetProductsByPriceRangeAsync) | ERROR | {'equivalence_status': 'ERROR', 'error': "'uniqueID'"} |
| Statement 7 (GetLowStockProductsAsync) | ERROR | {'equivalence_status': 'ERROR', 'error': "'uniqueID'"} |

**Equivalency Summary**: 0 equivalent, 0 non-equivalent, 7 errors. All errors returned the same "'uniqueID'" error from the tool.

## Package Changes

### Before
```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />
```

### After
```xml
<PackageReference Include="Npgsql" Version="8.0.1" />
```

### Unchanged Packages
- Microsoft.Extensions.Configuration 8.0.0
- Microsoft.Extensions.Configuration.Json 8.0.0
- Microsoft.Extensions.DependencyInjection 8.0.0

## Connection String Changes

### Before (SQL Server)
```
Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### After (PostgreSQL)
```
Host=localhost;Database=ProductManagement;Username=postgres;Password=postgres
```

### Parameter Mapping
| SQL Server Parameter | PostgreSQL Parameter |
|---------------------|---------------------|
| Server=localhost | Host=localhost |
| Database=ProductManagement | Database=ProductManagement |
| Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets=true | (removed - not applicable) |
| TrustServerCertificate=True | (removed - not applicable) |

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Class | Occurrences |
|-----------------|-------------|-------------|
| SqlConnection | NpgsqlConnection | 3 (field, GetConnectionAsync, constructor) |
| SqlCommand | NpgsqlCommand | 7 (one per data access method) |
| SqlDataReader | NpgsqlDataReader | 1 (MapProductFromReader) |
| Microsoft.Data.SqlClient | Npgsql | 1 (using directive) |

## Files Modified

### sourceCode/DataAccess/ProductRepository.cs
- Replaced `using Microsoft.Data.SqlClient;` with `using Npgsql;`
- Replaced all SqlConnection → NpgsqlConnection
- Replaced all SqlCommand → NpgsqlCommand
- Replaced SqlDataReader → NpgsqlDataReader
- Replaced all 7 SQL statements with PostgreSQL equivalents

### sourceCode/AdoCore.csproj
- Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.1

### sourceCode/appsettings.json
- Updated DevConnection and ProdConnection to PostgreSQL format

## Files Created

### sourceCode/extracted_statements.sql
- Catalog of all 7 original MS SQL statements

### sourceCode/converted_statements.sql
- Catalog of all 7 converted PostgreSQL statements

### sourceCode/sql_equivalency_validation_report.json
- Comprehensive equivalency validation report in required JSON format

### sourceCode/migration_report.md
- This final migration report

## Detailed Statement Conversion Log

### Statement 1: GetAllProductsAsync
- **Type**: CTE with window functions (AVG OVER, COUNT OVER), INNER JOIN, CASE, ROUND
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects; SQL syntax already PostgreSQL-compatible
- **Equivalency**: ERROR ('uniqueID')

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, LEFT JOIN, CASE with NULL handling, ROUND
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects; SQL syntax already PostgreSQL-compatible
- **Equivalency**: ERROR ('uniqueID')

### Statement 3: InsertProductAsync
- **Type**: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE(), UPDATE
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Restructured using writable CTEs; SCOPE_IDENTITY() → RETURNING; GETDATE() → NOW()
- **Equivalency**: ERROR ('uniqueID')

### Statement 4: UpdateProductAsync
- **Type**: Transaction block with DECLARE, SELECT into variables, UPDATE, INSERT
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Restructured using writable CTEs; DECLARE/SET → CTE; GETDATE() → NOW()
- **Equivalency**: ERROR ('uniqueID')

### Statement 5: DeleteProductAsync
- **Type**: Transaction block with DECLARE, SELECT, INSERT, DELETE, UPDATE with CASE
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Restructured using writable CTEs; DECLARE/SET → CTE; GETDATE() → NOW()
- **Equivalency**: ERROR ('uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK, PERCENT_RANK window functions, BETWEEN, CASE
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects; SQL syntax already PostgreSQL-compatible
- **Equivalency**: ERROR ('uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX window functions, CASE, ROUND
- **DMS Attempt**: Failed - Metadata model creation failed
- **Manual Conversion**: Lowercase schema objects; Added CAST for integer division fix
- **Equivalency**: ERROR ('uniqueID')

## Manual Interventions Required
All 7 statements required manual intervention due to DMS tool failure. The manual conversions applied lowercase schema object naming conventions per the transformation definition's guidelines for DMS failures. The SQL Equivalency tool returned errors for all 7 pairs, requiring manual review to confirm conversion correctness.

## Recommendations
1. Verify all 7 converted SQL statements against a running PostgreSQL instance
2. Run integration tests with the PostgreSQL database to confirm functional equivalence
3. Review the writable CTE approach used for Insert/Update/Delete operations
4. Consider using stored procedures for complex transaction blocks if writable CTEs cause issues
5. Update PostgreSQL connection credentials for production environment
