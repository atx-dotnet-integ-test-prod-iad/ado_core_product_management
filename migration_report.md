# SQL Server to PostgreSQL Migration Report

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-08 |
| **Source Database** | Microsoft SQL Server |
| **Target Database** | PostgreSQL |
| **Application Type** | .NET ADO.NET Application |
| **Total SQL Statements Processed** | 7 |
| **Statements Successfully Converted by DMS MCP Tool** | 0 |
| **Statements Requiring Manual Intervention** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Validation Errors** | 7 |

## DMS Tool Status

The DMS MCP Statement Conversion Tool (`dms-mcp___statement_conversion_tool`) was attempted for all 7 SQL statements. All 7 failed with the same error:

```
Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
```

**DMS Configuration:**
- Migration Project: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- Database: `ProductManagement`
- Schema: `dbo`
- Region: `us-east-1`
- Server: `172.31.94.132`

**DMS Schema Mapping Tool** (`dms-mcp___schema_mapping_tool`) successfully retrieved schema mappings for all 3 tables, which guided the manual conversion.

## SQL Equivalency Tool Status

The SQL Equivalency Tool (`sql-equivalency___validate_sql_equivalence`) was invoked for all 7 statement pairs. All 7 returned an ERROR status:

```json
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

No agent judgment was used for equivalency determination. All results come exclusively from the tool.

## Files Modified

| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | All 7 SQL statements replaced with PostgreSQL equivalents; ADO.NET classes replaced (SqlConnection→NpgsqlConnection, SqlCommand→NpgsqlCommand, SqlDataReader→NpgsqlDataReader); using statement updated |
| `AdoCore.csproj` | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| `appsettings.json` | Connection strings updated from SQL Server to PostgreSQL format |

## Files Created (Migration Artifacts)

| File | Description |
|------|-------------|
| `extracted_statements.sql` | Complete catalog of all 7 original MS SQL statements |
| `converted_statements.sql` | Complete catalog of all 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report for all 7 statement pairs |
| `dms_failure_summary.md` | Detailed documentation of DMS tool failures and manual conversion decisions |
| `migration_report.md` | This report |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server/Host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `true` | Removed (not applicable) |
| TrustServerCertificate | `True` | Removed (not applicable) |

## Package Changes

| Original Package | Version | New Package | Version |
|-----------------|---------|-------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.6 |

*Note: Plan specified Npgsql 8.0.1 but was upgraded to 8.0.6 to resolve known high severity vulnerability (GHSA-x9vc-6hfv-hg8c).*

## ADO.NET Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per query method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

## Detailed SQL Statement Conversion

### Statement 1: GetAllProductsAsync
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Changes:** CTE renamed `productstats_cte`, all table/column names to lowercase
- **SQL Features:** CTE, AVG/COUNT OVER(), CASE, ROUND, INNER JOIN, ORDER BY CASE

### Statement 2: GetProductByIdAsync
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Changes:** CTE renamed `producthistory_cte`, all names lowercase
- **SQL Features:** CTE, LAG() OVER(), CASE with NULL, ROUND, LEFT JOIN
- **Parameters Preserved:** @ProductId

### Statement 3: InsertProductAsync
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Changes:** DECLARE/SET/SCOPE_IDENTITY → writable CTE with RETURNING; GETDATE() → clock_timestamp(); BEGIN TRANSACTION/COMMIT removed (handled by app); all names lowercase
- **SQL Features:** INSERT, RETURNING, multi-table writable CTEs
- **Parameters Preserved:** @Name, @Description, @Price, @StockQuantity

### Statement 4: UpdateProductAsync
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Changes:** DECLARE removed, restructured with writable CTEs; GETDATE() → clock_timestamp(); all names lowercase
- **SQL Features:** Writable CTEs, UPDATE, INSERT, subquery
- **Parameters Preserved:** @ProductId, @Name, @Description, @Price, @StockQuantity

### Statement 5: DeleteProductAsync
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Changes:** DECLARE removed, restructured with writable CTEs; GETDATE() → clock_timestamp(); all names lowercase
- **SQL Features:** Writable CTEs, DELETE, INSERT, UPDATE with CASE, subquery
- **Parameters Preserved:** @ProductId

### Statement 6: GetProductsByPriceRangeAsync
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Changes:** All table/column names to lowercase
- **SQL Features:** CTE, RANK(), PERCENT_RANK(), BETWEEN, CASE
- **Parameters Preserved:** @MinPrice, @MaxPrice

### Statement 7: GetLowStockProductsAsync
- **Conversion Method:** DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
- **Equivalency Status:** ERROR (tool returned `'uniqueID'` error)
- **Changes:** All names lowercase; added `::numeric` cast for integer division in ROUND
- **SQL Features:** CTE, AVG/MIN/MAX OVER(), CASE, ROUND
- **Parameters Preserved:** @Threshold

## Schema Mapping (from DMS Schema Mapping Tool)

| Source Table (SQL Server) | Target Table (PostgreSQL) | Target Schema |
|--------------------------|--------------------------|---------------|
| `[dbo].[Products]` | `products` | `productmanagement_dbo` |
| `[dbo].[ProductHistory]` | `producthistory` | `productmanagement_dbo` |
| `[dbo].[ProductStats]` | `productstats` | `productmanagement_dbo` |

### Key Type Mappings
| SQL Server Type | PostgreSQL Type |
|----------------|-----------------|
| `int IDENTITY(1,1)` | `INTEGER GENERATED ALWAYS AS IDENTITY` |
| `nvarchar(N)` | `VARCHAR(N)` |
| `decimal(18,2)` | `NUMERIC(18,2)` |
| `datetime` | `TIMESTAMP WITHOUT TIME ZONE` |
| `bit` | `NUMERIC(1,0)` |

### Key Function Mappings
| SQL Server Function | PostgreSQL Equivalent |
|--------------------|----------------------|
| `GETDATE()` | `clock_timestamp()` |
| `SCOPE_IDENTITY()` | `RETURNING` clause |
| `DECLARE @var` | Writable CTE restructuring |
| `BEGIN TRANSACTION/COMMIT` | Application-level transaction management |

## Statements Requiring Manual Review

All 7 statements require manual review because:
1. DMS conversion failed for all 7 statements
2. SQL Equivalency validation returned ERROR for all 7 statement pairs
3. Manual conversion was applied with lowercase schema mapping rules

**Recommended Actions:**
- Test each query against a PostgreSQL database with actual data
- Verify writable CTE behavior for INSERT/UPDATE/DELETE operations (Statements 3, 4, 5)
- Validate that the RETURNING clause properly returns the new product ID (Statement 3)
- Confirm clock_timestamp() provides equivalent behavior to GETDATE()
- Verify integer division handling with ::numeric cast (Statement 7)

## Build Status

**Final Build: SUCCEEDED**
- 0 Errors
- 10 Warnings (all pre-existing nullable reference warnings)
- No package vulnerability warnings
