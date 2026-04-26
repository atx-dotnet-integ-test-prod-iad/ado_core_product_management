# Migration Report: MS SQL Server to PostgreSQL

## Summary
This report documents the complete migration of the AdoCore .NET ADO application from Microsoft SQL Server to PostgreSQL.

## Migration Statistics

| Metric | Count |
|--------|-------|
| Total SQL Statements Processed | 17 |
| DMS Tool Successful Conversions | 0 |
| DMS Tool Failed Conversions | 17 |
| Manual Conversions (with lowercase schema) | 17 |
| SQL Equivalency - EQUIVALENT | 0 |
| SQL Equivalency - NOT_EQUIVALENT | 0 |
| SQL Equivalency - ERROR | 17 |

## DMS Tool Status
- **Tool**: dms-mcp___statement_conversion_tool
- **Migration Project**: arn:aws:dms:us-east-1:789616364195:migration-project:7Y3LT3YQEBH6LC5D7Z5XJNQ3VU
- **Status**: All conversion attempts failed
- **Error**: `Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}`
- **Attempts**: 8+ attempts with varying configurations (poll intervals, explicit database/server names)
- **Note**: DMS schema_mapping_tool WAS functional and provided accurate schema mappings used for manual conversion

## SQL Equivalency Tool Status
- **Tool**: sql-equivalency___validate_sql_equivalence
- **Status**: All validation attempts returned ERROR
- **Error**: `'uniqueID'`
- **Attempts**: 17 statement pairs validated, all returned same error
- **Note**: Error appears systemic/infrastructure-related, not query-specific

## Schema Mapping (from DMS schema_mapping_tool)
The DMS schema_mapping_tool successfully provided schema mappings:

| Source (MS SQL) | Target (PostgreSQL) |
|-----------------|---------------------|
| [dbo].[Products] | products (schema: productmanagement_dbo) |
| [dbo].[ProductHistory] | producthistory (schema: productmanagement_dbo) |
| [dbo].[ProductStats] | productstats (schema: productmanagement_dbo) |

### Data Type Mappings
| MS SQL Type | PostgreSQL Type |
|-------------|-----------------|
| int IDENTITY(1,1) | INTEGER GENERATED ALWAYS AS IDENTITY |
| nvarchar(n) | VARCHAR(n) |
| datetime | TIMESTAMP WITHOUT TIME ZONE |
| decimal(p,s) | NUMERIC(p,s) |
| bit | BOOLEAN |
| GETDATE() | clock_timestamp() |

## Files Modified

### 1. sourceCode/DataAccess/ProductRepository.cs
- **SQL Statements**: All 7 inline SQL statements converted to PostgreSQL syntax
  1. GetAllProductsAsync - CTE with window functions
  2. GetProductByIdAsync - CTE with LAG window function
  3. InsertProductAsync - Transaction with SCOPE_IDENTITY() → lastval()
  4. UpdateProductAsync - Transaction with variable declarations → subquery approach
  5. DeleteProductAsync - Transaction with variable declarations → subquery approach
  6. GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
  7. GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions
- **Imports**: `using Microsoft.Data.SqlClient;` → `using Npgsql;`
- **Class Replacements**:
  - SqlConnection → NpgsqlConnection
  - SqlCommand → NpgsqlCommand (7 instances)
  - SqlDataReader → NpgsqlDataReader
- **Column References**: MapProductFromReader updated with lowercase column names

### 2. sourceCode/AdoCore.csproj
- **Package Change**: `Microsoft.Data.SqlClient` 5.1.4 → `Npgsql` 8.0.1

### 3. sourceCode/appsettings.json
- **Connection Strings**: Converted from SQL Server to PostgreSQL format
  - `Server=localhost` → `Host=localhost`
  - Added `Port=5432`
  - `Trusted_Connection=True` → `Username=postgres;Password=postgres`
  - Removed `MultipleActiveResultSets=true`
  - Removed `TrustServerCertificate=True`

### 4. sourceCode/Scripts/01_InitialSetup.sql
- Converted from T-SQL to PostgreSQL syntax
- IF NOT EXISTS with sys.objects → CREATE TABLE IF NOT EXISTS
- Stored procedures → PostgreSQL functions
- SCOPE_IDENTITY() → RETURNING clause
- Removed GO batch separators and SET NOCOUNT ON

### 5. sourceCode/Database/Scripts/01_InitialSetup.sql
- Comprehensive conversion from T-SQL to PostgreSQL
- Tables, indexes, triggers, stored procedures, and sample data
- Trigger: `CREATE TRIGGER ON ... AFTER` → trigger function + `CREATE TRIGGER ... EXECUTE FUNCTION`
- `SYSTEM_USER` → `current_user`
- `inserted/deleted` pseudo-tables → `NEW/OLD`
- `bit` → `BOOLEAN`

## Build Status
- **Build Result**: SUCCESS
- **Errors**: 0
- **Warnings**: 12 (pre-existing nullable reference warnings + Npgsql vulnerability note)

## Key SQL Conversion Patterns Applied

| MS SQL Pattern | PostgreSQL Equivalent |
|----------------|----------------------|
| SCOPE_IDENTITY() | lastval() |
| GETDATE() | clock_timestamp() |
| BEGIN TRANSACTION | BEGIN |
| DECLARE @var TYPE; SET @var = val | Variable declarations in DO block or subquery |
| SELECT @var = col FROM table | SELECT col INTO var FROM table |
| nvarchar(n) | VARCHAR(n) |
| datetime | TIMESTAMP WITHOUT TIME ZONE |
| IDENTITY(1,1) | GENERATED ALWAYS AS IDENTITY |
| [dbo].[TableName] | tablename (lowercase) |
| CREATE OR ALTER PROCEDURE | CREATE OR REPLACE FUNCTION |
| SET NOCOUNT ON | (removed - not needed) |
| GO | (removed - T-SQL batch separator) |
| SYSTEM_USER | current_user |
| inserted/deleted | NEW/OLD |
| bit DEFAULT 1/0 | BOOLEAN DEFAULT TRUE/FALSE |

## Statements Requiring Manual Review
All 17 statements were manually converted due to DMS tool failure. All should be reviewed for correctness:
1. Transaction blocks (statements 3-5) were restructured to avoid T-SQL variable declarations
2. The trigger conversion requires PostgreSQL trigger function + trigger creation pattern
3. Window functions and CTEs syntax is compatible between MS SQL and PostgreSQL with only naming changes

## Artifacts
- `extracted_statements.sql` - Original MS SQL statements from ProductRepository.cs
- `converted_statements.sql` - Converted PostgreSQL statements
- `sql_equivalency_validation_report.json` - Complete equivalency validation report (17 pairs, all ERROR)
- `migration_report.md` - This report
