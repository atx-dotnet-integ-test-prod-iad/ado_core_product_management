# Final Migration Report: MS SQL Server to PostgreSQL

## Migration Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-04-16 |
| **Source Database** | Microsoft SQL Server |
| **Target Database** | PostgreSQL |
| **Application Type** | .NET ADO.NET Console Application |
| **Framework** | .NET 9.0 |
| **Total SQL Statements Processed** | 7 |
| **Statements Converted by DMS Tool** | 0 (DMS service error) |
| **Statements Manually Converted** | 7 |
| **Statements Validated as Equivalent** | 0 |
| **Statements Validated as Non-Equivalent** | 0 |
| **Statements with Equivalency Errors** | 7 (SQL Equivalency tool service error) |
| **Build Status** | ✅ SUCCESS (0 errors, 10 warnings) |

## Migration Scope

### Files Modified
| File | Changes |
|------|---------|
| `DataAccess/ProductRepository.cs` | Replaced 7 SQL statements, updated using directive, replaced all ADO.NET classes |
| `AdoCore.csproj` | Replaced Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.9 |
| `appsettings.json` | Converted connection strings from SQL Server to PostgreSQL format |

### Files Not Requiring Changes
| File | Reason |
|------|--------|
| `Program.cs` | Uses IConfiguration abstractions (database-agnostic) |
| `Business/ProductService.cs` | Business logic layer, no database-specific code |
| `CLI/CommandLineInterface.cs` | CLI layer, no database-specific code |
| `CLI/InteractiveMenu.cs` | UI layer, no database-specific code |
| `Models/Product.cs` | Data model, no database-specific code |

## DMS Tool Status

All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the following configuration:
- **Migration Project ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Database**: ProductManagement
- **Schema**: dbo
- **Region**: us-east-1

**All 7 calls failed** with the same error:
```
Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
```

Multiple retry strategies were attempted:
1. Default parameters - FAILED
2. Increased max_poll_attempts (30) and poll_interval_seconds (15) - FAILED
3. Increased max_poll_attempts (50) and poll_interval_seconds (20) - FAILED
4. Explicit server_name parameter - FAILED
5. Simple test query - FAILED

**Fallback Applied**: Manual conversion with lowercase schema object naming per transformation definition rule `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`.

## SQL Equivalency Tool Status

All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`).

**All 7 calls returned ERROR** with the same message:
```
{"equivalence_status": "ERROR", "error": "'uniqueID'"}
```

This was confirmed as a systemic service-level issue by also testing a trivial `SELECT 1` vs `SELECT 1` pair, which returned the same error.

**Per transformation definition**: Equivalency status is recorded exactly as returned by the tool. Agent judgment was NOT used to determine equivalency for any statement pair.

## Detailed SQL Statement Migration

### Statement 1: GetAllProductsAsync
| Property | Value |
|----------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | GetAllProductsAsync() |
| **Type** | SELECT with CTE, AVG/COUNT window functions, CASE WHEN, ROUND, INNER JOIN |
| **DMS Status** | FAILED |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool service error) |
| **Key Changes** | Lowercased all identifiers (ProductStats→productstats, AvgPrice→avgprice, etc.) |

### Statement 2: GetProductByIdAsync
| Property | Value |
|----------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | GetProductByIdAsync(int productId) |
| **Type** | SELECT with CTE, LAG window functions, CASE WHEN, ROUND, LEFT JOIN |
| **DMS Status** | FAILED |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool service error) |
| **Key Changes** | Lowercased all identifiers (ProductHistory→producthistory, PreviousPrice→previousprice, etc.) |

### Statement 3: InsertProductAsync
| Property | Value |
|----------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | InsertProductAsync(Product product) |
| **Type** | Transaction block with INSERT, SCOPE_IDENTITY, INSERT history, UPDATE stats |
| **DMS Status** | FAILED |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool service error) |
| **Key Changes** | SCOPE_IDENTITY()→INSERT...RETURNING via writable CTE; GETDATE()→NOW(); DECLARE/SET→writable CTE chain; BEGIN TRANSACTION/COMMIT→removed (single atomic CTE statement) |

### Statement 4: UpdateProductAsync
| Property | Value |
|----------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | UpdateProductAsync(Product product) |
| **Type** | Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT history, UPDATE stats |
| **DMS Status** | FAILED |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool service error) |
| **Key Changes** | DECLARE @OldPrice/SET→CTE old_values; GETDATE()→NOW(); BEGIN TRANSACTION/COMMIT→removed; restructured as writable CTE chain |

### Statement 5: DeleteProductAsync
| Property | Value |
|----------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | DeleteProductAsync(int productId) |
| **Type** | Transaction block with DECLARE, SELECT INTO vars, INSERT history, DELETE, UPDATE stats with CASE |
| **DMS Status** | FAILED |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool service error) |
| **Key Changes** | DECLARE @OldPrice/SET→CTE old_values; GETDATE()→NOW(); BEGIN TRANSACTION/COMMIT→removed; restructured as writable CTE chain |

### Statement 6: GetProductsByPriceRangeAsync
| Property | Value |
|----------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice) |
| **Type** | SELECT with CTE, RANK, PERCENT_RANK window functions, BETWEEN, CASE WHEN |
| **DMS Status** | FAILED |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool service error) |
| **Key Changes** | Lowercased all identifiers (RankedProducts→rankedproducts, PriceRank→pricerank, etc.) |

### Statement 7: GetLowStockProductsAsync
| Property | Value |
|----------|-------|
| **Source File** | DataAccess/ProductRepository.cs |
| **Method** | GetLowStockProductsAsync(int threshold) |
| **Type** | SELECT with CTE, AVG/MIN/MAX window functions, CASE WHEN, ROUND |
| **DMS Status** | FAILED |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool service error) |
| **Key Changes** | Lowercased all identifiers; added CAST(stockquantity AS NUMERIC) for integer division fix in ROUND |

## ADO.NET Class Replacements

| Original (SQL Server) | Replacement (PostgreSQL) | Occurrences |
|------------------------|--------------------------|-------------|
| `using Microsoft.Data.SqlClient;` | `using Npgsql;` | 1 |
| `SqlConnection` | `NpgsqlConnection` | 3 (field, method return, constructor) |
| `SqlCommand` | `NpgsqlCommand` | 7 (one per SQL method) |
| `SqlDataReader` | `NpgsqlDataReader` | 1 (MapProductFromReader parameter) |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server identifier | `Server=localhost` | `Host=localhost` |
| Database | `Database=ProductManagement` | `Database=ProductManagement` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MultipleActiveResultSets | `MultipleActiveResultSets=true` | *Removed (not needed)* |
| TrustServerCertificate | `TrustServerCertificate=True` | *Removed (not applicable)* |

## Package Dependency Changes

| Original Package | Version | Replacement Package | Version |
|-----------------|---------|-------------------|---------|
| Microsoft.Data.SqlClient | 5.1.4 | Npgsql | 8.0.9 |

**Note**: Plan specified Npgsql 8.0.1, but it has a known high severity vulnerability (GHSA-x9vc-6hfv-hg8c). Upgraded to 8.0.9 per security guardrail.

## Migration Artifacts

| Artifact | Location | Contents |
|----------|----------|----------|
| `extracted_statements.sql` | sourceCode/ | All 7 original MS SQL statements |
| `converted_statements.sql` | sourceCode/ | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | sourceCode/ | All 7 pairs with tool-determined equivalency status |
| `conversion_log.md` | sourceCode/ | DMS failure documentation and manual conversion details |
| `final_migration_report.md` | sourceCode/ | This report |

## Statements Requiring Manual Review

**All 7 statements** require manual review because:
1. DMS tool was unable to convert any statements (infrastructure error)
2. SQL Equivalency tool was unable to validate any statement pairs (service error)
3. Manual conversions were applied using lowercase schema naming convention

**Key areas to verify during review:**
- Writable CTEs (Statements 3, 4, 5) - ensure PostgreSQL version handles the multi-table operations atomically
- Integer division (Statement 7) - CAST(stockquantity AS NUMERIC) added to prevent integer division
- Parameter binding compatibility with Npgsql's @parameter syntax
- Transaction semantics preserved through CTE atomicity

## Build Verification

```
Build succeeded.
    10 Warning(s)
    0 Error(s)
```

All warnings are pre-existing nullable reference warnings (CS8600, CS8601, CS8603, CS8618, CS8625) that existed before migration.
