# Migration Summary Report: MS SQL Server to PostgreSQL
## AdoCore Application - ADO.NET Database Migration

### Migration Overview
- **Date**: 2026-04-06
- **Source Database**: Microsoft SQL Server 2019 (ProductManagement)
- **Target Database**: PostgreSQL 13 (postgres)
- **Application Framework**: .NET 9.0 with ADO.NET
- **Migration Tool**: AWS DMS MCP Tool (attempted), Manual Conversion (applied)

---

### SQL Statement Processing Summary

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 7 |
| Successfully Converted by DMS | 0 |
| Manual Conversion Required (DMS Failed) | 7 |
| Equivalency Validated as EQUIVALENT | 0 |
| Equivalency Validated as NOT_EQUIVALENT | 0 |
| Equivalency Validation ERROR | 7 |

### DMS Tool Status
- **DMS Migration Project ARN**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **DMS Status**: All 7 statements were submitted to DMS but failed due to metadata model creation/conversion timeout
- **DMS Error**: "Metadata model creation/conversion did not complete after 15 attempts"
- **Fallback**: Manual conversion applied with lowercase schema object names (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)

### SQL Equivalency Tool Status
- **Tool Status**: All 7 statement pairs were validated through the SQL Equivalency tool
- **Tool Error**: Returned ERROR with "'uniqueID'" internal error for all 7 pairs
- **Equivalency Status**: All 7 marked as ERROR per transformation definition requirements

---

### SQL Statement Conversion Details

#### Statement 1: GetAllProductsAsync
- **Source Method**: GetAllProductsAsync()
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects converted to lowercase (ProductStats → productstats, Products → products, etc.)
- **Equivalency**: ERROR (tool internal error)

#### Statement 2: GetProductByIdAsync
- **Source Method**: GetProductByIdAsync(int productId)
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects converted to lowercase (ProductHistory → producthistory, Products → products, etc.)
- **Equivalency**: ERROR (tool internal error)

#### Statement 3: InsertProductAsync
- **Source Method**: InsertProductAsync(Product product)
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - SCOPE_IDENTITY() → lastval()
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT removed (managed by Npgsql)
  - DECLARE @NewProductId / SET @NewProductId removed, using lastval() instead
  - Schema objects converted to lowercase
- **Equivalency**: ERROR (tool internal error)

#### Statement 4: UpdateProductAsync
- **Source Method**: UpdateProductAsync(Product product)
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - DECLARE variables removed, restructured to use INSERT...SELECT for history capture
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT removed (managed by Npgsql)
  - Stats UPDATE uses subquery instead of variable
  - Reordered: History INSERT → Stats UPDATE → Product UPDATE (captures old values before update)
  - Schema objects converted to lowercase
- **Equivalency**: ERROR (tool internal error)

#### Statement 5: DeleteProductAsync
- **Source Method**: DeleteProductAsync(int productId)
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - DECLARE variables removed, restructured to use INSERT...SELECT for history capture
  - GETDATE() → NOW()
  - BEGIN TRANSACTION/COMMIT removed (managed by Npgsql)
  - Stats UPDATE uses subquery instead of variable
  - Reordered: History INSERT → Stats UPDATE → DELETE (captures old values before deletion)
  - Schema objects converted to lowercase
- **Equivalency**: ERROR (tool internal error)

#### Statement 6: GetProductsByPriceRangeAsync
- **Source Method**: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**: Schema objects converted to lowercase (RankedProducts → rankedproducts, Products → products, etc.)
- **Equivalency**: ERROR (tool internal error)

#### Statement 7: GetLowStockProductsAsync
- **Source Method**: GetLowStockProductsAsync(int threshold)
- **Source File**: DataAccess/ProductRepository.cs
- **Conversion Method**: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Changes**:
  - Schema objects converted to lowercase (StockAnalysis → stockanalysis, Products → products, etc.)
  - Added CAST(stockquantity AS NUMERIC) for proper integer division in ROUND function
- **Equivalency**: ERROR (tool internal error)

---

### Files Modified

| File | Change Type | Description |
|------|------------|-------------|
| DataAccess/ProductRepository.cs | Modified | SQL statements converted, SqlClient → Npgsql types |
| AdoCore.csproj | Modified | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| appsettings.json | Modified | SQL Server → PostgreSQL connection strings |

### New Artifacts Created

| File | Description |
|------|-------------|
| extracted_statements.sql | Catalog of all 7 original MS SQL statements |
| converted_statements.sql | Catalog of all 7 converted PostgreSQL statements |
| sql_equivalency_validation_report.json | JSON report with equivalency validation for all 7 pairs |
| migration_summary_report.md | This report |

---

### Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | Server=localhost | Host=localhost |
| Port | (default 1433) | Port=5432 |
| Database | Database=ProductManagement | Database=postgres |
| Authentication | Trusted_Connection=True | Username=postgres;Password=postgres |
| MARS | MultipleActiveResultSets=true | (removed - N/A) |
| TLS | TrustServerCertificate=True | (removed - N/A) |

### Package Dependency Changes

| Package | Before | After |
|---------|--------|-------|
| Microsoft.Data.SqlClient | 5.1.4 | Removed |
| Npgsql | N/A | 8.0.6 |
| Microsoft.Extensions.Configuration | 8.0.0 | 8.0.0 (unchanged) |
| Microsoft.Extensions.Configuration.Json | 8.0.0 | 8.0.0 (unchanged) |
| Microsoft.Extensions.DependencyInjection | 8.0.0 | 8.0.0 (unchanged) |

---

### Issues and Warnings

1. **DMS Tool Failure**: The DMS MCP tool failed for all 7 statements due to metadata model creation/conversion timeout. All conversions were done manually with lowercase schema mapping.

2. **SQL Equivalency Tool Error**: The SQL Equivalency tool returned ERROR with "'uniqueID'" internal error for all 7 statement pairs. This appears to be a systemic issue with the tool, not specific to the statements.

3. **Transaction Management**: The original SQL used embedded BEGIN TRANSACTION/COMMIT within SQL strings. In the PostgreSQL version, these were removed since Npgsql's transaction management (BeginTransactionAsync/CommitAsync/RollbackAsync) in the ExecuteInTransactionAsync method handles this at the C# level. The individual SQL statements execute within the connection's context.

4. **Variable Elimination**: SQL Server DECLARE/SET variables were eliminated and replaced with subqueries and INSERT...SELECT patterns to work with Npgsql's parameterized query model.

5. **Integer Division**: In Statement 7 (GetLowStockProductsAsync), added explicit CAST(stockquantity AS NUMERIC) to prevent integer division truncation in PostgreSQL's ROUND function.

6. **Connection String Credentials**: The PostgreSQL connection strings use placeholder credentials (postgres/postgres). These should be updated with actual credentials for production deployment, preferably using environment variables or a secrets manager.

---

### Build Status
- Build verification: Pending (dotnet build requires NuGet package restore which depends on network access)
