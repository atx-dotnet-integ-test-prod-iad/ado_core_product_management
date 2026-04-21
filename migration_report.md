# Migration Report: SQL Server to PostgreSQL (AdoCore)

## Summary
This report documents the migration of the AdoCore .NET application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics
| Metric | Value |
|--------|-------|
| Total SQL Statements Processed | 7 |
| DMS Conversion Successful | 0 |
| DMS Conversion Failed | 7 |
| Manual Conversions (with lowercase schema) | 7 |
| SQL Equivalency Tool - EQUIVALENT | 0 |
| SQL Equivalency Tool - NOT_EQUIVALENT | 0 |
| SQL Equivalency Tool - ERROR | 7 |
| Files Modified | 3 |
| Build Status | **SUCCESS** |

## DMS Conversion Results
All 7 SQL statements were passed through the DMS MCP tool (`dms-mcp___statement_conversion_tool`) as required. All failed with the same systemic error:

- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **DMS ARN**: `arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU`
- **Multiple retries**: Attempted with varying poll intervals (10-30s) and max poll attempts (15-40)

### Manual Conversion Applied
Per transformation plan instructions, all statements were manually converted with:
- **Conversion Method**: `DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA`
- All table and column names converted to lowercase for PostgreSQL convention
- `SCOPE_IDENTITY()` → `LASTVAL()`
- `GETDATE()` → `NOW()`
- `BEGIN TRANSACTION` → `BEGIN`
- `DECLARE @var` / variable assignments → restructured using subqueries
- Integer division → explicit `CAST(... AS NUMERIC)` where needed

## SQL Equivalency Validation Results
All 7 statement pairs were validated through the SQL Equivalency tool (`sql-equivalency___validate_sql_equivalence`). All returned ERROR with a systemic `'uniqueID'` error, which is a tool-level issue unrelated to the SQL statements.

- **Report File**: `sql_equivalency_validation_report.json`
- **No agent judgment was used** to determine equivalency

## Statements Processed

### Statement 1: GetAllProductsAsync
- **Type**: CTE with AVG/COUNT window functions, CASE, ROUND, INNER JOIN
- **DMS**: FAILED
- **Manual Conversion**: Lowercase schema names applied
- **Equivalency**: ERROR ('uniqueID')

### Statement 2: GetProductByIdAsync
- **Type**: CTE with LAG window function, parameterized query, LEFT JOIN
- **DMS**: FAILED
- **Manual Conversion**: Lowercase schema names applied
- **Equivalency**: ERROR ('uniqueID')

### Statement 3: InsertProductAsync
- **Type**: Transaction with DECLARE, INSERT, SCOPE_IDENTITY(), GETDATE()
- **DMS**: FAILED
- **Manual Conversion**: SCOPE_IDENTITY() → LASTVAL(), GETDATE() → NOW(), removed DECLARE, restructured transaction
- **Equivalency**: ERROR ('uniqueID')

### Statement 4: UpdateProductAsync
- **Type**: Transaction with DECLARE, SELECT into vars, UPDATE, GETDATE()
- **DMS**: FAILED
- **Manual Conversion**: Restructured to capture old values via INSERT...SELECT before update, GETDATE() → NOW()
- **Equivalency**: ERROR ('uniqueID')

### Statement 5: DeleteProductAsync
- **Type**: Transaction with DECLARE, SELECT into vars, DELETE, GETDATE()
- **DMS**: FAILED
- **Manual Conversion**: Restructured to capture old values via INSERT...SELECT before delete, GETDATE() → NOW()
- **Equivalency**: ERROR ('uniqueID')

### Statement 6: GetProductsByPriceRangeAsync
- **Type**: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
- **DMS**: FAILED
- **Manual Conversion**: Lowercase schema names applied
- **Equivalency**: ERROR ('uniqueID')

### Statement 7: GetLowStockProductsAsync
- **Type**: CTE with AVG/MIN/MAX OVER, CASE, ROUND
- **DMS**: FAILED
- **Manual Conversion**: Lowercase schema names applied, added CAST for integer division
- **Equivalency**: ERROR ('uniqueID')

## Files Modified

### 1. `sourceCode/DataAccess/ProductRepository.cs`
- Replaced `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- Replaced all 7 SQL statements with PostgreSQL-converted versions
- Replaced `SqlConnection` → `NpgsqlConnection`
- Replaced `SqlCommand` → `NpgsqlCommand`
- Replaced `SqlDataReader` → `NpgsqlDataReader`
- Transaction handling (BeginTransactionAsync/CommitAsync/RollbackAsync) compatible with Npgsql

### 2. `sourceCode/AdoCore.csproj`
- Replaced `<PackageReference Include="Microsoft.Data.SqlClient" Version="5.1.4" />`
- With `<PackageReference Include="Npgsql" Version="8.0.6" />`
- All other packages unchanged

### 3. `sourceCode/appsettings.json`
- Updated connection strings from SQL Server format to PostgreSQL format
- `Server=localhost` → `Host=localhost`
- Removed `Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True`
- Added `Username=postgres;Password=postgres`

## Artifacts Created
| File | Description |
|------|-------------|
| `extracted_statements.sql` | All 7 original MS SQL statements |
| `converted_statements.sql` | All 7 converted PostgreSQL statements |
| `sql_equivalency_validation_report.json` | Comprehensive equivalency validation report |
| `dms_failure_summary.md` | DMS failure documentation |
| `migration_report.md` | This migration report |

## Verification
- **Build**: `dotnet build AdoCore.sln` → **SUCCESS** (0 errors, 10 warnings - all pre-existing nullable warnings)
- **No remaining SQL Server references**: Verified by searching entire codebase
- **All public APIs preserved**: Method signatures unchanged
- **Security**: Parameterized queries maintained throughout
