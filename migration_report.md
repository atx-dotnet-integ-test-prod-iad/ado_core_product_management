# SQL Server to PostgreSQL Migration Report

## Summary
- **Project**: AdoCore (.NET 9 Console Application)
- **Source Database**: Microsoft SQL Server (Microsoft.Data.SqlClient 5.1.4)
- **Target Database**: PostgreSQL (Npgsql 8.0.6)

## Statement Processing Summary
| Metric | Count |
|--------|-------|
| Total SQL statements processed | 7 |
| Statements successfully converted by DMS MCP tool | 0 |
| Statements requiring manual intervention (DMS failure) | 7 |
| Statements validated as equivalent | 0 |
| Statements validated as non-equivalent | 0 |
| Statements with equivalency validation errors | 7 |

## DMS Tool Failures
All 7 SQL statements were passed to the DMS MCP tool (dms-mcp___statement_conversion_tool) for conversion. All failed with one of two errors:
1. "Metadata model creation failed: Metadata model creation did not complete after 15 attempts"
2. "Metadata model creation failed: DMS Schema Conversion can't access the S3 resource 'atx-db-modernization-789616364195-us-east-1'"

## Manual Conversion Applied
Since DMS failed, manual conversion was applied with the following rules (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA):
- All schema object names converted to lowercase (tables, columns, aliases)
- SCOPE_IDENTITY() replaced with INSERT...RETURNING pattern using CTEs
- GETDATE() replaced with NOW()
- Transaction blocks restructured as writable CTEs (PostgreSQL's data-modifying CTEs)
- DECLARE/SET variable patterns replaced with CTE-based subqueries
- Integer division cast to ::numeric where needed for proper decimal results

## SQL Equivalency Validation
All 7 statement pairs were validated through the SQL Equivalency MCP tool (sql-equivalency___validate_sql_equivalence). All returned ERROR status with error "'uniqueID'" - this appears to be a tool-level error unrelated to the SQL statements themselves.

## Files Modified
| File | Changes |
|------|---------|
| sourceCode/DataAccess/ProductRepository.cs | Replaced all SQL statements with PostgreSQL equivalents; replaced SqlConnection/SqlCommand/SqlDataReader with NpgsqlConnection/NpgsqlCommand/NpgsqlDataReader; updated using directive from Microsoft.Data.SqlClient to Npgsql; updated column name references in MapProductFromReader to lowercase |
| sourceCode/AdoCore.csproj | Replaced Microsoft.Data.SqlClient 5.1.4 with Npgsql 8.0.6 |
| sourceCode/appsettings.json | Updated connection strings from SQL Server format to PostgreSQL format (Server→Host, Trusted_Connection→Username/Password) |

## Files Created
| File | Purpose |
|------|---------|
| sourceCode/extracted_statements.sql | Catalog of all original MS SQL statements |
| sourceCode/converted_statements.sql | Catalog of all converted PostgreSQL statements |
| sourceCode/sql_equivalency_validation_report.json | Comprehensive equivalency validation report in JSON format |

## Detailed Statement Conversions

### Statement 1: GetAllProductsAsync (SELECT with CTE and window functions)
- **Conversion**: Lowercase schema objects, structure preserved (CTEs and window functions are compatible)
- **DMS Error**: Metadata model creation timeout

### Statement 2: GetProductByIdAsync (SELECT with CTE and LAG window function)
- **Conversion**: Lowercase schema objects, structure preserved
- **DMS Error**: S3 resource access error

### Statement 3: InsertProductAsync (Transaction with SCOPE_IDENTITY)
- **Conversion**: Restructured from DECLARE/BEGIN TRANSACTION/SCOPE_IDENTITY pattern to writable CTE with INSERT...RETURNING
- **DMS Error**: Metadata model creation timeout

### Statement 4: UpdateProductAsync (Transaction with variable capture)
- **Conversion**: Restructured from DECLARE/BEGIN TRANSACTION with variable assignment to writable CTE pattern
- **DMS Error**: Metadata model creation timeout

### Statement 5: DeleteProductAsync (Transaction with variable capture)
- **Conversion**: Restructured from DECLARE/BEGIN TRANSACTION with variable assignment to writable CTE with DELETE...RETURNING
- **DMS Error**: S3 resource access error

### Statement 6: GetProductsByPriceRangeAsync (SELECT with RANK/PERCENT_RANK)
- **Conversion**: Lowercase schema objects, structure preserved (window functions are compatible)
- **DMS Error**: Metadata model creation timeout

### Statement 7: GetLowStockProductsAsync (SELECT with multiple window functions)
- **Conversion**: Lowercase schema objects, added ::numeric cast for integer division in ROUND
- **DMS Error**: Metadata model creation timeout

## Static Code Changes
| Original (SQL Server) | Replacement (PostgreSQL) |
|----------------------|--------------------------|
| using Microsoft.Data.SqlClient | using Npgsql |
| SqlConnection | NpgsqlConnection |
| SqlCommand | NpgsqlCommand |
| SqlDataReader | NpgsqlDataReader |
| Parameters.AddWithValue | Parameters.AddWithValue (compatible) |
| BeginTransactionAsync | BeginTransactionAsync (compatible) |

## Connection String Changes
| Original | Replacement |
|----------|-------------|
| Server=localhost | Host=localhost |
| Database=ProductManagement | Database=productmanagement |
| Trusted_Connection=True | Username=postgres;Password=postgres |
| MultipleActiveResultSets=true | (removed - not applicable) |
| TrustServerCertificate=True | (removed - not applicable) |
