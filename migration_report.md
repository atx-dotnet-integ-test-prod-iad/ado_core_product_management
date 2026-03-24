# Migration Report: SQL Server to PostgreSQL

## Summary

| Metric | Value |
|--------|-------|
| **Migration Date** | 2026-03-24 |
| **Source Database** | Microsoft SQL Server 2019 (ProductManagement) |
| **Target Database** | PostgreSQL 13 (postgres) |
| **Application Framework** | .NET 9.0 / ADO.NET |
| **Source Package** | Microsoft.Data.SqlClient 5.1.4 |
| **Target Package** | Npgsql 8.0.6 |
| **Build Status** | ✅ Success (0 errors, 10 pre-existing warnings) |

---

## SQL Statement Processing

| Metric | Count |
|--------|-------|
| **Total SQL Statements Processed** | 7 |
| **Successfully Converted by DMS Tool** | 0 |
| **Requiring Manual Intervention (DMS Failed)** | 7 |
| **Validated as EQUIVALENT** | 0 |
| **Validated as NOT_EQUIVALENT** | 0 |
| **Equivalency ERROR** | 7 |

### DMS Tool Status
All 7 SQL statements were submitted to the DMS MCP tool (`dms-mcp___statement_conversion_tool`) with the migration project ARN `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`. All failed due to service-side issues:
- **Statements 1-2**: Metadata model creation/conversion timeout (15 attempts)
- **Statement 3**: Statement definition is not valid
- **Statements 4-7**: Command execution timeout (300 seconds)

### SQL Equivalency Tool Status
All 7 statement pairs were submitted to the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR with `'uniqueID'` error (service-side issue). Per transformation definition: "If sql-equivalency returns an error, mark the equivalency status as ERROR."

### Manual Conversion Applied
Since DMS failed for all statements, manual conversion was applied with **lowercase schema object names** per the transformation definition's DMS failure handling rules.

---

## Statement-by-Statement Details

### Statement 1: GetAllProductsAsync
| Field | Value |
|-------|-------|
| **Source** | ProductRepository.cs, GetAllProductsAsync() |
| **Type** | CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN |
| **DMS Status** | ❌ Failed - Metadata model conversion timeout |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned 'uniqueID' error) |
| **Key Changes** | Schema objects to lowercase (Products→products, ProductId→productid, etc.) |

### Statement 2: GetProductByIdAsync
| Field | Value |
|-------|-------|
| **Source** | ProductRepository.cs, GetProductByIdAsync() |
| **Type** | CTE with LAG window functions, LEFT JOIN, CASE, ROUND |
| **DMS Status** | ❌ Failed - Metadata model creation timeout |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned 'uniqueID' error) |
| **Key Changes** | Schema objects to lowercase |

### Statement 3: InsertProductAsync
| Field | Value |
|-------|-------|
| **Source** | ProductRepository.cs, InsertProductAsync() |
| **Type** | Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE() |
| **DMS Status** | ❌ Failed - Statement definition is not valid |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned 'uniqueID' error) |
| **Key Changes** | SCOPE_IDENTITY() → RETURNING productid, GETDATE() → NOW(), Transaction block → CTE with data-modifying statements |

### Statement 4: UpdateProductAsync
| Field | Value |
|-------|-------|
| **Source** | ProductRepository.cs, UpdateProductAsync() |
| **Type** | Transaction block with DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE() |
| **DMS Status** | ❌ Failed - Command execution timeout |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned 'uniqueID' error) |
| **Key Changes** | GETDATE() → NOW(), DECLARE/SET → CTE-based old_values capture, Transaction block → data-modifying CTEs |

### Statement 5: DeleteProductAsync
| Field | Value |
|-------|-------|
| **Source** | ProductRepository.cs, DeleteProductAsync() |
| **Type** | Transaction block with DECLARE, SELECT INTO, INSERT, DELETE, GETDATE() |
| **DMS Status** | ❌ Failed - Command execution timeout |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned 'uniqueID' error) |
| **Key Changes** | GETDATE() → NOW(), DECLARE/SET → CTE-based old_values capture, Transaction block → data-modifying CTEs |

### Statement 6: GetProductsByPriceRangeAsync
| Field | Value |
|-------|-------|
| **Source** | ProductRepository.cs, GetProductsByPriceRangeAsync() |
| **Type** | CTE with RANK(), PERCENT_RANK() window functions, CASE, BETWEEN |
| **DMS Status** | ❌ Failed - Command execution timeout |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned 'uniqueID' error) |
| **Key Changes** | Schema objects to lowercase |

### Statement 7: GetLowStockProductsAsync
| Field | Value |
|-------|-------|
| **Source** | ProductRepository.cs, GetLowStockProductsAsync() |
| **Type** | CTE with AVG/MIN/MAX window functions, CASE, ROUND |
| **DMS Status** | ❌ Failed - Command execution timeout |
| **Conversion Method** | DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA |
| **Equivalency Status** | ERROR (tool returned 'uniqueID' error) |
| **Key Changes** | Schema objects to lowercase, added ::numeric cast for integer division |

---

## Files Modified

| File | Changes |
|------|---------|
| **AdoCore.csproj** | Microsoft.Data.SqlClient 5.1.4 → Npgsql 8.0.6 |
| **DataAccess/ProductRepository.cs** | using directive, all SQL statements, all ADO.NET class references |
| **appsettings.json** | Connection strings: SQL Server format → PostgreSQL format |
| **Database/Scripts/01_InitialSetup.sql** | Full conversion to PostgreSQL DDL syntax |
| **Scripts/01_InitialSetup.sql** | Full conversion to PostgreSQL DDL syntax |

## Class Replacements

| SQL Server Class | Npgsql Equivalent | Occurrences |
|-----------------|-------------------|-------------|
| `SqlConnection` | `NpgsqlConnection` | 3 |
| `SqlCommand` | `NpgsqlCommand` | 7 |
| `SqlDataReader` | `NpgsqlDataReader` | 1 |
| `using Microsoft.Data.SqlClient` | `using Npgsql` | 1 |

## Connection String Changes

| Parameter | SQL Server | PostgreSQL |
|-----------|-----------|------------|
| Server host | `Server=localhost` | `Host=localhost` |
| Port | (default 1433) | `Port=5432` |
| Database | `Database=ProductManagement` | `Database=postgres` |
| Authentication | `Trusted_Connection=True` | `Username=postgres;Password=postgres` |
| MARS | `MultipleActiveResultSets=true` | (removed - PostgreSQL N/A) |
| TLS | `TrustServerCertificate=True` | (removed - PostgreSQL N/A) |

## SQL Syntax Changes Summary

| SQL Server Syntax | PostgreSQL Equivalent |
|-------------------|---------------------|
| `SCOPE_IDENTITY()` | `RETURNING productid` clause |
| `GETDATE()` | `NOW()` |
| `BEGIN TRANSACTION/COMMIT` | Data-modifying CTEs |
| `DECLARE @var TYPE; SET @var = ...` | CTE-based value capture |
| `[dbo].[TableName]` | `tablename` (lowercase) |
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `BIT` | `BOOLEAN` |
| `IDENTITY(1,1)` | `SERIAL` |
| `GO` | (removed) |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |
| `SYSTEM_USER` | `CURRENT_USER` |
| `StockQuantity / AvgStock` (int division) | `stockquantity::numeric / avgstock` |

---

## Artifacts Generated

| Artifact | Location | Description |
|----------|----------|-------------|
| `extracted_statements.sql` | sourceCode/ | Original 7 SQL statements with source locations |
| `converted_statements.sql` | sourceCode/ | Original + converted statement pairs for all 7 statements |
| `sql_equivalency_validation_report.json` | sourceCode/ | Comprehensive equivalency report with all 7 statement details |
| `migration_report.md` | sourceCode/ | This report |

---

## Exit Criteria Verification

| Criteria | Status |
|----------|--------|
| All SQL Server packages replaced with PostgreSQL equivalents | ✅ |
| All SqlConnection/SqlCommand/SqlDataReader replaced with Npgsql | ✅ |
| All SQL statements processed through DMS MCP tool | ✅ (all 7 submitted, all failed) |
| All statement pairs validated through SQL Equivalency tool | ✅ (all 7 submitted, all returned ERROR) |
| Comprehensive equivalency report generated | ✅ |
| No agent judgment used for equivalency | ✅ (all statuses from tool) |
| DMS failures documented with manual conversion | ✅ |
| Connection strings updated to PostgreSQL format | ✅ |
| Application compiles without errors | ✅ (0 errors, 10 pre-existing warnings) |
| Comprehensive artifacts created | ✅ |

---

## Notes and Recommendations

1. **DMS Tool Failures**: All 7 statements failed DMS conversion due to service timeouts and errors. The DMS service appeared to be experiencing infrastructure issues. If the DMS service becomes available, it is recommended to re-run the conversions to validate the manual conversions.

2. **SQL Equivalency Tool Failures**: All 7 statement pair validations returned ERROR with `'uniqueID'` error. This appears to be a service-side configuration issue. When the service is restored, re-validation is recommended.

3. **Data-Modifying CTEs**: Statements 3, 4, and 5 (Insert, Update, Delete) were restructured from SQL Server transaction blocks with DECLARE/SET to PostgreSQL data-modifying CTEs. This approach allows single-statement execution through Npgsql while maintaining transactional atomicity.

4. **Integer Division**: Statement 7 (GetLowStockProductsAsync) includes a `::numeric` cast for integer division to ensure proper decimal results in PostgreSQL.

5. **Npgsql Version**: Used Npgsql 8.0.6 instead of 8.0.0 to address known vulnerability GHSA-x9vc-6hfv-hg8c.
